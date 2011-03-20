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
					   knownShips:(NSDictionary *)knownShips
				  problemReporter:(id<OOProblemReporting>)issues;

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
#define kDefault_
#define kDefault_
#define kDefault_
#define kDefault_
#define kDefault_
#define kDefault_
#define kDefault_
#define kDefault_


// MARK: Helpers

static NSString *UniqueRoleForShipKey(NSString *key)
{
	return $sprintf(@"_oo_unique_role_for_%@", key);
}


static float ReadLegacyChance(NSDictionary *shipdata, NSString *key, OOShipClass *likeShip, SEL likeSelector, float defaultValue)
{
	float result = defaultValue;
	id fuzzy = [shipdata objectForKey:key];
	if (fuzzy != nil)  result = OOFuzzyBooleanProbabilityFromObject(fuzzy, 0.0f);
	else if (likeShip != nil)
	{
		typedef float (*FloatGetterIMP)(id self, SEL _cmd);
		FloatGetterIMP getter = (FloatGetterIMP)[likeShip methodForSelector:likeSelector];
		if (getter != NULL)
		{
			result = getter(likeShip, likeSelector);
		}
	}
	
	return result;
}


static Vector ReadLegacyVector(NSDictionary *shipdata, NSString *key, OOShipClass *likeShip, SEL likeSelector, Vector defaultValue)
{
	NSString *vecString = [shipdata oo_stringForKey:key];
	Vector result = defaultValue;
	if (vecString != nil)
	{
		ScanVectorFromString(vecString, &result);
	}
	else if (likeShip != nil)
	{
		typedef Vector (*VectorGetterIMP)(id self, SEL _cmd);
		VectorGetterIMP getter = (VectorGetterIMP)[likeShip methodForSelector:likeSelector];
		if (getter != NULL)
		{
			result = getter(likeShip, likeSelector);
		}
	}
	
	return result;
}


// N.B.: returns owning reference (hence name not being ReadRole).
static OORoleSet *NewRoleSetFromProperty(NSDictionary *shipdata, NSString *key, OOShipClass *likeShip, SEL likeSelector, NSString *defaultValue)
{
	NSString *role = [shipdata objectForKey:key];
	if (role == nil && likeShip != nil)
	{
		role = [likeShip performSelector:likeSelector];
	}
	if (role == nil)  role = defaultValue;
	if (role != nil)
	{
		return [[OORoleSet alloc] initWithRole:role probability:1];
	}
	else  return nil;
}


/*	These macros abstract the process of reading values, applying defaults and
	inheriting from like_ship. The defaults are macros defined above.
	
	The types are:
	ARRAY
	BOOL
	DICT
	FLOAT
	FUZZY	(A chance value for a “fuzzy boolean” value, ranging from 0 to 1)
	PFLOAT	(A float no lower than 0)
	ROLE	(A string put into a single-role OORoleSet with probability of 1)
	STRING
	UINT
	VECTOR
*/

#define READ_ARRAY(NAME, KEY)	_##NAME = [[shipdata oo_arrayForKey:@KEY defaultValue:(likeShip != nil) ? [likeShip NAME] : kDefault_##NAME] copy]

#define READ_BOOL(NAME, KEY)	_##NAME = [shipdata oo_boolForKey:@KEY defaultValue:(likeShip != nil) ? [likeShip NAME] : kDefault_##NAME]

#define READ_DICT(NAME, KEY)	_##NAME = [[shipdata oo_dictionaryForKey:@KEY defaultValue:(likeShip != nil) ? [likeShip NAME] : kDefault_##NAME] copy]

#define READ_FLOAT(NAME, KEY)	_##NAME = [shipdata oo_floatForKey:@KEY defaultValue:(likeShip != nil) ? [likeShip NAME] : kDefault_##NAME]

#define READ_FUZZY(NAME, KEY)	_##NAME = ReadLegacyChance(shipdata, @KEY, likeShip, @selector(NAME), kDefault_##NAME)

#define READ_PFLOAT(NAME, KEY)	_##NAME = fmaxf(0.0f, [shipdata oo_floatForKey:@KEY defaultValue:(likeShip != nil) ? [likeShip NAME] : kDefault_##NAME])

#define READ_ROLE(NAME, KEY)	_##NAME = NewRoleSetFromProperty(shipdata, @KEY, likeShip, @selector(NAME), kDefault_##NAME)

#define READ_STRING(NAME, KEY)	_##NAME = [[shipdata oo_stringForKey:@KEY defaultValue:(likeShip != nil) ? [likeShip NAME] : kDefault_##NAME] copy]

#define READ_UINT(NAME, KEY)	_##NAME = [shipdata oo_unsignedIntegerForKey:@KEY defaultValue:(likeShip != nil) ? [likeShip NAME] : kDefault_##NAME]

#define READ_VECTOR(NAME, KEY)	_##NAME = ReadLegacyVector(shipdata, @KEY, likeShip, @selector(name), kDefault_##NAME)


@implementation OOShipClass (Legacy)

- (id) initWithKey:(NSString *)key
	   legacyPList:(NSDictionary *)legacyPList
		knownShips:(NSDictionary *)knownShips
   problemReporter:(id<OOProblemReporting>)issues
{
	NSParameterAssert(key != nil);
	
	if ((self = [self init]))
	{
		_shipKey = [key copy];
		if (![self priv_loadFromLegacyPList:legacyPList knownShips:knownShips problemReporter:issues])
		{
			DESTROY(self);
		}
	}
	
	return self;
}


- (BOOL) priv_loadFromLegacyPList:(NSDictionary *)shipdata
					   knownShips:(NSDictionary *)knownShips
				  problemReporter:(id<OOProblemReporting>)issues
{
	NSString *shipKey = [self shipKey];
	
	OOShipClass *likeShip = nil;
	NSString *likeShipKey = [shipdata oo_stringForKey:@"like_ship"];
	if (likeShipKey != nil)
	{
		likeShip = [knownShips objectForKey:likeShipKey];
		if (likeShip == nil)
		{
			OOReportError(issues, @"Ship %@ has unresolved like_ship dependency to %@.", shipKey, likeShipKey);
			return NO;
		}
	}
	
	// These three values aren’t inherited.
	_isTemplate = [shipdata oo_boolForKey:@"is_template"];
	_isExternalDependency = [shipdata oo_boolForKey:@"is_external_dependency"];
	_displayName = [[shipdata oo_stringForKey:@"display_name"] copy];
	
	READ_STRING	(name,					"name");
	
	OOScanClass scanClass = OOScanClassFromString([shipdata oo_stringForKey:@"scan_class" defaultValue:@"CLASS_NOT_SET"]);
	if (scanClass == CLASS_NOT_SET)  scanClass = OOScanClassFromString([shipdata oo_stringForKey:@"scanClass" defaultValue:@"CLASS_NOT_SET"]);
	if (scanClass != CLASS_NOT_SET)  _scanClass = scanClass;
	else if (_likeShip != nil)  scanClass = [likeShip scanClass];
	
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
	else if (likeShip != nil)  _autoAI = [likeShip autoAI];
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
		else  _materialDefinitions = [[likeShip materialDefinitions] copy];
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
	
	/*	Load scanner lollipop colours. This doesn’t correctly handle the case
		where a ship is like_shipped to another and only overrides one colour
		while inheriting the other. I can live with this.
		-- Ahruman 2011-03-18
	 */
	OOColor *scannerColor1 = [OOColor colorWithDescription:[shipdata objectForKey:@"scanner_display_color1"]];
	OOColor *scannerColor2 = [OOColor colorWithDescription:[shipdata objectForKey:@"scanner_display_color2"]];
	if (scannerColor1 == nil)
	{
		if (scannerColor2 != nil)  _scannerColors = $array(scannerColor2);
		else _scannerColors = [[likeShip scannerColors] copy];
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
		esorts). We also want to avoid including the unique role for the parent
		ship if like_shipped.
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
		// No roles specified; inherited or empty list.
		if (_roles == nil)  _roles = [[OORoleSet alloc] initWithRole:uniqueRole probability:1];
		else
		{
			[_roles autorelease];
			_roles = [[[_roles roleSetWithRemovedRole:UniqueRoleForShipKey([[self likeShip] shipKey])] roleSetWithAddedRole:uniqueRole probability:1] retain];
		}
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
		if (_escortRoles == nil)  _escortRoles = [[likeShip escortRoles] copy];
		if (_escortRoles == nil)  _escortRoles = [[OORoleSet alloc] initWithRole:kDefault_escortRoles probability:1];
	}
	
	READ_VECTOR	(forwardViewPosition,	"view_position_forward");
	READ_VECTOR	(aftViewPosition,		"view_position_aft");
	READ_VECTOR	(portViewPosition,		"view_position_port");
	READ_VECTOR	(starboardViewPosition,	"view_position_starboard");
	READ_ARRAY	(customViews,			"custom_views");
	
	READ_UINT	(cargoSpaceCapacity,	"max_cargo");
	READ_UINT	(cargoSpaceUsedMax,		"likely_cargo");
	_cargoSpaceUsedMin = MAX([likeShip cargoSpaceUsedMin], _cargoSpaceUsedMax);
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
	else if (likeShip != nil)
	{
		_cargoType = [likeShip cargoType];
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
	
	return YES;
}

@end
