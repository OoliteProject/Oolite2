/*

PlayerEntity+Serialization.m


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

#import "PlayerEntity+Serialization.h"
#import "PlayerEntityLegacyScriptEngine.h"
#import "PlayerEntityLoadSave.h"
#import "OOVersion.h"
#import "OOStringParsing.h"

#import "Universe.h"
#import "StationEntity.h"
#import "MyOpenGLView.h"
#import "OOShipRegistry.h"
#import "OOEquipmentType.h"


@implementation PlayerEntity (Serialization)

- (NSDictionary *) legacyCommanderDataDictionary
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	[result setObject:OoliteVersion() forKey:@"written_by_version"];

	NSString *gal_seed = [NSString stringWithFormat:@"%d %d %d %d %d %d", galaxy_seed.a, galaxy_seed.b, galaxy_seed.c, galaxy_seed.d, galaxy_seed.e, galaxy_seed.f];
	NSString *gal_coords = [NSString stringWithFormat:@"%d %d",(int)galaxy_coordinates.x,(int)galaxy_coordinates.y];
	NSString *tgt_coords = [NSString stringWithFormat:@"%d %d",(int)cursor_coordinates.x,(int)cursor_coordinates.y];

	[result setObject:gal_seed		forKey:@"galaxy_seed"];
	[result setObject:gal_coords	forKey:@"galaxy_coordinates"];
	[result setObject:tgt_coords	forKey:@"target_coordinates"];
	
	if (!equal_seeds(found_system_seed,kNilRandomSeed))
	{
		NSString *found_seed = [NSString stringWithFormat:@"%d %d %d %d %d %d", found_system_seed.a, found_system_seed.b, found_system_seed.c, found_system_seed.d, found_system_seed.e, found_system_seed.f];
		[result setObject:found_seed	forKey:@"found_system_seed"];
	}
	
	// Write the name of the current system. Useful for looking up saved game information and for overlapping systems.
	[result setObject:[UNIVERSE getSystemName:[self system_seed]] forKey:@"current_system_name"];
	// Write the name of the targeted system. Useful for overlapping systems.
	[result setObject:[UNIVERSE getSystemName:[self target_system_seed]] forKey:@"target_system_name"];
	
	[result setObject:player_name		forKey:@"player_name"];
	
	/*
		BUG: GNUstep truncates integer values to 32 bits when loading XML plists.
		Workaround: store credits as a double. 53 bits of precision ought to
		be good enough for anybody. Besides, we display credits with double
		precision anyway.
		-- Ahruman 2011-02-15
	*/
	[result oo_setFloat:credits				forKey:@"credits"];
	[result oo_setUnsignedInteger:fuel		forKey:@"fuel"];
	[result oo_setFloat:fuel_charge_rate	forKey:@"fuel_charge_rate"]; // ## fuel charge testing
	
	[result oo_setInteger:galaxy_number	forKey:@"galaxy_number"];
	
	[result oo_setBool:[self weaponsOnline]	forKey:@"weapons_online"];
	
	[result oo_setInteger:forward_weapon_type	forKey:@"forward_weapon"];
	[result oo_setInteger:aft_weapon_type		forKey:@"aft_weapon"];
	[result oo_setInteger:port_weapon_type		forKey:@"port_weapon"];
	[result oo_setInteger:starboard_weapon_type	forKey:@"starboard_weapon"];
	[result setObject:[self serializeShipSubEntities] forKey:@"subentities_status"];
	
	[result oo_setInteger:max_cargo + 5 * max_passengers	forKey:@"max_cargo"];
	
	[result setObject:shipCommodityData		forKey:@"shipCommodityData"];
	
	// sanitise commodity units - the savegame might contain the wrong units
	NSMutableArray* manifest = [NSMutableArray arrayWithArray:shipCommodityData];
	int 	i=0;
	for (i = [manifest count] - 1; i >= 0 ; i--)
	{
		NSMutableArray*	commodityInfo = [NSMutableArray arrayWithArray:(NSArray *)[manifest objectAtIndex:i]];
		// manifest contains entries for all 17 commodities, whether their quantity is 0 or more.
		[commodityInfo replaceObjectAtIndex:MARKET_UNITS withObject:[NSNumber numberWithInt:[UNIVERSE unitsForCommodity:i]]];
		[manifest replaceObjectAtIndex:i withObject:[NSArray arrayWithArray:commodityInfo]];
	}
	[shipCommodityData release];
	shipCommodityData = [[NSArray arrayWithArray:manifest] retain];
	
	// Deprecated equipment flags. New equipment shouldn't be added here (it'll be handled by the extra_equipment dictionary).
	[result oo_setBool:[self hasDockingComputer]		forKey:@"has_docking_computer"];
	[result oo_setBool:[self hasGalacticHyperdrive]	forKey:@"has_galactic_hyperdrive"];
	[result oo_setBool:[self hasEscapePod]				forKey:@"has_escape_pod"];
	[result oo_setBool:[self hasECM]					forKey:@"has_ecm"];
	[result oo_setBool:[self hasScoop]					forKey:@"has_scoop"];
	[result oo_setBool:[self hasFuelInjection]			forKey:@"has_fuel_injection"];
	
	if ([self hasEquipmentItem:@"EQ_NAVAL_ENERGY_UNIT"])
	{
		[result oo_setBool:YES forKey:@"has_energy_unit"];
		[result oo_setInteger:OLD_ENERGY_UNIT_NAVAL forKey:@"energy_unit"];
	}
	else if ([self hasEquipmentItem:@"EQ_ENERGY_UNIT"])
	{
		[result oo_setBool:YES forKey:@"has_energy_unit"];
		[result oo_setInteger:OLD_ENERGY_UNIT_NORMAL forKey:@"energy_unit"];
	}
	
	NSMutableArray* missileRoles = [NSMutableArray arrayWithCapacity:max_missiles];
	
	for (i = 0; i < (int)max_missiles; i++)
	{
		if (missile_entity[i])
		{
			[missileRoles addObject:[missile_entity[i] primaryRole]];
		}
		else
		{
			[missileRoles addObject:@"NONE"];
		}
	}
	[result setObject:missileRoles forKey:@"missile_roles"];
	
	[result oo_setInteger:missiles forKey:@"missiles"];
	
	[result oo_setInteger:legalStatus forKey:@"legal_status"];
	[result oo_setInteger:market_rnd forKey:@"market_rnd"];
	[result oo_setInteger:ship_kills forKey:@"ship_kills"];
	
	// ship depreciation
	[result oo_setInteger:ship_trade_in_factor forKey:@"ship_trade_in_factor"];
	
	// mission variables
	if (mission_variables != nil)
	{
		[result setObject:[NSDictionary dictionaryWithDictionary:mission_variables] forKey:@"mission_variables"];
	}
	
	// communications log
	NSArray *log = [self commLog];
	if (log != nil)  [result setObject:log forKey:@"comm_log"];
	
	[result oo_setUnsignedInteger:entity_personality forKey:@"entity_personality"];
	
	// extra equipment flags
	NSMutableDictionary	*equipment = [NSMutableDictionary dictionary];
	NSEnumerator		*eqEnum = nil;
	NSString			*eqDesc = nil;
	for (eqEnum = [self equipmentEnumerator]; (eqDesc = [eqEnum nextObject]); )
	{
		[equipment oo_setBool:YES forKey:eqDesc];
	}
	if ([equipment count] != 0)
	{
		[result setObject:equipment forKey:@"extra_equipment"];
	}
	if (primedEquipment < [eqScripts count]) [result setObject:[[eqScripts oo_arrayAtIndex:primedEquipment] oo_stringAtIndex:0] forKey:@"primed_equipment"];
	
	// reputation
	[result setObject:reputation forKey:@"reputation"];
	
	// passengers
	[result oo_setInteger:max_passengers forKey:@"max_passengers"];
	[result setObject:passengers forKey:@"passengers"];
	[result setObject:passenger_record forKey:@"passenger_record"];
	
	//specialCargo
	if (specialCargo)  [result setObject:specialCargo forKey:@"special_cargo"];
	
	// contracts
	[result setObject:contracts forKey:@"contracts"];
	[result setObject:contract_record forKey:@"contract_record"];
	
	[result setObject:missionDestinations forKey:@"missionDestinations"];
	
	//shipyard
	[result setObject:shipyard_record forKey:@"shipyard_record"];
	
	//ship's clock
	[result setObject:[NSNumber numberWithDouble:ship_clock] forKey:@"ship_clock"];
	
	//speech
	[result setObject:[NSNumber numberWithBool:isSpeechOn] forKey:@"speech_on"];
#if OOLITE_ESPEAK
	[result setObject:[UNIVERSE voiceName:voice_no] forKey:@"speech_voice"];
	[result setObject:[NSNumber numberWithBool:voice_gender_m] forKey:@"speech_gender"];
#endif
	
	//base ship description
	[result setObject:[self shipDataKey] forKey:@"ship_desc"];
	[result setObject:[[self shipInfoDictionary] oo_stringForKey:KEY_NAME] forKey:@"ship_name"];
	
	//custom view no.
	[result oo_setUnsignedInteger:_customViewIndex forKey:@"custom_view_index"];

	//local market
	if ([dockedStation localMarket])  [result setObject:[dockedStation localMarket] forKey:@"localMarket"];
	
	// persistant UNIVERSE information
	if ([UNIVERSE localPlanetInfoOverrides])
	{
		[result setObject:[UNIVERSE localPlanetInfoOverrides] forKey:@"local_planetinfo_overrides"];
	}
	
	// trumble information
	[result setObject:[self trumbleValue] forKey:@"trumbles"];
	
	// wormhole information
	NSMutableArray * wormholeDicts = [NSMutableArray arrayWithCapacity:[scannedWormholes count]];
	NSEnumerator * wormholes = [scannedWormholes objectEnumerator];
	WormholeEntity * wh;
	while ((wh = (WormholeEntity*)[wormholes nextObject]))
	{
		[wormholeDicts addObject:[wh getDict]];
	}
	[result setObject:wormholeDicts forKey:@"wormholes"];

	// create checksum
	clear_checksum();
	munge_checksum(galaxy_seed.a);	munge_checksum(galaxy_seed.b);	munge_checksum(galaxy_seed.c);
	munge_checksum(galaxy_seed.d);	munge_checksum(galaxy_seed.e);	munge_checksum(galaxy_seed.f);
	munge_checksum((int)galaxy_coordinates.x);	munge_checksum((int)galaxy_coordinates.y);
	munge_checksum((int)credits);		munge_checksum(fuel);
	munge_checksum(max_cargo);		munge_checksum(missiles);
	munge_checksum(legalStatus);	munge_checksum(market_rnd);		munge_checksum(ship_kills);
	
	if (mission_variables != nil)
		munge_checksum([[mission_variables description] length]);
	if (equipment != nil)
		munge_checksum([[equipment description] length]);
	
	int final_checksum = munge_checksum([[self shipDataKey] length]);

	//set checksum
	[result oo_setInteger:final_checksum forKey:@"checksum"];
	
	return result;
}


- (BOOL) setCommanderDataFromLegacyDictionary:(NSDictionary *)dict
{
	unsigned i;
	
	[[UNIVERSE gameView] resetTypedString];

	// Required keys
	if ([dict oo_stringForKey:@"ship_desc"] == nil)  return NO;
	if ([dict oo_stringForKey:@"galaxy_seed"] == nil)  return NO;
	if ([dict oo_stringForKey:@"galaxy_coordinates"] == nil)  return NO;
	
	// BOOL strict = [dict oo_boolForKey:@"strict" defaultValue:NO];
	// FIXME: when upgrading is implemented, warn about strict mode not being supported.
	
	//base ship description
	NSString *shipKey = [dict oo_stringForKey:@"ship_desc"];
	OOShipClass *shipClass = [[OOShipRegistry sharedRegistry] shipClassForKey:shipKey];
	NSDictionary *shipInfo = [[OOShipRegistry sharedRegistry] shipInfoForKey:shipKey];
	if (shipInfo == nil)  return NO;
	if (![self setUpShipWithShipClass:shipClass andDictionary:shipInfo])  return NO;
	
	// ship depreciation
	ship_trade_in_factor = [dict oo_intForKey:@"ship_trade_in_factor" defaultValue:95];
	
	galaxy_seed = RandomSeedFromString([dict oo_stringForKey:@"galaxy_seed"]);
	if (is_nil_seed(galaxy_seed))  return NO;
	[UNIVERSE setGalaxySeed: galaxy_seed andReinit:YES];
	
	NSArray *coord_vals = ScanTokensFromString([dict oo_stringForKey:@"galaxy_coordinates"]);
	galaxy_coordinates.x = [coord_vals oo_unsignedCharAtIndex:0];
	galaxy_coordinates.y = [coord_vals oo_unsignedCharAtIndex:1];
	cursor_coordinates = galaxy_coordinates;
	
	NSString *keyStringValue = [dict oo_stringForKey:@"target_coordinates"];
	if (keyStringValue != nil)
	{
		coord_vals = ScanTokensFromString(keyStringValue);
		cursor_coordinates.x = [coord_vals oo_unsignedCharAtIndex:0];
		cursor_coordinates.y = [coord_vals oo_unsignedCharAtIndex:1];
	}
	
	keyStringValue = [dict oo_stringForKey:@"found_system_seed"];
	found_system_seed = (keyStringValue != nil) ? RandomSeedFromString(keyStringValue) : kNilRandomSeed;
	
	[player_name release];
	player_name = [[dict oo_stringForKey:@"player_name" defaultValue:PLAYER_DEFAULT_NAME] copy];
	
	[shipCommodityData autorelease];
	shipCommodityData = [[dict oo_arrayForKey:@"shipCommodityData" defaultValue:shipCommodityData] copy];
	
	// extra equipment flags
	[self removeAllEquipment];
	NSMutableDictionary *equipment = [NSMutableDictionary dictionaryWithDictionary:[dict oo_dictionaryForKey:@"extra_equipment"]];
	
	// Equipment flags	(deprecated in favour of equipment dictionary, keep for compatibility)
	if ([dict oo_boolForKey:@"has_docking_computer"])		[equipment oo_setBool:YES forKey:@"EQ_DOCK_COMP"];
	if ([dict oo_boolForKey:@"has_galactic_hyperdrive"])	[equipment oo_setBool:YES forKey:@"EQ_GAL_DRIVE"];
	if ([dict oo_boolForKey:@"has_escape_pod"])				[equipment oo_setBool:YES forKey:@"EQ_ESCAPE_POD"];
	if ([dict oo_boolForKey:@"has_ecm"])					[equipment oo_setBool:YES forKey:@"EQ_ECM"];
	if ([dict oo_boolForKey:@"has_scoop"])					[equipment oo_setBool:YES forKey:@"EQ_FUEL_SCOOPS"];
	if ([dict oo_boolForKey:@"has_fuel_injection"])			[equipment oo_setBool:YES forKey:@"EQ_FUEL_INJECTION"];
	
	// Legacy energy unit type -> energy unit equipment item
	if ([dict oo_boolForKey:@"has_energy_unit"] && [self installedEnergyUnitType] == ENERGY_UNIT_NONE)
	{
		OOEnergyUnitType eType = [dict oo_intForKey:@"energy_unit" defaultValue:ENERGY_UNIT_NORMAL];
		switch (eType)
		{
			// look for NEU first!
			case OLD_ENERGY_UNIT_NAVAL:
				[equipment oo_setBool:YES forKey:@"EQ_NAVAL_ENERGY_UNIT"];
				break;
			
			case OLD_ENERGY_UNIT_NORMAL:
				[equipment oo_setBool:YES forKey:@"EQ_ENERGY_UNIT"];
				break;

			default:
				break;
		}
	}
	
	eqScripts = [[NSMutableArray alloc] init];
	[self addEquipmentFromCollection:equipment];
	primedEquipment = [self getEqScriptIndexForKey:[dict oo_stringForKey:@"primed_equipment"]];	// if key not found primedEquipment is set to primed-none

	if ([self hasEquipmentItem:@"EQ_ADVANCED_COMPASS"])  compassMode = COMPASS_MODE_PLANET;
	else  compassMode = COMPASS_MODE_BASIC;
	compassTarget = nil;
	
	// speech
	isSpeechOn = [dict oo_boolForKey:@"speech_on"];
#if OOLITE_ESPEAK
	voice_gender_m = [dict oo_boolForKey:@"speech_gender" defaultValue:YES];
	voice_no = [UNIVERSE setVoice:[UNIVERSE voiceNumber:[dict oo_stringForKey:@"speech_voice" defaultValue:nil]] withGenderM:voice_gender_m];
#endif
	
	// reputation
	[reputation release];
	reputation = [[dict oo_dictionaryForKey:@"reputation"] mutableCopy];
	if (reputation == nil)  reputation = [[NSMutableDictionary alloc] init];

	// passengers
	max_passengers = [dict oo_intForKey:@"max_passengers"];
	[passengers release];
	passengers = [[dict oo_arrayForKey:@"passengers"] mutableCopy];
	if (passengers == nil)  passengers = [[NSMutableArray alloc] init];
	[passenger_record release];
	passenger_record = [[dict oo_dictionaryForKey:@"passenger_record"] mutableCopy];
	if (passenger_record == nil)  passenger_record = [[NSMutableDictionary alloc] init];
	
	//specialCargo
	[specialCargo release];
	specialCargo = [[dict oo_stringForKey:@"special_cargo"] copy];

	// contracts
	[contracts release];
	contracts = [[dict oo_arrayForKey:@"contracts"] mutableCopy];
	if (contracts == nil)  contracts = [[NSMutableArray alloc] init];
	contract_record = [[dict oo_dictionaryForKey:@"contract_record"] mutableCopy];
	if (contract_record == nil)  contract_record = [[NSMutableDictionary alloc] init];
	
	// mission destinations
	missionDestinations = [[dict oo_arrayForKey:@"missionDestinations"] mutableCopy];
	if (missionDestinations == nil)  missionDestinations = [[NSMutableArray alloc] init];

	// shipyard
	shipyard_record = [[dict oo_dictionaryForKey:@"shipyard_record"] mutableCopy];
	if (shipyard_record == nil)  shipyard_record = [[NSMutableDictionary alloc] init];

	// Normalize cargo capacity
	unsigned original_hold_size = [UNIVERSE maxCargoForShip:[self shipDataKey]];
	max_cargo = [dict oo_intForKey:@"max_cargo" defaultValue:max_cargo];
	if (max_cargo > original_hold_size)  [self addEquipmentItem:@"EQ_CARGO_BAY"];
	max_cargo = original_hold_size + ([self hasExpandedCargoBay] ? [self extraCargo] : 0) - max_passengers * 5;
	credits = OODeciCreditsFromObject([dict objectForKey:@"credits"]);
	
	fuel = [dict oo_unsignedIntForKey:@"fuel" defaultValue:fuel];
	fuel_charge_rate = [dict oo_floatForKey:@"fuel_charge_rate" defaultValue:fuel_charge_rate]; // ## fuel charge testing
	
	galaxy_number = [dict oo_intForKey:@"galaxy_number"];
	forward_weapon_type = [dict oo_intForKey:@"forward_weapon"];
	aft_weapon_type = [dict oo_intForKey:@"aft_weapon"];
	port_weapon_type = [dict oo_intForKey:@"port_weapon"];
	starboard_weapon_type = [dict oo_intForKey:@"starboard_weapon"];
	
	weapons_online = [dict oo_boolForKey:@"weapons_online" defaultValue:YES];
	
	legalStatus = [dict oo_intForKey:@"legal_status"];
	market_rnd = [dict oo_intForKey:@"market_rnd"];
	ship_kills = [dict oo_intForKey:@"ship_kills"];
	
	ship_clock = [dict oo_doubleForKey:@"ship_clock" defaultValue:PLAYER_SHIP_CLOCK_START];
	fps_check_time = ship_clock;

	// mission_variables
	[mission_variables release];
	mission_variables = [[dict oo_dictionaryForKey:@"mission_variables"] mutableCopy];
	if (mission_variables == nil)  mission_variables = [[NSMutableArray alloc] init];
	
	// persistant UNIVERSE info
	NSDictionary *planetInfoOverrides = [dict oo_dictionaryForKey:@"local_planetinfo_overrides"];
	if (planetInfoOverrides != nil)  [UNIVERSE setLocalPlanetInfoOverrides:planetInfoOverrides];
	
	// communications log
	[commLog release];
	commLog = [[NSMutableArray alloc] init];
	
	NSArray *savedCommLog = [dict oo_arrayForKey:@"comm_log"];
	unsigned commCount = [savedCommLog count];
	for (i = 0; i < commCount; i++)
	{
		[UNIVERSE addCommsMessage:[savedCommLog objectAtIndex:i] forCount:0 andShowComms:NO logOnly:YES];
	}
	
	/*	entity_personality for scripts and shaders. If undefined, we fall back
		to old behaviour of using a random value each time game is loaded (set
		up in -setUp). Saving of entity_personality was added in 1.74.
		-- Ahruman 2009-09-13
	*/
	entity_personality = [dict oo_unsignedShortForKey:@"entity_personality" defaultValue:entity_personality];
	
	// set up missiles
	[self setActiveMissile:0];
	for (i = 0; i < PLAYER_MAX_MISSILES; i++)
	{
		[missile_entity[i] release];
		missile_entity[i] = nil;
	}
	NSArray *missileRoles = [dict oo_arrayForKey:@"missile_roles"];
	if (missileRoles != nil)
	{
		for (i = 0, missiles = 0; i < [missileRoles count] && missiles < max_missiles; i++)
		{
			NSString *missile_desc = [missileRoles oo_stringAtIndex:i];
			if (missile_desc != nil && ![missile_desc isEqualToString:@"NONE"])
			{
				ShipEntity *amiss = [UNIVERSE newShipWithRole:missile_desc];
				if (amiss)
				{
					missile_list[missiles] = [OOEquipmentType equipmentTypeWithIdentifier:missile_desc];
					missile_entity[missiles] = amiss;   // retain count = 1
					missiles++;
				}
				else
				{
					OOLogWARN(@"load.failed.missileNotFound", @"couldn't find missile with role '%@' in [PlayerEntity setCommanderDataFromDictionary:], missile entry discarded.", missile_desc);
				}
			}
		}
	}
	else	// no missile_roles
	{
		for (i = 0; i < missiles; i++)
		{
			missile_list[i] = [OOEquipmentType equipmentTypeWithIdentifier:@"EQ_MISSILE"];
			missile_entity[i] = [UNIVERSE newShipWithRole:@"EQ_MISSILE"];	// retain count = 1 - should be okay as long as we keep a missile with this role
																			// in the base package.
		}
	}
	
	[self setActiveMissile:0];
	
	forward_shield = [self maxForwardShieldLevel];
	aft_shield = [self maxAftShieldLevel];
	
	// Where are we? What system are we targeting?
	// current_system_name and target_system_name, if present on the savegame,
	// are the only way - at present - to distinguish between overlapping systems. Kaks 20100706
	
	// If we have the current system name, let's see if it matches the current system.
	NSString *sysName = [dict oo_stringForKey:@"current_system_name"];
	system_seed = [UNIVERSE findSystemFromName:sysName];
	
	if (is_nil_seed(system_seed) || (galaxy_coordinates.x != system_seed.d && galaxy_coordinates.y != system_seed.b))
	{
		// no match found, find the system from the coordinates.
		system_seed = [UNIVERSE findSystemAtCoords:galaxy_coordinates withGalaxySeed:galaxy_seed];
	}
	
	// If we have a target system name, let's see if it matches the system at the cursor coordinates.
	sysName = [dict oo_stringForKey:@"target_system_name"];
	target_system_seed = [UNIVERSE findSystemFromName:sysName];
	
	if (is_nil_seed(target_system_seed) || (cursor_coordinates.x != target_system_seed.d && cursor_coordinates.y != target_system_seed.b))
	{
		// no match found, find the system from the coordinates.
		BOOL sameCoords = (cursor_coordinates.x == galaxy_coordinates.x && cursor_coordinates.y == galaxy_coordinates.y);
		if (sameCoords) target_system_seed = system_seed;
		else target_system_seed = [UNIVERSE findSystemAtCoords:cursor_coordinates withGalaxySeed:galaxy_seed];
	}
	
	// restore subentities status
	[self deserializeShipSubEntitiesFrom:[dict oo_stringForKey:@"subentities_status"]];

	// wormholes
	NSArray * whArray;
	whArray = [dict objectForKey:@"wormholes"];
	NSEnumerator * whDicts = [whArray objectEnumerator];
	NSDictionary * whCurrDict;
	[scannedWormholes release];
	scannedWormholes = [[NSMutableArray alloc] initWithCapacity:[whArray count]];
	while ((whCurrDict = [whDicts nextObject]) != nil)
	{
		WormholeEntity * wh = [[WormholeEntity alloc] initWithDict:whCurrDict];
		[scannedWormholes addObject:wh];
		/* TODO - add to Universe if the wormhole hasn't expired yet; but in this case
		 * we need to save/load position and mass as well, which we currently 
		 * don't
		if (equal_seeds([wh origin], system_seed))
		{
			[UNIVERSE addEntity:wh];
		}
		*/
	}
	
	// custom view no.
	if (_customViews != nil)
		_customViewIndex = [dict oo_unsignedIntForKey:@"custom_view_index"] % [_customViews count];

	// trumble information
	[self setUpTrumbles];
	[self setTrumbleValueFrom:[dict objectForKey:@"trumbles"]];	// if it doesn't exist we'll check user-defaults
	
	return YES;
}

@end
