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


/* MARK: Defaults
	
	Each default’s name is kDefault_ followed by the name of the correpsonding
	property, so that it can be looked up by a READ macro below.
	
	Note that the default values here are the defaults for 1.x, and don’t use
	the default constants declared in OOShipClass.h since those might be
	changed for 2.0.
*/

//				 isTemplate					NO
//				 isExternalDependency		NO
//				 displayName				_name
#define kDefault_name						nil
//				 scanClass					CLASS_NOT_SET (a buggy situation; should probably default to CLASS_NEUTRAL)
#define kDefault_beaconCode					nil
#define kDefault_isHulk						NO
#define kDefault_HUDName					@"hud.plist"		// hud
#define kDefault_pilotKey					nil					// pilot
#define kDefault_unpilotedChance			NO					// unpiloted
#define kDefault_escapePodRoles				@"escape-capsule"	// escape_pod_model
#define kDefault_countsAsKill				YES
// launch_actions, script_actions, death_actions, setup_actions: nil
#define kDefault_scriptName					@"oolite-default-ship-script.js"
#define kDefault_scriptInfo					nil
#define kDefault_hasScoopMessage			NO
#define kDefault_AIName						@"nullAI.plist"		// ai_type
#define kDefault_trackContacts				NO
#define kDefault_autoAI						YES
#define kDefault_modelName					nil
#define kDefault_smooth						NO
//				 materials					nil
//				 shaders					nil
// scanner_display_color1, scanner_display_color2: nil
#define kDefault_exhaustDefinitions			nil					// exhaust
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
#define kDefault_heatInsulation				1					// 2 with heat shield.
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
#define kDefault_aftEjectPosition			kZeroVector		// Actual default is middle back of bounding box.
#define kDefault_rotationalVelocity			kIdentityQuaternion
//				 isCarrier					NO
#define kDefault_isRotating					NO
#define kDefault_stationRoll				0.4
#define kDefault_
#define kDefault_
#define kDefault_


// MARK: Helpers

static NSString *UniqueRoleForShipKey(NSString *key)
{
	return $sprintf(@"_oo_unique_role_for_%@", key);
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
	if (defaultValue == nil)
	{
		return [[OORoleSet alloc] initWithRoleString:defaultValue];
	}
	return nil;
}


/*	These macros abstract the process of reading values and applying defaults.
	The defaults are macros defined above.
	
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

#define READ_ARRAY(NAME, KEY)	_##NAME = [[shipdata oo_arrayForKey:@KEY defaultValue:kDefault_##NAME] copy]

#define READ_BOOL(NAME, KEY)	_##NAME = [shipdata oo_boolForKey:@KEY defaultValue:kDefault_##NAME]

#define READ_DICT(NAME, KEY)	_##NAME = [[shipdata oo_dictionaryForKey:@KEY defaultValue:kDefault_##NAME] copy]

#define READ_FLOAT(NAME, KEY)	_##NAME = [shipdata oo_floatForKey:@KEY defaultValue:kDefault_##NAME]

#define READ_FUZZY(NAME, KEY)	_##NAME = ReadChance(shipdata, @KEY, kDefault_##NAME)

#define READ_PFLOAT(NAME, KEY)	_##NAME = fmaxf(0.0f, [shipdata oo_floatForKey:@KEY defaultValue:kDefault_##NAME])

#define READ_QUAT(NAME, KEY)	_##NAME = ReadQuaternion(shipdata, @KEY, kDefault_##NAME)

#define READ_ROLE(NAME, KEY)	_##NAME = NewRoleSetFromProperty(shipdata, @KEY, kDefault_##NAME)

#define READ_STRING(NAME, KEY)	_##NAME = [[shipdata oo_stringForKey:@KEY defaultValue:kDefault_##NAME] copy]

#define READ_UINT(NAME, KEY)	_##NAME = [shipdata oo_unsignedIntegerForKey:@KEY defaultValue:kDefault_##NAME]

#define READ_VECTOR(NAME, KEY)	_##NAME = ReadVector(shipdata, @KEY, kDefault_##NAME)

#define READ_WEAPON(NAME, KEY)	_##NAME = ReadWeaponType(shipdata, @KEY, kDefault_##NAME)


@implementation OOShipClass (Legacy)

- (id) initWithKey:(NSString *)key
	   legacyPList:(NSDictionary *)legacyPList
   problemReporter:(id<OOProblemReporting>)issues
{
	NSParameterAssert(key != nil);
	
	if ((self = [self init]))
	{
		_shipKey = [key copy];
		if (![self priv_loadFromLegacyPList:legacyPList problemReporter:issues])
		{
			DESTROY(self);
		}
	}
	
	return self;
}


- (BOOL) priv_loadFromLegacyPList:(NSDictionary *)shipdata
				  problemReporter:(id<OOProblemReporting>)issues
{
	NSString *shipKey = [self shipKey];
	
	// These three values aren’t inherited.
	_isTemplate = [shipdata oo_boolForKey:@"is_template"];
	_isExternalDependency = [shipdata oo_boolForKey:@"is_external_dependency"];
	_displayName = [[shipdata oo_stringForKey:@"display_name"] copy];
	
	READ_STRING	(name,					"name");
	
	OOScanClass scanClass = OOScanClassFromString([shipdata oo_stringForKey:@"scan_class" defaultValue:@"CLASS_NOT_SET"]);
	if (scanClass == CLASS_NOT_SET)  scanClass = OOScanClassFromString([shipdata oo_stringForKey:@"scanClass" defaultValue:@"CLASS_NOT_SET"]);
	_scanClass = scanClass;	// Should we replace CLASS_NOT_SET with CLASS_NEUTRAL here? 1.x doesn’t, but that’s probably a bug. -- Ahruman 2011-03-20
	
	READ_STRING	(beaconCode,			"beacon");
	READ_BOOL	(isHulk,				"is_hulk");
	READ_STRING	(HUDName,				"hud");
	
	READ_STRING	(pilotKey,				"pilot");
	READ_FUZZY	(unpilotedChance,		"unpiloted");
	READ_ROLE	(escapePodRoles,		"escape_pod_model");	// Despite the name, escape_pod_model takes a role.
	READ_BOOL	(countsAsKill,			"counts_as_kill");
	
	/*	FIXME: (maybe) automatically convert legacy actions to JavaScript.
		-- Ahruman 2011-03-18
	*/
	if ([shipdata objectForKey:@"launch_actions"] != nil ||
		[shipdata objectForKey:@"script_actions"] != nil ||
		[shipdata objectForKey:@"death_actions"] != nil ||
		[shipdata objectForKey:@"setup_actions"] != nil)
	{
		OOReportWarning(issues, @"Ship %@ has legacy script actions, which will be ignored.", shipKey);
	}
	READ_STRING	(scriptName,			"script");
	READ_DICT	(scriptInfo,			"script_info");
	READ_BOOL	(hasScoopMessage,		"has_scoop_message");
	READ_STRING	(AIName,				"ai_type");
	READ_BOOL	(trackContacts,			"track_contacts");
	
	/*	auto_ai is, for some reason I don’t remember, a fuzzy boolean in 1.x.
		The uses for this seem limited, and should be easily achieved by
		scripting, so we only allow booleans and warn if fuzzy values are used.
	*/
	id autoAI = [shipdata objectForKey:@"auto_ai"];
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
	
	READ_STRING	(modelName,				"model");
	READ_BOOL	(smooth,				"smooth");
	
	/*	Merge the two material dictionaries, with "shaders" overriding
		"materials" since 2.x always has shaders.
		FIXME: this might not be the right thing, since the actual shaders
		are expected to stop working in 2.x.
		-- Ahruman 2011-03-18
	*/
	NSDictionary *materials = [shipdata oo_dictionaryForKey:@"materials"];
	NSDictionary *shaders = [shipdata oo_dictionaryForKey:@"shaders"];
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
	READ_ARRAY	(exhaustDefinitions,	"exhaust");
	
	//	Load scanner lollipop colours.
	OOColor *scannerColor1 = [OOColor colorWithDescription:[shipdata objectForKey:@"scanner_display_color1"]];
	OOColor *scannerColor2 = [OOColor colorWithDescription:[shipdata objectForKey:@"scanner_display_color2"]];
	if (scannerColor1 == nil)
	{
		if (scannerColor2 != nil)  _scannerColors = $array(scannerColor2);
	}
	else
	{
		if (scannerColor2 == nil)  _scannerColors = $array(scannerColor1);
		else  _scannerColors = $array(scannerColor1, scannerColor2);
	}
	
	READ_UINT	(bounty,				"bounty");
	READ_PFLOAT	(density,				"density");
	
	/*	Deal with roles.
		We want to add a unique role for each ship, to simplify cases where 1.x
		allows ships to be referenced by key but 2.x doesn’t (like specifying
		esorts).
	*/
	NSString *uniqueRole = UniqueRoleForShipKey(shipKey);
	NSString *roleString = [shipdata oo_stringForKey:@"roles"];
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
	READ_ARRAY	(subentityDefinitions,	"subentities");
	READ_BOOL	(isFrangible,			"frangible");
	
	READ_UINT	(escortCount,			"escorts");
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
	NSString *escort = [shipdata oo_stringForKey:@"escort_ship"];
	if (escort != nil)  _escortRoles = [[OORoleSet alloc] initWithRole:UniqueRoleForShipKey(escort) probability:1];
	else
	{
		READ_ROLE(escortRoles, "escort_role");
		if (_escortRoles == nil)  _escortRoles = [[OORoleSet alloc] initWithRole:kDefault_escortRoles probability:1];
	}
	
	READ_VECTOR	(forwardViewPosition,	"view_position_forward");
	READ_VECTOR	(aftViewPosition,		"view_position_aft");
	READ_VECTOR	(portViewPosition,		"view_position_port");
	READ_VECTOR	(starboardViewPosition,	"view_position_starboard");
	READ_ARRAY	(customViews,			"custom_views");
	
	READ_UINT	(cargoSpaceCapacity,	"max_cargo");
	READ_UINT	(cargoSpaceUsedMax,		"likely_cargo");
	_cargoSpaceUsedMin = _cargoSpaceUsedMax;
	READ_UINT	(cargoBayExpansionSize,	"extra_cargo");
	
	NSString *cargoType = [shipdata oo_stringForKey:@"cargo_type"];
	if (cargoType != nil)
	{
		_cargoType = StringToCargoType(cargoType);
		if (_cargoType == CARGO_UNDEFINED)
		{
			OOReportWarning(issues, @"Unknown cargo type \"%@\" for ship %@, treating as CARGO_NOT_CARGO.", cargoType, shipKey);
			_cargoType = CARGO_NOT_CARGO;
		}
	}
	
	READ_PFLOAT	(energyCapacity,		"max_energy");
	READ_PFLOAT	(energyRechargeRate,	"energy_recharge_rate");
	
	// Note: as per 1.x, fuel defaults to 0.
	READ_UINT	(initialFuel,			"fuel");
	READ_PFLOAT	(fuelChargeRate,		"fuel_charge_rate");
	_fuelCapacity = MAX(70U, _initialFuel);		// 1.x has no explicit fuel capacity.	
	
	READ_PFLOAT	(heatInsulation,		"heat_insulation");	// FIXME: 1.x handles NPC heat shield equipment by changing the default to 2.0. Ideally, we’d handle it by handling equipment.
	
	READ_PFLOAT	(maxFlightSpeed,		"max_flight_speed");
	READ_PFLOAT	(maxFlightRoll,			"max_flight_roll");
	READ_PFLOAT	(maxFlightPitch,		"max_flight_pitch");
	READ_PFLOAT	(maxFlightYaw,			"max_flight_yaw");
	READ_PFLOAT	(maxThrust,				"thrust");
	READ_BOOL	(hasHyperspaceMotor,	"hyperspace_motor");
	READ_PFLOAT	(hyperspaceMotorSpinTime, "hyperspace_motor_spin_time");
	
	READ_FLOAT	(accuracy,				"accuracy");
	READ_WEAPON	(forwardWeaponType,		"forward_weapon_type");
	READ_WEAPON	(aftWeaponType,			"aft_weapon_type");
	READ_WEAPON	(portWeaponType,		"port_weapon_type");
	READ_WEAPON	(starboardWeaponType,	"starboard_weapon_type");
	READ_VECTOR	(forwardWeaponPosition,	"weapon_position_forward");
	READ_VECTOR	(aftWeaponPosition,		"weapon_position_aft");
	READ_VECTOR	(portWeaponPosition,	"weapon_position_port");
	READ_VECTOR	(starboardWeaponPosition, "weapon_position_starboard");
	READ_PFLOAT	(weaponEnergy,			"weapon_energy");
	READ_PFLOAT	(turretRange,			"weapon_range");
	[self priv_adjustLegacyWeaponStatsWithProblemReporter:issues];
	id laserColorDef = [shipdata objectForKey:@"laser_color"];
	if (laserColorDef != nil)
	{
		_laserColor = [[OOColor brightColorWithDescription:laserColorDef] retain];
	}
	else
	{
		_laserColor = [[OOColor redColor] retain];
	}
	
	READ_UINT	(missileCountMax,		"missiles");
	_missileCountMin = kDefault_missileCountMin;
	READ_UINT	(missileCapacity,		"max_missiles");
	READ_ROLE	(missileRoles,			"missile_role");
	
	READ_BOOL	(isSubmunition,			"is_submunition");
	
	READ_BOOL	(cloakIsPassive,		"cloak_passive");
	READ_BOOL	(cloakIsAutomatic,		"cloak_automatic");
	
	READ_FUZZY	(fragmentChance,		"fragment_chance");
	READ_FUZZY	(noBouldersChance,		"no_boulders");
	READ_ROLE	(debrisRoles,			"debris_role");
	READ_VECTOR	(scoopPosition,			"scoop_position");
	READ_VECTOR	(aftEjectPosition,		"aft_eject_position");
	
	READ_QUAT	(rotationalVelocity,	"rotational_velocity");
	
	/*	is_carrier and isCarrier are synonyms; isCarrier has priority.
		If it isn’t defined, carrierhood is inferred from roles.
		-- Ahruman 2011-03-20
	*/
	id isCarrier = [shipdata objectForKey:@"isCarrier"];
	if (isCarrier == nil)  isCarrier = [shipdata objectForKey:@"is_carrier"];
	if (isCarrier != nil)  _isCarrier = OOBooleanFromObject(isCarrier, NO);
	else
	{
		_isCarrier = [roleString rangeOfString:@"station"].location != NSNotFound || [roleString rangeOfString:@"carrier"].location != NSNotFound;
	}
	
	READ_BOOL	(isRotating,			"rotating");
	READ_BOOL	(stationRoll,			"station_roll");
	
	// EQUIPMENT
	
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
