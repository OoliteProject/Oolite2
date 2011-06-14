/*

OOPlayerShipEntity+LegacyScriptEngine.h

Various utility methods used for scripting.

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

#import "OOPlayerShipEntity.h"


@class OOScript;


typedef enum
{
	COMPARISON_EQUAL,
	COMPARISON_NOTEQUAL,
	COMPARISON_LESSTHAN,
	COMPARISON_GREATERTHAN,
	COMPARISON_ONEOF,
	COMPARISON_UNDEFINED
} OOComparisonType;


typedef enum
{
	OP_STRING,
	OP_NUMBER,
	OP_BOOL,
	OP_MISSION_VAR,
	OP_LOCAL_VAR,
	OP_FALSE,
	
	OP_INVALID	// Must be last.
} OOOperationType;


@interface OOPlayerShipEntity (Scripting)

- (NSDictionary*) missionVariables;

- (NSString *)missionVariableForKey:(NSString *)key;
- (void)setMissionVariable:(NSString *)value forKey:(NSString *)key;

- (NSArray *) missionsList;

- (void) setMissionDescription:(NSString *)textKey;
- (void) clearMissionDescription;
- (void) setMissionInstructions:(NSString *)text forMission:(NSString *)key;
- (void) setMissionDescription:(NSString *)textKey forMission:(NSString *)key;
- (void) clearMissionDescriptionForMission:(NSString *)key;

- (void) commsMessage:(NSString *)valueString;
- (void) commsMessageByUnpiloted:(NSString *)valueString;  // Enabled 02-May-2008 - Nikos. Same as commsMessage, but
							   // can be used by scripts to have unpiloted ships sending
							   // commsMessages, if we want to.

- (void) consoleMessage3s:(NSString *)valueString;
- (void) consoleMessage6s:(NSString *)valueString;

- (void) setLegalStatus:(NSString *)valueString;

- (void) setPlanetinfo:(NSString *)key_valueString;	// uses key=value format
- (void) setSpecificPlanetInfo:(NSString *)key_valueString;	// uses galaxy#=planet#=key=value

- (void) awardCargo:(NSString *)amount_typeString;
- (void) removeAllCargo:(BOOL)forceRemoval;

- (void) useSpecialCargo:(NSString *)descriptionString;

- (void) testForEquipment:(NSString *)equipString;  //eg. EQ_NAVAL_ENERGY_UNIT

- (void) messageShipAIs:(NSString *)roles_message;
- (void) addShips:(NSString *)roles_number;
- (void) addSystemShips:(NSString *)roles_number_position;
- (void) addShipsAt:(NSString *)roles_number_system_x_y_z;
- (void) addShipsAtPrecisely:(NSString *)roles_number_system_x_y_z;
- (void) addShipsWithinRadius:(NSString *)roles_number_system_x_y_z_r;
- (void) spawnShip:(NSString *)ship_key;
- (void) set:(NSString *)missionvariable_value;
- (void) reset:(NSString *)missionvariable;
/*
	set:missionvariable_value
	add:missionvariable_value
	subtract:missionvariable_value

	the value may be a string constant or one of the above calls
	ending in _bool, _number, or _string

	egs.
		set: mission_my_mission_status MISSION_START
		set: mission_my_mission_value 12.345
		set: mission_my_mission_clock clock_number
		add: mission_my_mission_clock 86400
		subtract: mission_my_mission_clock d100_number
*/

- (void) increment:(NSString *)missionVariableString;
- (void) decrement:(NSString *)missionVariableString;

- (void) add:(NSString *)missionVariableString_value;
- (void) subtract:(NSString *)missionVariableString_value;

- (void) addMissionText: (NSString *)textKey;
- (void) addLiteralMissionText: (NSString *)text;

- (void) setMissionChoices:(NSString *)choicesKey;	// choicesKey is a key for a dictionary of
													// choices/choice phrases in missiontext.plist and also..
- (void) resetMissionChoice;						// resets MissionChoice to nil

- (void) clearMissionScreen;

- (void) addMissionDestination:(NSString *)destinations;	// mark a system on the star charts
- (void) removeMissionDestination:(NSString *)destinations; // stop a system being marked on star charts

- (void) showShipModel: (NSString *)shipKey;
- (void) setMissionMusic: (NSString *)value;
- (void) setMissionTitle: (NSString *)value;

- (void) setGuiToMissionScreenWithCallback:(BOOL) callback;
- (void) endMissionScreenAndNoteOpportunity;
- (void) setBackgroundFromDescriptionsKey:(NSString*) d_key;

- (BOOL) addEqScriptForKey:(NSString *)eq_key;
- (void) removeEqScriptForKey:(NSString *)eq_key;
- (unsigned) getEqScriptIndexForKey:(NSString *)eq_key;

- (void) setGalacticHyperspaceBehaviourTo:(NSString *) galacticHyperspaceBehaviourString;
- (void) setGalacticHyperspaceFixedCoordsTo:(NSString *) galacticHyperspaceFixedCoordsString;

- (void) targetNearestIncomingMissile;

@end


NSString *missionTitle;

NSString *OOComparisonTypeToString(OOComparisonType type) CONST_FUNC;
