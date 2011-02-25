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
#import "OOConfLexer.h"


@interface OOConfParser (OOPrivate)

// Parser acts as its own delegate for standard parsing and NULL parsing.
- (BOOL) priv_plistBuilderHandleElement:(void *)element isArray:(BOOL)isArray producingObject:(id *)outObject;
- (BOOL) priv_nullActionHandleElement:(void *)element isArray:(BOOL)isArray producingObject:(id *)outObject;

@end


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
		id result = [parser parseWithDelegateAction:@selector(priv_plistBuilderHandleElement:isArray:producingObject:)];
		
		if (parser == nil && outError != NULL)
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
		return [parser parseWithDelegateAction:@selector(priv_plistBuilderHandleElement:isArray:producingObject:)];
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

- (id) initWithData:(NSData *)data problemReporter:(id <OOProblemReporting>)issues
{
	if ((self = [super init]))
	{
		_issues = [issues retain];
		_lexer = [[OOConfLexer alloc] initWithData:data issues:issues];
		if (_lexer == nil)
		{
			DESTROY(self);
		}
	}
	
	return self;
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


- (id) parseWithDelegateAction:(SEL)action
{
	/*	Rather than handling NULL action as a special case in actual parsing,
		replace it with a delegate and action that does nothing.
	*/
	if (action == NULL)
	{
		id delegate = _delegate;
		_delegate = self;
		id result = [self parseWithDelegateAction:@selector(priv_nullActionHandleElement:isArray:producingObject:)];
		_delegate = delegate;
		return result;
	}
	
	[_lexer advance];
	
	
	
	return nil;
}


- (BOOL) priv_plistBuilderHandleElement:(void *)element isArray:(BOOL)isArray producingObject:(id *)outObject
{
	*outObject = [self parseWithDelegateAction:@selector(priv_plistBuilderHandleElement:isArray:producingObject:)];
	return *outObject != nil;
}


- (BOOL) priv_nullActionHandleElement:(void *)element isArray:(BOOL)isArray producingObject:(id *)outObject
{
	[self parseWithDelegateAction:@selector(priv_nullActionHandleElement:isArray:producingObject:)];
	return YES;
}

@end
