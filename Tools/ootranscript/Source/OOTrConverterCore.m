/*

OOTrConverterCore.m
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


/*	Like TrADD, but asserts that both sides will evaluate to numbers. This
	allows the simplifier to convert x + -y to x - y without considering the
	possibility that x might be a string (causing concatenation).
*/
static OOTrExpression *AddNum(id left, id right)
{
	[left setBooleanAnnotation:YES forKey:kOOTrHasNumericTypeOverride];
	[right setBooleanAnnotation:YES forKey:kOOTrHasNumericTypeOverride];
	
	return TrADD(left, right);
}


@implementation OOTrConverter (TranscriptionCore)

/**** Common subexpressions ****/

#define DECLARE_SUBEXPR(name, expression) \
- (OOTrExpression *) expr##name \
{ \
	if (_expr##name == nil) \
	{ \
		_expr##name = (expression); \
		[self holdObject:_expr##name]; \
	} \
	return _expr##name; \
}

DECLARE_SUBEXPR(MathFloor, TrPROP(@"Math", @"floor"))
DECLARE_SUBEXPR(MathRandomCall, TrCALL(TrPROP(@"Math", @"random")))
DECLARE_SUBEXPR(PlayerBounty, TrPROP(@"player", @"bounty"))
DECLARE_SUBEXPR(PlayerCredits, TrPROP(@"player", @"credits"))
DECLARE_SUBEXPR(PlayerShip, TrPROP(@"player", @"ship"))
DECLARE_SUBEXPR(PlayerShipStatus, TrPROP([self exprPlayerShip], @"status"))
DECLARE_SUBEXPR(SystemInfo, TrPROP(@"system", @"info"))
DECLARE_SUBEXPR(SystemMainStation, TrPROP(@"system", @"mainStation"))
DECLARE_SUBEXPR(SystemSun, TrPROP(@"system", @"sun"))
DECLARE_SUBEXPR(ThisMissionChoice, TrPROP(TrTHIS, kOOTrMissionChoice))
DECLARE_SUBEXPR(ThisMissionScreen, TrPROP(TrTHIS, kOOTrMissionScreenInfo))


/**** Query convertors ****/

- (OOTrExpression *) convertQuery_credits_number
{
	return [self exprPlayerCredits];
}


- (OOTrExpression *) convertQuery_d100_number
{
	// Math.floor(Math.random() * 100)
	return TrCALL([self exprMathFloor], TrMUL([self exprMathRandomCall], TrNUM(100)));
}


- (OOTrExpression *) convertQuery_d256_number
{
	// Math.floor(Math.random() * 256)
	return TrCALL([self exprMathFloor], TrMUL([self exprMathRandomCall], TrNUM(256)));
}


- (OOTrExpression *) convertQuery_dockedAtMainStation_bool
{
	/*	player.ship.docked && player.ship.dockedStation == system.mainStation
		(player.ship.docked is required, because player.ship.dockedStation ==
		system.mainStation is true in interstellar space.)
	*/
	OOTrExpression *playerShip = [self exprPlayerShip];
	OOTrExpression *dockedExpr = TrPROP(playerShip, @"docked");
	OOTrExpression *isMainStationExpr = TrEQUAL(TrPROP(playerShip, @"dockedStation"), [self exprSystemMainStation]);
	
	return TrAND(dockedExpr, isMainStationExpr);
}


- (OOTrExpression *) convertQuery_foundEquipment_bool
{
	[self setInitializer:TrNO forProperty:@"$foundEquipment"];
	return TrPROP(TrTHIS, @"$foundEquipment");
}


- (OOTrExpression *) convertQuery_galaxy_number
{
	return TrID(@"galaxyNumber");
}


- (OOTrExpression *) convertQuery_gui_screen_string
{
	return TrID(@"guiScreen");
}


- (OOTrExpression *) convertQuery_missionChoice_string
{
	[self addMissionInitializer];
	return [self exprThisMissionChoice];
}


- (OOTrExpression *) convertQuery_planet_number
{
	return TrPROP(@"system", @"ID");
}


- (OOTrExpression *) convertQuery_score_number
{
	return TrPROP(@"player", @"score");
}


- (OOTrExpression *) convertQuery_scriptTimer_number
{
	return TrPROP(@"clock", @"legacy_scriptTimer");
}


- (OOTrExpression *) convertQuery_status_string
{
	return [self exprPlayerShipStatus];
}


- (OOTrExpression *) convertQuery_shipsFound_number
{
	[self setInitializer:TrNUM(0) forProperty:@"$shipsFound"];
	return TrPROP(TrTHIS, @"$shipsFound");
}


- (OOTrExpression *) convertQuery_sunGoneNova_bool
{
	return TrPROP([self exprSystemSun], @"hasGoneNova");
}


- (OOTrExpression *) convertQuery_sunWillGoNova_bool
{
	return TrPROP([self exprSystemSun], @"isGoingNova");
}


/**** Action convertors ****/

- (OOTrStatement *) convertAction_addFuel:(NSString *)params
{
	OOTrExpression *target = TrPROP([self exprPlayerShip], @"fuel");
	return TrASSIGN(target, AddNum(target, [self expandIntegerExpression:params]));
}


- (OOTrStatement *) convertAction_addMissionText:(NSString *)params
{
	[self addMissionInitializer];
	
	OOTrExpression *messageVar = TrPROP([self exprThisMissionScreen], @"message");
	OOTrStatement *result = TrASSIGN(messageVar, TrADD(messageVar, TrCALL(TrID(@"expandMissionText"), [self expandString:params])));
	
	[result setBooleanAnnotation:YES forKey:kOOTrMissionFence];
	return result;
}


- (OOTrStatement *) convertAction_addShips:(NSString *)params
{
	NSArray *tokens = OOScanTokensFromString(params);
	if ([tokens count] != 2)
	{
		OOReportError(_issues, @"Syntax error for %@: -- expected %@ followed by %@, got \"%@\".", @"addShips:", @"role", @"count", params);
		return nil;
	}
	
	OOTrExpression *role = [self expandString:[tokens objectAtIndex:0]];
	OOTrExpression *count = [self expandIntegerExpression:[tokens objectAtIndex:1]];
	
	return TrCALL(TrPROP(@"system", @"legacy_addShips"), role, count);
}


- (OOTrStatement *) convertAction_addSystemShips:(NSString *)params
{
	NSArray *tokens = OOScanTokensFromString(params);
	if ([tokens count] != 3)
	{
		OOReportError(_issues, @"Syntax error for %@: -- expected <%@> <%@> <%@>, got \"%@\".", @"addSystemShips:", @"role", @"count", @"position", params);
		return nil;
	}
	
	OOTrExpression *role = [self expandString:[tokens objectAtIndex:0]];
	OOTrExpression *count = [self expandIntegerExpression:[tokens objectAtIndex:1]];
	OOTrExpression *position = [self expandFloatExpression:[tokens objectAtIndex:2]];
	
	return TrCALL(TrPROP(@"system", @"legacy_addSystemShips"), role, count, position);
}


- (OOTrStatement *) convertAction_awardCargo:(NSString *)params
{
	NSArray *tokens = OOScanTokensFromString(params);
	if ([tokens count] != 2)
	{
		OOReportError(_issues, @"Syntax error for %@: -- expected %@ followed by %@, got \"%@\".", @"awardCargo:", @"count", @"type", params);
		return nil;
	}
	
	OOTrExpression *quantity = [self expandIntegerExpression:[tokens objectAtIndex:0]];
	OOTrExpression *type = [self expandString:[tokens objectAtIndex:1]];
	
	OOTrExpression *target = TrPROP(TrPROP([self exprPlayerShip], @"manifest"), type);
	return TrASSIGN(target, AddNum(target, quantity));
}


- (OOTrStatement *) convertAction_awardCredits:(NSString *)params
{
	OOTrExpression *target = [self exprPlayerCredits];
	return TrASSIGN(target, AddNum(target, [self expandIntegerExpression:params]));
}


- (OOTrStatement *) convertAction_awardEquipment:(NSString *)params
{
	// Legacy scripts have various special cases.
	return TrHELPER(@"awardEquipment", [self expandString:params]);
}


- (OOTrStatement *) convertAction_awardFuel:(NSString *)params
{
	return [self convertAction_addFuel:params];
}


- (OOTrStatement *) convertAction_awardShipKills:(NSString *)params
{
	OOTrExpression *target = TrPROP(@"player", @"score");
	return TrASSIGN(target, AddNum(target, [self expandIntegerExpression:params]));
}


- (OOTrStatement *) convertAction_blowUpStation
{
	return TrCALL(TrPROP([self exprSystemMainStation], @"explode"));
}


- (OOTrStatement *) convertAction_checkForShips:(NSString *)params
{
	[self setInitializer:TrNUM(0) forProperty:@"$shipsFound"];
	return TrASSIGN(TrPROP(TrTHIS, @"$shipsFound"), TrCALL(TrPROP(@"system", @"countShipsWithPrimaryRole"), [self expandStringOrNumber:params]));
}


- (OOTrStatement *) convertAction_clearMissionDescription
{
	return TrCALL(TrPROP(@"mission", @"setInstructions"), TrNULL);
}


- (OOTrStatement *) convertAction_commsMessage:(NSString *)params
{
	return TrCALL(TrPROP(@"player", @"commsMessage"), [self expandString:params]);
}


- (OOTrStatement *) convertAction_decrement:(NSString *)params
{
	OOTrExpression *target = [self resolveVariable:params];
	if (target == nil)
	{
		OOReportError(_issues, @"Syntax error for %@ -- expected mission_variable or local_variable, got \"%@\".", @"decrement:", params);
		return nil;
	}
	
	return TrASSIGN(target, TrSUB(TrCALL([self parseIntOrZeroHelper], target), TrNUM(1)));
}


- (OOTrStatement *) convertAction_increment:(NSString *)params
{
	OOTrExpression *target = [self resolveVariable:params];
	if (target == nil)
	{
		OOReportError(_issues, @"Syntax error for %@ -- expected mission_variable or local_variable, got \"%@\".", @"increment:", params);
		return nil;
	}
	
	return TrASSIGN(target, AddNum(TrCALL([self parseIntOrZeroHelper], target), TrNUM(1)));
}


- (OOTrStatement *) convertAction_launchFromStation
{
	return TrCALL(TrPROP([self exprPlayerShip], @"launch"));
}


- (OOTrStatement *) convertAction_removeAllCargo
{
	return TrCALL(TrPROP([self exprPlayerShip], @"removeAllCargo"));
}


- (OOTrStatement *) convertAction_resetMissionChoice
{
	return TrASSIGN([self exprThisMissionChoice], TrNULL);
}


- (OOTrStatement *) convertAction_sendAllShipsAway
{
	return TrCALL(TrPROP(@"system", @"sendAllShipsAway"));
}


- (OOTrStatement *) convertAction_set:(NSString *)params
{
	NSMutableArray *tokens = OOScanTokensFromString(params);
	
	if ([tokens count] < 2)
	{
		OOReportError(_issues, @"Syntax error for set: -- expected mission_variable or local_variable followed by value expression, got \"%@\".", params);
		return nil;
	}
	
	NSString *targetString = [[[tokens objectAtIndex:0] retain] autorelease];
	[tokens removeObjectAtIndex:0];
	
	OOTrExpression *targetExpr = [self resolveVariable:targetString];
	if (targetExpr == nil)
	{
		OOReportError(_issues, @"Syntax error for %@ -- expected mission_variable or local_variable, got \"%@\".", @"set:", targetString);
		return nil;
	}
	
	return TrASSIGN(targetExpr, [self expandStringOrNumber:[tokens componentsJoinedByString:@" "]]);
}


- (OOTrStatement *) convertAction_setFuelLeak:(NSString *)params
{
	return TrASSIGN(TrPROP([self exprPlayerShip], @"fuelLeakRate"), [self expandFloatExpression:params]);
}


- (OOTrStatement *) convertAction_setGuiToMissionScreen
{
	OOTrExpression *missionChoice = [self exprThisMissionChoice];
	
	// function (choice) { this.$missionChoice = choice; this.tickle(); delete this.$missionChoice; }
	OOTrExpression *callback = TrFUNC(nil, $array(@"choice"), $array(
		TrASSIGN(missionChoice, TrID(@"choice")),
		TrCALL(TrPROP(TrTHIS, @"tickle")),
		TrASSIGN(missionChoice, TrNULL)
	));
	
	OOTrExpression *runScreen = TrCALL(TrPROP(@"mission", @"runScreen"), [self exprThisMissionScreen], callback);
	
	/*	Reset mission parameters after calling runScreen(). Analyzing all the
		ways screens in the legacy informal state machine model could interact
		would be intractable, so we just go for the thing people are most
		likely to want, i.e. no interactions.
	*/
	OOTrExpression *resetMission = TrASSIGN([self exprThisMissionScreen], [[self initializers] objectForKey:kOOTrMissionScreenInfo]);
	
	// Sequence events with comma operator; the simplifier will flatten this.
	OOTrExpression *result = TrCOMMA(runScreen, resetMission);
	
	[result setBooleanAnnotation:YES forKey:kOOTrMissionCall];
	return result;
}


- (OOTrStatement *) convertAction_setLegalStatus:(NSString *)params
{
	return TrASSIGN([self exprPlayerBounty], [self expandIntegerExpression:params]);
}


- (OOTrStatement *) convertAction_setMissionChoices:(NSString *)params
{
	[self addMissionInitializer];
	
	OOTrExpression *choicesKeyVar = TrPROP([self exprThisMissionScreen], @"choicesKey");
	OOTrStatement *result = TrASSIGN(choicesKeyVar, [self expandString:params]);
	
	[result setBooleanAnnotation:YES forKey:kOOTrMissionFence];
	return result;
}


- (OOTrStatement *) convertAction_setMissionDescription:(NSString *)params
{
	return TrCALL(TrPROP(@"mission", @"setInstructionsKey"), [self expandString:params]);
}


- (OOTrStatement *) convertAction_setMissionImage:(NSString *)params
{
	[self addMissionInitializer];
	
	OOTrExpression *overlayVar = TrPROP([self exprThisMissionScreen], @"overlay");
	OOTrStatement *result = TrASSIGN(overlayVar, [self expandStringOrNone:params]);
	
	// No fence, setMissionImage: must be called before setGuiToMissionScreen.
	
	return result;
}


- (OOTrStatement *) convertAction_setPlanetinfo:(NSString *)params
{
	/*	FIXME: this doesn’t work. Many JS systemInfo writes take place
		immediately, while legacy setPlanetInfo: is deferred.
		
		The obvious fix would be to store changes and apply them when leaving
		the system, but the changes need to survive saving and reloading.
		
		It looks like we need to add a setInfoLater() method to systemInfo.
	*/
	
	NSArray *tokens = [params componentsSeparatedByString:@"="];
	if ([tokens count] != 2)
	{
		OOReportError(_issues, @"Syntax error for setPlanetInfo: -- expected \"key=role\", got \"%@\".", params);
		return nil;
	}
	
	NSCharacterSet *ws = [NSCharacterSet whitespaceCharacterSet];
	NSString *key = [[tokens objectAtIndex:0] stringByTrimmingCharactersInSet:ws];
	NSString *value = [[tokens objectAtIndex:1] stringByTrimmingCharactersInSet:ws];
	
	return TrASSIGN(TrPROP([self exprSystemInfo], key), [self expandStringOrBoolean:value]);
}


- (OOTrStatement *) convertAction_showShipModel:(NSString *)params
{
	[self addMissionInitializer];
	
	OOTrExpression *modelVar = TrPROP([self exprThisMissionScreen], @"model");
	OOTrStatement *result = TrASSIGN(modelVar, [self expandStringOrNone:params]);
	
	// No fence, showShipModel: must be called before setGuiToMissionScreen.
	
	return result;
}


- (OOTrStatement *) convertAction_setSunNovaIn:(NSString *)params
{
	return TrCALL(TrPROP([self exprSystemSun], @"goNova"), [self expandFloatExpression:params]);
}


- (OOTrStatement *) convertAction_testForEquipment:(NSString *)params
{
	[self setInitializer:TrNO forProperty:kOOTrFoundEquipment];
	
	OOTrExpression *eqKey = [[self expandString:params] simplified];
	OOTrExpression *test = nil;
	
	if ([eqKey isKindOfClass:[OOTrStringLiteral class]])
	{
		NSString *eqKeyStr = [(OOTrStringLiteral *)eqKey stringValue];
		
		NSString *desiredState = @"EQUIPMENT_OK";
		if ([eqKeyStr hasSuffix:@"_DAMAGED"])
		{
			eqKey = TrSTR([eqKeyStr substringToIndex:[eqKeyStr length] - 8]);
			desiredState = @"EQUIPMENT_DAMAGED";
		}
		
		// player.ship.equipmentStatus(eqKey) == desiredState
		test = TrEQUAL(TrCALL(TrPROP([self exprPlayerShip], @"equipmentStatus"), eqKey), TrSTR(desiredState));
		return TrASSIGN(TrPROP(TrTHIS, kOOTrFoundEquipment), test);
	}
	else
	{
		// Need to deal with EQUIPMENT_OK vs EQUIPMENT_DAMAGED at runtime.
		return TrCALL([self testForEquipmentHelper], eqKey);
	}
	
}


- (OOTrStatement *) convertAction_useSpecialCargo:(NSString *)params
{
	return TrCALL(TrPROP([self exprPlayerShip], @"useSpecialCargo"), [self expandString:params]);
}

@end
