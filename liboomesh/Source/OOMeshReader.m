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
#import "OOProblemReportManager.h"
#import "OOCollectionExtractors.h"
#import "OOFloatArray.h"
#import "OOMaterialSpecification.h"


@interface OOMeshReader (Private)

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)expected;
- (void) priv_reportMallocFailure;
- (NSString *) priv_displayPath;

- (BOOL) priv_readSegmentNamed:(NSString *)name ofType:(NSString *)type;
- (BOOL) priv_readProperty:(id *)outProperty;
- (BOOL) priv_readDictionary:(NSDictionary **)outDictionary;
- (BOOL) priv_readArray:(NSDictionary **)outArray;

@end


@implementation OOMeshReader

- (id) initWithPath:(NSString *)path issues:(id <OOProblemReportManager>)ioIssues
{
	if ((self = [super init]))
	{
		_issues = [ioIssues retain];
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
	
	[super dealloc];
}


- (void) parse
{
	if (_lexer == nil)  return;	// Parsed already or initialization failed.
	
	BOOL OK = YES;
	NSMutableDictionary *rootProperties = [NSMutableDictionary dictionary];
	
	_unknownSegmentTypes = [NSMutableSet set];
	_materials = [NSMutableDictionary dictionary];
	
	/*	The root element is structurally similar to a segment, but it's
		currently the only one that can contain other segments, and there must
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
		//	Root body: like a dictionary body, but with segments.
		OOMeshTokenType token = [_lexer currentTokenType];
		if (token == kOOMeshTokenKeyword || token == kOOMeshTokenString)
		{
			keyValue = [_lexer currentTokenString];
			[_lexer consumeOptionalNewlines];
			
			// Distinguish segments from propertys.
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
				// Segment.
				NSString *segmentName = [_lexer currentTokenString];
				OK = [self priv_readSegmentNamed:segmentName ofType:keyValue];
			}
			else
			{
				OK = NO;
				[self priv_reportBasicParseError:@"segment name or :"];
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
			OOReportWarning(_issues, @"unknownData", @"\"%@\" contains unknown data after then end of the file.", [self priv_displayPath]);
		}
	}
	
	// FIXME: verify completeness.
	DESTROY(_lexer);
	
	_unknownSegmentTypes = nil;
	_materials = nil;
}


- (OOAbstractMesh *) mesh
{
	[self parse];
	return nil;
}

@end


@implementation OOMeshReader (Private)

- (void) priv_reportParseError:(NSString *)format, ...
{
	NSString *base = OOLocalizeProblemString(_issues, @"Parse error on line %u of %@: %@.");
	format = OOLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [_lexer lineNumber], [self priv_displayPath], message];
	[_issues addProblemOfType:kOOMProblemTypeError key:@"parseError" message:message];
}


- (void) priv_reportBasicParseError:(NSString *)expected
{
	[self priv_reportParseError:@"expected %@, got %@", expected, [_lexer currentTokenString]];
}


- (void) priv_reportMallocFailure
{
	OOReportError(_issues, @"allocFailed", @"Not enough memory to read %@.", [[NSFileManager defaultManager] displayNameAtPath:_path]);
}


- (NSString *) priv_displayPath
{
	return [[NSFileManager defaultManager] displayNameAtPath:_path];
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
	if (EXPECT_NOT(buffer == nil))
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
	
	return [OOFloatArray arrayWithFloatsNoCopy:buffer count:count freeWhenDone:YES];
}


- (BOOL) priv_completeAttributeWithProperties:(NSDictionary *)properties data:(OOFloatArray *)data name:(NSString *)name
{
	return YES;
}


- (NSData *) priv_readGroupDataWithProperties:(NSDictionary *)properties name:(NSString *)name
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
	
	// FIXME: use appropriate integer size based on vertexCount.
	NSUInteger i, count = [faceCountObj unsignedIntegerValue] * 3;
	unsigned *buffer = malloc(count * sizeof (unsigned));
	if (EXPECT_NOT(buffer == nil))
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
	
	return [NSData dataWithBytesNoCopy:buffer length:count * sizeof (unsigned) freeWhenDone:YES];
}


- (BOOL) priv_completeGroupWithProperties:(NSDictionary *)properties data:(NSData *)data name:(NSString *)name
{
	return YES;
}


- (BOOL) priv_completeMaterialWithProperties:(NSDictionary *)properties data:(id)ignored name:(NSString *)name
{
	OOMaterialSpecification *material = [[OOMaterialSpecification alloc] initWithMaterialKey:name];
	if (EXPECT_NOT(material == nil))  return NO;
	
	//	FIXME: set up material.
	
	[_materials setObject:material forKey:name];
	[material release];
	
	return YES;
}



typedef id (*dataHandlerIMP)(id self, SEL _cmd, NSDictionary *attributeProperties, NSString *name);
typedef BOOL(*completionIMP)(id self, SEL _cmd, NSDictionary *attributeProperties, id data, NSString *name);

- (BOOL) priv_readSegmentNamed:(NSString *)name ofType:(NSString *)type
{
	/*	Segment contents are semantically identical to dictionaries, but they
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
		if (![_unknownSegmentTypes containsObject:type])
		{
			[_unknownSegmentTypes addObject:type];
			OOReportWarning(_issues, @"unknownSegmentType", @"Unknown segment of type \"%@\" on line %u of %@; contents will be ignored.", type, [_lexer lineNumber], [self priv_displayPath]);
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
	
	while (OK)
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
				
				if (dataHander != NULL && [keyValue isEqualToString:@"data"])
				{
					data = dataHander(self, dataHandlerSEL, properties, name);
					[[data retain] autorelease];
					OK = data != nil;
				}
				else
				{
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
		else if (token == kOOMeshTokenCloseBrace)
		{
			[pool release];
			break;
		}
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
		
		[pool release];
	}
	
	if (OK && completionHandler != NULL)
	{
		OK = completionHandler(self, completionHandlerSEL, properties, data, name);
	}
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
			*outProperty = [_lexer currentTokenString];
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
	
	while (OK)
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
		else if (token == kOOMeshTokenCloseBrace)
		{
			[pool release];
			break;
		}
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
		
		[pool release];
	}
	
	if (OK)  *outDictionary = [NSDictionary dictionaryWithDictionary:result];
	return OK;
}


- (BOOL) priv_readArray:(NSDictionary **)outArray
{
	NSParameterAssert(outArray != NULL && [_lexer getToken:kOOMeshTokenOpenBracket]);
	
	BOOL OK = YES;
	NSMutableArray *result = [NSMutableArray array];
	[_lexer consumeOptionalNewlines];
	
	while (OK)
	{
		if ([_lexer currentTokenType] != kOOMeshTokenCloseBracket)
		{
			NSAutoreleasePool *pool = [NSAutoreleasePool new];
			
			id propertyValue = nil;
			OK = [self priv_readProperty:&propertyValue];
			if (OK)
			{
				[result addObject:propertyValue];
				OK = [_lexer consumeCommaOrNewlines];
				if (EXPECT_NOT(!OK))  [self priv_reportBasicParseError:@"comma or newline"];
			}
			
			[pool release];
		}
		else
		{
			break;
		}

	}
	
	if (OK)  *outArray = [NSArray arrayWithArray:result];
	return OK;
}

@end
