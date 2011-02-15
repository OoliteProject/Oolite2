/*
	OOMeshReader.m
	
	
	Copyright © 2010 Jens Ayton.
	
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
#import "OOMeshLexer.h"
#import "OOIndexArray.h"

#import "OORenderMesh.h"
#import "OOMaterialSpecification.h"
#import "OOAbstractMesh.h"


typedef enum
{
	kStoppedWithoutSeparator,
	kStoppedWithSeparator,
	kStoppedWithTerminator,
	kStoppedWithDoubleComma
} ConsumeSeparatorOrTerminatorResult;


@interface OOMeshReader (Private)

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)expected;
- (void) priv_reportMallocFailure;

- (BOOL) priv_readSectionNamed:(NSString *)name ofType:(NSString *)type;
- (BOOL) priv_readProperty:(id *)outProperty;
- (BOOL) priv_readDictionary:(NSDictionary **)outDictionary;
- (BOOL) priv_readArray:(NSArray **)outArray;

/*	Advance when reading a dictionary or array.
	A separator consists of at least one newline, or zero or more newlines with one comma in.
	A terminator consists of an optional separator of either form, followed by the specified terminator token.
*/
- (ConsumeSeparatorOrTerminatorResult) priv_consumeSeparatorOrTerminator:(OOMeshTokenType)terminator;

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
		
		_lexer = [[OOMeshLexer alloc] initWithPath:_path issues:_issues];
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
	
	BOOL OK = YES;
	NSMutableDictionary *rootProperties = [NSMutableDictionary dictionary];
	
	_unknownSectionTypes = [NSMutableSet set];
	_materialsByName = [NSMutableDictionary dictionary];
	
	_attributeArrays = [[NSMutableDictionary alloc] init];
	_groupIndexArrays = [[NSMutableArray alloc] init];
	_groupMaterials = [[NSMutableArray alloc] init];
	
	/*	The root element is structurally similar to a section, but it's
		currently the only one that can contain other sections, and there must
		be exactly one root of type oomesh, so it's a special case.
	*/
	NSString *keyValue = nil;
	id propertyValue = nil;
	
	[_lexer advance];
	if (OK)
	{
		OK = [_lexer getKeywordOrString:&keyValue];
		if (OK)  OK = [keyValue isEqualToString:@"oomesh"];
		if (EXPECT_NOT(!OK))  [self priv_reportBasicParseError:@"\"oomesh\""];
	}
	[_lexer consumeOptionalNewlines];
	if (OK)
	{
		OK = [_lexer getString:&_meshName];
		[_meshName retain];
		if (EXPECT_NOT(!OK))  [self priv_reportBasicParseError:@"string"];
	}
	[_lexer consumeOptionalNewlines];
	if (OK)
	{
		OK = [_lexer getToken:kOOMeshTokenColon];
		if (EXPECT_NOT(!OK))  [self priv_reportBasicParseError:@":"];
	}
	[_lexer consumeOptionalNewlines];
	if (OK)
	{
		OK = [_lexer getToken:kOOMeshTokenOpenBrace];
		if (EXPECT_NOT(!OK))  [self priv_reportBasicParseError:@"{"];
	}
	[_lexer consumeOptionalNewlines];
	
	while (OK)
	{
		//	Root body: like a dictionary body, but with sections.
		OOMeshTokenType token = [_lexer currentTokenType];
		if (token == kOOMeshTokenKeyword || token == kOOMeshTokenString)
		{
			keyValue = [_lexer currentTokenString];
			[_lexer consumeOptionalNewlines];
			
			// Distinguish sections from properties.
			token = [_lexer currentTokenType];
			if (token == kOOMeshTokenColon)
			{
				// Property.
				[_lexer consumeOptionalNewlines];
				OK = [self priv_readProperty:&propertyValue];
				
				if (OK)
				{
					if ([keyValue isEqualToString:@"vertexCount"])
					{
						NSUInteger value = OOUIntegerFromObject(propertyValue, NSNotFound);
						if (_vertexCount == NSNotFound)
						{
							_vertexCount = OOUIntegerFromObject(propertyValue, NSNotFound);
						}
						else if (value != _vertexCount)
						{
							[self priv_reportParseError:@"attempt to redefine vertex count from %lu to %lu", (unsigned long)_vertexCount, (unsigned long)value];
							OK = NO;
						}
					}
					else
					{
						[rootProperties setObject:propertyValue forKey:keyValue];
					}
				}
			}
			else if (token == kOOMeshTokenString)
			{
				// Section.
				NSString *sectionName = [_lexer currentTokenString];
				OK = [self priv_readSectionNamed:sectionName ofType:keyValue];
			}
			else
			{
				OK = NO;
				[self priv_reportBasicParseError:@"section name or :"];
			}

		}
		else if (token == kOOMeshTokenCloseBrace)  break;
		else
		{
			OK = NO;
			[self priv_reportBasicParseError:@"key or }"];
		}
		
		if (OK)
		{
			OK = [_lexer consumeCommaOrNewlines];
			if (EXPECT_NOT(!OK))  [self priv_reportBasicParseError:@"comma or newline"];
		}
	}
	
	if (OK)
	{
		[_lexer consumeOptionalNewlines];
		if (![_lexer getToken:kOOMeshTokenEOF])
		{
			OOReportWarning(_issues, @"There is unknown data after the end of the file, which will be ignored.");
		}
	}
	
	// FIXME: verify completeness.
	DESTROY(_lexer);
	
	_unknownSectionTypes = nil;
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


- (void) priv_reportBasicParseError:(NSString *)expected
{
	[self priv_reportParseError:@"expected %@, got %@", expected, [_lexer currentTokenDescription]];
}


- (void) priv_reportMallocFailure
{
	OOReportError(_issues, @"Not enough memory to read %@.", [[NSFileManager defaultManager] displayNameAtPath:_path]);
}


- (OOFloatArray *) priv_readAttributeDataWithProperties:(NSDictionary *)properties name:(NSString *)name
{
	id sizeObj = [properties objectForKey:@"size"];
	if (EXPECT_NOT(![sizeObj isKindOfClass:[NSNumber class]]))
	{
		[self priv_reportParseError:@"attribute \"%@\" does not specify a size", name];
		return nil;
	}
	if (EXPECT_NOT(_vertexCount == NSNotFound))
	{
		[self priv_reportParseError:@"attribute \"%@\" appears before vertexCount is specified.", name];
		return nil;
	}
	
	if (EXPECT_NOT(![_lexer getToken:kOOMeshTokenOpenBracket]))
	{
		[self priv_reportBasicParseError:@"["];
		return nil;
	}
	[_lexer consumeOptionalNewlines];
	
	NSUInteger i, count = _vertexCount * [sizeObj unsignedIntegerValue];
	float *buffer = malloc(count * sizeof (float));
	if (EXPECT_NOT(buffer == NULL))
	{
		[self priv_reportMallocFailure];
		return nil;
	}
	
	// Read <count> reals.
	for (i = 0; i < count; i++)
	{
		if (EXPECT_NOT(![_lexer getReal:&buffer[i]]))
		{
			[self priv_reportBasicParseError:@"number"];
			return nil;
		}
		
		if (EXPECT_NOT(![_lexer consumeCommaOrNewlines]))
		{
			[self priv_reportBasicParseError:@"comma or newline"];
			return nil;
		}
	}
	/*	Static analyzer reports a retain count problem here. This is a false
		positive: the method name includes “copy”, but not in the relevant
		sense.
		Mainline clang has an annotation for this, but it is’t available in
		OS X at the time of writing. It should be picked up automatically
		when it is.
	*/
	return [OOFloatArray arrayWithFloatsNoCopy:buffer count:count freeWhenDone:YES];
}


- (BOOL) priv_completeAttributeWithProperties:(NSDictionary *)properties data:(OOFloatArray *)data name:(NSString *)name
{
	[_attributeArrays setObject:data forKey:name];
	// Size is implicitly _vertexCount/[data count]. No other properties are used at this time.
	
	return YES;
}


- (OOIndexArray *) priv_readGroupDataWithProperties:(NSDictionary *)properties name:(NSString *)name
{
	id faceCountObj = [properties objectForKey:@"faceCount"];
	if (EXPECT_NOT(![faceCountObj isKindOfClass:[NSNumber class]]))
	{
		[self priv_reportParseError:@"group \"%@\" does not specify a face count", name];
		return nil;
	}
	if (EXPECT_NOT(_vertexCount == NSNotFound))
	{
		[self priv_reportParseError:@"group \"%@\" appears before vertexCount is specified.", name];
		return nil;
	}
	
	if (EXPECT_NOT(![_lexer getToken:kOOMeshTokenOpenBracket]))
	{
		[self priv_reportBasicParseError:@"["];
		return nil;
	}
	[_lexer consumeOptionalNewlines];
	
	NSUInteger i, count = [faceCountObj unsignedIntegerValue] * 3;
	GLuint *buffer = malloc(count * sizeof (GLuint));
	if (EXPECT_NOT(buffer == NULL))
	{
		[self priv_reportMallocFailure];
		return nil;
	}
	
	// Read <count> naturals.
	for (i = 0; i < count; i++)
	{
		uint64_t value;
		if (EXPECT_NOT(![_lexer getNatural:&value]))
		{
			[self priv_reportBasicParseError:@"number"];
			return nil;
		}
		if (EXPECT_NOT(value >= _vertexCount))
		{
			[self priv_reportParseError:@"vertex index %llu is out of range (vertex count is %lu).", value, (unsigned long)_vertexCount];
			return nil;
		}
		
		buffer[i] = value;
		
		if (EXPECT_NOT(![_lexer consumeCommaOrNewlines]))
		{
			[self priv_reportBasicParseError:@"comma or newline"];
			return nil;
		}
	}
	
	/*	Static analyzer reports a retain count problem here. This is a false
		positive: the method name includes “copy”, but not in the relevant
		sense.
		Mainline clang has an annotation for this, but it is’t available in
		OS X at the time of writing. It should be picked up automatically
		when it is.
	*/
	return [OOIndexArray arrayWithUnsignedIntsNoCopy:buffer count:count maximum:_vertexCount freeWhenDone:YES];
}


- (BOOL) priv_completeGroupWithProperties:(NSDictionary *)properties data:(OOIndexArray *)data name:(NSString *)name
{
	[_groupIndexArrays addObject:data];
	
	NSString *materialKey = [properties oo_stringForKey:@"material"];
	OOMaterialSpecification *materialSpec = nil;
	
	if (materialKey != nil)
	{
		materialSpec = [_materialsByName objectForKey:materialKey];
		if (materialSpec == nil)
		{
			OOReportWarning(_issues, @"Mesh group \"%@\" specifies undefined material \"%@\", defining empty material.", name);
		}
	}
	else
	{
		OOReportWarning(_issues, @"noMaterial", @"Mesh group \"%@\" does not specify a material, using empty material with same name as group.", name);
		materialKey = name;
	}
	
	if (materialSpec == nil)
	{
		// Either warning above.
		materialSpec = [[[OOMaterialSpecification alloc] initWithMaterialKey:materialKey] autorelease];
		[_materialsByName setObject:materialSpec forKey:materialKey];
	}
	
	[_groupMaterials addObject:materialSpec];
	
	return YES;
}


- (BOOL) priv_completeMaterialWithProperties:(NSDictionary *)properties data:(id)ignored name:(NSString *)name
{
	OOMaterialSpecification *material = [[OOMaterialSpecification alloc] initWithMaterialKey:name
																  propertyListRepresentation:properties
																					  issues:_issues];
	if (EXPECT_NOT(material == nil))  return NO;
	
	[_materialsByName setObject:material forKey:name];
	[material release];
	
	return YES;
}



typedef id (*dataHandlerIMP)(id self, SEL _cmd, NSDictionary *attributeProperties, NSString *name);
typedef BOOL(*completionIMP)(id self, SEL _cmd, NSDictionary *attributeProperties, id data, NSString *name);

- (BOOL) priv_readSectionNamed:(NSString *)name ofType:(NSString *)type
{
	/*	Section contents are semantically identical to dictionaries, but they
		differ semantically in how the contents are used. Also, for efficiency,
		the data sections are parsed differently.
	*/
	
	NSParameterAssert(name != nil && type != nil);
	
	BOOL OK = YES;
	NSMutableDictionary *properties = [NSMutableDictionary dictionary];
	SEL dataHandlerSEL = NULL;
	SEL completionHandlerSEL = NULL;
	dataHandlerIMP dataHander = NULL;
	completionIMP completionHandler = NULL;
	
	if ([type isEqualToString:@"attribute"])
	{
		dataHandlerSEL = @selector(priv_readAttributeDataWithProperties:name:);
		completionHandlerSEL = @selector(priv_completeAttributeWithProperties:data:name:);
	}
	else if ([type isEqualToString:@"group"])
	{
		dataHandlerSEL = @selector(priv_readGroupDataWithProperties:name:);
		completionHandlerSEL = @selector(priv_completeGroupWithProperties:data:name:);
	}
	else if ([type isEqualToString:@"material"])
	{
		completionHandlerSEL = @selector(priv_completeMaterialWithProperties:data:name:);
	}
	else
	{
		if (![_unknownSectionTypes containsObject:type])
		{
			[_unknownSectionTypes addObject:type];
			OOReportWarning(_issues, @"Unknown section of type \"%@\" on line %u; contents will be ignored.", type, [_lexer lineNumber]);
		}
		// We still need to parse it to find the end reliably.
	}
	
	if (dataHandlerSEL != NULL)
	{
		dataHander = (dataHandlerIMP)[self methodForSelector:dataHandlerSEL];
	}
	if (completionHandlerSEL != NULL)
	{
		completionHandler = (completionIMP)[self methodForSelector:completionHandlerSEL];
	}
	
	
	[_lexer consumeOptionalNewlines];
	OK = [_lexer getToken:kOOMeshTokenColon];
	if (EXPECT_NOT(!OK))  [self priv_reportBasicParseError:@":"];
	[_lexer consumeOptionalNewlines];
	OK = [_lexer getToken:kOOMeshTokenOpenBrace];
	if (EXPECT_NOT(!OK))  [self priv_reportBasicParseError:@"{"];
	[_lexer consumeOptionalNewlines];
	
	id data = nil;
	BOOL stop = ([_lexer currentTokenType] == kOOMeshTokenCloseBrace);
	
	while (OK && !stop)
	{
		NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
		
		OOMeshTokenType token = [_lexer currentTokenType];
		if (token == kOOMeshTokenKeyword || token == kOOMeshTokenString)
		{
			NSString *keyValue = [_lexer currentTokenString];
			[_lexer consumeOptionalNewlines];
			OK = [_lexer getToken:kOOMeshTokenColon];
			if (OK)
			{
				[_lexer consumeOptionalNewlines];
				
				if (dataHander != NULL && [keyValue isEqualToString:@"data"])
				{
					[data release];
					data = dataHander(self, dataHandlerSEL, properties, name);
					[data retain];
					OK = data != nil;
				}
				else
				{
					id propertyValue = nil;
					OK = [self priv_readProperty:&propertyValue];
					if (OK)  [properties setObject:propertyValue forKey:keyValue];
				}
			}
			else
			{
				OK = NO;
				[self priv_reportBasicParseError:@":"];
			}
			
		}
		
		switch ([self priv_consumeSeparatorOrTerminator:kOOMeshTokenCloseBrace])
		{
			case kStoppedWithoutSeparator:
				OK = NO;
				[self priv_reportBasicParseError:@"comma, newline or }"];
				break;
				
			case kStoppedWithSeparator:
				break;
				
			case kStoppedWithTerminator:
				stop = YES;
				break;
				
			case kStoppedWithDoubleComma:
				OK = NO;
				[self priv_reportBasicParseError:@"newline or key"];
				break;
		}
		
		[innerPool release];
	}
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	if (OK && completionHandler != NULL)
	{
		OK = completionHandler(self, completionHandlerSEL, properties, data, name);
	}
	[data release];
	[pool drain];
	
	return OK;
}


- (BOOL) priv_readProperty:(id *)outProperty
{
	NSParameterAssert(outProperty != NULL);
	
	BOOL OK = YES;
	
	if (OK) switch ([_lexer currentTokenType])
	{
		case kOOMeshTokenKeyword:
		{
			NSString *keyword = [_lexer currentTokenString];
			if ([keyword isEqualToString:@"true"])  *outProperty = [NSNumber numberWithBool:YES];
			else if ([keyword isEqualToString:@"false"])  *outProperty = [NSNumber numberWithBool:NO];
			else
			{
				OK = NO;
				[self priv_reportBasicParseError:@"property"];
			}
			break;
		}
			
		case kOOMeshTokenString:
			OK = [_lexer getString:outProperty];
			break;
			
		case kOOMeshTokenNatural:
		{
			uint64_t natural;
			OK = [_lexer getNatural:&natural];
			if (OK)
			{
				*outProperty = [NSNumber numberWithUnsignedLongLong:natural];
			}
			else
			{
				[self priv_reportParseError:@"identified \"%@\" as a number, but coudln't parse it as such.", [_lexer currentTokenString]];
			}
			break;
		}
			
		case kOOMeshTokenReal:
		{
			float real;
			OK = [_lexer getReal:&real];
			if (OK)
			{
				*outProperty = [NSNumber numberWithFloat:real];
			}
			else
			{
				[self priv_reportParseError:@"identified \"%@\" as a number, but coudln't parse it as such.", [_lexer currentTokenString]];
			}
			break;
		}
			
		case kOOMeshTokenOpenBrace:
			OK = [self priv_readDictionary:outProperty];
			break;
			
		case kOOMeshTokenOpenBracket:
			OK = [self priv_readArray:outProperty];
			break;
			
		default:
			[self priv_reportBasicParseError:@"property value"];
			OK = NO;
	}
	
	return OK;
}


- (BOOL) priv_readDictionary:(NSDictionary **)outDictionary
{
	NSParameterAssert(outDictionary != NULL && [_lexer getToken:kOOMeshTokenOpenBrace]);
	
	BOOL OK = YES;
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	[_lexer consumeOptionalNewlines];
	BOOL stop = ([_lexer currentTokenType] == kOOMeshTokenCloseBrace);
	
	while (OK && !stop)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		OOMeshTokenType token = [_lexer currentTokenType];
		if (token == kOOMeshTokenKeyword || token == kOOMeshTokenString)
		{
			NSString *keyValue = nil;
			id propertyValue = nil;
			
			keyValue = [_lexer currentTokenString];
			[_lexer consumeOptionalNewlines];
			OK = [_lexer getToken:kOOMeshTokenColon];
			if (OK)
			{
				[_lexer consumeOptionalNewlines];
				OK = [self priv_readProperty:&propertyValue];
				
				if (OK)  [result setObject:propertyValue forKey:keyValue];
			}
			else
			{
				OK = NO;
				[self priv_reportBasicParseError:@":"];
			}
			
		}
		
		switch ([self priv_consumeSeparatorOrTerminator:kOOMeshTokenCloseBrace])
		{
			case kStoppedWithoutSeparator:
				OK = NO;
				[self priv_reportBasicParseError:@"comma, newline or }"];
				break;
				
			case kStoppedWithSeparator:
				break;
				
			case kStoppedWithTerminator:
				stop = YES;
				break;
				
			case kStoppedWithDoubleComma:
				OK = NO;
				[self priv_reportBasicParseError:@"newline or key"];
				break;
		}
		
		[pool release];
	}
	
	if (OK)  *outDictionary = [NSDictionary dictionaryWithDictionary:result];
	return OK;
}


- (BOOL) priv_readArray:(NSArray **)outArray
{
	NSParameterAssert(outArray != NULL && [_lexer getToken:kOOMeshTokenOpenBracket]);
	
	BOOL OK = YES;
	NSMutableArray *result = [NSMutableArray array];
	[_lexer consumeOptionalNewlines];
	BOOL stop = ([_lexer currentTokenType] == kOOMeshTokenCloseBracket);
	
	while (OK && !stop)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		id propertyValue = nil;
		OK = [self priv_readProperty:&propertyValue];
		if (OK)
		{
			[result addObject:propertyValue];
		}
		[pool release];
		
		switch ([self priv_consumeSeparatorOrTerminator:kOOMeshTokenCloseBracket])
		{
			case kStoppedWithoutSeparator:
				OK = NO;
				[self priv_reportBasicParseError:@"comma, newline or ]"];
				break;
				
			case kStoppedWithSeparator:
				break;
				
			case kStoppedWithTerminator:
				stop = YES;
				break;
				
			case kStoppedWithDoubleComma:
				OK = NO;
				[self priv_reportBasicParseError:@"newline or value"];
				break;
		}
	}
	
	if (OK)  *outArray = [NSArray arrayWithArray:result];
	return OK;
}


- (ConsumeSeparatorOrTerminatorResult) priv_consumeSeparatorOrTerminator:(OOMeshTokenType)terminator
{
	ConsumeSeparatorOrTerminatorResult result = kStoppedWithoutSeparator;
	BOOL haveComma = NO;
	
	for (;;)
	{
		if (EXPECT_NOT(![_lexer advance]))  return result;
		
		OOMeshTokenType tok = [_lexer currentTokenType];
		if (tok == kOOMeshTokenNewline)
		{
			result = kStoppedWithSeparator;
		}
		else if (tok == kOOMeshTokenComma)
		{
			if (!haveComma)
			{
				result = kStoppedWithSeparator;
				haveComma = YES;
			}
			else
			{
				return kStoppedWithDoubleComma;
			}

		}
		else
		{
			if (tok == terminator)
			{
				result = kStoppedWithTerminator;
			}
			return result;
		}
	}
}

@end
