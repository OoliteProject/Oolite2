/*

PlayerEntityLegacyScriptEngine.m

Oolite
Copyright (C) 2004-2011 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import "PlayerEntityLegacyScriptEngine.h"
#import "PlayerEntityScriptMethods.h"
#import "PlayerEntitySound.h"
#import "GuiDisplayGen.h"
#import "Universe.h"
#import "ResourceManager.h"
#import "AI.h"
#import "ShipEntityAI.h"
#import "ShipEntityScriptMethods.h"
#import "OOScript.h"
#import "OOMusicController.h"
#import "OOColor.h"
#import "OOStringParsing.h"
#import "OOConstToString.h"
#import "OOLegacyTexture.h"
#import "OOSunEntity.h"
#import "OOPlanetEntity.h"
#import "OOPlanetEntity.h"
#import "StationEntity.h"
#import "Comparison.h"
#import "OOJavaScriptEngine.h"
#import "OOEquipmentType.h"

#define kOOLogUnconvertedNSLog @"unclassified.PlayerEntityLegacyScriptEngine"


#define SUPPORT_TRACE_MESSAGES	(!defined NDEBUG)

// Trace messages are very verbose debug messages in the script mechanism,
// disabled in logcontrol.plist by default and disabled here in release builds
// for performance reasons.
#if SUPPORT_TRACE_MESSAGES
#define TraceLog OOLog
#else
#define TraceLog(...) do {} while (0)
#endif


#define TRACE_AND_RETURN(x)	do { BOOL r = (x); TraceLog(kOOLogTraceTestConditionResult, @"      Result: %@", r ? @"YES" : @"NO"); return r; } while (0)


static NSString * const kOOLogScriptAddShipsFailed			= @"script.addShips.failed";
static NSString * const kOOLogScriptMissionDescNoText		= @"script.missionDescription.noMissionText";
static NSString * const kOOLogScriptMissionDescNoKey		= @"script.missionDescription.noMissionKey";

static NSString * const kOOLogDebug							= @"script.debug";
static NSString * const kOOLogDebugOnMetaClass				= @"$scriptDebugOn";
	   NSString * const kOOLogDebugMessage					= @"script.debug.message";
static NSString * const kOOLogDebugOnOff					= @"script.debug.onOff";
static NSString * const kOOLogDebugAddPlanet				= @"script.debug.addPlanet";
static NSString * const kOOLogDebugReplaceVariablesInString	= @"script.debug.replaceVariablesInString";
static NSString * const kOOLogDebugProcessSceneStringAddScene = @"script.debug.processSceneString.addScene";
static NSString * const kOOLogDebugProcessSceneStringAddModel = @"script.debug.processSceneString.addModel";
static NSString * const kOOLogDebugProcessSceneStringAddMiniPlanet = @"script.debug.processSceneString.addMiniPlanet";
static NSString * const kOOLogDebugProcessSceneStringAddBillboard = @"script.debug.processSceneString.addBillboard";

static NSString * const kOOLogTraceScriptAction				= @"script.debug.trace.scriptAction";
static NSString * const kOOLogTraceTestCondition			= @"script.debug.trace.testCondition";
static NSString * const kOOLogTraceTestConditionCheckingVariable = @"script.debug.trace.testCondition.checkingVariable";
static NSString * const kOOLogTraceTestConditionValues		= @"script.debug.trace.testCondition.testValues";
static NSString * const kOOLogTraceTestConditionResult		= @"script.debug.trace.testCondition.testResult";
static NSString * const kOOLogTraceTestConditionOneOf		= @"script.debug.trace.testCondition.oneOf";

static NSString * const kOOLogNoteRemoveAllCargo			= @"script.debug.note.removeAllCargo";
static NSString * const kOOLogNoteUseSpecialCargo			= @"script.debug.note.useSpecialCargo";
	   NSString * const kOOLogNoteAddShips					= @"script.debug.note.addShips";
static NSString * const kOOLogNoteSet						= @"script.debug.note.set";
static NSString * const kOOLogNoteShowShipModel				= @"script.debug.note.showShipModel";
static NSString * const kOOLogNoteFuelLeak					= @"script.debug.note.setFuelLeak";
static NSString * const kOOLogNoteAddPlanet					= @"script.debug.note.addPlanet";
static NSString * const kOOLogNoteProcessSceneString		= @"script.debug.note.processSceneString";

static NSString * const kOOLogSyntaxBadConditional			= @"script.debug.syntax.badConditional";
static NSString * const kOOLogSyntaxNoAction				= @"script.debug.syntax.action.noneSpecified";
static NSString * const kOOLogSyntaxBadAction				= @"script.debug.syntax.action.badSelector";
static NSString * const kOOLogSyntaxNoScriptCondition		= @"script.debug.syntax.scriptCondition.noneSpecified";
static NSString * const kOOLogSyntaxBadScriptCondition		= @"script.debug.syntax.scriptCondition.badSelector";
static NSString * const kOOLogSyntaxSetPlanetInfo			= @"script.debug.syntax.setPlanetInfo";
static NSString * const kOOLogSyntaxAwardCargo				= @"script.debug.syntax.awardCargo";
static NSString * const kOOLogSyntaxAwardEquipment			= @"script.debug.syntax.awardEquipment";
static NSString * const kOOLogSyntaxRemoveEquipment			= @"script.debug.syntax.removeEquipment";
static NSString * const kOOLogSyntaxMessageShipAIs			= @"script.debug.syntax.messageShipAIs";
	   NSString * const kOOLogSyntaxAddShips				= @"script.debug.syntax.addShips";
static NSString * const kOOLogSyntaxSet						= @"script.debug.syntax.set";
static NSString * const kOOLogSyntaxReset					= @"script.debug.syntax.reset";
static NSString * const kOOLogSyntaxIncrement				= @"script.debug.syntax.increment";
static NSString * const kOOLogSyntaxDecrement				= @"script.debug.syntax.decrement";
static NSString * const kOOLogSyntaxAdd						= @"script.debug.syntax.add";
static NSString * const kOOLogSyntaxSubtract				= @"script.debug.syntax.subtract";

static NSString * const kOOLogRemoveAllCargoNotDocked		= @"script.error.removeAllCargo.notDocked";


#define	ACTIONS_TEMP_PREFIX									"__oolite_actions_temp"
static NSString * const kActionTempPrefix					= @ ACTIONS_TEMP_PREFIX;
static NSString * const kActionTempFormat					= @ ACTIONS_TEMP_PREFIX ".%u";


static NSString		*sCurrentMissionKey = nil;


@interface PlayerEntity (ScriptingPrivate)

- (NSString *) expandMessage:(NSString *)valueString;

- (void) addScene:(NSArray *) items atOffset:(Vector) off;
- (BOOL) processSceneDictionary:(NSDictionary *) couplet atOffset:(Vector) off;
- (BOOL) processSceneString:(NSString*) item atOffset:(Vector) off;

@end


@implementation PlayerEntity (Scripting)


static NSString *CurrentScriptNameOr(NSString *alternative)
{
	if (sCurrentMissionKey != nil && ![sCurrentMissionKey hasPrefix:kActionTempPrefix])
	{
		return [NSString stringWithFormat:@"\"%@\"", sCurrentMissionKey];
	}
	return alternative;
}


OOINLINE NSString *CurrentScriptName(void)
{
	return CurrentScriptNameOr(nil);
}


OOINLINE NSString *CurrentScriptDesc(void)
{
	return CurrentScriptNameOr(@"<anonymous actions>");
}


- (NSDictionary *) missionVariables
{
	return mission_variables;
}


- (NSString *)missionVariableForKey:(NSString *)key
{
	NSString *result = nil;
	if (key != nil)  result = [mission_variables objectForKey:key];
	return result;
}


- (void)setMissionVariable:(NSString *)value forKey:(NSString *)key
{
	if (key != nil)
	{
		if (value != nil)  [mission_variables setObject:value forKey:key];
		else [mission_variables removeObjectForKey:key];
	}
}


- (NSMutableDictionary *)localVariablesForMission:(NSString *)missionKey
{
	NSMutableDictionary		*result = nil;
	
	if (missionKey == nil)  return nil;
	
	result = [localVariables objectForKey:missionKey];
	if (result == nil)
	{
		result = [NSMutableDictionary dictionary];
		[localVariables setObject:result forKey:missionKey];
	}
	
	return result;
}


- (NSString *)localVariableForKey:(NSString *)variableName andMission:(NSString *)missionKey
{
	return [[localVariables oo_dictionaryForKey:missionKey] objectForKey:variableName];
}


- (void)setLocalVariable:(NSString *)value forKey:(NSString *)variableName andMission:(NSString *)missionKey
{
	NSMutableDictionary		*locals = nil;
	
	if (variableName != nil && missionKey != nil)
	{
		locals = [self localVariablesForMission:missionKey];
		if (value != nil)
		{
			[locals setObject:value forKey:variableName];
		}
		else
		{
			[locals removeObjectForKey:variableName];
		}
	}
}


- (NSArray *) missionsList
{
	NSEnumerator			*scriptEnum = nil;
	NSString				*scriptName = nil;
	NSString				*vars = nil;
	NSMutableArray			*result = nil;
	
	result = [NSMutableArray array];
	
	for (scriptEnum = [worldScripts keyEnumerator]; (scriptName = [scriptEnum nextObject]); )
	{
		vars = [mission_variables objectForKey:scriptName];
		
		if (vars != nil)
		{
			[result addObject:[NSString stringWithFormat:@"\t%@", vars]];
		}
	}
	return result;
}


- (NSString*) replaceVariablesInString:(NSString*) args
{
	NSMutableDictionary	*locals = [self localVariablesForMission:sCurrentMissionKey];
	NSMutableString		*resultString = [NSMutableString stringWithString: args];
	NSString			*valueString;
	unsigned			i;
	NSMutableArray		*tokens = ScanTokensFromString(args);
	
	for (i = 0; i < [tokens  count]; i++)
	{
		valueString = [tokens objectAtIndex:i];
		
		if ([mission_variables objectForKey:valueString])
		{
			[resultString replaceOccurrencesOfString:valueString withString:[mission_variables objectForKey:valueString] options:NSLiteralSearch range:NSMakeRange(0, [resultString length])];
		}
		else if ([locals objectForKey:valueString])
		{
			[resultString replaceOccurrencesOfString:valueString withString:[locals objectForKey:valueString] options:NSLiteralSearch range:NSMakeRange(0, [resultString length])];
		}
		else if (([valueString hasSuffix:@"_number"])||([valueString hasSuffix:@"_bool"])||([valueString hasSuffix:@"_string"]))
		{
			SEL valueselector = NSSelectorFromString(valueString);
			if ([self respondsToSelector:valueselector])
			{
				[resultString replaceOccurrencesOfString:valueString withString:[NSString stringWithFormat:@"%@", [self performSelector:valueselector]] options:NSLiteralSearch range:NSMakeRange(0, [resultString length])];
			}
		}
		else if ([valueString hasPrefix:@"["]&&[valueString hasSuffix:@"]"])
		{
			NSString* replaceString = ExpandDescriptionForCurrentSystem(valueString);
			[resultString replaceOccurrencesOfString:valueString withString:replaceString options:NSLiteralSearch range:NSMakeRange(0, [resultString length])];
		}
	}
	
	OOLog(kOOLogDebugReplaceVariablesInString, @"EXPANSION: \"%@\" becomes \"%@\"", args, resultString);
	
	return [NSString stringWithString: resultString];
}

/*-----------------------------------------------------*/


- (void) setMissionDescription:(NSString *)textKey
{
	[self setMissionDescription:textKey forMission:sCurrentMissionKey];
}


- (void) setMissionDescription:(NSString *)textKey forMission:(NSString *)key
{
	NSString		*text = [[UNIVERSE missiontext] oo_stringForKey:textKey];
	
	if (!text)
	{
		OOLogERR(kOOLogScriptMissionDescNoText, @"in %@, no mission text set for key '%@' [UNIVERSE missiontext] is:\n%@ ", CurrentScriptDesc(), textKey, [UNIVERSE missiontext]);
		return;
	}
	
	[self setMissionInstructions:text forMission:key];
}


// implementation of mission.setInstructions(), also final part of legacy setMissionDescription
- (void) setMissionInstructions:(NSString *)text forMission:(NSString *)key
{
	if (!key)
	{
		OOLogERR(kOOLogScriptMissionDescNoKey, @"in %@, mission key not set", CurrentScriptDesc());
		return;
	}

	text = ExpandDescriptionForCurrentSystem(text);
	text = [self replaceVariablesInString: text];

	[mission_variables setObject:text forKey:key];
}


- (void) clearMissionDescription
{
	[self clearMissionDescriptionForMission:sCurrentMissionKey];
}


- (void) clearMissionDescriptionForMission:(NSString *)key
{
	if (!key)
	{
		OOLogERR(kOOLogScriptMissionDescNoKey, @"in %@, mission key not set", CurrentScriptDesc());
		return;
	}
	
	if (![mission_variables objectForKey:key]) return;
	
	[mission_variables removeObjectForKey:key];
}


- (void) setLegalStatus:(NSString *)valueString
{
	legalStatus = [valueString intValue];
}


/*-----------------------------------------------------*/


- (NSString *) expandMessage:(NSString *)valueString
{
	Random_Seed very_random_seed;
	very_random_seed.a = rand() & 255;
	very_random_seed.b = rand() & 255;
	very_random_seed.c = rand() & 255;
	very_random_seed.d = rand() & 255;
	very_random_seed.e = rand() & 255;
	very_random_seed.f = rand() & 255;
	seed_RNG_only_for_planet_description(very_random_seed);
	NSString* expandedMessage = ExpandDescriptionForCurrentSystem(valueString);
	return [self replaceVariablesInString: expandedMessage];
}


- (void) commsMessage:(NSString *)valueString
{	
	[UNIVERSE addCommsMessage:[self expandMessage:valueString] forCount:4.5];
}


// Enabled on 02-May-2008 - Nikos
// This method does the same as -commsMessage, (which in fact calls), the difference being that scripts can use this
// method to have unpiloted ship entities sending comms messages.
- (void) commsMessageByUnpiloted:(NSString *)valueString
{
	[self commsMessage:valueString];
}


- (void) consoleMessage3s:(NSString *)valueString
{
	[UNIVERSE addMessage:[self expandMessage:valueString] forCount: 3];
}


- (void) consoleMessage6s:(NSString *)valueString
{
	[UNIVERSE addMessage:[self expandMessage:valueString] forCount: 6];
}


- (void) setPlanetinfo:(NSString *)key_valueString	// uses key=value format
{
	NSArray *	tokens = [key_valueString componentsSeparatedByString:@"="];
	NSString*   keyString = nil;
	NSString*	valueString = nil;

	if ([tokens count] != 2)
	{
		OOLog(kOOLogSyntaxSetPlanetInfo, @"***** SCRIPT ERROR: in %@, CANNOT setPlanetinfo: '%@' (bad parameter count)", CurrentScriptDesc(), key_valueString);
		return;
	}
	
	keyString = [[tokens objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	valueString = [[tokens objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	[UNIVERSE setSystemDataKey:keyString value:valueString];

}


- (void) setSpecificPlanetInfo:(NSString *)key_valueString  // uses galaxy#=planet#=key=value
{
	NSArray *	tokens = [key_valueString componentsSeparatedByString:@"="];
	NSString*   keyString = nil;
	NSString*	valueString = nil;
	int gnum, pnum;

	if ([tokens count] != 4)
	{
		OOLog(kOOLogSyntaxSetPlanetInfo, @"***** SCRIPT ERROR: in %@, CANNOT setSpecificPlanetInfo: '%@' (bad parameter count)", CurrentScriptDesc(), key_valueString);
		return;
	}

	gnum = [tokens oo_intAtIndex:0];
	pnum = [tokens oo_intAtIndex:1];
	keyString = [[tokens objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	valueString = [[tokens objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	[UNIVERSE setSystemDataForGalaxy:gnum planet:pnum key:keyString value:valueString];
}


- (void) awardCargo:(NSString *)amount_typeString
{
	NSArray					*tokens = ScanTokensFromString(amount_typeString);
	NSString				*typeString = nil;
	OOCargoQuantityDelta	amount;
	OOCargoType				type;
	OOMassUnit				unit;
	NSArray					*commodityArray = nil;

	if ([tokens count] != 2)
	{
		OOLog(kOOLogSyntaxAwardCargo, @"***** SCRIPT ERROR: in %@, CANNOT awardCargo: '%@' (%@)", CurrentScriptDesc(), amount_typeString, @"bad parameter count");
		return;
	}
	
	typeString = [tokens objectAtIndex:1];
	type = [UNIVERSE commodityForName:typeString];
	if (type == CARGO_UNDEFINED)  type = [typeString intValue];
	
	commodityArray = [UNIVERSE commodityDataForType:type];
	
	if (commodityArray == nil)
	{
		OOLog(kOOLogSyntaxAwardCargo, @"***** SCRIPT ERROR: in %@, CANNOT awardCargo: '%@' (%@)", CurrentScriptDesc(), amount_typeString, @"unknown type");
		return;
	}
	
	amount = [tokens oo_intAtIndex:0];
	if (amount < 0)
	{
		OOLog(kOOLogSyntaxAwardCargo, @"***** SCRIPT ERROR: in %@, CANNOT awardCargo: '%@' (%@)", CurrentScriptDesc(), amount_typeString, @"negative quantity");
		return;
	}
	
	unit = [UNIVERSE unitsForCommodity:type];
	if (specialCargo && unit == UNITS_TONS)
	{
		OOLog(kOOLogSyntaxAwardCargo, @"***** SCRIPT ERROR: in %@, CANNOT awardCargo: '%@' (%@)", CurrentScriptDesc(), amount_typeString, @"cargo hold full with special cargo");
		return;
	}
	
	[self awardCargoType:type amount:amount];
}


- (void) removeAllCargo:(BOOL)forceRemoval
{
	// misnamed function. it only removes  cargo measured in TONS, g & Kg items are not removed. --Kaks 20091004 
	OOCargoType				type;
	OOMassUnit				unit;
	
	if ([self status] != STATUS_DOCKED && !forceRemoval)
	{
		OOLogWARN(kOOLogRemoveAllCargoNotDocked, @"%@removeAllCargo only works when docked.", [NSString stringWithFormat:@" in %@, ", CurrentScriptDesc()]);
		return;
	}
	
	OOLog(kOOLogNoteRemoveAllCargo, @"%@ removeAllCargo", forceRemoval ? @"Forcing" : @"Going to");
	
	NSMutableArray *manifest = [NSMutableArray arrayWithArray:shipCommodityData];
	for (type = 0; type < (OOCargoType)[manifest count]; type++)
	{
		NSMutableArray *manifest_commodity = [NSMutableArray arrayWithArray:[manifest oo_arrayAtIndex:type]];
		// manifest contains entries for all 17 commodities, whether their quantity is 0 or more.
		unit = [UNIVERSE unitsForCommodity:type]; // will return tons for unknown types
		if (unit == UNITS_TONS)
		{
			[manifest_commodity replaceObjectAtIndex:MARKET_QUANTITY withObject:[NSNumber numberWithInt:0]];
			[manifest replaceObjectAtIndex:type withObject:[NSArray arrayWithArray:manifest_commodity]];
		}
	}
	
	if (forceRemoval && [self status] != STATUS_DOCKED)
	{
		int i;
		for (i = [cargo count]-1; i >=0; i--)
		{
			OOShipEntity* canister = [cargo objectAtIndex:i];
			if (!canister) break;
			unit = [UNIVERSE unitsForCommodity:[canister commodityType]];
			if (unit == UNITS_TONS)
				[cargo removeObjectAtIndex:i];
		}
	}
	
	[shipCommodityData release];
	shipCommodityData = [manifest mutableCopy];
	
	DESTROY(specialCargo);
	
	[self calculateCurrentCargo];
}


- (void) useSpecialCargo:(NSString *)descriptionString
{
	[self removeAllCargo:YES];	
	OOLog(kOOLogNoteUseSpecialCargo, @"Going to useSpecialCargo:'%@'", descriptionString);
	specialCargo = [ExpandDescriptionForCurrentSystem(descriptionString) retain];
}


- (void) testForEquipment:(NSString *)equipString	//eg. EQ_NAVAL_ENERGY_UNIT
{
	found_equipment = [self hasEquipmentItem:equipString];
}


- (void) messageShipAIs:(NSString *)roles_message
{
	NSMutableArray*	tokens = ScanTokensFromString(roles_message);
	NSString*   roleString = nil;
	NSString*	messageString = nil;

	if ([tokens count] < 2)
	{
		OOLog(kOOLogSyntaxMessageShipAIs, @"***** SCRIPT ERROR: in %@, CANNOT messageShipAIs: '%@' (bad parameter count)", CurrentScriptDesc(), roles_message);
		return;
	}

	roleString = [tokens objectAtIndex:0];
	[tokens removeObjectAtIndex:0];
	messageString = [tokens componentsJoinedByString:@" "];

	[UNIVERSE sendShipsWithPrimaryRole:roleString messageToAI:messageString];
}


- (void) addShips:(NSString *)roles_number
{
	NSMutableArray*	tokens = ScanTokensFromString(roles_number);
	NSString*   roleString = nil;
	NSString*	numberString = nil;
	
	if ([tokens count] != 2)
	{
		OOLog(kOOLogSyntaxAddShips, @"***** SCRIPT ERROR: in %@, CANNOT addShips: '%@' (expected <role> <count>)", CurrentScriptDesc(), roles_number);
		return;
	}
	
	roleString = [tokens objectAtIndex:0];
	numberString = [tokens objectAtIndex:1];
	
	int number = [numberString intValue];
	if (number < 0)
	{
		OOLog(kOOLogSyntaxAddShips, @"***** SCRIPT ERROR: in %@, can't add %i ships -- that's less than zero, y'know..", CurrentScriptDesc(), number);
		return;
	}
	
	OOLog(kOOLogNoteAddShips, @"DEBUG: Going to add %d ships with role '%@'", number, roleString);
	
	while (number--)
		[UNIVERSE witchspaceShipWithPrimaryRole:roleString];
}


- (void) addSystemShips:(NSString *)roles_number_position
{
	NSMutableArray*	tokens = ScanTokensFromString(roles_number_position);
	NSString*   roleString = nil;
	NSString*	numberString = nil;
	NSString*	positionString = nil;

	if ([tokens count] != 3)
	{
		OOLog(kOOLogSyntaxAddShips, @"***** SCRIPT ERROR: in %@, CANNOT addSystemShips: '%@' (expected <role> <count> <position>)", CurrentScriptDesc(), roles_number_position);
		return;
	}

	roleString = [tokens objectAtIndex:0];
	numberString = [tokens objectAtIndex:1];
	positionString = [tokens objectAtIndex:2];

	int number = [numberString intValue];
	double posn = [positionString doubleValue];
	if (number < 0)
	{
		OOLog(kOOLogSyntaxAddShips, @"***** SCRIPT ERROR: in %@, can't add %i ships -- that's less than zero, y'know..", CurrentScriptDesc(), number);
		return;
	}

	OOLog(kOOLogNoteAddShips, @"DEBUG: Going to add %d ships with role '%@' at a point %.3f along route1", number, roleString, posn);

	while (number--)
		[UNIVERSE addShipWithRole:roleString nearRouteOneAt:posn];
}


- (void) addShipsAt:(NSString *)roles_number_system_x_y_z
{
	NSMutableArray*	tokens = ScanTokensFromString(roles_number_system_x_y_z);

	NSString*   roleString = nil;
	NSString*	numberString = nil;
	NSString*	systemString = nil;
	NSString*	xString = nil;
	NSString*	yString = nil;
	NSString*	zString = nil;

	if ([tokens count] != 6)
	{
		OOLog(kOOLogSyntaxAddShips, @"***** SCRIPT ERROR: in %@, CANNOT addShipsAt: '%@' (expected <role> <count> <coordinate-system> <x> <y> <z>)", CurrentScriptDesc(), roles_number_system_x_y_z);
		return;
	}

	roleString = [tokens objectAtIndex:0];
	numberString = [tokens objectAtIndex:1];
	systemString = [tokens objectAtIndex:2];
	xString = [tokens objectAtIndex:3];
	yString = [tokens objectAtIndex:4];
	zString = [tokens objectAtIndex:5];

	Vector posn = make_vector( [xString floatValue], [yString floatValue], [zString floatValue]);

	int number = [numberString intValue];
	if (number < 1)
	{
		OOLog(kOOLogSyntaxAddShips, @"----- WARNING in %@  Tried to add %i ships -- no ship added.", CurrentScriptDesc(), number);
		return;
	}

	OOLog(kOOLogNoteAddShips, @"DEBUG: Going to add %d ship(s) with role '%@' at point (%.3f, %.3f, %.3f) using system %@", number, roleString, posn.x, posn.y, posn.z, systemString);

	if (![UNIVERSE addShips: number withRole:roleString nearPosition: posn withCoordinateSystem: systemString])
	{
		OOLog(kOOLogScriptAddShipsFailed, @"***** SCRIPT ERROR: in %@, %@ could not add %u ships with role \"%@\"", CurrentScriptDesc(), @"addShipsAt:", number, roleString);
	}
}


- (void) addShipsAtPrecisely:(NSString *)roles_number_system_x_y_z
{
	NSMutableArray*	tokens = ScanTokensFromString(roles_number_system_x_y_z);

	NSString*   roleString = nil;
	NSString*	numberString = nil;
	NSString*	systemString = nil;
	NSString*	xString = nil;
	NSString*	yString = nil;
	NSString*	zString = nil;

	if ([tokens count] != 6)
	{
		OOLog(kOOLogSyntaxAddShips, @"***** SCRIPT ERROR: in %@,* CANNOT addShipsAtPrecisely: '%@' (expected <role> <count> <coordinate-system> <x> <y> <z>)", CurrentScriptDesc(), roles_number_system_x_y_z);
		return;
	}

	roleString = [tokens objectAtIndex:0];
	numberString = [tokens objectAtIndex:1];
	systemString = [tokens objectAtIndex:2];
	xString = [tokens objectAtIndex:3];
	yString = [tokens objectAtIndex:4];
	zString = [tokens objectAtIndex:5];

	Vector posn = make_vector( [xString floatValue], [yString floatValue], [zString floatValue]);

	int number = [numberString intValue];
	if (number < 1)
	{
		OOLog(kOOLogSyntaxAddShips, @"----- WARNING: in %@, Can't add %i ships -- no ship added.", CurrentScriptDesc(), number);
		return;
	}

	OOLog(kOOLogNoteAddShips, @"DEBUG: Going to add %d ship(s) with role '%@' precisely at point (%.3f, %.3f, %.3f) using system %@", number, roleString, posn.x, posn.y, posn.z, systemString);

	if (![UNIVERSE addShips: number withRole:roleString atPosition: posn withCoordinateSystem: systemString])
	{
		OOLog(kOOLogScriptAddShipsFailed, @"***** SCRIPT ERROR: in %@, %@ could not add %u ships with role '%@'", CurrentScriptDesc(), @"addShipsAtPrecisely:", number, roleString);
	}
}


- (void) addShipsWithinRadius:(NSString *)roles_number_system_x_y_z_r
{
	NSMutableArray*	tokens = ScanTokensFromString(roles_number_system_x_y_z_r);

	if ([tokens count] != 7)
	{
		OOLog(kOOLogSyntaxAddShips, @"***** SCRIPT ERROR: in %@, CANNOT 'addShipsWithinRadius: %@' (expected <role> <count> <coordinate-system> <x> <y> <z> <radius>))", CurrentScriptDesc(), roles_number_system_x_y_z_r);
		return;
	}

	NSString* roleString = [tokens objectAtIndex:0];
	int number = [[tokens objectAtIndex:1] intValue];
	NSString* systemString = [tokens objectAtIndex:2];
	GLfloat x = [[tokens objectAtIndex:3] floatValue];
	GLfloat y = [[tokens objectAtIndex:4] floatValue];
	GLfloat z = [[tokens objectAtIndex:5] floatValue];
	GLfloat r = [[tokens objectAtIndex:6] floatValue];
	Vector posn = make_vector( x, y, z);

	if (number < 1)
	{
		OOLog(kOOLogSyntaxAddShips, @"----- WARNING: in %@, can't add %i ships -- no ship added.", CurrentScriptDesc(), number);
		return;
	}

	OOLog(kOOLogNoteAddShips, @"DEBUG: Going to add %d ship(s) with role '%@' within %.2f radius about point (%.3f, %.3f, %.3f) using system %@", number, roleString, r, x, y, z, systemString);

	if (![UNIVERSE addShips:number withRole: roleString nearPosition: posn withCoordinateSystem: systemString withinRadius: r])
	{
		OOLog(kOOLogScriptAddShipsFailed, @"***** SCRIPT ERROR :in %@, %@ could not add %u ships with role \"%@\"", CurrentScriptDesc(), @"addShipsWithinRadius:", number, roleString);
	}
}


- (void) spawnShip:(NSString *)ship_key
{
	if ([UNIVERSE spawnShip:ship_key])
	{
		OOLog(kOOLogNoteAddShips, @"DEBUG: Spawned ship with shipdata key '%@'.", ship_key);
	}
	else
	{
		OOLog(kOOLogScriptAddShipsFailed, @"***** SCRIPT ERROR: in %@, could not spawn ship with shipdata key '%@'.", CurrentScriptDesc(), ship_key);
	}
}


- (void) set:(NSString *)missionvariable_value
{
	NSMutableArray		*tokens = ScanTokensFromString(missionvariable_value);
	NSString			*missionVariableString = nil;
	NSString			*valueString = nil;
	BOOL				hasMissionPrefix, hasLocalPrefix;

	if ([tokens count] < 2)
	{
		OOLog(kOOLogSyntaxSet, @"***** SCRIPT ERROR: in %@, CANNOT SET '%@' (expected mission_variable or local_variable followed by value expression)", CurrentScriptDesc(), missionvariable_value);
		return;
	}

	missionVariableString = [tokens objectAtIndex:0];
	[tokens removeObjectAtIndex:0];
	valueString = [tokens componentsJoinedByString:@" "];

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (!hasMissionPrefix && !hasLocalPrefix)
	{
		OOLog(kOOLogSyntaxSet, @"***** SCRIPT ERROR: in %@, IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'", CurrentScriptDesc(), missionVariableString);
		return;
	}

	OOLog(kOOLogNoteSet, @"DEBUG: script %@ is set to %@", missionVariableString, valueString);
	
	if (hasMissionPrefix)
	{
		[self setMissionVariable:valueString forKey:missionVariableString];
	}
	else
	{
		[self setLocalVariable:valueString forKey:missionVariableString andMission:sCurrentMissionKey];
	}
}


- (void) reset:(NSString *)missionvariable
{
	NSString*   missionVariableString = [missionvariable stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	BOOL hasMissionPrefix, hasLocalPrefix;

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (hasMissionPrefix)
	{
		[self setMissionVariable:nil forKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		[self setLocalVariable:nil forKey:missionVariableString andMission:sCurrentMissionKey];
	}
	else
	{
		OOLog(kOOLogSyntaxReset, @"***** SCRIPT ERROR: in %@, IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'", CurrentScriptDesc(), missionVariableString);
	}
}


- (void) increment:(NSString *)missionVariableString
{
	BOOL hasMissionPrefix, hasLocalPrefix;
	int value = 0;

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (hasMissionPrefix)
	{
		value = [[self missionVariableForKey:missionVariableString] intValue];
		value++;
		[self setMissionVariable:[NSString stringWithFormat:@"%d", value] forKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		value = [[self localVariableForKey:missionVariableString andMission:sCurrentMissionKey] intValue];
		value++;
		[self setLocalVariable:[NSString stringWithFormat:@"%d", value] forKey:missionVariableString andMission:sCurrentMissionKey];
	}
	else
	{
		OOLog(kOOLogSyntaxIncrement, @"***** SCRIPT ERROR: in %@, IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'", CurrentScriptDesc(), missionVariableString);
	}
}


- (void) decrement:(NSString *)missionVariableString
{
	BOOL hasMissionPrefix, hasLocalPrefix;
	int value = 0;

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];
	
	if (hasMissionPrefix)
	{
		value = [[self missionVariableForKey:missionVariableString] intValue];
		value--;
		[self setMissionVariable:[NSString stringWithFormat:@"%d", value] forKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		value = [[self localVariableForKey:missionVariableString andMission:sCurrentMissionKey] intValue];
		value--;
		[self setLocalVariable:[NSString stringWithFormat:@"%d", value] forKey:missionVariableString andMission:sCurrentMissionKey];
	}
	else
	{
		OOLog(kOOLogSyntaxDecrement, @"***** SCRIPT ERROR: in %@, IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'", CurrentScriptDesc(), missionVariableString);
	}
}


- (void) add:(NSString *)missionVariableString_value
{
	NSString*   missionVariableString = nil;
	NSString*   valueString;
	double	value;
	NSMutableArray*	tokens = ScanTokensFromString(missionVariableString_value);
	BOOL hasMissionPrefix, hasLocalPrefix;

	if ([tokens count] < 2)
	{
		OOLog(kOOLogSyntaxAdd, @"***** SCRIPT ERROR: in %@, CANNOT ADD: '%@'", CurrentScriptDesc(), missionVariableString_value);
		return;
	}

	missionVariableString = [tokens objectAtIndex:0];
	[tokens removeObjectAtIndex:0];
	valueString = [tokens componentsJoinedByString:@" "];

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];

	if (hasMissionPrefix)
	{
		value = [[self missionVariableForKey:missionVariableString] doubleValue];
		value += [valueString doubleValue];
		[self setMissionVariable:[NSString stringWithFormat:@"%f", value] forKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		value = [[self localVariableForKey:missionVariableString andMission:sCurrentMissionKey] doubleValue];
		value += [valueString doubleValue];
		[self setLocalVariable:[NSString stringWithFormat:@"%f", value] forKey:missionVariableString andMission:sCurrentMissionKey];
	}
	else
	{
		OOLog(kOOLogSyntaxAdd, @"***** SCRIPT ERROR: in %@, CANNOT ADD: '%@' -- IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'", CurrentScriptDesc(), missionVariableString_value);
	}
}


- (void) subtract:(NSString *)missionVariableString_value
{
	NSString*   missionVariableString = nil;
	NSString*   valueString;
	double	value;
	NSMutableArray*	tokens = ScanTokensFromString(missionVariableString_value);
	BOOL hasMissionPrefix, hasLocalPrefix;

	if ([tokens count] < 2)
	{
		OOLog(kOOLogSyntaxSubtract, @"***** SCRIPT ERROR: in %@, CANNOT SUBTRACT: '%@'", CurrentScriptDesc(), missionVariableString_value);
		return;
	}

	missionVariableString = [tokens objectAtIndex:0];
	[tokens removeObjectAtIndex:0];
	valueString = [tokens componentsJoinedByString:@" "];

	hasMissionPrefix = [missionVariableString hasPrefix:@"mission_"];
	hasLocalPrefix = [missionVariableString hasPrefix:@"local_"];
	
	if (hasMissionPrefix)
	{
		value = [[self missionVariableForKey:missionVariableString] doubleValue];
		value -= [valueString doubleValue];
		[self setMissionVariable:[NSString stringWithFormat:@"%f", value] forKey:missionVariableString];
	}
	else if (hasLocalPrefix)
	{
		value = [[self localVariableForKey:missionVariableString andMission:sCurrentMissionKey] doubleValue];
		value -= [valueString doubleValue];
		[self setLocalVariable:[NSString stringWithFormat:@"%f", value] forKey:missionVariableString andMission:sCurrentMissionKey];
	}
	else
	{
		OOLog(kOOLogSyntaxSubtract, @"***** SCRIPT ERROR: in %@, CANNOT ADD: '%@' -- IDENTIFIER '%@' DOES NOT BEGIN WITH 'mission_' or 'local_'", CurrentScriptDesc(), missionVariableString_value);
	}
}


- (void) resetScriptTimer
{
	
}


- (void) addMissionText: (NSString *)textKey
{
	NSString			*text = nil;
	NSArray				*paras = nil;
	
	if ([textKey isEqualToString:lastTextKey])  return; // don't repeatedly add the same text
	[lastTextKey release];
	lastTextKey = [textKey copy];
	
	// Replace literal \n in strings with line breaks and perform expansions.
	text = [[UNIVERSE missiontext] oo_stringForKey:textKey];
	if (text == nil)  return;
	text = ExpandDescriptionForCurrentSystem(text);
	paras = [text componentsSeparatedByString:@"\\n"];
	text = [paras componentsJoinedByString:@"\n"];
	text = [self replaceVariablesInString:text];
	
	[self addLiteralMissionText:text];
}


- (void) addLiteralMissionText:(NSString *)text
{
	GuiDisplayGen		*gui = [UNIVERSE gui];
	NSArray				*paras = [text componentsSeparatedByString:@"\n"];
	unsigned			i, count;
	
	if (text != nil)
	{
		count = [paras count];
		for (i = 0; i < count; i++)
		{
			missionTextRow = [gui addLongText:[paras objectAtIndex:i] startingAtRow:missionTextRow align:GUI_ALIGN_LEFT];
		}
	}
}


- (void) setMissionChoices:(NSString *)choicesKey	// choicesKey is a key for a dictionary of
{													// choices/choice phrases in missiontext.plist and also..
	GuiDisplayGen* gui = [UNIVERSE gui];
	// TODO: MORE STUFF HERE
	//
	// What it does now:
	// find list of choices in missiontext.plist
	// add them to gui setting the key for each line to the key in the dict of choices
	// and the text of the line to the value in the dict of choices
	// and also set the selectable range
	// ++ change the mission screen's response to wait for a choice
	// and only if the selectable range is not present ask:
	// Press Space Commander...
	//
	NSDictionary *choices_dict = [[UNIVERSE missiontext] oo_dictionaryForKey:choicesKey];
	if ([choices_dict count] == 0)
	{
		return;
	}
	
	NSArray *choice_keys = [[choices_dict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	[gui setText:@"" forRow:21];			// clears out the 'Press spacebar' message
	[gui setKey:@"" forRow:21];				// clears the key to enable pollDemoControls to check for a selection
	[gui setSelectableRange:NSMakeRange(0,0)];	// clears the selectable range
	
	int					choices_row = 22 - [choice_keys count];
	NSEnumerator		*choiceEnum = nil;
	NSString			*choiceKey = nil;
	NSString			*choiceText = nil;
	
	for (choiceEnum = [choice_keys objectEnumerator]; (choiceKey = [choiceEnum nextObject]); )
	{
		choiceText = [NSString stringWithFormat:@" %@ ",[choices_dict objectForKey:choiceKey]];
		choiceText = ExpandDescriptionForCurrentSystem(choiceText);
		choiceText = [self replaceVariablesInString:choiceText];
		[gui setText:choiceText forRow:choices_row align: GUI_ALIGN_CENTER];
		[gui setKey:choiceKey forRow:choices_row];
		[gui setColor:[OOColor yellowColor] forRow:choices_row];
		choices_row++;
	}
	
	[gui setSelectableRange:NSMakeRange(22 - [choice_keys count], [choice_keys count])];
	[gui setSelectedRow: 22 - [choice_keys count]];
	
	[self resetMissionChoice];
}


- (void) resetMissionChoice
{
	[self setMissionChoice:nil];
}


- (void) clearMissionScreen
{
	[self setMissionOverlayDescriptor:nil];
	[self setMissionBackgroundDescriptor:nil];
	[self setMissionTitle:nil];
	[self setMissionMusic:nil];
	[self showShipModel:nil];
}


- (void) addMissionDestination:(NSString *)destinations
{
	unsigned i, j;
	int pnum, dest;
	NSMutableArray *tokens = ScanTokensFromString(destinations);
	BOOL addDestination;
	
	for (j = 0; j < [tokens count]; j++)
	{
		dest = [tokens oo_intAtIndex:j];
		if (dest < 0 || dest > 255)
			continue;
		
		addDestination = YES;
		for (i = 0; i < [missionDestinations count]; i++)
		{
			pnum = [missionDestinations oo_intAtIndex:i];
			if (pnum == dest)
			{
				addDestination = NO;
				break;
			}
		}
		
		if (addDestination == YES)
			[missionDestinations addObject:[NSNumber numberWithUnsignedInt:dest]];
	}
}


- (void) removeMissionDestination:(NSString *)destinations
{
	unsigned			i, j;
	int					pnum, dest;
	NSMutableArray		*tokens = ScanTokensFromString(destinations);
	BOOL				removeDestination;

	for (j = 0; j < [tokens count]; j++)
	{
		dest = [[tokens objectAtIndex:j] intValue];
		if (dest < 0 || dest > 255)  continue;
		
		removeDestination = NO;
		for (i = 0; i < [missionDestinations count]; i++)
		{
			pnum = [missionDestinations oo_intAtIndex:i];
			if (pnum == dest)
			{
				removeDestination = YES;
				break;
			}
		}
		
		if (removeDestination == YES)
		{
			[missionDestinations removeObjectAtIndex:i];
		}
	}
}


- (void) showShipModel:(NSString *)role
{
	if ([role isEqualToString:@"none"] || [role length] == 0)
	{
		[UNIVERSE removeDemoShips];
		return;
	}
	
	OOShipEntity *ship = [UNIVERSE makeDemoShipWithRole:role spinning:YES];
	OOLog(kOOLogNoteShowShipModel, @"::::: showShipModel:'%@' (%@) (%@)", role, ship, [ship name]);
}


- (void) setMissionMusic:(NSString *)value
{
	if ([value length] == 0 || [[value lowercaseString] isEqualToString:@"none"])
	{
		value = nil;
	}
	[[OOMusicController	sharedController] setMissionMusic:value];
}


- (void) setMissionTitle:(NSString *)value
{
	if (missionTitle != value)
	{
		[missionTitle release];
		missionTitle = [value copy];
	}
}


- (void) setMissionImage:(NSString *)value
{
	if ([value length] != 0 && ![[value lowercaseString] isEqualToString:@"none"])
 	{
		[self setMissionOverlayDescriptor:[NSDictionary dictionaryWithObject:value forKey:@"name"]];
	}
	else
	{
		[self setMissionOverlayDescriptor:nil];
	}

}


- (void) setMissionBackground:(NSString *)value
{
	if ([value length] != 0 && ![[value lowercaseString] isEqualToString:@"none"])
 	{
		[self setMissionBackgroundDescriptor:[NSDictionary dictionaryWithObject:value forKey:@"name"]];
	}
	else
	{
		[self setMissionBackgroundDescriptor:nil];
	}
}

/*-----------------------------------------------------*/


- (void) endMissionScreenAndNoteOpportunity
{
	// Older scripts might intercept missionScreenEnded first, and call secondary mission screens.
	if(![self doWorldEventUntilMissionScreen:OOJSID("missionScreenEnded")])
	{
		// if we're here, no mission screen is running. Opportunity! :)
		[self doWorldEventUntilMissionScreen:OOJSID("missionScreenOpportunity")];
	}
}


- (void) setGuiToMissionScreenWithCallback:(BOOL) callback
{
	GuiDisplayGen	*gui = [UNIVERSE gui];

	// GUI stuff
	{
		[gui clear];
		[gui setTitle: missionTitle ? missionTitle : DESC(@"mission-information")];
		
		[gui setText:DESC(@"press-space-commander") forRow:21 align:GUI_ALIGN_CENTER];
		[gui setColor:[OOColor yellowColor] forRow:21];
		[gui setKey:@"spacebar" forRow:21];
		
		[gui setSelectableRange:NSMakeRange(0,0)];
		
		[gui setForegroundTextureDescriptor:[self missionOverlayDescriptorOrDefault]];
		[gui setBackgroundTextureDescriptor:[self missionBackgroundDescriptorOrDefault]];
		
		[gui setShowTextCursor:NO];
	}
	/* ends */

	missionTextRow = 1;

	if (gui)
		gui_screen = GUI_SCREEN_MISSION;

	if (lastTextKey)
	{
		[lastTextKey release];
		lastTextKey = nil;
	}
	
	[[OOMusicController sharedController] playMissionMusic];
	
	// the following are necessary...
	[UNIVERSE setViewDirection:VIEW_GUI_DISPLAY];
	_missionWithCallback = callback;
}


- (void) setBackgroundFromDescriptionsKey:(NSString*) d_key
{
	NSArray* items = [[UNIVERSE descriptions] oo_arrayForKey:d_key];
	if (items == nil) return;
	
	[self addScene:items atOffset:kZeroVector];
	[self setShowDemoShips: YES];
}


- (void) addScene:(NSArray *)items atOffset:(Vector)off
{
	unsigned				i;
	
	if (items == nil)  return;
	
	for (i = 0; i < [items count]; i++)
	{
		id item = [items objectAtIndex:i];
		if ([item isKindOfClass:[NSString class]])
		{
			[self processSceneString:item atOffset: off];
		}
		else if ([item isKindOfClass:[NSArray class]])
		{
			[self addScene:item atOffset: off];
		}
		else if ([item isKindOfClass:[NSDictionary class]])
		{
			[self processSceneDictionary:item atOffset: off];
		}
	}
}


- (BOOL) processSceneDictionary:(NSDictionary *) couplet atOffset:(Vector) off
{
	NSArray *conditions = [couplet objectForKey:@"conditions"];
	NSArray *actions = nil;
	if ([couplet objectForKey:@"do"])
		actions = [NSArray arrayWithObject: [couplet objectForKey:@"do"]];
	NSArray *else_actions = nil;
	if ([couplet objectForKey:@"else"])
		else_actions = [NSArray arrayWithObject: [couplet objectForKey:@"else"]];
	BOOL success = YES;
	if (conditions == nil)
	{
		OOLog(@"script.scene.couplet.badConditions", @"***** SCENE ERROR: %@ - conditions not %@, returning %@.", [couplet description], @" found",@"YES and performing 'do' actions");
	}
	else
	{
		if (![conditions isKindOfClass:[NSArray class]])
		{
			OOLog(@"script.scene.couplet.badConditions", @"***** SCENE ERROR: %@ - conditions not %@, returning %@.", [conditions description], @"an array",@"NO");
			return NO;
		}
	}
	
	// perform successful actions...
	if ((success) && (actions) && [actions count])
		[self addScene: actions atOffset: off];
	
	// perform unsuccessful actions
	if ((!success) && (else_actions) && [else_actions count])
		[self addScene: else_actions atOffset: off];
	
	return success;
}


- (BOOL) processSceneString:(NSString*) item atOffset:(Vector) off
{
	Vector	model_p0;
	Quaternion	model_q;
	
	if (!item)
		return NO;
	NSArray * i_info = ScanTokensFromString(item);
	if (!i_info)
		return NO;
	NSString* i_key = [(NSString*)[i_info objectAtIndex:0] lowercaseString];

	OOLog(kOOLogNoteProcessSceneString, @"..... processing %@ (%@)", i_info, i_key);

	//
	// recursively add further scenes:
	//
	if ([i_key isEqualToString:@"scene"])
	{
		if ([i_info count] != 5)	// must be scene_key_x_y_z
			return NO;				//		   0.... 1.. 2 3 4
		NSString* scene_key = (NSString*)[i_info objectAtIndex: 1];
		Vector	scene_offset = {0};
		ScanVectorFromString([[i_info subarrayWithRange:NSMakeRange(2, 3)] componentsJoinedByString:@" "], &scene_offset);
		scene_offset.x += off.x;	scene_offset.y += off.y;	scene_offset.z += off.z;
		NSArray * scene_items = (NSArray *)[[UNIVERSE descriptions] objectForKey:scene_key];
		OOLog(kOOLogDebugProcessSceneStringAddScene, @"::::: adding scene: '%@'", scene_key);
		//
		if (scene_items)
		{
			[self addScene: scene_items atOffset: scene_offset];
			return YES;
		}
		else
			return NO;
	}
	//
	// Add ship models:
	//
	if ([i_key isEqualToString:@"ship"]||[i_key isEqualToString:@"model"]||[i_key isEqualToString:@"role"])
	{
		if ([i_info count] != 10)	// must be item_name_x_y_z_W_X_Y_Z_align
		{
			return NO;				//		   0... 1... 2 3 4 5 6 7 8 9....
		}
		
		OOShipEntity* ship = nil;
		
		if ([i_key isEqualToString:@"ship"]||[i_key isEqualToString:@"model"])
		{
			ship = [UNIVERSE newShipWithName:[i_info oo_stringAtIndex: 1]];
		}
		else if ([i_key isEqualToString:@"role"])
		{
			ship = [UNIVERSE newShipWithRole:[i_info oo_stringAtIndex: 1]];
		}
		if (!ship)
			return NO;

		ScanVectorAndQuaternionFromString([[i_info subarrayWithRange:NSMakeRange(2, 7)] componentsJoinedByString:@" "], &model_p0, &model_q);
		
		Vector	model_offset = positionOffsetForShipInRotationToAlignment(ship, model_q, [i_info oo_stringAtIndex:9]);
		model_p0 = vector_add(model_p0, vector_subtract(off, model_offset));

		OOLog(kOOLogDebugProcessSceneStringAddModel, @"::::: adding model to scene:'%@'", ship);
		[ship setOrientation: model_q];
		[ship setPosition: model_p0];
		[UNIVERSE setMainLightPosition:(Vector){ DEMO_LIGHT_POSITION }]; // set light origin
		[ship setScanClass: CLASS_NO_DRAW];
		[ship switchAITo: @"nullAI.plist"];
		[UNIVERSE addEntity: ship];	// STATUS_IN_FLIGHT, AI state GLOBAL
		[ship setStatus: STATUS_COCKPIT_DISPLAY];
		[ship setRoll: 0.0];
		[ship setPitch: 0.0];
		[ship setVelocity: kZeroVector];
		[ship setBehaviour: BEHAVIOUR_STOP_STILL];

		[ship release];
		return YES;
	}
	//
	// Add player ship model:
	//
	if ([i_key isEqualToString:@"player"])
	{
		if ([i_info count] != 9)	// must be player_x_y_z_W_X_Y_Z_align
			return NO;				//		   0..... 1 2 3 4 5 6 7 8....

		OOShipEntity* doppelganger = [UNIVERSE newShipWithName:[self shipDataKey]];   // retain count = 1
		if (!doppelganger)
			return NO;
		
		ScanVectorAndQuaternionFromString([[i_info subarrayWithRange:NSMakeRange( 1, 7)] componentsJoinedByString:@" "], &model_p0, &model_q);
		
		Vector	model_offset = positionOffsetForShipInRotationToAlignment( doppelganger, model_q, (NSString*)[i_info objectAtIndex:8]);
		model_p0.x += off.x - model_offset.x;
		model_p0.y += off.y - model_offset.y;
		model_p0.z += off.z - model_offset.z;

		OOLog(kOOLogDebugProcessSceneStringAddModel, @"::::: adding model to scene:'%@'", doppelganger);
		[doppelganger setOrientation: model_q];
		[doppelganger setPosition: model_p0];
		[UNIVERSE setMainLightPosition:(Vector){ DEMO_LIGHT_POSITION }]; // set light origin
		[doppelganger setScanClass: CLASS_NO_DRAW];
		[doppelganger switchAITo: @"nullAI.plist"];
		[UNIVERSE addEntity: doppelganger];
		[doppelganger setStatus: STATUS_COCKPIT_DISPLAY];
		[doppelganger setRoll: 0.0];
		[doppelganger setPitch: 0.0];
		[doppelganger setVelocity: kZeroVector];
		[doppelganger setBehaviour: BEHAVIOUR_STOP_STILL];

		[doppelganger release];
		return YES;
	}
	//
	// Add  planet model: selected via gui-scene-show-planet/-local-planet
	//
	if ([i_key isEqualToString:@"local-planet"] || [i_key isEqualToString:@"target-planet"])
	{
		if ([i_info count] != 4)	// must be xxxxx-planet_x_y_z
			return NO;				//		   0........... 1 2 3
		
#if NEW_PLANETS
		OOPlanetEntity *originalPlanet = nil;
		if ([i_key isEqualToString:@"local-planet"])
		{
			originalPlanet = [UNIVERSE planet];
		}
		else
		{
			originalPlanet = [[[OOPlanetEntity alloc] initAsMainPlanetForSystemSeed:target_system_seed] autorelease];
		}
		OOPlanetEntity *doppelganger = [originalPlanet miniatureVersion];
		if (doppelganger == nil)  return NO;

#else
		OOPlanetEntity* doppelganger = nil;
		NSMutableDictionary *planetInfo = [NSMutableDictionary dictionaryWithDictionary:[UNIVERSE generateSystemData:target_system_seed]];

#if 1
		// sunlight position for F7 screen is chosen pseudo randomly from  4 different positions.
		if (target_system_seed.b & 8)
		{
			_sysInfoLight = (target_system_seed.b & 2) ? (Vector){ -10000.0, 4000.0, -10000.0 } : (Vector){ -12000.0, -5000.0, -10000.0 };
		}
		else
		{
			_sysInfoLight = (target_system_seed.d & 2) ? (Vector){ 6000.0, -5000.0, -10000.0 } : (Vector){ 6000.0, 4000.0, -10000.0 };
		}
#else
		// basic sunlight position for F7 screen.
		_sysInfoLight = (Vector){ -12000.0, -5000.0, -10000.0 };
#endif

		[UNIVERSE setMainLightPosition:_sysInfoLight]; // set light origin
		
		if ([i_key isEqualToString:@"local-planet"] && [UNIVERSE sun])
		{
			OOPlanetEntity *mainPlanet = [UNIVERSE planet];
			OOLegacyTexture *texture = [mainPlanet texture];
			if (texture != nil)
			{
				[planetInfo setObject:texture forKey:@"_oo_textureObject"];
				[planetInfo oo_setBool:[mainPlanet isExplicitlyTextured] forKey:@"_oo_isExplicitlyTextured"];
				[planetInfo oo_setBool:YES forKey:@"mainForLocalSystem"];
				//[planetInfo oo_setQuaternion:[mainPlanet orientation] forKey:@"orientation"]; // the orientation is overwritten later on, without regard for the real planet's orientation.
			}
		}
		
		doppelganger = [[OOPlanetEntity alloc] initFromDictionary:planetInfo withAtmosphere:YES andSeed:target_system_seed];
		[doppelganger miniaturize];
		[doppelganger autorelease];
		
		if (doppelganger == nil)  return NO;
#endif
		
		ScanVectorFromString([[i_info subarrayWithRange:NSMakeRange(1, 3)] componentsJoinedByString:@" "], &model_p0);
		
		// miniature radii are roughly between 60 and 120. Place miniatures with a radius bigger than 60 a bit futher away.
		model_p0 = vector_multiply_scalar(model_p0, 1 - 0.5 * ((60 - [doppelganger radius]) / 60));
		
		model_p0 = vector_add(model_p0, off);
		
#if NEW_PLANETS
		Quaternion model_q = { 0.912871, 0.365148, 0.182574, 0.0 }; // pole at top right for new planets.
#else
		// Only one quaternion needed.
		//model_q = make_quaternion( M_SQRT1_2, 0.314, M_SQRT1_2, 0.0 );
		Quaternion model_q = { 0.833492, 0.333396, 0.440611, 0.0 }; // TODO: find a better quaternion value.
#endif
		OOLog(kOOLogDebugProcessSceneStringAddMiniPlanet, @"::::: adding %@ to scene:'%@'", i_key, doppelganger);
		[doppelganger setOrientation: model_q];
		[doppelganger setPosition: model_p0];
		/* MKW - add rotation based on current time 
		 *     - necessary to duplicate the rotation already performed in PlanetEntity.m since we reset the orientation above. */
		int		deltaT = floor(fmod([self clockTimeAdjusted], 86400));
		[doppelganger update: deltaT];
		[UNIVERSE addEntity:doppelganger];
		
		return YES;
	}
	
	return NO;
}


- (BOOL) addEqScriptForKey:(NSString *)eq_key
{
	if (eq_key == nil) return NO;
	
	NSString			*key = nil;
	NSString			*scriptName = [[OOEquipmentType equipmentTypeWithIdentifier:eq_key] scriptName];
	
	OOLog(@"player.equipmentScript", @"Added equipment %@, with the following script property: '%@'.", eq_key, scriptName);

	if (scriptName == nil) return NO;
	
	NSMutableDictionary	*properties = [NSMutableDictionary dictionary];
	unsigned			i, c = [eqScripts count];
	
	// no duplicates!
	for (i = 0; i < c; i++)
	{
		key = [[eqScripts oo_arrayAtIndex:i] oo_stringAtIndex:0];
		if ([key isEqualToString: eq_key]) return NO;
	}
	
	[properties setObject:self forKey:@"ship"];
	[properties setObject:eq_key forKey:@"equipmentKey"];
	OOScript *s = [OOScript jsScriptFromFileNamed:scriptName properties:properties];
	
	OOLog(@"player.equipmentScript", @"Script '%@': installation %@successful.", scriptName,(s == nil ? @"un" : @""));

	if (s == nil) return NO;
	[s retain];
	[eqScripts addObject:[NSArray arrayWithObjects:eq_key,s,nil]];
	if (primedEquipment == [eqScripts count] - 1) primedEquipment++;	// if primed-none, keep it as primed-none.
	OOLog(@"player.equipmentScript", @"Scriptable equipment available: %u.",[eqScripts count]);
	return YES;
}


- (void) removeEqScriptForKey:(NSString *)eq_key
{
	if (eq_key == nil) return;
	
	NSString			*key = nil;
	unsigned			i, c = [eqScripts count];
	
	for (i = 0; i < c; i++)
	{
		key = [[eqScripts oo_arrayAtIndex:i] oo_stringAtIndex:0];
		if ([key isEqualToString: eq_key]) 
		{
			OOScript *s =[[eqScripts oo_arrayAtIndex:i] objectAtIndex:1];
			[eqScripts removeObjectAtIndex:i];
			DESTROY(s);
			if (i == primedEquipment) primedEquipment = c;	// primed-none
			else if (i < primedEquipment) primedEquipment--; // track the primed equipment
			if (c == primedEquipment) primedEquipment--; // the array has shrunk by one!

			OOLog(@"player.equipmentScript", @"Removed equipment %@, with the following script property: '%@'.", eq_key, [[OOEquipmentType equipmentTypeWithIdentifier:eq_key] scriptName]);
		}
	}
}


- (unsigned) getEqScriptIndexForKey:(NSString *)eq_key
{
	unsigned			i, c = [eqScripts count];
	
	if (eq_key == nil) return c;
	
	NSString			*key = nil;
	
	for (i = 0; i < c; i++)
	{
		key = [[eqScripts oo_arrayAtIndex:i] oo_stringAtIndex:0];
		if ([key isEqualToString: eq_key]) return i;
	}
	
	return c;
}


- (void) targetNearestIncomingMissile
{
	[self scanForNearestIncomingMissile];
	OOEntity *foundTarget = [self foundTarget];
	if (foundTarget != nil)
	{
		ident_engaged = YES;
		missile_status = MISSILE_STATUS_TARGET_LOCKED;
		[self addTarget:foundTarget];
	}
}


- (void) setGalacticHyperspaceBehaviourTo:(NSString *)galacticHyperspaceBehaviourString
{
	OOGalacticHyperspaceBehaviour ghBehaviour = OOGalacticHyperspaceBehaviourFromString(galacticHyperspaceBehaviourString);
	if (ghBehaviour == GALACTIC_HYPERSPACE_BEHAVIOUR_UNKNOWN)
	{
		OOLog(@"player.setGalacticHyperspaceBehaviour.invalidInput",
			  @"setGalacticHyperspaceBehaviourTo: called with unknown behaviour %@.", galacticHyperspaceBehaviourString);
	}
	[self setGalacticHyperspaceBehaviour:ghBehaviour];
}


- (void) setGalacticHyperspaceFixedCoordsTo:(NSString *)galacticHyperspaceFixedCoordsString
{	
	NSArray *coord_vals = ScanTokensFromString(galacticHyperspaceFixedCoordsString);
	if ([coord_vals count] < 2)	// Will be 0 if string is nil
	{
		OOLog(@"player.setGalacticHyperspaceFixedCoords.invalidInput",
			  @"setGalacticHyperspaceFixedCoords: called with bad specifier. Defaulting to Oolite standard.");
		galacticHyperspaceFixedCoords.x = galacticHyperspaceFixedCoords.y = 0x60;
	}
	
	[self setGalacticHyperspaceFixedCoordsX:[coord_vals oo_unsignedCharAtIndex:0]
										  y:[coord_vals oo_unsignedCharAtIndex:1]];
}

@end


NSString *OOComparisonTypeToString(OOComparisonType type)
{
	switch (type)
	{
		case COMPARISON_EQUAL:			return @"equal";
		case COMPARISON_NOTEQUAL:		return @"notequal";
		case COMPARISON_LESSTHAN:		return @"lessthan";
		case COMPARISON_GREATERTHAN:	return @"greaterthan";
		case COMPARISON_ONEOF:			return @"oneof";
		case COMPARISON_UNDEFINED:		return @"undefined";
	}
	return @"<error: invalid comparison type>";
}
