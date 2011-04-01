/*

OOTrConverter.m
ootranscript


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

#import "OOTrConverterInternal.h"
#import "OOTRJSSimplify.h"
#import "OOTRJSGraphViz.h"
#import "NSString+OOJavaScriptLiteral.h"
#import "OOLegacyEngineUtilities.h"


#define SIMPLIFY 0


NSString * const kOOTrMissionFence = @"kOOTrMissionFence";
NSString * const kOOTrMissionCall = @"kOOTrMissionCall";


static OOTrExpression *SimplifyBoolExpression(OOTrExpression *expr);
static OOTrExpression *StringListFromExpression(OOTrExpression *expression);
static BOOL StringContainsEscapes(NSString *string);


@interface OOTrExpression (EventExtraction)

- (OOTrExpression *) extractRequiredSubCondition:(OOTrExpression *)expression;

@end


NSString *OOTrJavaScriptPredicateFromLegacyConditions(NSArray *conditions, NSString *name, id <OOProblemReporting> problemReporter)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	OOTrFunctionDeclaration *func = OOTrJavaScriptPredicateExpressionFromLegacyConditions(conditions, name, problemReporter);
	
#ifndef NDEBUG
	[func writeGraphVizToPath:@"/tmp/ootranscript-predicate-dump.dot"];
#endif
	
	NSString *result = [[func jsStatementCode] retain];
	[pool release];
	
	return [result autorelease];
}


OOTrFunctionDeclaration *OOTrJavaScriptPredicateExpressionFromLegacyConditions(NSArray *conditions, NSString *name, id <OOProblemReporting> problemReporter)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSArray *sanitizedConditions = OOSanitizeLegacyScriptConditions(conditions, name);
	if (sanitizedConditions == nil)
	{
		[pool release];
		return nil;
	}
	
	OOTrConverter *converter = [[[OOTrConverter alloc] initWithProblemReporter:problemReporter] autorelease];
	OOTrExpression *rootExpression = [converter parseConditions:sanitizedConditions];
	
	[rootExpression retain];
	[pool release];
	pool = [NSAutoreleasePool new];
	[rootExpression autorelease];
	
#if SIMPLIFY
	rootExpression = [rootExpression simplified];
#endif
	
	OOTrFunctionDeclaration *func = TrFUNC(name, nil, TrRETURN(rootExpression));
	
	[func retain];
	[pool release];
	
	return [func autorelease];
}


static OOTrStatement *BuildHandler(NSString *name, NSMutableArray *actions, BOOL callTickle)
{
	if (callTickle)
	{
		[actions addObject:TrCALL(TrPROP(TrTHIS, @"tickle"))];
	}
	OOTrFunctionDeclaration *function = TrFUNC(name, nil, actions);
	return TrASSIGN(TrPROP(TrTHIS, name), function);
}


OOTrFunctionDeclaration *OOTrJavaScriptFunctionExpressionFromLegacyScriptActions(NSArray *actions, NSString *name, id <OOProblemReporting> problemReporter)
{
	NSCParameterAssert(actions != nil && name != nil);
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSArray *sanitizedActions = OOSanitizeLegacyScript(actions, name, NO);
	if (sanitizedActions == nil)
	{
		[pool release];
		return nil;
	}
	
	OOTrConverter *converter = [[[OOTrConverter alloc] initWithProblemReporter:problemReporter] autorelease];
	OOTrCompoundStatement *actionsCompound = [converter parseSanitizedScript:sanitizedActions];
	NSMutableArray *convertedActions = [NSMutableArray arrayWithArray:[actionsCompound statements]];
	
	/*
		In addition to running peridocically, the legacy script was run in
		connection with certain events, and specific player ship statuses were
		only seen once for each such event. Script actions that are conditional
		on such an event can therefore be pulled out into event handlers.
	 */
	NSMutableArray *dockActions = [converter extractActions:convertedActions keyedToEvent:@"STATUS_DOCKING"];
	NSMutableArray *launchActions = [converter extractActions:convertedActions keyedToEvent:@"STATUS_LAUNCHING"];
	NSMutableArray *enterWitchspaceActions = [converter extractActions:convertedActions keyedToEvent:@"STATUS_ENTERING_WITCHSPACE"];
	NSMutableArray *exitWitchspaceActions = [converter extractActions:convertedActions keyedToEvent:@"STATUS_EXITING_WITCHSPACE"];
	
	NSMutableArray *script = [NSMutableArray arrayWithCapacity:6];
	[script addObject:TrASSIGN(TrPROP(TrTHIS, @"name"), TrSTR(name))];
	
	NSDictionary *initializers = [converter initializers];
	if (initializers != nil)
	{
		NSString *property = nil;
		foreachkey (property, initializers)
		{
			OOTrExpression *value = [initializers objectForKey:property];
			[script addObject:TrASSIGN(TrPROP(TrTHIS, TrID(property)), value)];
		}
	}
	
	BOOL tickle = [convertedActions count] != 0;
	if (dockActions != nil)  [script addObject:BuildHandler(@"shipWillDockWithStation", dockActions, tickle)];
	if (launchActions != nil)  [script addObject:BuildHandler(@"shipWillLaunchFromStation", launchActions, tickle)];
	if (enterWitchspaceActions != nil)  [script addObject:BuildHandler(@"shipWillEnterWitchspace", enterWitchspaceActions, tickle)];
	if (exitWitchspaceActions != nil)  [script addObject:BuildHandler(@"shipWillExitWitchspace", exitWitchspaceActions, tickle)];
	if (tickle)  [script addObject:BuildHandler(@"tickle", convertedActions, NO)];
	
	OOTrFunctionDeclaration *func = TrFUNC([name oo_isSimpleJSIdentifier] ? name : nil, nil, script);
	[func retain];
	[pool release];
	
	return [func autorelease];
	
#if 0
	NSDictionary *initializers = [converter initializers];
	if (initializers != nil)
	{
		NSArray *funcBodyStatements = [functionBody statements];
		NSMutableArray *reifiedInitializers = [NSMutableArray arrayWithCapacity:[initializers count] + [funcBodyStatements count]];
		NSString *property = nil;
		foreachkey (property, initializers)
		{
			OOTrExpression *value = [initializers objectForKey:property];
			[reifiedInitializers addObject:TrASSIGN(TrPROP(TrTHIS, TrID(property)), value)];
		}
		
		[reifiedInitializers addObjectsFromArray:funcBodyStatements];
		functionBody = [OOTrCompoundStatement compoundStatementWithStatements:reifiedInitializers];
	}
	
#if SIMPLIFY
	functionBody = [functionBody simplified];
#endif
	
	OOTrFunctionDeclaration *func = nil;
	if (functionBody != nil)
	{
		func = TrFUNC(name, nil, functionBody);
	}
	
	[func retain];
	[pool release];
	
	return [func autorelease];
#endif
}


@implementation OOTrConverter

- (id) initWithProblemReporter:(id <OOProblemReporting>)problemReporter
{
	if ((self = [super init]))
	{
		_issues = [problemReporter retain];
	}
	return self;
}

- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_objectHolder);
	DESTROY(_initializers);
	DESTROY(_variables);
	
	[super dealloc];
}


- (void) holdObject:(id)object
{
	// Retain an object indirectly through _objectHolder, so we can release them en masse.
	
	if (EXPECT_NOT(object == nil))  return;
	if (_objectHolder == nil)  _objectHolder = [[NSMutableSet alloc] init];
	[_objectHolder addObject:object];
}


- (OOTrExpression *) resolveVariable:(NSString *)name
{
	OOTrExpression *result = [_variables objectForKey:name];
	if (result != nil)  return result;
	
	if ([name hasPrefix:@"mission_"])
	{
		result = TrPROP(@"missionVariables", [name substringFromIndex:8]);
	}
	else if ([name hasPrefix:@"local_"])
	{
		name = [@"$_" stringByAppendingString:[name substringFromIndex:6]];
		[self setInitializer:TrNULL forProperty:name];
		result = TrPROP(TrTHIS, name);
	}
	
	if (result != nil)
	{
		if (_variables == nil)  _variables = [[NSMutableDictionary alloc] init];
		[_variables setObject:result forKey:name];
	}
	
	return result;
}


- (void) setInitializer:(OOTrExpression *)initializer forProperty:(NSString *)property
{
	if (initializer == nil || property == nil)  return;
	NSParameterAssert([property oo_isSimpleJSIdentifier]);
	
	if (_initializers == nil)  _initializers = [[NSMutableDictionary alloc] init];
	[_initializers setObject:initializer forKey:property];
}


- (NSDictionary *) initializers
{
	return _initializers;
}


- (void) addMissionInitializer
{
	if ([_initializers objectForKey:kOOTrMissionScreenInfo] == nil)
	{
		[self setInitializer:[OOTrObjectDeclaration declarationWithProperties:$dict(@"message", TrSTR(@""))]
				 forProperty:kOOTrMissionScreenInfo];
		[self setInitializer:TrNULL forProperty:kOOTrMissionChoice];
	}
}


- (OOTrExpression *) parseIntOrZeroHelper
{
	if (_parseIntOrZeroHelper == nil)
	{
		/*
			this.$parseIntOrZero = function $parseIntOrZero(param)
			{
				let value = parseInt(param);
				return isNaN(value) ? 0 : value;
			}
		*/
		
		OOTrFunctionDeclaration *func = TrFUNC(kOOTrParseIntOrZero, $array(@"param"), $array
		(
			TrLET(@"value", TrCALL(@"parseInt", TrID(@"param"))),
			TrRETURN(TrCOND(TrCALL(@"isNaN", TrID(@"value")), TrNUM(0), TrID(@"value")))
		));
		[self setInitializer:func forProperty:kOOTrParseIntOrZero];
		
		_parseIntOrZeroHelper = TrPROP(TrTHIS, kOOTrParseIntOrZero);
		[self holdObject:_parseIntOrZeroHelper];
	}
	
	return _parseIntOrZeroHelper;
}


- (OOTrExpression *) parseFloatOrZeroHelper
{
	if (_parseFloatOrZeroHelper == nil)
	{
		/*
			this.$parseFloatOrZero = function $parseFloatOrZero(param)
			{
				let value = parseFloat(param);
				return isNaN(value) ? 0 : value;
			}
		*/
		
		OOTrFunctionDeclaration *func = TrFUNC(kOOTrParseFloatOrZero, $array(@"param"), $array
		(
			TrLET(@"value", TrCALL(@"parseFloat", TrID(@"param"))),
			TrRETURN(TrCOND(TrCALL(@"isNaN", TrID(@"value")), TrNUM(0), TrID(@"value")))
		));
		[self setInitializer:func forProperty:kOOTrParseFloatOrZero];
		
		_parseFloatOrZeroHelper = TrPROP(TrTHIS, kOOTrParseFloatOrZero);
		[self holdObject:_parseFloatOrZeroHelper];
	}
	
	return _parseFloatOrZeroHelper;
}


- (OOTrExpression *) testForEquipmentHelper
{
	if (_testForEquimentHelper == nil)
	{
		/*
			this.$testForEquipment = function $testForEquipment(eqKey)
			{
				let desiredState = "EQUIPMENT_OK";
				if (/.*_DAMAGED$/.test(eqKey))
				{
					desiredState = "EQUIPMENT_DAMAGED";
					eqKey = eqKey.slice(0, -8);
				}
				this.$foundEquipment = player.ship.equipmentStatus(eqKey) == desiredState;
			}
		 */
		OOTrExpression *eqKey = TrID(@"eqKey");
		OOTrExpression *desiredState = TrID(@"desiredState");
		OOTrFunctionDeclaration *func = TrFUNC(kOOTrTestForEquipment, $array(@"eqKey"), $array
		(
			TrLET(@"desiredState", TrSTR(@"EQUIPMENT_OK")),
			TrIF(TrCALL(TrPROP(TrREGEXP(@".*_DAMAGED$", nil), @"test"), eqKey),
			$array
			(
				TrASSIGN(desiredState, TrSTR(@"EQUIPMENT_DAMAGED")),
				TrASSIGN(eqKey, TrCALL(TrPROP(eqKey, @"slice"), TrNUM(0), TrNUM(-8)))
			), nil),
			TrASSIGN(TrPROP(TrTHIS, @"$foundEquipment"), TrEQUAL(TrCALL(TrPROP([self exprPlayerShip], @"equipmentStatus"), eqKey), desiredState))
		));
		[self setInitializer:func forProperty:kOOTrTestForEquipment];
											 
		 _testForEquimentHelper = TrPROP(TrTHIS, kOOTrTestForEquipment);
		 [self holdObject:_testForEquimentHelper];
	}
	return _testForEquimentHelper;
}


- (void) fixUpMissionMethodOrder:(NSMutableArray *)statements
{
	NSUInteger i, count = [statements count], fenceLoc = NSNotFound;
	
	// Look for last statement with kOOTrMissionFence set.
	for (i = count; i > 0; i--)
	{
		OOTrStatement *statement = [statements objectAtIndex:i - 1];
		if ([[statement annotationForKey:kOOTrMissionFence] boolValue])
		{
			fenceLoc = i - 1;
			break;
		}
	}
	
	if (fenceLoc == NSNotFound)  return;
	
	// Iterate backwards from fenceLoc, moving any statements with kOOTrMissionCall set to after the fence.
	for (i = fenceLoc; i > 0; i--)
	{
		OOTrStatement *statement = [statements objectAtIndex:i - 1];
		if ([[statement annotationForKey:kOOTrMissionCall] boolValue])
		{
			[[statement retain] autorelease];
			[statements removeObjectAtIndex:i - 1];
			[statements insertObject:statement atIndex:fenceLoc];
		}
	}
}


- (OOTrCompoundStatement *) parseSanitizedScript:(NSArray *)script
{
	if (script == nil)  return TrNULLSTMT;
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSMutableArray *parsedStatments = [NSMutableArray arrayWithCapacity:[script count]];
	NSArray *statement = nil;
	foreach (statement, script)
	{
		OOTrStatement *parsed = [self parseSanitizedStatment:statement];
		if (parsed == nil)  return nil;
		[parsedStatments addObject:parsed];
	}
	
	[self fixUpMissionMethodOrder:parsedStatments];
	
	OOTrCompoundStatement *result = [OOTrCompoundStatement compoundStatementWithStatements:parsedStatments];
	[result retain];
	[pool release];
	return [result autorelease];
}


- (OOTrStatement *) parseSanitizedStatment:(NSArray *)statement
{
	// See OOLegacyScriptWhitelist.h for format description.
	if ([statement oo_boolAtIndex:0])
	{
		return [self parseConditionalStatement:statement];
	}
	else
	{
		return [self parseActionStatement:statement];
	}
}


- (OOTrStatement *) parseConditionalStatement:(NSArray *)statement
{
	NSArray *conditions = [statement oo_arrayAtIndex:1];
	NSArray *trueScript = [statement oo_arrayAtIndex:2];
	NSArray *falseScript = [statement oo_arrayAtIndex:3];
	
	OOTrExpression *parsedCondition = [self parseConditions:conditions];
	OOTrStatement *trueStatment = [self parseSanitizedScript:trueScript];
	OOTrStatement *falseStatment = [self parseSanitizedScript:falseScript];
	
	if (parsedCondition == nil || trueStatment == nil || falseStatment == nil)
	{
		return nil;	// Error should have been reported.
	}
	
	return TrIF(parsedCondition, trueStatment, falseStatment);
}


- (OOTrStatement *) parseActionStatement:(NSArray *)statement
{
	NSString *rawString = [statement oo_stringAtIndex:1];
	NSString *selectorStr = [statement oo_stringAtIndex:2];
	
	BOOL takesParam = [statement count] > 3;
	NSString *argument = nil;
	if (takesParam)  argument = [statement oo_stringAtIndex:3];
	
	OOTrStatement *result = nil;
	
	NSString *convertSelector = [@"convertAction_" stringByAppendingString:selectorStr];
	SEL selector = NSSelectorFromString(convertSelector);
	if (![self respondsToSelector:selector])
	{
		OOReportError(_issues, @"Cannot convert unknown action method \"%@\" in statement \"%@\".", selectorStr, rawString);
		return TrNULLSTMT; //nil;
	}
	result = [self performSelector:selector withObject:argument];
	if (result == nil)
	{
		OOReportError(_issues, @"Conversion of action method \"%@\" produced a NULL expression in statement \"%@\".", selectorStr, rawString);
		return nil;
	}
	
	return result;
}


- (OOTrExpression *) parseConditions:(NSArray *)conditions
{
	OOTrExpression *conds = nil;
	
	NSEnumerator *condEnum = [conditions objectEnumerator];
	NSArray *condition = nil;
	while ((condition = [condEnum nextObject]))
	{
		OOTrExpression *expr = [self parseOneCondition:condition];
		if (expr == nil)  return nil;
		
		if (conds == nil)  conds = expr;
		else  conds = TrAND(conds, expr);
	}
	
	return conds;
}


- (OOTrExpression *) parseOneCondition:(NSArray *)condition
{
	OOOperationType opType = [condition oo_intAtIndex:0];
	if (opType == OP_FALSE)  return TrNO;
	
	NSString *rawString = [condition oo_stringAtIndex:1];
	NSString *selectorStr = [condition oo_stringAtIndex:2];
	OOComparisonType compType = [condition oo_intAtIndex:3];
	NSArray *arguments = [condition oo_arrayAtIndex:4];
	
	OOTrExpression *lhs = nil;
	
	// Convert left-hand side.
	if (opType == OP_MISSION_VAR || opType == OP_LOCAL_VAR)
	{
		lhs = [self resolveVariable:selectorStr];
	}
	else
	{
		NSString *convertSelector = [@"convertQuery_" stringByAppendingString:selectorStr];
		SEL selector = NSSelectorFromString(convertSelector);
		if (![self respondsToSelector:selector])
		{
			OOReportError(_issues, @"Cannot convert unknown query method \"%@\" in condition \"%@\".", selectorStr, rawString);
			return nil;
		}
		lhs = [self performSelector:selector];
		if (lhs == nil)
		{
			OOReportError(_issues, @"Conversion of query method \"%@\" produced a NULL expression in condition \"%@\".", selectorStr, rawString);
			return nil;
		}
	}
	
	BOOL rhsIsString;
	OOTrExpression *rhs = [self expandConditionRightHandSide:arguments isString:&rhsIsString];
	
	switch (opType)
	{
		case OP_NUMBER:
			rhs = TrTONUM(rhs);		// Number literals will be fixed up in the simplify stage.
			return [self convertNumberOperation:compType
									   withLeft:lhs
										  right:rhs
									  rawString:rawString];
			
		case OP_STRING:
		case OP_MISSION_VAR:
		case OP_LOCAL_VAR:
			return [self convertStringOperation:compType
									   withLeft:lhs
										  right:rhs
									 isVariable:(opType == OP_MISSION_VAR || opType == OP_LOCAL_VAR)
									  rawString:rawString];
			
		case OP_BOOL:
			return [self convertBooleanOperation:compType
										withLeft:lhs
										   right:rhs
									   rawString:rawString];
			
		case OP_FALSE:
		case OP_INVALID:
			;
	}
	
	OOReportError(_issues, @"Unhandled operation type %u", opType);
	return nil;
}


- (OOTrExpression *) expandOneArgument:(NSArray *)argument isString:(BOOL *)isString
{
	NSParameterAssert(isString != NULL);
	
	BOOL isSelector = [argument oo_boolAtIndex:0];
	NSString *stringValue = [argument oo_stringAtIndex:1];
	
	if (!isSelector)
	{
		*isString = YES;
		return TrSTR(stringValue);
	}
	
	return nil;
}


- (OOTrExpression *) expandConditionRightHandSide:(NSArray *)components isString:(BOOL *)isString
{
	BOOL partialIsString = NO;
	OOTrExpression *exprs = nil;
	
	NSEnumerator *argEnum = [components objectEnumerator];
	NSArray *argument = nil;
	while ((argument = [argEnum nextObject]))
	{
		OOTrExpression *expr = [self expandOneArgument:argument isString:isString];
		if (expr == nil)  return nil;
		
		if (exprs == nil)  exprs = expr;
		else
		{
			exprs = TrADD(exprs, expr);
			partialIsString = *isString;
		}
	}
	
	return exprs;
}


- (OOTrExpression *) expandString:(NSString *)string
{
	if (!StringContainsEscapes(string))
	{
		// Simple case: just a literal string.
		return TrSTR(string);
	}
	
	/*	Kludge: handle some common cases to make output code look less stupid.
		A better way might be to expand all brackets instead. A problem there
		is that in principle, descriptions.plist entries can override method
		call substitutions (but not local or mission variables), although it
		would be reasonable to consider that a bug.
	*/
	static NSDictionary *specialCases = nil;
	if (specialCases == nil)
	{
		specialCases = $dict
		(
			@"[credits_number]", [self exprPlayerCredits],
			@"[score_number]", TrPROP(@"player", @"score"),
			@"-[credits_number]", TrUOP(UnaryMinus, [self exprPlayerCredits]),
			@"[legalStatus_number]", [self exprPlayerBounty],
			@"[commanderLegalStatus_number]", [self exprPlayerBounty],
			@"[commander_legal_status]", [self exprPlayerBounty],
			@"[d100_number]", TrPROP(@"system", @"psuedoRandom100"),
			@"[d256_number]", TrPROP(@"system", @"psuedoRandom256")
		);
	}
	
	OOTrExpression *special = [specialCases objectForKey:string];
	if (special != nil)  return special;
	
	if ([string rangeOfString:@"[local_"].location != NSNotFound)
	{
		return [self expandStringWithLocalVariables:string];
	}
	else if ([string rangeOfString:@"[mission_"].location != NSNotFound)
	{
		return [self expandStringWithMissionVariables:string];
	}
	
	return TrCALL(TrID(@"expandDescription"), TrSTR(string));
}


- (OOTrExpression *) expandStringOrNumber:(NSString *)string
{
	if (OOIsNumberLiteral(string, NO))  return TrTONUM(TrSTR(string));
	else  return [self expandString:string];
}


- (OOTrExpression *) expandStringOrBoolean:(NSString *)string
{
	OOTrExpression *result = [self expandString:string];
	if ([result isKindOfClass:[OOTrStringLiteral class]])
	{
		string = [(OOTrStringLiteral *)result stringValue];
		if ([string isEqualToString:@"YES"])  return TrYES;
		if ([string isEqualToString:@"NO"])  return TrNO;
	}
	
	return result;
}


- (OOTrExpression *) expandStringOrNone:(NSString *)string
{
	OOTrExpression *result = [self expandString:string];
	if ([result isEqual:TrSTR(@"none")])  result = TrNULL;
	return result;
}


- (OOTrExpression *) expandStringWithMissionVariables:(NSString *)string
{
	/*	Strings with [mission_foo] substitutions are handled by splitting
		at the first [mission_foo], inserting the relevant mission variable,
		then recursively calling expandString: for the prefix and suffix.
		
		Example:
			"foo [mission_a] bar %R [mission_a] baz" is split as:
				prefix: "foo "
				varName: mission_a
				suffix: " bar %R [mission_a] baz"
		
		Recursive processing should result in the JS expression:
		"foo " + missionVariables.a + expandDescription(" bar %R ") + missionVariables.$b + " baz"
	*/
	
	NSUInteger length = [string length];
	
	NSRange varStart = [string rangeOfString:@"[mission_"];
	NSAssert1(varStart.location != NSNotFound, @"%s called for string without mission variables.", __func__);
	
	NSUInteger endOfTag = varStart.location + varStart.length;
	NSRange varEnd = [string rangeOfString:@"]" options:0 range:NSMakeRange(endOfTag, length - endOfTag)];
	if (varEnd.location == NSNotFound)
	{
		/*	[mission_ without closing ], not a substitution. To avoid infinite
			recursion, we split this into two parts after mission and before _.
			The simplifier should clean this up later.
		*/
		
		NSString *prefix = [string substringToIndex:endOfTag - 1];
		NSString *suffix = [string substringFromIndex:endOfTag - 1];
		
		return TrADD([self expandString:prefix], [self expandString:suffix]);
	}
	
	NSString *prefix = [string substringToIndex:varStart.location];
	NSString *suffix = [string substringFromIndex:varEnd.location + varEnd.length];
	NSString *varName = [string substringWithRange:NSMakeRange(varStart.location + 1, varEnd.location - varStart.location - 1)];
	
	OOTrExpression *result = [self resolveVariable:varName];
	if (result == nil)  return nil;
	
	if ([prefix length] > 0)
	{
		result = TrADD([self expandString:prefix], result);
	}
	if ([suffix length] > 0)
	{
		result = TrADD(result, [self expandString:suffix]);
	}
	
	return result;
}


- (OOTrExpression *) expandStringWithLocalVariables:(NSString *)string
{
	// Same as above, but for local_variables.
	
	NSUInteger length = [string length];
	
	NSRange varStart = [string rangeOfString:@"[local_"];
	NSAssert1(varStart.location != NSNotFound, @"%s called for string without local variables.", __func__);
	
	NSUInteger endOfTag = varStart.location + varStart.length;
	NSRange varEnd = [string rangeOfString:@"]" options:0 range:NSMakeRange(endOfTag, length - endOfTag)];
	if (varEnd.location == NSNotFound)
	{
		/*	[local_ without closing ], not a substitution. To avoid infinite
			recursion, we split this into two parts after local and before _.
			The simplifier should clean this up later.
		*/
		
		NSString *prefix = [string substringToIndex:endOfTag - 1];
		NSString *suffix = [string substringFromIndex:endOfTag - 1];
		
		return TrADD([self expandString:prefix], [self expandString:suffix]);
	}
	
	NSString *prefix = [string substringToIndex:varStart.location];
	NSString *suffix = [string substringFromIndex:varEnd.location + varEnd.length];
	NSString *varName = [string substringWithRange:NSMakeRange(varStart.location + 1, varEnd.location - varStart.location - 1)];
	
	OOTrExpression *result = [self resolveVariable:varName];
	if (result == nil)  return nil;
	
	if ([prefix length] > 0)
	{
		result = TrADD([self expandString:prefix], result);
	}
	if ([suffix length] > 0)
	{
		result = TrADD(result, [self expandString:suffix]);
	}
	
	return result;
}


- (OOTrExpression *) expandIntegerExpression:(NSString *)string
{
	OOTrExpression *expanded = [self expandString:string];
	if ([expanded isNumericConstant])
	{
		double value = [expanded doubleValue];
		return TrNUM(trunc(value));
	}
	if ([expanded hasNumericType])
	{
		/*	The logical thing to do here would be call Math.trunc() on the
			value. However, Math.trunc() doesn’t exist. It’s reasonable to
			assume that all Oolite methods that expect an integer will handle
			non-integer values, given there’s no actual distincition in JS,
			so we just return the value without consideration to integerosity.
		*/
		return expanded;
	}
	
	return TrHELPER(@"parseIntOrZero", expanded);
}


- (OOTrExpression *) expandFloatExpression:(NSString *)string
{
	OOTrExpression *expanded = [self expandString:string];
	if ([expanded isNumericConstant] || [expanded hasNumericType])
	{
		return TrTONUM(TrSTR(string));
	}
	else
	{
		return TrHELPER(@"parseFloatOrZero", [self expandString:string]);
	}
}


- (OOTrExpression *) convertNumberOperation:(OOComparisonType)compType
								   withLeft:(OOTrExpression *)lhs
									  right:(OOTrExpression *)rhs
								  rawString:(NSString *)rawString
{
	switch (compType)
	{
		case COMPARISON_EQUAL:
			return TrEQUAL(lhs, rhs);
			
		case COMPARISON_NOTEQUAL:
			return TrNEQUAL(lhs, rhs);
			
		case COMPARISON_LESSTHAN:
			return TrLESS(lhs, rhs);
			
		case COMPARISON_GREATERTHAN:
			return TrLESS(rhs, lhs);
			
		case COMPARISON_ONEOF:
			return TrHELPER(@"oneOfNumber", lhs, rhs);
			
		case COMPARISON_UNDEFINED:
			;
	}
	
	OOReportError(_issues, @"Operator \"%@\" is not valid for %@ expressions. (\"%@\")", OOComparisonTypeToString(compType), @"number", rawString);
	return nil;
}


- (OOTrExpression *) convertBooleanOperation:(OOComparisonType)compType
									withLeft:(OOTrExpression *)lhs
									   right:(OOTrExpression *)rhs
								   rawString:(NSString *)rawString
{
	lhs = SimplifyBoolExpression(lhs);
	rhs = SimplifyBoolExpression(rhs);
	
	switch (compType)
	{
		case COMPARISON_EQUAL:
			/*	The simplifier can’t do anything to boolean because it
				doesn’t know the dynamic type of lhs, which we can assume to
				be boolean.
			*/
			if (rhs == TrYES)  return lhs;
			if (rhs == TrNO)  return TrNOT(lhs);
			return TrEQUAL(lhs, rhs);
			
		case COMPARISON_NOTEQUAL:
			if (rhs == TrYES)  return TrNOT(lhs);
			if (rhs == TrNO)  return lhs;
			return TrNEQUAL(lhs, rhs);
			
		case COMPARISON_LESSTHAN:
		case COMPARISON_GREATERTHAN:
		case COMPARISON_ONEOF:
		case COMPARISON_UNDEFINED:
			;
	}
	
	OOReportError(_issues, @"Operator \"%@\" is not valid for %@ expressions. (\"%@\")", OOComparisonTypeToString(compType), @"boolean", rawString);
	return nil;
}


- (OOTrExpression *) convertStringOperation:(OOComparisonType)compType
								   withLeft:(OOTrExpression *)lhs
									  right:(OOTrExpression *)rhs
								 isVariable:(BOOL)isVariable
								  rawString:(NSString *)rawString
{
	switch (compType)
	{
		case COMPARISON_EQUAL:
			return TrEQUAL(lhs, rhs);
			
		case COMPARISON_NOTEQUAL:
			return TrNEQUAL(lhs, rhs);
			
		case COMPARISON_LESSTHAN:
			return TrLESS(lhs, TrTONUM(rhs));
			
		case COMPARISON_GREATERTHAN:
			return TrLESS(TrTONUM(rhs), lhs);
			
		case COMPARISON_ONEOF:
		{
			/*	Construct:
				LIST.indexOf(lhs) != -1
				...where LIST is StringListFromExpression(rhs).
			*/
			
			OOTrExpression *listExpr = StringListFromExpression(rhs);
			OOTrExpression *indexOfExpr = TrCALL(TrPROP(listExpr, TrID(@"indexOf")), lhs);
			OOTrExpression *notEqExpr = TrNEQUAL(indexOfExpr, TrNUM(-1));
			
			return notEqExpr;
		}
			
		case COMPARISON_UNDEFINED:
		{
			if (isVariable)
			{
				// Mission variables are never undefined in the JS sense, only null.
				// Local variables are explicitly set to null by the converter.
				return TrSEQUAL(lhs, TrNULL);
			}
			else
			{
				/*	Construct:
					lhs === undefined || lhs === null
				*/
				return TrOR(TrSEQUAL(lhs, TrUNDEFINED), TrSEQUAL(lhs, TrNULL));
			}
		}
	}
	
	OOReportError(_issues, @"Operator \"%@\" is not valid for %@ expressions. (\"%@\")", OOComparisonTypeToString(compType), @"string", rawString);
	return nil;
}


- (NSMutableArray *) extractActions:(NSMutableArray *)actions keyedToEvent:(NSString *)event
{
	NSParameterAssert(actions != nil && event != nil);
	
	OOTrExpression *eventMatcher = TrEQUAL([self exprPlayerShipStatus], TrSTR(event));
	NSMutableArray *result = [NSMutableArray array];
	
	NSUInteger i, count = [actions count];
	for (i = 0; i < count; i++)
	{
		id statement = [actions objectAtIndex:i];
		if ([statement isKindOfClass:[OOTrConditionalStatement class]])
		{
			OOTrExpression *condition = [(OOTrConditionalStatement *)statement condition];
			condition = [condition extractRequiredSubCondition:eventMatcher];
			if (condition != nil)
			{
				// The statement was conditional on the event expression; condition is now simplified to assume the event has been matched.
				[result addObject:TrIF(condition, [statement trueStatement], [statement falseStatement])];
				[actions removeObjectAtIndex:i];
				i--;
				count--;
			}
		}
	}
	
	if ([result count] > 0)  return result;
	return nil;
}

@end


static OOTrExpression *SimplifyBoolExpression(OOTrExpression *expr)
{
	expr = [expr simplified];
	if ([expr isKindOfClass:[OOTrStringLiteral class]])
	{
		/*	Legacy scripting uses case-sensitive YES and NO for boolean
		 comparisions.
		 Semantic issue: a condition like:
		 "foo_bool equal 1"
		 (where foo_bool is true) will fail in legacy script and pass in
		 converted JS. This is considered acceptable unless we run into it
		 in real life.
		 */
		NSString *string = [(OOTrStringLiteral *)expr stringValue];
		if ([string isEqualToString:@"YES"])  expr = TrYES;
		else if ([string isEqualToString:@"NO"])  expr = TrNO;
	}
	if ([expr hasKnownBooleanValue])  expr = [expr booleanLiteralValue];
	
	return expr;
}


static OOTrExpression *StringListFromExpression(OOTrExpression *expression)
{
	/*	Given an expression whose value is expected to be a string containing
	 a comma-separated list, return an expression representing an array.
	 */
	
	expression = [expression simplified];
	if ([expression isKindOfClass:[OOTrStringLiteral class]])
	{
		/*	If it’s a string literal, replace it with an array of string literals.
		 NOTE: it would be possible to optimize the case where it's a string
		 literal with no commas, which reduces to an equality comparison,
		 but that’s unlikely to exist in practice.
		 */
		NSString *string = [(OOTrStringLiteral *)expression stringValue];
		NSArray *components = [string componentsSeparatedByString:@","];
		return [OOTrArrayDeclaration declarationWithStrings:components];
	}
	else
	{
		/*	Construct:
		 ("" + expression).split(",")
		 */
		return TrCALL(TrPROP(TrTOSTR(expression), TrID(@"split")), TrSTR(@","));
	}
}


static BOOL StringContainsEscapes(NSString *string)
{
	if ([string rangeOfString:@"["].location != NSNotFound && [string rangeOfString:@"]"].location != NSNotFound)  return YES;
	if ([string rangeOfString:@"%H"].location != NSNotFound)  return YES;
	if ([string rangeOfString:@"%I"].location != NSNotFound)  return YES;
	if ([string rangeOfString:@"%R"].location != NSNotFound)  return YES;
	if ([string rangeOfString:@"%X"].location != NSNotFound)  return YES;
	
	return NO;
}


@implementation OOTrExpression (EventExtraction)

- (OOTrExpression *) extractRequiredSubCondition:(OOTrExpression *)expression
{
	if ([expression isEqual:self])  return TrYES;
	else  return nil;
}

@end


@implementation OOTrLogicalAndOperator (EventExtraction)

- (OOTrExpression *) extractRequiredSubCondition:(OOTrExpression *)expression
{
	OOTrExpression *left = [self leftArgument];
	OOTrExpression *right = [self rightArgument];
	OOTrExpression *extractLeft = [left extractRequiredSubCondition:expression];
	OOTrExpression *extractRight = [right extractRequiredSubCondition:expression];
	
	if (extractLeft == nil && extractRight == nil)  return nil;
	return TrAND(extractLeft ? extractLeft : left, extractRight ? extractRight : right);
}

@end
