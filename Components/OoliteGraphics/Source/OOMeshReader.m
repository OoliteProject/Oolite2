/*
	OOMeshReader.m
	
	
	Copyright © 2011 Jens Ayton.
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/


#import "OOMeshReader.h"
#import <OoliteBase/OOConfLexer.h>
#import "OOMeshDefinitions.h"

#import "OOIndexArray.h"
#import "OORenderMesh.h"
#import "OOMaterialSpecification.h"
#import "OOAbstractMesh.h"


enum
{
	/*
		Allow up to half a billion vertices and half a billion faces per group
		- far too many to be practical, but not enough to start causing range
		problems.
	 */
	kMaximumVertexCount			= 500000000,
	kMaximumFaceCount			= 500000000,
};


/*
	For the purposes of mesh parsing, JSON objects/dictionaries come in a few
	flavours. For efficient parsing, we need to know which type we're in.
	
	The root element is a dictionary which contains sections.
	There are three "sections", i.e. root-child dictionaries with predefined
	names: "materials", "attributes" and "groups".
	The values in each section have their own dictionary types.
	
	Every other dictionary is of type "general", with no special parsing
	behaviour.
*/
typedef enum
{
	kDictTypeRoot,
	kDictTypeMaterialsSection,
	kDictTypeMaterial,
	kDictTypeAttributesSection,
	kDictTypeAttribute,
	kDictTypeGroupsSection,
	kDictTypeGroup,
	kDictTypeGeneral
} DictionaryType;


@interface OOMeshReader (Private)

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportStructuralError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)expected;
- (void) priv_reportMallocFailure;

- (BOOL) priv_readDictionary:(NSDictionary **)outDictionary ofType:(DictionaryType)type withKey:(NSString *)key;
- (BOOL) priv_readRootValueForKey:(NSString *)key;
- (BOOL) priv_readArray:(NSArray **)outArray;
- (BOOL) priv_readProperty:(id *)outProperty;

@end


@implementation OOMeshReader

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues
{
	if ((self = [super init]))
	{
		_issues = [issues retain];
		_path = [path copy];
		
		_vertexCount = NSNotFound;
		
		_lexer = [[OOConfLexer alloc] initWithPath:_path issues:_issues];
		if (_lexer == nil)  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_path);
	DESTROY(_lexer);
	DESTROY(_renderMesh);
	
	DESTROY(_meshName);
	DESTROY(_attributeArrays);
	DESTROY(_groupIndexArrays);
	DESTROY(_groupMaterials);
	
	[super dealloc];
}


- (void) parse
{
	if (_lexer == nil)  return;	// Parsed already or initialization failed.
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	_attributeArrays = [[NSMutableDictionary alloc] init];
	_groupIndexArrays = [[NSMutableArray alloc] init];
	_groupMaterials = [[NSMutableArray alloc] init];
	
	_vertexCount = NSNotFound;
	
	[_lexer advance];
	BOOL OK = [self priv_readDictionary:NULL ofType:kDictTypeRoot withKey:nil];
	
	if (OK)
	{
		[_lexer advance];
		if (![_lexer getToken:kOOConfTokenEOF])
		{
			OOReportWarning(_issues, @"There is unknown data after the end of the file, which will be ignored.");
		}
	}
	
	DESTROY(_lexer);
	_materialsByName = nil;
	
	[pool drain];
}


#if !OOLITE_LEAN

- (OOAbstractMesh *) abstractMesh
{
	OORenderMesh *renderMesh = nil;
	[self getRenderMesh:&renderMesh andMaterialSpecs:NULL];
	
	OOAbstractMesh *mesh = [renderMesh abstractMeshWithMaterialSpecs:_groupMaterials];
	
	if (_meshName != nil)  [mesh setName:_meshName];
	if (_meshDescription != nil)  [mesh setModelDescription:_meshDescription];
	
	return mesh;
}


- (BOOL) prefersAbstractMesh
{
	return NO;
}


- (NSString *) meshName
{
	[self parse];
	
	return _meshName;
}


- (NSString *) meshDescription
{
	[self parse];
	
	return _meshDescription;
}

#endif


- (void) getRenderMesh:(OORenderMesh **)renderMesh andMaterialSpecs:(NSArray **)materialSpecifications
{
	if (renderMesh != NULL)
	{
		if (_renderMesh == nil)
		{
			[self parse];
			if ([_attributeArrays count] > 0 && [_groupIndexArrays count] > 0)
			{
				_renderMesh = [[OORenderMesh alloc] initWithName:_meshName
													 vertexCount:_vertexCount
													  attributes:_attributeArrays
														  groups:_groupIndexArrays];
			}
			else
			{
				_renderMesh = [[NSNull null] retain];
			}

		}
		
		if (_renderMesh != (id)[NSNull null])
		{
			*renderMesh = _renderMesh;
		}
		else
		{
			*renderMesh = nil;
		}

	}
	
	if (materialSpecifications != NULL)
	{
		*materialSpecifications = _groupMaterials;
	}
}

@end


@implementation OOMeshReader (Private)

- (void) priv_reportParseError:(NSString *)format, ...
{
	NSString *base = OOLocalizeProblemString(_issues, @"Parse error on line %u: %@.");
	format = OOLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [_lexer lineNumber], message];
	[_issues addProblemOfType:kOOProblemTypeError message:message];
}


- (void) priv_reportStructuralError:(NSString *)format, ...
{
	NSString *base = OOLocalizeProblemString(_issues, @"Structural error on line %u: %@.");
	format = OOLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [_lexer lineNumber], message];
	[_issues addProblemOfType:kOOProblemTypeError message:message];
}


- (void) priv_reportBasicParseError:(NSString *)expected
{
	NSString *key = [@"expected-" stringByAppendingString:expected];
	NSString *localized = OOLocalizeProblemString(_issues, key);
	if (localized == key)  localized = expected;
	
	[self priv_reportParseError:@"expected %@, got %@", localized, [_lexer currentTokenDescription]];
}


- (void) priv_reportMallocFailure
{
	OOReportError(_issues, @"Not enough memory to read %@.", [[NSFileManager defaultManager] displayNameAtPath:_path]);
}


- (BOOL) priv_completeMaterialWithDictionary:(NSMutableDictionary *)dictionary data:(id)data name:(NSString *)name
{
	OOMaterialSpecification *material = [[OOMaterialSpecification alloc] initWithMaterialKey:name
																  propertyListRepresentation:dictionary
																					  issues:_issues];
	if (material == nil)  return NO;
	
	[_materialsByName setObject:material forKey:name];
	[material release];
	
	return YES;
}


- (id) priv_readAttributeDataWithDictionary:(NSMutableDictionary *)dictionary name:(NSString *)name
{
	OOUInteger size = [dictionary oo_unsignedIntegerForKey:kSizeKey];
	if (size < 1 || 4 < size)
	{
		[self priv_reportStructuralError:@"attribute \"%@\" does not specify a valid size (must be 1 to 4)"];
		return nil;
	}
	NSAssert(_vertexCount != NSNotFound, @"Vertex count should have been validated already");
	
	OOConfLexer *lexer = _lexer;
	if (![lexer getToken:kOOConfTokenOpenBracket])
	{
		[self priv_reportBasicParseError:@"["];
		return nil;
	}
	[lexer advance];
	
	NSUInteger i = 0, count = _vertexCount * size;
	float *buffer = malloc(count * sizeof (float));
	if (buffer == NULL)
	{
		[self priv_reportMallocFailure];
		return nil;
	}
	
	// Read <count> reals.
	for (;;)
	{
		if (EXPECT_NOT(![lexer getFloat:&buffer[i]]))
		{
			[self priv_reportBasicParseError:@"number"];
			return nil;
		}
		
		if (++i == count)  break;
		
		if (EXPECT_NOT(![lexer consumeToken:kOOConfTokenComma]))
		{
			[self priv_reportBasicParseError:@"\",\""];
			return nil;
		}
		[lexer advance];
	}
	
	if (![lexer consumeToken:kOOConfTokenCloseBracket])
	{
		[self priv_reportBasicParseError:@"\"]\""];
		return nil;
	}
	
	return [OOFloatArray arrayWithFloatsNoCopy:buffer count:count freeWhenDone:YES];
}


- (BOOL) priv_completeAttributeWithDictionary:(NSMutableDictionary *)dictionary data:(id)data name:(NSString *)name
{
	[_attributeArrays setObject:data forKey:name];
	return YES;
}


- (id) priv_readGroupDataWithDictionary:(NSMutableDictionary *)dictionary name:(NSString *)name
{
	OOUInteger size = [dictionary oo_unsignedIntegerForKey:kFaceCountKey];
	if (size < 1 || kMaximumFaceCount < size)
	{
		[self priv_reportStructuralError:@"group \"%@\" does not specify a valid size (must be 1 to %u)", kMaximumFaceCount];
		return nil;
	}
	NSAssert(_vertexCount != NSNotFound, @"Vertex count should have been validated already.");
	
	OOConfLexer *lexer = _lexer;
	if (![lexer getToken:kOOConfTokenOpenBracket])
	{
		[self priv_reportBasicParseError:@"["];
		return nil;
	}
	[lexer advance];
	
	NSUInteger i = 0, count = 3 * size, vertexCount = _vertexCount;
	GLuint *buffer = malloc(count * sizeof (GLuint));
	if (buffer == NULL)
	{
		[self priv_reportMallocFailure];
		return nil;
	}
	
	// Read <count> integers.
	for (;;)
	{
		uint64_t value;
		if (EXPECT_NOT(![lexer getNatural:&value]))
		{
			[self priv_reportBasicParseError:@"integer"];
			return nil;
		}
		if (EXPECT_NOT(value >= vertexCount))
		{
			[self priv_reportParseError:@"vertex index %llu is out of range (vertex count is %lu)", (unsigned long long)value, (unsigned long)vertexCount];
			return nil;
		}
		buffer[i] = value;
		
		if (++i == count)  break;
		
		if (EXPECT_NOT(![lexer consumeToken:kOOConfTokenComma]))
		{
			[self priv_reportBasicParseError:@"\",\""];
			return nil;
		}
		[lexer advance];
	}
	
	if (![lexer consumeToken:kOOConfTokenCloseBracket])
	{
		[self priv_reportBasicParseError:@"\"]\""];
		return nil;
	}
	
	return [OOIndexArray arrayWithUnsignedIntsNoCopy:buffer count:count maximum:vertexCount freeWhenDone:YES];
}


- (BOOL) priv_completeGroupWithDictionary:(NSMutableDictionary *)dictionary data:(id)data name:(NSString *)name
{
	// Groups must have materials.
	NSString *materialKey = [dictionary oo_stringForKey:kMaterialKey];
	if (materialKey == nil)
	{
		[self priv_reportStructuralError:@"Mesh hroup \"%@\" does not specify a material", name];
		return NO;
	}
	OOMaterialSpecification *materialSpec = [_materialsByName objectForKey:materialKey];
	if (materialSpec == nil)
	{
		[self priv_reportStructuralError:@"Mesh group \"%@\" specifies undefined material \"%@\"", name, materialKey];
		return NO;
	}
	
	[_groupIndexArrays addObject:data];
	[_groupMaterials addObject:materialSpec];
	
	return YES;
}


- (BOOL) priv_readDictionary:(NSDictionary **)outDictionary ofType:(DictionaryType)type withKey:(NSString *)parentKey
{
	NSMutableDictionary *dictionary = nil;
	BOOL				isGroup = NO;
	DictionaryType		subType = kDictTypeGeneral;
	SEL					dataHandlerSEL = NULL;
	SEL					completionHandlerSEL = NULL;
	id					data = nil;
	NSString			*entryType = nil;	// For section entries, the name of the section; used for error reporting.
	
	// Set up DictionaryType-dependent parsing parameters.
	switch (type)
	{
		case kDictTypeMaterialsSection:
			isGroup = YES;
			subType = kDictTypeMaterial;
			break;
			
		case kDictTypeMaterial:
			entryType = kMaterialsSectionKey;
			completionHandlerSEL = @selector(priv_completeMaterialWithDictionary:data:name:);
			break;
			
		case kDictTypeAttributesSection:
			isGroup = YES;
			subType = kDictTypeAttribute;
			break;
			
		case kDictTypeAttribute:
			entryType = kAttributesSectionKey;
			dataHandlerSEL = @selector(priv_readAttributeDataWithDictionary:name:);
			completionHandlerSEL = @selector(priv_completeAttributeWithDictionary:data:name:);
			break;
			
		case kDictTypeGroupsSection:
			isGroup = YES;
			subType = kDictTypeGroup;
			break;
			
		case kDictTypeGroup:
			entryType = kGroupsSectionKey;
			dataHandlerSEL = @selector(priv_readGroupDataWithDictionary:name:);
			completionHandlerSEL = @selector(priv_completeGroupWithDictionary:data:name:);
			break;
		
		case kDictTypeGeneral:
		case kDictTypeRoot:
			break;
	}
	
	// Create result dictionary, if there's a consumer for it.
	if (outDictionary != NULL || completionHandlerSEL != NULL)  dictionary = [NSMutableDictionary dictionary];
	
	
	// Be a dictionary, or else.
	if (![_lexer getToken:kOOConfTokenOpenBrace])
	{
		[self priv_reportBasicParseError:@"\"{\""];
		return NO;
	}
	[_lexer advance];
	
	BOOL OK = YES;
	BOOL stop = [_lexer currentTokenType] == kOOConfTokenCloseBrace;
	
	// For each pair...
	while (OK && !stop)
	{
		NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
		
		// We should be at a key or the closing brace.
		OOConfTokenType token = [_lexer currentTokenType];
		if (token == kOOConfTokenKeyword || token == kOOConfTokenString)
		{
			// Read the key.
			NSString *keyValue = [_lexer currentTokenString];
			[_lexer advance];
			
			// Skip the colon.
			if (![_lexer getToken:kOOConfTokenColon])
			{
				[self priv_reportBasicParseError:@"\":\""];
				OK = NO;
			}
			if (OK)
			{
				[_lexer advance];
				
				// Handle the various special cases.
				if (isGroup)
				{
					// Groups can only contain dictionaries.
					OK = [self priv_readDictionary:NULL ofType:subType withKey:keyValue];
				}
				else if (type == kDictTypeRoot)
				{
					// Root dictionary has funky requirements.
					OK = [self priv_readRootValueForKey:keyValue];
				}
				else  if (dataHandlerSEL != NULL && [kDataKey isEqualToString:keyValue])
				{
					// Data sections for attributes and groups.
					if (data != nil)
					{
						[self priv_reportStructuralError:@"\"data\" occurred twice in %@ entry \"%@\"", entryType, parentKey];
						OK = NO;
					}
					else
					{
						data = [self performSelector:dataHandlerSEL withObject:dictionary withObject:parentKey];
						OK = (data != nil);
					}
				}
				else
				{
					// The general case: read a dictionary key.
					id value = nil;
					OK = [self priv_readProperty:&value];
					if (OK)
					{
						[dictionary setObject:value forKey:keyValue];
					}
				}
			}
		}
		
		if (OK)
		{
			// We now expect a comma or closing brace.
			if (![_lexer advance])
			{
				OK = NO;
				[self priv_reportBasicParseError:@"\",\" or \"}\""];
			}
			else
			{
				token = [_lexer currentTokenType];
				
				if (token == kOOConfTokenComma)
				{
					[_lexer advance];
				}
				else if (token == kOOConfTokenCloseBrace)
				{
					stop = YES;
				}
				else
				{
					OK = NO;
					[self priv_reportBasicParseError:@"\",\" or \"}\""];
				}
			}
		}
		
		[innerPool drain];
	}
	
	if (OK)
	{
		if (completionHandlerSEL != NULL)
		{
			typedef BOOL(*CompletionIMP)(id self, SEL _cmd, NSMutableDictionary *dictionary, id data, NSString *name);
			CompletionIMP completionHandler = (CompletionIMP)[self methodForSelector:completionHandlerSEL];
			NSAssert(completionHandler != NULL, @"Wonky completion handler.");
			OK = completionHandler(self, completionHandlerSEL, dictionary, data, parentKey);
		}
		if (OK && outDictionary != NULL)  *outDictionary = dictionary;
	}
	
	return OK;
}


- (BOOL) priv_readRootValueForKey:(NSString *)key
{
	if ([kVertexCountKey isEqualToString:key])
	{
		if (_vertexCount != NSNotFound)
		{
			[self priv_reportStructuralError:@"vertexCount appears more than once"];
		}
		
		uint64_t natural;
		if (![_lexer getNatural:&natural])
		{
			[self priv_reportStructuralError:@"vertexCount must be an integer"];
			return NO;
		}
		
		if (natural >= kMaximumVertexCount)
		{
			[self priv_reportStructuralError:@"vertexCount may not be more than %u", kMaximumVertexCount];
			return NO;
		}
		
		_vertexCount = natural;
		return YES;
	}
	else if ([kMaterialsSectionKey isEqualToString:key])
	{
		/*	_materialsByName is created here instead of at the beginning of
			-parse so that we use it to check whether we've seen the materials
			section yet (below):
		*/
		_materialsByName = [NSMutableDictionary dictionary];
		return [self priv_readDictionary:NULL ofType:kDictTypeMaterialsSection withKey:key];
	}
	else if ([kAttributesSectionKey isEqualToString:key])
	{
		//	"attributes" must appear after "vertexCount".
		if (_vertexCount == NSNotFound)
		{
			[self priv_reportStructuralError:@"The %@ section must appear after %@", key, kVertexCountKey];
			return NO;
		}
		
		return [self priv_readDictionary:NULL ofType:kDictTypeAttributesSection withKey:key];
	}
	else if ([kGroupsSectionKey isEqualToString:key])
	{
		//	"groups" must appear after "vertexCount" and "materials".
		if (_vertexCount == NSNotFound)
		{
			[self priv_reportStructuralError:@"The %@ section must appear after %@", key, kVertexCountKey];
			return NO;
		}
		if (_materialsByName == nil)
		{
			[self priv_reportStructuralError:@"The %@ section must appear after %@", key, kMaterialsSectionKey];
			return NO;
		}
		
		return [self priv_readDictionary:NULL ofType:kDictTypeGroupsSection withKey:key];
	}
	else if ([kMeshDescriptionKey isEqualToString:key])
	{
		id property = nil;
		if (![self priv_readProperty:&property])  return NO;
		
		if ([property isKindOfClass:[NSString class]])
		{
			DESTROY(_meshDescription);
			_meshDescription = [property retain];
		}
		else
		{
			OOReportWarning(_issues, @"Ignoring \"description\" value because it isn't a string.");
		}
		return YES;
	}
	else
	{
		//	Unknown root-level property; permit for future expansion.
		return [self priv_readProperty:NULL];
	}
}


- (BOOL) priv_readArray:(NSArray **)outArray
{
	NSMutableArray		*result = nil;
	
	if (outArray != NULL)  result = [NSMutableArray array];
	
	// Ensure that we're dealing with an array.
	if (![_lexer getToken:kOOConfTokenOpenBracket])
	{
		[self priv_reportBasicParseError:@"\"[\""];
		return NO;
	}
	[_lexer advance];
	
	BOOL				OK = YES;
	BOOL				stop = [_lexer currentTokenType] == kOOConfTokenCloseBracket;
	
	while (OK && !stop)
	{
		NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
		
		OOConfTokenType token = [_lexer currentTokenType];
		if (token == kOOConfTokenCloseBracket)
		{
			stop = YES;
		}
		else
		{
			id propertyValue = nil;
			id *propertyPtr = NULL;
			if (outArray != NULL)  propertyPtr = &propertyValue;
			
			OK = [self priv_readProperty:propertyPtr];
			if (OK)
			{
				[result addObject:propertyValue];
			}
		}
		
		if (OK)
		{
			// We now expect a comma or closing bracket.
			if (![_lexer advance])
			{
				OK = NO;
				[self priv_reportBasicParseError:@"\",\" or \"]\""];
			}
			else
			{
				token = [_lexer currentTokenType];
				
				if (token == kOOConfTokenComma)
				{
					[_lexer advance];
				}
				else if (token == kOOConfTokenCloseBracket)
				{
					stop = YES;
				}
				else
				{
					OK = NO;
					[self priv_reportBasicParseError:@"\",\" or \"]\""];
				}
			}
		}
		
		[innerPool drain];
	}
	
	if (OK && outArray != NULL)  *outArray = result;
	return OK;
}


- (BOOL) priv_readProperty:(id *)outProperty
{
	id					result = nil;
	BOOL				OK = NO;
	
	switch ([_lexer currentTokenType])
	{
			
		case kOOConfTokenString:
			OK = [_lexer getString:&result];
			break;
			
		case kOOConfTokenNatural:
		{
			uint64_t natural;
			OK = [_lexer getNatural:&natural];
			if (OK)  result = [NSNumber numberWithUnsignedLongLong:natural];
			break;
		}
			
		case kOOConfTokenReal:
		{
			double value;
			OK = [_lexer getDouble:&value];
			if (OK)  result = [NSNumber numberWithDouble:value];
			break;
		}
			
		case kOOConfTokenOpenBrace:
			return [self priv_readDictionary:outProperty ofType:kDictTypeGeneral withKey:nil];
			/*	Don't break for validation because readDictionary: can parse a
				dictionary without generating a value if outProperty is NULL.
			*/
			
		case kOOConfTokenOpenBracket:
			return [self priv_readArray:outProperty];
			/*	Don't break for validation because readDictionary: can parse a
				dictionary without generating a value if outProperty is NULL.
			*/
			
		case kOOConfTokenKeyword:
		{
			NSString *stringValue = [_lexer currentTokenString];
			
			OK = YES;
			if ([@"true" isEqualToString:stringValue])  result = $true;
			else if ([@"false" isEqualToString:stringValue])  result = $false;
			else if ([@"null" isEqualToString:stringValue])  result = $null;
			else
			{
				[self priv_reportBasicParseError:@"value"];
				OK = NO;
			}
			
			break;
		}
			
		default:
			[self priv_reportBasicParseError:@"value"];
			OK = NO;
	}
	
	if (OK && result == nil)
	{
		[self priv_reportParseError:@"internal error: property parser reported success but produced no value"];
		OK = NO;
	}
	
	if (outProperty != NULL)  *outProperty = result;
	return OK;
}

@end
