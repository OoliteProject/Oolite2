/*

OOTrConverterInternal.h
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

#import <OoliteBase/OoliteBase.h>
#import "OOTrConverter.h"
#import "OOTrJSAST.h"
#import "OOLegacyScriptWhitelist.h"
#import "OOLegacyEngineUtilities.h"



// LegacyHelpers.name(args)
#define TrHELPER(name, args...)	TrCALL(TrPROP(TrID(@"LegacyHelpers"), TrSTR(name)), args)

#define TrTONUM(expr)			TrUOP(UnaryPlus, expr)
#define TrTOSTR(expr)			TrADD(TrSTR(@""), expr)


@interface OOTrConverter: NSObject
{
@private
	id <OOProblemReporting>		_issues;
	
	NSMutableSet				*_objectHolder;
	
	NSMutableDictionary			*_initializers;
	NSMutableDictionary			*_variables;
	
	OOTrExpression				*_exprMathFloor;
	OOTrExpression				*_exprMathRandomCall;
	OOTrExpression				*_exprPlayerBounty;
	OOTrExpression				*_exprPlayerCredits;
	OOTrExpression				*_exprPlayerShip;
	OOTrExpression				*_exprPlayerShipStatus;
	OOTrExpression				*_exprSystemInfo;
	OOTrExpression				*_exprSystemMainStation;
	OOTrExpression				*_exprSystemSun;
	OOTrExpression				*_exprThisMissionChoice;
	OOTrExpression				*_exprThisMissionScreen;
	
	OOTrExpression				*_parseIntOrZeroHelper;
	OOTrExpression				*_parseFloatOrZeroHelper;
	OOTrExpression				*_testForEquimentHelper;
}

- (id) initWithProblemReporter:(id <OOProblemReporting>)problemReporter;

// Return appropriate expression for a mission_variable or local_variable. Returns nil for any other string.
- (OOTrExpression *) resolveVariable:(NSString *)name;

// Initializers are added to the top of actions, and the beginning of predicates.
- (void) setInitializer:(OOTrExpression *)initializer forProperty:(NSString *)property;
- (NSDictionary *) initializers;

- (void) addMissionInitializer;

- (OOTrExpression *) parseIntOrZeroHelper;
- (OOTrExpression *) parseFloatOrZeroHelper;
- (OOTrExpression *) testForEquipmentHelper;

// All parse methods expect sanitized actions/conditions.
- (OOTrCompoundStatement *) parseSanitizedScript:(NSArray *)script;
- (OOTrStatement *) parseSanitizedStatment:(NSArray *)statement;
- (OOTrStatement *) parseConditionalStatement:(NSArray *)statement;
- (OOTrStatement *) parseActionStatement:(NSArray *)statement;

- (OOTrExpression *) parseConditions:(NSArray *)conditions;
- (OOTrExpression *) parseOneCondition:(NSArray *)condition;

- (OOTrExpression *) expandConditionRightHandSide:(NSArray *)components isString:(BOOL *)isString;

- (OOTrExpression *) convertNumberOperation:(OOComparisonType)compType
								   withLeft:(OOTrExpression *)lhs
									  right:(OOTrExpression *)rhs
								  rawString:(NSString *)rawString;

- (OOTrExpression *) convertBooleanOperation:(OOComparisonType)compType
									withLeft:(OOTrExpression *)lhs
									   right:(OOTrExpression *)rhs
								   rawString:(NSString *)rawString;

- (OOTrExpression *) convertStringOperation:(OOComparisonType)compType
								   withLeft:(OOTrExpression *)lhs
									  right:(OOTrExpression *)rhs
								 isVariable:(BOOL)isMissionVariable
								  rawString:(NSString *)rawString;

- (OOTrExpression *) expandString:(NSString *)string;
- (OOTrExpression *) expandStringOrNumber:(NSString *)string;
- (OOTrExpression *) expandStringOrBoolean:(NSString *)string;
- (OOTrExpression *) expandStringOrNone:(NSString *)string;
- (OOTrExpression *) expandStringWithMissionVariables:(NSString *)string;
- (OOTrExpression *) expandStringWithLocalVariables:(NSString *)string;

- (OOTrExpression *) expandIntegerExpression:(NSString *)string;
- (OOTrExpression *) expandFloatExpression:(NSString *)string;

- (void) holdObject:(id)object;

- (NSMutableArray *) extractActions:(NSMutableArray *)actions keyedToEvent:(NSString *)event;

@end


@interface OOTrConverter (CachedExpressions)

- (OOTrExpression *) exprPlayerBounty;
- (OOTrExpression *) exprPlayerCredits;
- (OOTrExpression *) exprPlayerShip;
- (OOTrExpression *) exprPlayerShipStatus;

@end


#define kOOTrMissionScreenInfo	@"$missionScreen"
#define kOOTrMissionChoice		@"$missionChoice"
#define kOOTrFoundEquipment		@"$foundEquipment"

#define kOOTrParseIntOrZero		@"$parseIntOrZero"
#define kOOTrParseFloatOrZero	@"$parseFoatOrZero"
#define kOOTrTestForEquipment	@"$testForEquipment"

// Annotations used to rearrange scripts which deal with missions.
extern NSString * const kOOTrMissionFence;
extern NSString * const kOOTrMissionCall;
