//
//  OOShipClass+Legacy.m
//  Oolite
//
//  Created by Jens Ayton on 2011-03-20.
//  Copyright 2011 the Oolite team. All rights reserved.
//

#import "OOShipClass+Legacy.h"
#import "OORoleSet.h"
#import "OOEquipmentType.h"
#import "OOColor.h"
#import "OOStringParsing.h"
#import "OOConstToString.h"


@interface OOShipClass (LegacyPrivate)

- (BOOL) priv_loadFromLegacyPList:(NSDictionary *)legacyPList
				  problemReporter:(id<OOProblemReporting>)issues;

- (void) priv_adjustLegacyWeaponStatsWithProblemReporter:(id<OOProblemReporting>)issues;

@end


//	MARK: Keys
#define kKey_likeShipKey					@"_oo_like_ship_key" //@"like_ship"
#define kKey_isTemplate						@"is_template"
#define kKey_isExternalDependency			@"is_external_dependency"
#define kKey_name							@"name"
#define kKey_displayName					@"display_name"
#define kKey_scanClass1						@"scan_class"
#define kKey_scanClass2						@"scanClass"
#define kKey_beaconCode						@"beacon"
#define kKey_isHulk							@"is_hulk"
#define kKey_HUDName						@"hud"
#define kKey_pilotKey						@"pilot"
#define kKey_unpilotedChance				@"unpiloted"
#define kKey_escapePodCount					@"has_escape_pod"
#define kKey_escapePodRoles					@"escape_pod_model"
#define kKey_countsAsKill					@"counts_as_kill"
#define kKey_legacyLaunchActions			@"launch_actions"
#define kKey_legacyScriptActions			@"script_actions"
#define kKey_legacyDeathActions				@"death_actions"
#define kKey_legacySetupActions				@"setup_actions"
#define kKey_scriptName						@"script"
#define kKey_scriptInfo						@"script_info"
#define kKey_hasScoopMessage				@"has_scoop_message"
#define kKey_AIName							@"ai_type"
#define kKey_autoAI							@"auto_ai"
#define kKey_trackCloseContacts				@"track_contacts"
#define kKey_modelName						@"model"
#define kKey_smooth							@"smooth"
#define kKey_materials						@"materials"
#define kKey_shaders						@"shaders"
#define kKey_exhaustDefinitions				@"exhaust"
#define kKey_scannerColor1					@"scanner_display_color1"
#define kKey_scannerColor2					@"scanner_display_color2"
#define kKey_scannerRange					@"scanner_range"
#define kKey_bounty							@"bounty"
#define kKey_density						@"density"
#define kKey_roles							@"roles"
#define kKey_subentityDefinitions			@"subentities"
#define kKey_isFrangible					@"frangible"
#define kKey_escortCount					@"escorts"
#define kKey_escortShip						@"escort_ship"
#define kKey_escortRoles					@"escort_role"
#define kKey_forwardViewPosition			@"view_position_forward"
#define kKey_aftViewPosition				@"view_position_aft"
#define kKey_portViewPosition				@"view_position_port"
#define kKey_starboardViewPosition			@"view_position_starboard"
#define kKey_customViews					@"custom_views"
#define kKey_cargoSpaceCapacity				@"max_cargo"
#define kKey_cargoSpaceUsedMax				@"likely_cargo"
#define kKey_cargoBayExpansionSize			@"extra_cargo"
#define kKey_cargoType						@"cargo_type"
#define kKey_energyCapacity					@"max_energy"
#define kKey_energyRechargeRate				@"energy_recharge_rate"
#define kKey_initialFuel					@"fuel"
#define kKey_heatInsulation					@"heat_insulation"
#define kKey_maxFlightSpeed					@"max_flight_speed"
#define kKey_maxFlightRoll					@"max_flight_roll"
#define kKey_maxFlightPitch					@"max_flight_pitch"
#define kKey_maxFlightYaw					@"max_flight_yaw"
#define kKey_maxThrust						@"thrust"
#define kKey_hasHyperspaceMotor				@"hyperspace_motor"
#define kKey_hyperspaceMotorSpinTime		@"hyperspace_motor_spin_time"
#define kKey_accuracy						@"accuracy"
#define kKey_forwardWeaponType				@"forward_weapon_type"
#define kKey_aftWeaponType					@"aft_weapon_type"
#define kKey_portWeaponType					@"port_weapon_type"
#define kKey_starboardWeaponType			@"starboard_weapon_type"
#define kKey_forwardWeaponPosition			@"weapon_position_forward"
#define kKey_aftWeaponPosition				@"weapon_position_aft"
#define kKey_portWeaponPosition				@"weapon_position_port"
#define kKey_starboardWeaponPosition		@"weapon_position_starboard"
#define kKey_weaponEnergy					@"weapon_energy"
#define kKey_turretRange					@"weapon_range"
#define kKey_laserColor						@"laser_color"
#define kKey_missileCountMax				@"missiles"
#define kKey_missileCapacity				@"max_missiles"
#define kKey_missileRoles					@"missile_role"
#define kKey_qcMineChance					@"has_energy_bomb"
#define kKey_isSubmunition					@"is_submunition"
#define kKey_cloakIsPassive					@"cloak_passive"
#define kKey_cloakIsAutomatic				@"cloak_automatic"
#define kKey_fragmentChance					@"fragment_chance"
#define kKey_noBouldersChance				@"no_boulders"
#define kKey_debrisRoles					@"debris_role"
#define kKey_scoopPosition					@"scoop_position"
#define kKey_aftEjectPosition				@"aft_eject_position"
#define kKey_rotationalVelocity				@"rotational_velocity"
#define kKey_isCarrier1						@"isCarrier"
#define kKey_isCarrier2						@"is_carrier"
#define kKey_isRotating						@"rotating"
#define kKey_stationRoll					@"station_roll"
#define kKey_hasNPCTrafficChance			@"has_npc_traffic"
#define kKey_hasPatrolShipsChance			@"has_patrol_ships"
#define kKey_maxScavengers					@"max_scavengers"
#define kKey_maxDefenseShips				@"max_defense_ships"
#define kKey_maxPolice						@"max_police"
#define kKey_defenseShip					@"defense_ship"
#define kKey_defenseShipRoles				@"defense_ship_role"
#define kKey_equivalentTechLevel			@"equivalent_tech_level"
#define kKey_equipmentPriceFactor			@"equipment_price_factor"
#define kKey_marketKey						@"market"
#define kKey_hasShipyard1					@"has_shipyard"
#define kKey_hasShipyard2					@"hasShipyard"
#define kKey_requiresDockingClearance		@"requires_docking_clearance"
#define kKey_allowsInterstellarUndocking	@"interstellar_undocking"
#define kKey_allowsAutoDocking				@"allows_auto_docking"
#define kKey_allowsFastDocking				@"allows_fast_docking"
#define kKey_dockingTunnelCorners			@"tunnel_corners"
#define kKey_dockingTunnelStartAngle		@"tunnel_start_angle"
#define kKey_dockingTunnelAspectRatio		@"tunnel_aspect_ratio"
#define kKey_extraEquipment					@"extra_equipment"


/*	MARK: Defaults
	
	Each default’s name is kDefault_ followed by the name of the correpsonding
	property, so that it can be looked up by a READ macro below.
	
	Note that the default values here are the defaults for 1.x, and don’t use
	the default constants declared in OOShipClass.h since those might be
	changed for 2.0.
*/

#define kDefault_likeShipKey				nil					// like_ship
#define kDefault_isTemplate					NO
#define kDefault_isExternalDependency		NO
#define kDefault_name						@"?"
#define kDefault_displayName				_name
//				 scanClass					CLASS_NOT_SET (turns into CLASS_NEUTRAL)
#define kDefault_beaconCode					nil
#define kDefault_isHulk						NO
#define kDefault_HUDName					@"hud.plist"		// hud
#define kDefault_pilotKey					nil					// pilot
#define kDefault_unpilotedChance			NO					// unpiloted
#define kDefault_escapePodCount				0					// has_escape_pod — despite the name, this may be greater than 1.	
#define kDefault_escapePodRoles				@"escape-capsule"	// escape_pod_model
#define kDefault_countsAsKill				YES
// launch_actions, script_actions, death_actions, setup_actions: nil
#define kDefault_scriptName					@"oolite-default-ship-script.js"
#define kDefault_scriptInfo					nil
#define kDefault_hasScoopMessage			YES
#define kDefault_AIName						@"nullAI.plist"		// ai_type
#define kDefault_trackCloseContacts			NO
#define kDefault_autoAI						YES
#define kDefault_modelName					nil
#define kDefault_smooth						NO
//				 materials					nil
//				 shaders					nil
// scanner_display_color1, scanner_display_color2: nil
#define kDefault_exhaustDefinitions			nil					// exhaust
#define kDefault_scannerRange				SCANNER_MAX_RANGE
#define kDefault_bounty						0
#define kDefault_density					1
//				 roles						nil
#define kDefault_subentityDefinitions		nil					// subentities
#define kDefault_isFrangible				YES
#define kDefault_escortCount				0					// escorts
// escort_ship: nil. escort_role: traditionally either "escort" or "wingman" depending on context.
#define kDefault_escortRoles				@"escort"
#define kDefault_forwardViewPosition		kZeroVector
#define kDefault_aftViewPosition			kZeroVector
#define kDefault_portViewPosition			kZeroVector
#define kDefault_starboardViewPosition		kZeroVector
#define kDefault_customViews				nil
#define kDefault_cargoSpaceCapacity			0					// max_cargo
#define kDefault_cargoSpaceUsedMax			0					// likely_cargo
#define kDefault_cargoBayExpansionSize		15					// extra_cargo
#define kDefault_cargoType					CARGO_NOT_CARGO
#define kDefault_energyCapacity				200					// max_energy
#define kDefault_energyRechargeRate			1
#define kDefault_initialFuel				0					// fuel
#define kDefault_fuelChargeRate				1
#define kDefault_heatInsulation				1
#define kDefault_maxFlightSpeed				160
#define kDefault_maxFlightRoll				2
#define kDefault_maxFlightPitch				1
#define kDefault_maxFlightYaw				_maxFlightPitch
#define kDefault_maxThrust					15					// thrust
#define kDefault_hasHyperspaceMotor			YES					// hyperspace_motor
#define kDefault_hyperspaceMotorSpinTime	15
#define kDefault_accuracy					-100				// Signals fallback behaviour
#define kDefault_forwardWeaponType			WEAPON_NONE
#define kDefault_aftWeaponType				WEAPON_NONE
#define kDefault_portWeaponType				WEAPON_NONE
#define kDefault_starboardWeaponType		WEAPON_NONE
#define kDefault_forwardWeaponPosition		kZeroVector
#define kDefault_aftWeaponPosition			kZeroVector
#define kDefault_portWeaponPosition			kZeroVector
#define kDefault_starboardWeaponPosition	kZeroVector
#define kDefault_weaponEnergy				0					// Actual default depends on forward_weapon_type
#define kDefault_turretRange				6000				// weapon_range for turrets only
//				 laserColor					redColor
#define kDefault_missileCountMax			0					// missiles
#define kDefault_missileCountMin			_missileCountMax
#define kDefault_missileCapacity			_missileCountMax	// max_missiles
#define kDefault_missileRoles				@"EQ_MISSILE(8) missile(2)"		// missile_role. (Note that you can’t specify multiple roles like this in 1.x, but specifying none has this effect.)
#define kDefault_isSubmunition				NO
#define kDefault_cloakIsPassive				NO
#define kDefault_cloakIsAutomatic			YES
#define kDefault_fragmentChance				0.9
#define kDefault_noBouldersChance			0
#define kDefault_debrisRoles				@"boulder"
#define kDefault_scoopPosition				kZeroVector
#define kDefault_aftEjectPosition			kZeroVector			// Actual default is middle back of bounding box.
#define kDefault_rotationalVelocity			kIdentityQuaternion
//				 isCarrier					NO
//				 is_rotating				NO
#define kDefault_stationRoll				0.4
#define kDefault_hasNPCTrafficChance		YES
#define kDefault_hasPatrolShipsChance		NO					// But forced to YES if is main station and has_npc_traffic
#define kDefault_maxScavengers				3
#define kDefault_maxDefenseShips			3
#define kDefault_maxPolice					8
// defense_ship: nil, defense_ship_role: contextual
#define kDefault_defenseShipRoles			nil
#define kDefault_equivalentTechLevel		NSNotFound			// Placeholder, similar to nil
#define kDefault_equipmentPriceFactor		1
#define kDefault_marketKey					nil
#define kDefault_hasShipyard				NO					// Can be boolean or conditions; always treated as true for main station.	
#define kDefault_requiresDockingClearance	NO
#define kDefault_allowsInterstellarUndocking NO
#define kDefault_allowsAutoDocking			YES
#define kDefault_allowsFastDocking			NO					// Overridden for main station
#define kDefault_dockingTunnelCorners		4
#define kDefault_dockingTunnelStartAngle	45
#define kDefault_dockingTunnelAspectRatio	2.67


// MARK: Helpers

static NSString *UniqueRoleForShipKey(NSString *key)
{
	return $sprintf(@"[%@]", key);
}


static float ReadChance(NSDictionary *shipdata, NSString *key, float defaultValue)
{
	float result = defaultValue;
	id fuzzy = [shipdata objectForKey:key];
	if (fuzzy != nil)  result = OOFuzzyBooleanProbabilityFromObject(fuzzy, 0.0f);
	
	return result;
}


static Vector ReadVector(NSDictionary *shipdata, NSString *key, Vector defaultValue)
{
	NSString *vecString = [shipdata oo_stringForKey:key];
	Vector result = defaultValue;
	if (vecString != nil)
	{
		ScanVectorFromString(vecString, &result);
	}
	
	return result;
}


static Quaternion ReadQuaternion(NSDictionary *shipdata, NSString *key, Quaternion defaultValue)
{
	NSString *quatString = [shipdata oo_stringForKey:key];
	Quaternion result = defaultValue;
	if (quatString != nil)
	{
		ScanQuaternionFromString(quatString, &result);
	}
	
	return result;
}


static OOWeaponType ReadWeaponType(NSDictionary *shipdata, NSString *key, OOWeaponType defaultValue)
{
	NSString *weaponTypeString = [shipdata oo_stringForKey:key];
	OOWeaponType result = defaultValue;
	if (weaponTypeString != nil)  result = OOWeaponTypeFromString(weaponTypeString);
	
	return result;
}


// N.B.: returns owning reference (hence name not being ReadRole).
static OORoleSet *NewRoleSetFromProperty(NSDictionary *shipdata, NSString *key, NSString *defaultValue)
{
	NSString *role = [shipdata objectForKey:key];
	if (role != nil)
	{
		return [[OORoleSet alloc] initWithRole:role probability:1];
	}
	if (defaultValue != nil)
	{
		return [[OORoleSet alloc] initWithRoleString:defaultValue];
	}
	return nil;
}


/*	These macros abstract the process of reading values and applying defaults.
	The keys and defaults are macros defined above.
	
	The types are:
	ARRAY
	BOOL
	DICT
	FLOAT
	FUZZY	(A chance value for a “fuzzy boolean” value, ranging from 0 to 1)
	PFLOAT	(A float no lower than 0)
	QUAT	(A quaternion encoded as a string with four numbers)
	ROLE	(A string put into a single-role OORoleSet with probability of 1)
	STRING
	UINT
	VECTOR	(A vector encoded as a string with three numbers)
	WEAPON	(OOWeaponType)
*/

#define READ_ARRAY(NAME)	_##NAME = [[shipdata oo_arrayForKey:kKey_##NAME defaultValue:kDefault_##NAME] copy]
#define READ_BOOL(NAME)		_##NAME = [shipdata oo_boolForKey:kKey_##NAME defaultValue:kDefault_##NAME]
#define READ_DICT(NAME)		_##NAME = [[shipdata oo_dictionaryForKey:kKey_##NAME defaultValue:kDefault_##NAME] copy]
#define READ_FLOAT(NAME)	_##NAME = [shipdata oo_floatForKey:kKey_##NAME defaultValue:kDefault_##NAME]
#define READ_FUZZY(NAME)	_##NAME = ReadChance(shipdata, kKey_##NAME, kDefault_##NAME)
#define READ_PFLOAT(NAME)	_##NAME = fmaxf(0.0f, [shipdata oo_floatForKey:kKey_##NAME defaultValue:kDefault_##NAME])
#define READ_QUAT(NAME)		_##NAME = ReadQuaternion(shipdata, kKey_##NAME, kDefault_##NAME)
#define READ_ROLE(NAME)		_##NAME = NewRoleSetFromProperty(shipdata, kKey_##NAME, kDefault_##NAME)
#define READ_STRING(NAME)	_##NAME = [[shipdata oo_stringForKey:kKey_##NAME defaultValue:kDefault_##NAME] copy]
#define READ_UINT(NAME)		_##NAME = [shipdata oo_unsignedIntegerForKey:kKey_##NAME defaultValue:kDefault_##NAME]
#define READ_VECTOR(NAME)	_##NAME = ReadVector(shipdata, kKey_##NAME, kDefault_##NAME)
#define READ_WEAPON(NAME)	_##NAME = ReadWeaponType(shipdata, kKey_##NAME, kDefault_##NAME)


@implementation OOShipClass (Legacy)

- (id) initWithKey:(NSString *)key
	   legacyPList:(NSDictionary *)legacyPList
   problemReporter:(id<OOProblemReporting>)issues
{
	NSParameterAssert(key != nil);
	
	if ((self = [self init]))
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		_shipKey = [key copy];
		if (![self priv_loadFromLegacyPList:legacyPList problemReporter:issues])
		{
			DESTROY(self);
		}
		
		[pool drain];
	}
	
	return self;
}


- (BOOL) priv_loadFromLegacyPList:(NSDictionary *)shipdata
				  problemReporter:(id<OOProblemReporting>)issues
{
	NSString *shipKey = [self shipKey];
	
	READ_STRING	(likeShipKey);
	READ_BOOL	(isTemplate);
	READ_BOOL	(isExternalDependency);
	
	READ_STRING	(name);
	READ_STRING	(displayName);
	
	OOScanClass scanClass = OOScanClassFromString([shipdata oo_stringForKey:kKey_scanClass1 defaultValue:@"CLASS_NOT_SET"]);
	if (scanClass == CLASS_NOT_SET)  scanClass = OOScanClassFromString([shipdata oo_stringForKey:kKey_scanClass2 defaultValue:@"CLASS_NOT_SET"]);
	if (scanClass == CLASS_NOT_SET)  scanClass = CLASS_NEUTRAL;
	_scanClass = scanClass;
	
	READ_STRING	(beaconCode);
	READ_BOOL	(isHulk);
	READ_STRING	(HUDName);
	
	READ_STRING	(pilotKey);
	READ_FUZZY	(unpilotedChance);
	READ_UINT	(escapePodCount);
	READ_ROLE	(escapePodRoles);	// Despite the name, escape_pod_model takes a role.
	READ_BOOL	(countsAsKill);
	
	/*
		Check for legacy script actions, keeping in mind that setup_actions
		containing ”initialiseTurret” are used as a flag to indicate that the
		ship is used as a ball turret and isn’t a real script command any
		longer.
		-- Ahruman 2011-03-24
	*/
	BOOL hasLegacyActions = NO;
	id setupActions = [shipdata objectForKey:kKey_legacySetupActions];
	if ([setupActions isKindOfClass:[NSArray class]])
	{
		NSString *action = nil;
		foreach (action, setupActions)
		{
			if ([action isKindOfClass:[NSString class]])
			{
				if ([[ScanTokensFromString(action) objectAtIndex:0] isEqualToString:@"initialiseTurret"])
				{
					_isBallTurret = YES;
				}
			}
		}
		if (!_isBallTurret || [setupActions count] > 1)
		{
			hasLegacyActions = YES;
		}
	}
	if ([shipdata objectForKey:kKey_legacyLaunchActions] != nil ||
		[shipdata objectForKey:kKey_legacyScriptActions] != nil ||
		[shipdata objectForKey:kKey_legacyDeathActions] != nil)
	{
		hasLegacyActions = YES;
	}
	if (hasLegacyActions)
	{
		/*
			FIXME: (maybe) automatically convert legacy actions to JavaScript.
			-- Ahruman 2011-03-18
		*/
		OOReportWarning(issues, @"Ship %@ has legacy script actions, which will be ignored.", shipKey);
	}
	READ_STRING	(scriptName);
	READ_DICT	(scriptInfo);
	READ_BOOL	(hasScoopMessage);
	READ_STRING	(AIName);
	READ_BOOL	(trackCloseContacts);
	
	/*	auto_ai is, for some reason I don’t remember, a fuzzy boolean in 1.x.
		The uses for this seem limited, and should be easily achieved by
		scripting, so we only allow booleans and warn if fuzzy values are used.
		-- Ahruman 2011-03-20
	*/
	id autoAI = [shipdata objectForKey:kKey_autoAI];
	if (autoAI != nil)
	{
		float autoAIChance = OOFuzzyBooleanProbabilityFromObject(autoAI, 1.0f);
		if (0.0f < autoAIChance && autoAIChance < 1.0f)
		{
			_autoAI = (autoAIChance >= 0.5f);
			OOReportWarning(issues, @"Ship %@ has a fuzzy auto_ai value of %g. Oolite 2.0 requires a boolean value, so %@ has been chosen. If you want a random value, use a script.", shipKey, autoAIChance, _autoAI ? @"true" : @"false");
		}
		else
		{
			_autoAI = (autoAIChance > 0.0f);
		}

	}
	else  _autoAI = kDefault_autoAI;
	
	READ_STRING	(modelName);
	READ_BOOL	(smooth);
	
	/*	Merge the two material dictionaries, with "shaders" overriding
		"materials" since 2.x always has shaders.
		FIXME: this might not be the right thing, since the actual shaders
		are expected to stop working in 2.x. Also, the contents of the
		dictionaries need updating.
		-- Ahruman 2011-03-18
	*/
	NSDictionary *materials = [shipdata oo_dictionaryForKey:kKey_materials];
	NSDictionary *shaders = [shipdata oo_dictionaryForKey:kKey_shaders];
	if (materials == nil)
	{
		if (shaders != nil)  _materialDefinitions = [shaders copy];
	}
	else
	{
		if (shaders == nil)  _materialDefinitions = [materials copy];
		else
		{
			NSMutableDictionary *mutableMaterials = [materials mutableCopy];
			[mutableMaterials addEntriesFromDictionary:shaders];
			_materialDefinitions = [mutableMaterials copy];
			[mutableMaterials release];
		}
	}
	
	/*	FIXME: we probably want a more direct representation for exhaust
		parameters. Current format is a string with six numbers, of which one
		is ignored.
		-- Ahruman 2011-03-18
	*/
	READ_ARRAY	(exhaustDefinitions);
	
	//	Load scanner lollipop colours.
	OOColor *scannerColor1 = [OOColor colorWithDescription:[shipdata objectForKey:kKey_scannerColor1]];
	OOColor *scannerColor2 = [OOColor colorWithDescription:[shipdata objectForKey:kKey_scannerColor2]];
	if (scannerColor1 == nil)
	{
		if (scannerColor2 != nil)  _scannerColors = $array(scannerColor2);
	}
	else
	{
		if (scannerColor2 == nil)  _scannerColors = $array(scannerColor1);
		else  _scannerColors = $array(scannerColor1, scannerColor2);
	}
	
	READ_FLOAT	(scannerRange);
	
	READ_UINT	(bounty);
	READ_PFLOAT	(density);
	
	/*	Deal with roles.
		We want to add a unique role for each ship, to simplify cases where 1.x
		allows ships to be referenced by key but 2.x doesn’t (like specifying
		esorts).
	*/
	NSString *uniqueRole = UniqueRoleForShipKey(shipKey);
	NSString *roleString = [shipdata oo_stringForKey:kKey_roles];
	if (roleString != nil)
	{
		[_roles release];
		_roles = [[[OORoleSet roleSetWithString:roleString] roleSetWithAddedRole:uniqueRole probability:1] retain];
	}
	else
	{
		_roles = [[OORoleSet alloc] initWithRole:uniqueRole probability:1];
	}
	
	/*	FIXME: convert to canonical subentity representation.
		-- Ahruman 2011-03-18
	*/
	READ_ARRAY	(subentityDefinitions);
	READ_BOOL	(isFrangible);
	
	READ_UINT	(escortCount);
	// FIXME: wrap up limit handling in macros too?
	if (_escortCount > 16)
	{
		OOReportWarning(issues, @"Escort count for ship %@ is %u, but the highest permitted value for Oolite 1.x is 16. The value will be clamped.", _escortCount);
		_escortCount = 16;	// 1.x limit, should stay 16 even if 2.0 limit is raised.
	}
	
	/*	Set up escort roles. 1.x has two options here: escort_ship (a ship key)
		or escort_role, with escort_ship taking priority. For 2.x, we only
		support roles, but we also add each ship’s key as a hopefully-unique
		role.
	*/
	NSString *escort = [shipdata oo_stringForKey:kKey_escortShip];
	if (escort != nil)  _escortRoles = [[OORoleSet alloc] initWithRole:UniqueRoleForShipKey(escort) probability:1];
	else
	{
		READ_ROLE(escortRoles);
	}
	
	READ_VECTOR	(forwardViewPosition);
	READ_VECTOR	(aftViewPosition);
	READ_VECTOR	(portViewPosition);
	READ_VECTOR	(starboardViewPosition);
	READ_ARRAY	(customViews);
	
	READ_UINT	(cargoSpaceCapacity);
	READ_UINT	(cargoSpaceUsedMax);
	_cargoSpaceUsedMin = _cargoSpaceUsedMax;
	READ_UINT	(cargoBayExpansionSize);
	
	NSString *cargoType = [shipdata oo_stringForKey:kKey_cargoType];
	if (cargoType != nil)
	{
		_cargoType = StringToCargoType(cargoType);
		if (_cargoType == CARGO_UNDEFINED)
		{
			OOReportWarning(issues, @"Unknown cargo type \"%@\" for ship %@, treating as CARGO_NOT_CARGO.", cargoType, shipKey);
			_cargoType = CARGO_NOT_CARGO;
		}
	}
	
	READ_PFLOAT	(energyCapacity);
	READ_PFLOAT	(energyRechargeRate);
	
	// Note: as per 1.x, fuel defaults to 0.
	READ_UINT	(initialFuel);
	_fuelCapacity = MAX(70U, _initialFuel);		// 1.x has no explicit fuel capacity.
	
	/*
		In 1.x, heat insulation defaults to 1 unless there is a heat shield,
		which implies that we should reduce heatInsulation by 1 if the ship
		has a heat shield with probability 1 and warn if it has one with a
		probability < 1. However, there doesn’t actually seem to be a way to
		specify that a ship has a heat shield, so this _appears_ to be a moot
		point.
		-- Ahruman 2011-03-26
	*/
	READ_PFLOAT	(heatInsulation);
	
	READ_PFLOAT	(maxFlightSpeed);
	READ_PFLOAT	(maxFlightRoll);
	READ_PFLOAT	(maxFlightPitch);
	READ_PFLOAT	(maxFlightYaw);
	READ_PFLOAT	(maxThrust);
	READ_BOOL	(hasHyperspaceMotor);
	READ_PFLOAT	(hyperspaceMotorSpinTime);
	
	READ_FLOAT	(accuracy);
	READ_WEAPON	(forwardWeaponType);
	READ_WEAPON	(aftWeaponType);
	READ_WEAPON	(portWeaponType);
	READ_WEAPON	(starboardWeaponType);
	READ_VECTOR	(forwardWeaponPosition);
	READ_VECTOR	(aftWeaponPosition);
	READ_VECTOR	(portWeaponPosition);
	READ_VECTOR	(starboardWeaponPosition);
	READ_PFLOAT	(weaponEnergy);
	READ_PFLOAT	(turretRange);
	[self priv_adjustLegacyWeaponStatsWithProblemReporter:issues];
	id laserColorDef = [shipdata objectForKey:kKey_laserColor];
	if (laserColorDef != nil)
	{
		_laserColor = [[OOColor brightColorWithDescription:laserColorDef] retain];
	}
	else
	{
		_laserColor = [[OOColor redColor] retain];
	}
	
	READ_UINT	(missileCountMax);
	_missileCountMin = kDefault_missileCountMin;
	READ_UINT	(missileCapacity);
	READ_ROLE	(missileRoles);
	
	/*	has_energy_bomb, confusingly, is a fuzzy boolean that assigns NPC
		ships one QC mine. This doesn’t translate directly to 2.x, so we
		instead use it as a weight modifier for the QC-mine missile role.
		Also, we need to add a missile slot of missileCapacity was implcit.
	*/
	float qcMineChance = ReadChance(shipdata, kKey_qcMineChance, 0);
	if (qcMineChance > 0)
	{
		if ([shipdata objectForKey:kKey_missileCountMax] == nil)  _missileCountMax++;
		
		// Calculate a weight that will result in about one mine on average.
		float avgMissileCount = 0.5f * (_missileCountMin + _missileCountMax);
		float weight = [_missileRoles totalRoleWeight] / avgMissileCount;
		
		// Scale by specified chance.
		weight *= qcMineChance;
		
		[_missileRoles autorelease];
		_missileRoles = [_missileRoles roleSetWithAddedRole:@"EQ_QC_MINE" probability:weight];
		[_missileRoles retain];
		
		OOReportWarning(issues, @"Ship %@ uses has_energy_bomb to add a Quirium Cascade Mine. This has no direct equivalent in Oolite 2. To compensate, ship's missileRoles have been changed to %@.", shipKey, [_missileRoles roleString]);
	}
	_missileCountMax = MIN(_missileCountMax, SHIPENTITY_MAX_MISSILES);
	
	READ_BOOL	(isSubmunition);
	
	READ_BOOL	(cloakIsPassive);
	READ_BOOL	(cloakIsAutomatic);
	
	READ_FUZZY	(fragmentChance);
	READ_FUZZY	(noBouldersChance);
	READ_ROLE	(debrisRoles);
	READ_VECTOR	(scoopPosition);
	READ_VECTOR	(aftEjectPosition);
	
	READ_QUAT	(rotationalVelocity);
	
	/*	is_carrier and isCarrier are synonyms; isCarrier has priority.
		If it isn’t defined, carrierhood is inferred from roles.
		-- Ahruman 2011-03-20
	*/
	id isCarrier = [shipdata objectForKey:kKey_isCarrier1];
	if (isCarrier == nil)  isCarrier = [shipdata objectForKey:kKey_isCarrier2];
	if (isCarrier != nil)  _isCarrier = OOBooleanFromObject(isCarrier, NO);
	else
	{
		_isCarrier = [roleString rangeOfString:@"station"].location != NSNotFound || [roleString rangeOfString:@"carrier"].location != NSNotFound;
	}
	
	if (_isCarrier)
	{
		/*	Only read carrier-related properties when actually loading a
			carrier.
		*/
		if ([shipdata oo_boolForKey:kKey_isRotating])
		{
			READ_FLOAT(stationRoll);
		}
		// else station_roll is effectively 0. (rotating predates station_roll and is now redundant.)
		
		READ_FUZZY	(hasNPCTrafficChance);
		READ_FUZZY	(hasPatrolShipsChance);
		READ_UINT	(maxScavengers);
		READ_UINT	(maxPolice);
		READ_UINT	(maxDefenseShips);
		
		/*	defenseShipRoles has the same issues as escortRoles above. As a
			bonus, the default depends on the system tech level and a random
			roll, so we just default to nil.
		*/
		NSString *defenseShip = [shipdata oo_stringForKey:kKey_defenseShip];
		if (defenseShip != nil)  _escortRoles = [[OORoleSet alloc] initWithRole:UniqueRoleForShipKey(defenseShip) probability:1];
		else
		{
			READ_ROLE(defenseShipRoles);
		}
		
		READ_UINT	(equivalentTechLevel);
		READ_FLOAT	(equipmentPriceFactor);
		_equipmentPriceFactor = fmaxf(_equipmentPriceFactor, 0.5f);
		READ_STRING	(marketKey);
		
		/*	hasShipyard can be a (non-fuzzy) boolean or a legacy script condition.
			It can also be written has_shipyard or hasShipyard, with the former
			taking precedence.
			FIXME: bring in JS code generation!
		*/
		id hasShipyard = [shipdata objectForKey:kKey_hasShipyard1];
		if (hasShipyard == nil)  hasShipyard = [shipdata objectForKey:kKey_hasShipyard2];
		if (hasShipyard != nil)
		{
			if ([hasShipyard isKindOfClass:[NSArray class]])
			{
				OOReportWarning(issues, @"Ship %@ uses legacy script conditions for the has_shipyard property. This is being treated as false; the conditions must be translated to JavaScript.", shipKey);
			}
			else  _hasShipyard = OOBooleanFromObject(hasShipyard, kDefault_hasShipyard);
		}
		
		/*	FIXME: in 1.x the requires_docking_clearance default can be
			overriden through planetinfo. Not sure how to deal with that.
			-- Ahruman 2011-03-20
		*/
		READ_BOOL	(requiresDockingClearance);
		READ_BOOL	(allowsInterstellarUndocking);
		READ_BOOL	(allowsAutoDocking);
		READ_BOOL	(allowsFastDocking);
		READ_UINT	(dockingTunnelCorners);
		READ_FLOAT	(dockingTunnelStartAngle);
		READ_PFLOAT	(dockingTunnelAspectRatio);
	}
	
	// Equipment.
	BOOL			isPlayer = [[self roles] hasRole:@"player"];
	
	NSMutableArray	*equipment = [NSMutableArray array];
	NSDictionary	*eqFuzzes = $dict
	(
		@"has_shield_booster",			@"EQ_SHIELD_BOOSTER",
		@"has_shield_enhancer",			@"EQ_SHIELD_ENHANCER",
		@"has_ecm",						@"EQ_ECM",
		@"has_scoop",					@"EQ_FUEL_SCOOPS",
		@"has_escape_pod",				@"EQ_ESCAPE_POD",
		@"has_cloaking_device",			@"EQ_CLOAKING_DEVICE",
		@"has_fuel_injection",			@"EQ_FUEL_INJECTION",
		
	 // These are not supported.
		@"has_military_jammer"			@"",
		@"has_military_scanner_filter"	@""
	);
	NSString *eqFuzzKey = nil;
	foreachkey (eqFuzzKey, eqFuzzes)
	{
		float chance = [shipdata oo_fuzzyBooleanProbabilityForKey:eqFuzzKey];
		if (chance > 0)
		{
			NSString *eqType = [eqFuzzes objectForKey:eqFuzzKey];
			if ([eqType length] > 0)
			{
				NSDictionary *eqDict = $dict(kOOShipClassEquipmentKeyKey, eqType, kOOShipClassEquipmentChanceKey, [NSNumber numberWithFloat:chance]);
				[equipment addObject:eqDict];
			}
			else
			{
				OOReportWarning(issues, @"Ship %@ specifies %@, but this equipment is not available in Oolite 2.", shipKey, eqFuzzKey);
			}
		}
	}
	
	if (isPlayer)
	{
		//	extra_equipment is a dictionary of booleans moonlighting as a set.
		NSDictionary *extraEquipment = [shipdata oo_dictionaryForKey:kKey_extraEquipment];
		NSString *eqKey = nil;
		foreachkey (eqKey, extraEquipment)
		{
			if (![extraEquipment oo_boolForKey:eqKey])
			{
				OOReportWarning(issues, @"Ship %@ has an extra_equipment dictionary which contains a false value for the equipment %@. This is pointless and will be ignored.", shipKey, eqKey);
				continue;
			}
			
			NSDictionary *eqDict = $dict(kOOShipClassEquipmentKeyKey, eqKey, kOOShipClassEquipmentChanceKey, [NSNumber numberWithFloat:1]);
			[equipment addObject:eqDict];
		}
	}
	else if ([shipdata objectForKey:kKey_extraEquipment] != nil)
	{
		OOReportWarning(issues, @"Ship %@ has an extra_equipment dictionary, but is not a player ship. The extra_equipment will be ignored.", shipKey);
	}
	
	_equipment = [equipment copy];
	
	return YES;
}


- (void) priv_adjustLegacyWeaponStatsWithProblemReporter:(id<OOProblemReporting>)issues
{
	float weaponDamage = 0;
	float weaponRechargeRate = 0;
	float weaponRange = 0;
	
	switch (_forwardWeaponType)
	{
		case WEAPON_PLASMA_CANNON:
			weaponDamage =			6.0;
			weaponRechargeRate =	0.25;
			weaponRange =			5000;
			break;
		case WEAPON_PULSE_LASER:
			weaponDamage =			15.0;
			weaponRechargeRate =	0.33;
			weaponRange =			12500;
			break;
		case WEAPON_BEAM_LASER:
			weaponDamage =			15.0;
			weaponRechargeRate =	0.25;
			weaponRange =			15000;
			break;
		case WEAPON_MINING_LASER:
			weaponDamage =			50.0;
			weaponRechargeRate =	0.5;
			weaponRange =			12500;
			break;
		case WEAPON_THARGOID_LASER:
			weaponDamage =			12.5;
			weaponRechargeRate =	0.5;
			weaponRange =			17500;
			break;
		case WEAPON_MILITARY_LASER:
			weaponDamage =			23.0;
			weaponRechargeRate =	0.20;
			weaponRange =			30000;
			break;
		case WEAPON_NONE:
		case WEAPON_UNDEFINED:
			weaponDamage =			0.0;	// indicating no weapon!
			weaponRechargeRate =	0.20;	// maximum rate
			weaponRange =			32000;
			break;
	}
	
	if (_weaponEnergy > 0)
	{
		/*	There are two cases for weapon_energy:
			* if weaponDamage is 0, this is assumed to be a missile or bomb,
			  which can have any weapon damage value (simply by leaving
			  _weaponEnergy alone).
			* Otherwise, the damage is limited to 50.
		*/
		if (weaponDamage != 0 && _weaponEnergy > 50)
		{
			OOReportWarning(issues, @"Ship %@ specifies out-of-range weapon_energy %g, which will be clamped to 50.", [self shipKey], _weaponEnergy);
			_weaponEnergy = 50;
		}
	}
}

@end
