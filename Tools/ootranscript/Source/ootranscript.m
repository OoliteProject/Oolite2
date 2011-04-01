/*

ootranscript.m
ootranscript

Test rig for Oolite legacy script to JavaScript translation.


Copyright © 2010-2011 Jens Ayton

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

#import <OoliteBase/OoliteBase.h>
#import "OOTrConverter.h"
#import "OOLegacyScriptWhitelist.h"
#import "whitelist.h"
#import "OOTrJSAST.h"
#import "OOTRJSSimplify.h"
#import "OOTRJSGraphViz.h"


#define TEST		0
#define SIMPLIFY	1

#if TEST
void Test(void);
#endif


static void LoadWhitelist(void);


int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	LoadWhitelist();
	
#if TEST
	Test();
#else
	if (argc < 2)
	{
		fprintf(stderr, "An input file name must be specified.\n");
		return EXIT_FAILURE;
	}
	
	NSString *path = [NSString stringWithUTF8String:argv[1]];
	char buffer[PATH_MAX];
	realpath([[path stringByExpandingTildeInPath] UTF8String], buffer);
	path = [NSString stringWithUTF8String:buffer];
	
	NSDictionary *sourceScript = [NSDictionary dictionaryWithContentsOfFile:path];
	if (sourceScript == nil)  return EXIT_FAILURE;
	
	NSMutableArray *convertedRoot = [NSMutableArray arrayWithCapacity:[sourceScript count]];
	NSString *name = nil;
	foreachkey (name, sourceScript)
	{
		NSArray *script = [sourceScript oo_arrayForKey:name];
		if (script == nil)  continue;
		
		OOSimpleProblemReportManager *problemReporter = [[[OOSimpleProblemReportManager alloc] initWithContextString:$sprintf(@"Converting \"%@\":", name)
																								  messageClassPrefix:@"script.convert"] autorelease];
		
		OOTrExpression *parsed = OOTrJavaScriptFunctionExpressionFromLegacyScriptActions(script, name, problemReporter);
		if (parsed != nil)
		{
#ifndef NDEBUG
			[(SIMPLIFY ? [parsed simplified] : parsed) writeGraphVizToPath:$sprintf(@"/tmp/ootranscript-converted-%@.dot", name)];
#endif
			
			OOTrStatement *assignment = TrASSIGN(TrPROP(TrTHIS, name), parsed);
#if SIMPLIFY
			assignment = [assignment simplified];
#endif
			[convertedRoot addObject:assignment];
		}
	}
	
	OOTrExpression *root = [OOTrCompoundStatement compoundStatementWithStatements:convertedRoot];
	OOLog(@"script.composite.converted", @"%@", [root jsStatementCode]);
	
#endif
	
	[pool drain];
	return 0;
}


static void LoadWhitelist(void)
{
	NSData *whitelistData = [NSData dataWithBytes:kwhitelist length:kwhitelistLength];
	NSString *error = nil;
	NSDictionary *whitelist = [NSPropertyListSerialization propertyListFromData:whitelistData
															   mutabilityOption:kCFPropertyListImmutable
																		 format:NULL
															   errorDescription:&error];
	if (whitelist == nil || ![whitelist isKindOfClass:[NSDictionary class]])
	{
		if (error == nil)  error = @"unknown error.";
		OOLog(@"whitelist.error", @"Could not load whitelist: %@", error);
		exit(EXIT_FAILURE);
	}
	OOSanitizerSetWhitelist(whitelist);
}


#if TEST

#import "OOTrJSAST.h"


void Test(void)
{
	// Playground for AST functionality testing.
#if 0
	id one = TrNUM(1);
	id two = TrNUM(2);
	id three = TrNUM(3);
	
	// 1 + 2 * 3
	
	// (1 + 2) * 3
	id mulAdd = TrBOP(Multiply, one, TrBOP(Add, two, three));
	
	// 1 + 2 - 3
	id addSub = TrBOP(Add, one, TrBOP(Subtract, two, three));
	
	// myFunc("A string", (1 + 2) * 3, (a.foo, b["bar one"]))
	id funcCall = TrCALL(TrID(@"myFunc"), TrSTR(@"A string"), mulAdd, TrBOP(Comma, TrPROP(TrID(@"a"), TrSTR(@"foo")), TrPROP(TrID(@"b"), TrSTR(@"bar one"))));
	
	id funcBody = TrFUNC(@"testFunction", $array(@"p1", @"p2"), $array(addSub, funcCall));
	id funcCall2 = TrCALL(funcBody, TrNUM(1), TrSTR(@"foo"));
	
	OOLog(@"test", @"%@", [funcCall2 jsStatementCode]);
	OOLog(@"test", @"%@", [[funcCall2 simplified] jsStatementCode]);
#endif
	
#if 0
	// Should simplify to "green".
	id conds = TrCOND(TrCOND(TrSTR(@"banana"), TrNO, TrYES), TrSTR(@"red"), TrSTR(@"green"));
	
	OOLog(@"test", @"%@", [conds jsStatementCode]);
	OOLog(@"test", @"%@", [[conds simplified] jsStatementCode]);
	
	id ifBlock = TrIF(TrVOID(TrID(@"a")), TrCALL(TrID(@"foo")), TrIF(TrID(@"b"), TrCALL(TrID(@"bar")), TrCALL(TrID(@"baz"))));
	
	OOLog(@"test", @"%@", [ifBlock jsStatementCode]);
	OOLog(@"test", @"%@", [[ifBlock simplified] jsStatementCode]);
#endif
	
	// 5 - 8 - 10
	id leftHeavy = TrSUB(TrSUB(TrNUM(5), TrNUM(8)), TrNUM(10));
	// 5 - (8 - 10)
	id rightHeavy = TrSUB(TrNUM(5), TrSUB(TrNUM(8), TrNUM(10)));
	
	OOLog(@"test", @"%@", [leftHeavy jsStatementCode]);
	OOLog(@"test", @"%@", [rightHeavy jsStatementCode]);
	
	OOTrASTFlushCache();
}

#endif
