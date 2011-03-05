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
#import <OoliteBase/OoliteBase.h>
#import <OoliteBase/OOConfParsingInternal.h>
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

#if OLD
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
#endif


@interface OOMeshReader (OOPrivate)

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportStructuralError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)expected;
- (void) priv_reportMallocFailure;

- (BOOL) priv_rootParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object;
- (BOOL) priv_readRootValueForKey:(NSString *)key;

- (BOOL) priv_materialsDictionaryParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object;
- (BOOL)priv_readMaterialDictionaryNamed:(NSString *)name;

- (BOOL) priv_attributesDictionaryParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object;
- (BOOL) priv_attributeParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object;
- (OOFloatArray *) priv_readAttributeDataWithDictionary:(NSMutableDictionary *)dictionary;

- (BOOL) priv_groupsDictionaryParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object;
- (BOOL) priv_groupParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object;
- (OOIndexArray *) priv_readGroupDataWithDictionary:(NSMutableDictionary *)dictionary;
- (BOOL) priv_finishGroupWithDictionary:(NSMutableDictionary *)dictionary;

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
		_parser = [[OOConfParser alloc] initWithLexer:_lexer];
		if (_parser == nil)  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_path);
	DESTROY(_lexer);
	DESTROY(_parser);
	DESTROY(_renderMesh);
	
	DESTROY(_meshName);
	DESTROY(_attributeArrays);
	DESTROY(_groupIndexArrays);
	DESTROY(_groupMaterials);
	
	[super dealloc];
}


- (void) parse
{
	if (_parser == nil)  return;	// Parsed already or initialization failed.
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	_attributeArrays = [[NSMutableDictionary alloc] init];
	_groupIndexArrays = [[NSMutableArray alloc] init];
	_groupMaterials = [[NSMutableArray alloc] init];
	
	_vertexCount = NSNotFound;
	
	[_parser setDelegate:self];
	BOOL OK = [_parser parseWithDelegateAction:@selector(priv_rootParseEvent:key:object:) result:NULL];
	
	if (OK)
	{
		[_lexer advance];
		if (![_lexer getToken:kOOConfTokenEOF])
		{
			OOReportWarning(_issues, @"There is unknown data after the end of the file, which will be ignored.");
		}
	}
	
	DESTROY(_lexer);
	DESTROY(_parser);
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


- (void) priv_reportParseError:(NSString *)format, ...
{
	NSString *base = OOLocalizeProblemString(_issues, @"Parse error on line %u: %@.");
	format = OOLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [[_parser lexer] lineNumber], message];
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
	
	message = [NSString stringWithFormat:base, [[_parser lexer] lineNumber], message];
	[_issues addProblemOfType:kOOProblemTypeError message:message];
}


- (void) priv_reportBasicParseError:(NSString *)expected
{
	NSString *key = [@"expected-" stringByAppendingString:expected];
	NSString *localized = OOLocalizeProblemString(_issues, key);
	if (localized == key)  localized = expected;
	
	[self priv_reportParseError:@"expected %@, got %@", localized, [[_parser lexer] currentTokenDescription]];
}


- (void) priv_reportMallocFailure
{
	OOReportError(_issues, @"Not enough memory to read %@.", [[NSFileManager defaultManager] displayNameAtPath:_path]);
}


- (BOOL) priv_rootParseEvent:(OOConfParserActionEventType)event
						 key:(void *)key
					  object:(id *)object
{
	switch (event)
	{
		case kOOConfArrayBegin:
		case kOOConfArrayElement:
		case kOOConfArrayEnd:
		case kOOConfArrayFailed:
			[self priv_reportStructuralError:@"the root element must be a dictionary"];
			return NO;
			
		case kOOConfDictionaryBegin:
		case kOOConfDictionaryEnd:
		case kOOConfDictionaryFailed:
			// Ignore these events.
			return YES;
			
		case kOOConfDictionaryElement:
			return [self priv_readRootValueForKey:key];
	}
	
	return NO;
}


- (BOOL) priv_readRootValueForKey:(NSString *)key
{
	if ([kVertexCountKey isEqualToString:key])
	{
		if (_vertexCount != NSNotFound)
		{
			[self priv_reportStructuralError:@"vertexCount appears more than once"];
			return NO;
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
		if ([_lexer currentTokenType] != kOOConfTokenOpenBrace)
		{
			[self priv_reportStructuralError:@"%@ must be a dictionary", key];
			return NO;
		}
		
		/*	_materialsByName is created here instead of at the beginning of
			-parse so that we use it to check whether we've seen the materials
			section yet (below):
		*/
		
		_materialsByName = [NSMutableDictionary dictionary];
		return [_parser parseWithDelegateAction:@selector(priv_materialsDictionaryParseEvent:key:object:) result:NULL];
	}
	else if ([kAttributesSectionKey isEqualToString:key])
	{
		if ([_lexer currentTokenType] != kOOConfTokenOpenBrace)
		{
			[self priv_reportStructuralError:@"%@ must be a dictionary", key];
			return NO;
		}
		
		//	"attributes" must appear after "vertexCount".
		if (_vertexCount == NSNotFound)
		{
			[self priv_reportStructuralError:@"The %@ section must appear after %@", key, kVertexCountKey];
			return NO;
		}
		
		return [_parser parseWithDelegateAction:@selector(priv_attributesDictionaryParseEvent:key:object:) result:NULL];
	}
	else if ([kGroupsSectionKey isEqualToString:key])
	{
		if ([_lexer currentTokenType] != kOOConfTokenOpenBrace)
		{
			[self priv_reportStructuralError:@"%@ must be a dictionary", key];
			return NO;
		}
		
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
		
		return [_parser parseWithDelegateAction:@selector(priv_groupsDictionaryParseEvent:key:object:) result:NULL];
	}
	else if ([kMeshDescriptionKey isEqualToString:key])
	{
		id property = [_parser parseAsPropertyList];
		if (property == nil)  return NO;
		
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
		return [_parser parseWithDelegateAction:NULL result:NULL];
	}
}


- (BOOL) priv_materialsDictionaryParseEvent:(OOConfParserActionEventType)event
										key:(void *)key
									 object:(id *)object
{
	switch (event)
	{
		case kOOConfArrayBegin:
		case kOOConfArrayElement:
		case kOOConfArrayEnd:
		case kOOConfArrayFailed:
			// Should have been checked already.
			return NO;
			
		case kOOConfDictionaryBegin:
		case kOOConfDictionaryEnd:
		case kOOConfDictionaryFailed:
			// Ignore these events.
			return YES;
			
		case kOOConfDictionaryElement:
			return [self priv_readMaterialDictionaryNamed:key];
	}
	
	return NO;
}


- (BOOL)priv_readMaterialDictionaryNamed:(NSString *)name
{
	id propertyList = [_parser parseAsPropertyList];
	if (propertyList == nil)  return NO;
	
	OOMaterialSpecification *material = [[OOMaterialSpecification alloc] initWithMaterialKey:name
																  propertyListRepresentation:propertyList
																					  issues:_issues];
	if (material == nil)  return NO;
	
	[_materialsByName setObject:material forKey:name];
	[material release];
	
	return YES;
}


- (BOOL) priv_attributesDictionaryParseEvent:(OOConfParserActionEventType)event
										 key:(void *)key
									  object:(id *)object
{
	switch (event)
	{
		case kOOConfArrayBegin:
		case kOOConfArrayElement:
		case kOOConfArrayEnd:
		case kOOConfArrayFailed:
			// Should have been checked already.
			return NO;
			
		case kOOConfDictionaryBegin:
		case kOOConfDictionaryEnd:
		case kOOConfDictionaryFailed:
			// Ignore these events.
			return YES;
			
		case kOOConfDictionaryElement:
			_currentElementName = key;
			BOOL result = [_parser parseWithDelegateAction:@selector(priv_attributeParseEvent:key:object:) result:object];
			_currentElementName = nil;
			return result;
	}
	
	return NO;
}


- (BOOL) priv_attributeParseEvent:(OOConfParserActionEventType)event
							  key:(void *)key
						   object:(id *)object
{
	switch (event)
	{
		case kOOConfArrayBegin:
		case kOOConfArrayElement:
		case kOOConfArrayEnd:
		case kOOConfArrayFailed:
			// Should have been checked already.
			return NO;
			
		case kOOConfDictionaryBegin:
			*object = [NSMutableDictionary dictionary];
			return YES;
			
		case kOOConfDictionaryEnd:
		{
			OOFloatArray *attributeData = [*object objectForKey:kDataKey];
			if (attributeData == nil)
			{
				[self priv_reportStructuralError:@"Attribute \"%@\" has no vertex data", _currentElementName];
				return NO;
			}
			
			[_attributeArrays setObject:attributeData forKey:_currentElementName];
			[*object removeAllObjects];
			return YES;
		}
			
		case kOOConfDictionaryFailed:
			return YES;
			
		case kOOConfDictionaryElement:
		{
			id value = nil;
			if ([kDataKey isEqualToString:key])
			{
				value = [self priv_readAttributeDataWithDictionary:*object];
			}
			else
			{
				value = [_parser parseAsPropertyList];
			}
			if (value == nil)  return NO;
			[*object setObject:value forKey:key];
			return YES;
		}
	}
	
	return NO;
}


- (OOFloatArray *) priv_readAttributeDataWithDictionary:(NSMutableDictionary *)dictionary
{
	OOUInteger size = [dictionary oo_unsignedIntegerForKey:kSizeKey];
	if (size < 1 || 4 < size)
	{
		[self priv_reportStructuralError:@"attribute \"%@@\" does not specify a valid size (must be 1 to 4)", _currentElementName];
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


- (BOOL) priv_groupsDictionaryParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object
{
	switch (event)
	{
		case kOOConfArrayBegin:
		case kOOConfArrayElement:
		case kOOConfArrayEnd:
		case kOOConfArrayFailed:
			// Should have been checked already.
			return NO;
			
		case kOOConfDictionaryBegin:
		case kOOConfDictionaryEnd:
		case kOOConfDictionaryFailed:
			// Ignore these events.
			return YES;
			
		case kOOConfDictionaryElement:
			_currentElementName = key;
			BOOL result = [_parser parseWithDelegateAction:@selector(priv_groupParseEvent:key:object:) result:object];
			_currentElementName = nil;
			return result;
	}
	
	return NO;
}


- (BOOL) priv_groupParseEvent:(OOConfParserActionEventType)event
						  key:(void *)key
					   object:(id *)object
{
	switch (event)
	{
		case kOOConfArrayBegin:
		case kOOConfArrayElement:
		case kOOConfArrayEnd:
		case kOOConfArrayFailed:
			// Should have been checked already.
			return NO;
			
		case kOOConfDictionaryBegin:
			*object = [NSMutableDictionary dictionary];
			return YES;
			
		case kOOConfDictionaryEnd:
		{
			BOOL OK = [self priv_finishGroupWithDictionary:*object];
			[*object removeAllObjects];
			return OK;
		}
			
		case kOOConfDictionaryFailed:
			return YES;
			
		case kOOConfDictionaryElement:
		{
			id value = nil;
			if ([kDataKey isEqualToString:key])
			{
				value = [self priv_readGroupDataWithDictionary:*object];
			}
			else
			{
				value = [_parser parseAsPropertyList];
			}
			if (value == nil)  return NO;
			[*object setObject:value forKey:key];
			return YES;
		}
	}
	
	return NO;
}


- (OOIndexArray *) priv_readGroupDataWithDictionary:(NSMutableDictionary *)dictionary
{
	OOUInteger size = [dictionary oo_unsignedIntegerForKey:kFaceCountKey];
	if (size < 1 || kMaximumFaceCount < size)
	{
		[self priv_reportStructuralError:@"group \"%@\" does not specify a valid size (must be 1 to %u)", _currentElementName, kMaximumFaceCount];
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


- (BOOL) priv_finishGroupWithDictionary:(NSMutableDictionary *)dictionary
{
	// Groups must have materials.
	NSString *materialKey = [dictionary oo_stringForKey:kMaterialKey];
	if (materialKey == nil)
	{
		[self priv_reportStructuralError:@"Mesh group \"%@\" does not specify a material", _currentElementName];
		return NO;
	}
	OOMaterialSpecification *materialSpec = [_materialsByName objectForKey:materialKey];
	if (materialSpec == nil)
	{
		[self priv_reportStructuralError:@"Mesh group \"%@\" specifies undefined material \"%@\"", _currentElementName, materialKey];
		return NO;
	}
	
	OOIndexArray *data = [dictionary objectForKey:kDataKey];
	if (data == nil)
	{
		[self priv_reportStructuralError:@"Mesh group \"%@\" has no vertex index data", _currentElementName];
		return NO;
	}
	
	[_groupIndexArrays addObject:data];
	[_groupMaterials addObject:materialSpec];
	
	return YES;
}

@end
