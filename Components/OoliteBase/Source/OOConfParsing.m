/*

OOConfParsing.m
By Jens Ayton


Copyright © 2011 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import "OOConfParsingInternal.h"
#import "OOProblemReporting.h"
#import "MYCollectionUtilities.h"
#import "OOFunctionAttributes.h"


typedef BOOL (*ParseActionIMP)(id self, SEL _cmd, OOConfParserActionEventType eventType, void *key, id *outObject);


@interface OOConfParser (OOPrivate)

// Parser acts as its own delegate for standard parsing and NULL parsing.
- (BOOL) priv_plistBuilderParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object;
- (BOOL) priv_nullParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object;

- (BOOL) priv_parseDictionaryWithAction:(SEL)action result:(id *)result;
- (BOOL) priv_parseArrayWithAction:(SEL)action result:(id *)result;

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)string;

@end


#define PLIST_BUILDER_SEL	@selector(priv_plistBuilderParseEvent:key:object:)
#define DO_NOTHING_SEL		@selector(priv_nullParseEvent:key:object:)


@implementation NSObject (OOConfParsing)

+ (id) objectFromOOConfString:(NSString *)ooConfString error:(NSError **)outError
{
	return [self objectFromOOConfData:[ooConfString dataUsingEncoding:NSUTF8StringEncoding] error:outError];
}


+ (id) objectFromOOConfData:(NSData *)ooConfData error:(NSError **)outError
{
	if (ooConfData == nil)  return nil;
	
	OOErrorConvertingProblemReporter *problemReporter = nil;
	OOConfParser *parser = nil;
	@try
	{
		problemReporter = [[OOErrorConvertingProblemReporter alloc] init];
		parser = [[OOConfParser alloc] initWithData:ooConfData problemReporter:problemReporter];
		id result = [parser parseAsPropertyList];
		
		if (result == nil && outError != NULL)
		{
			*outError = [problemReporter error];
		}
		
		return result;
	}
	@finally
	{
		[problemReporter release];
		[parser release];
	}
}


+ (id) objectWithContentsOfOOConfURL:(NSURL *)url error:(NSError **)outError
{
	NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMapped error:outError];
	if (data != nil)  return [self objectFromOOConfData:data error:outError];
	else  return nil;
}


+ (id) objectFromOOConfString:(NSString *)ooConfString problemReporter:(id<OOProblemReporting>)problemReporter
{
	return [self objectFromOOConfData:[ooConfString dataUsingEncoding:NSUTF8StringEncoding] problemReporter:problemReporter];
}


+ (id) objectFromOOConfData:(NSData *)ooConfData problemReporter:(id<OOProblemReporting>)problemReporter
{
	OOConfParser *parser = [[OOConfParser alloc] initWithData:ooConfData problemReporter:problemReporter];
	@try
	{
		[parser setDelegate:parser];
		id result = [parser parseAsPropertyList];
		
		if (result != nil)
		{
			OOConfLexer *lexer = [parser lexer];
			[lexer advance];
			if ([lexer currentTokenType] != kOOConfTokenEOF)
			{
				OOReportWarning(problemReporter, @"Ignoring additional tokens beyond end of data (line %lu).", [[parser lexer] lineNumber]);
			}
		}
		return result;
	}
	@finally
	{
		[parser release];
	}
}


+ (id) objectWithContentsOfOOConfURL:(NSURL *)url problemReporter:(id<OOProblemReporting>)problemReporter
{
	NSError *error = nil;
	NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMapped error:&error];
	if (data != nil)  return [self objectFromOOConfData:data problemReporter:problemReporter];
	else
	{
		OOReportNSError(problemReporter, nil, error);
		return nil;
	}
}

@end


@implementation OOConfParser

- (id) initWithLexer:(OOConfLexer *)lexer
{
	if (lexer == nil)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_lexer = [lexer retain];
		_issues = [lexer problemReporter];
	}
	
	return self;
}


- (id) initWithData:(NSData *)data problemReporter:(id <OOProblemReporting>)issues
{
	return [self initWithLexer:[[[OOConfLexer alloc] initWithData:data issues:issues] autorelease]];
}


- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_lexer);
	
	[super dealloc];
}


- (id<OOProblemReporting>) problemReporter
{
	return _issues;
}


- (OOConfLexer *) lexer
{
	return _lexer;
}


- (id) delegate
{
	return _delegate;
}


- (void) setDelegate:(id)delegate
{
	_delegate = delegate;
}


- (BOOL) parseWithDelegateAction:(SEL)action result:(id *)result
{
	id sink = nil;
	if (result == NULL)  result = &sink;
	
	if (action == NULL)
	{
		/*	Rather than handling NULL action as a special case in actual parsing,
			replace it with a delegate and action that does nothing.
		*/
		id delegate = _delegate;
		_delegate = self;
		BOOL OK = [self parseWithDelegateAction:DO_NOTHING_SEL
										 result:result];
		_delegate = delegate;
		return OK;
	}
	
//	[_lexer advance];
	
	BOOL OK;
	switch ([_lexer currentTokenType])
	{
		case kOOConfTokenString:
			return [_lexer getString:result];
			
		case kOOConfTokenNatural:
		{
			uint64_t natural;
			OK = [_lexer getNatural:&natural];
			if (OK)  *result = [NSNumber numberWithUnsignedLongLong:natural];
			return OK;
		}
			
		case kOOConfTokenReal:
		{
			double value;
			OK = [_lexer getDouble:&value];
			if (OK)  *result = [NSNumber numberWithDouble:value];
			return OK;
		}
			
		case kOOConfTokenOpenBrace:
			return [self priv_parseDictionaryWithAction:action result:result];
			
		case kOOConfTokenOpenBracket:
			return [self priv_parseArrayWithAction:action result:result];
			
		case kOOConfTokenKeyword:
		{
			NSString *stringValue = [_lexer currentTokenString];
			
			if ([@"true" isEqualToString:stringValue])  *result = $true;
			else if ([@"false" isEqualToString:stringValue])  *result = $false;
			else if ([@"null" isEqualToString:stringValue])  *result = $null;
			else
			{
				break;
			}
			return YES;
		}
			
		default:
			break;
	}
	
	[self priv_reportBasicParseError:@"value"];
	return NO;
}


- (id) parseAsPropertyList
{
	id delegate = _delegate;
	_delegate = self;
	
	id result = nil;
	BOOL OK = [self parseWithDelegateAction:PLIST_BUILDER_SEL result:&result];
	if (!OK)  result = nil;
	
	_delegate = delegate;
	
	return result;
}


- (BOOL) priv_parseDictionaryWithAction:(SEL)actionSEL result:(id *)result
{
	ParseActionIMP actionIMP = (ParseActionIMP)[_delegate methodForSelector:actionSEL];
	NSAssert(actionIMP != NULL, @"OOConfParser delegate actions must be implemented.");
	
	// Be a dictionary, or else.
	if (![_lexer getToken:kOOConfTokenOpenBrace])
	{
		[self priv_reportBasicParseError:@"\"{\""];
		return NO;
	}
	[_lexer advance];
	
	BOOL OK = YES;
	BOOL stop = [_lexer currentTokenType] == kOOConfTokenCloseBrace;
	
	// Give action opportunity to set up.
	*result = nil;
	OK = actionIMP(_delegate, actionSEL, kOOConfDictionaryBegin, nil, result);
	
	// For each pair...
	while (OK && !stop)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		// We should be at a key or the closing brace.
		OOConfTokenType token = [_lexer currentTokenType];
		if (token == kOOConfTokenString || (token == kOOConfTokenKeyword && !_strictJSON))
		{
			// Read a key.
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
				OK = actionIMP(_delegate, actionSEL, kOOConfDictionaryElement, keyValue, result);
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
		
		[pool drain];
	}
	
	if (OK)
	{
		// Give action an opportunity to finish up.
		OK = actionIMP(_delegate, actionSEL, kOOConfDictionaryEnd, nil, result);
	}
	else
	{
		actionIMP(_delegate, actionSEL, kOOConfDictionaryFailed, nil, result);
	}
	
	return OK;
}


- (BOOL) priv_parseArrayWithAction:(SEL)actionSEL result:(id *)result
{
	ParseActionIMP actionIMP = (ParseActionIMP)[_delegate methodForSelector:actionSEL];
	NSAssert(actionIMP != NULL, @"OOConfParser delegate actions must be implemented.");
	
	// Be an array, or else.
	if (![_lexer getToken:kOOConfTokenOpenBracket])
	{
		[self priv_reportBasicParseError:@"\"[\""];
		return NO;
	}
	[_lexer advance];
	
	BOOL OK = YES;
	BOOL stop = [_lexer currentTokenType] == kOOConfTokenCloseBrace;
	
	// Give action opportunity to set up.
	*result = nil;
	OK = actionIMP(_delegate, actionSEL, kOOConfArrayBegin, 0, result);
	
	uintptr_t index = 0;
	
	// For each pair...
	while (OK && !stop)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		OK = actionIMP(_delegate, actionSEL, kOOConfArrayElement, (void *)index, result);
		index++;
		
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
				OOConfTokenType token = [_lexer currentTokenType];
				
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
		
		[pool drain];
	}
	
	if (OK)
	{
		// Give action an opportunity to finish up.
		OK = actionIMP(_delegate, actionSEL, kOOConfArrayEnd, 0, result);
	}
	else
	{
		actionIMP(_delegate, actionSEL, kOOConfArrayFailed, 0, result);
	}

	
	return OK;
}


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
	NSString *key = [@"expected-" stringByAppendingString:expected];
	NSString *localized = OOLocalizeProblemString(_issues, key);
	if (localized == key)  localized = expected;
	
	[self priv_reportParseError:@"expected %@, got %@", localized, [_lexer currentTokenDescription]];
}


- (BOOL) priv_plistBuilderParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object
{
	switch (event)
	{
		case kOOConfArrayBegin:
			*object = [NSMutableArray array];
			return *object != nil;
			
		case kOOConfDictionaryBegin:
			*object = [NSMutableDictionary dictionary];
			return *object != nil;
			
		case kOOConfArrayElement:
		case kOOConfDictionaryElement:
		{
			id value = nil;
			BOOL OK = [self parseWithDelegateAction:PLIST_BUILDER_SEL
											 result:&value];
			if (EXPECT_NOT(!OK))  return NO;
			if (event == kOOConfArrayElement)
			{
				[(NSMutableArray *)*object addObject:value];
			}
			else
			{
				[(NSMutableDictionary *)*object setObject:value forKey:key];
			}
			return YES;
		}
			
		case kOOConfArrayEnd:
		case kOOConfDictionaryEnd:
		case kOOConfArrayFailed:
		case kOOConfDictionaryFailed:
			return YES;
	}
	
	return NO;
}


- (BOOL) priv_nullParseEvent:(OOConfParserActionEventType)event key:(void *)key object:(id *)object
{
	switch (event)
	{
		case kOOConfArrayElement:
		case kOOConfDictionaryElement:
			return [self parseWithDelegateAction:DO_NOTHING_SEL
										  result:object];
			
		case kOOConfArrayBegin:
		case kOOConfDictionaryBegin:
		case kOOConfArrayEnd:
		case kOOConfDictionaryEnd:
		case kOOConfArrayFailed:
		case kOOConfDictionaryFailed:
			return YES;
	}
	
	return NO;
}

@end
