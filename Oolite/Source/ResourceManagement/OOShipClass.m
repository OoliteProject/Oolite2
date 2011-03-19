/*

OOShipClass.m


Oolite
Copyright © 2004–2011 Giles C Williams and contributors

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

#import "OOShipClass.h"
#import "OOShipRegistry.h"
#import "OORoleSet.h"
#import "OOEquipmentType.h"
#import "OOColor.h"
#import "OOStringParsing.h"
#import "OOConstToString.h"


NSString * const kOODefaultHUDName					= @"hud.plist";
NSString * const kOODefaultEscapePodRole			= @"escape-capsule";
NSString * const kOODefaultShipScriptName			= @"oolite-default-ship-script.js";
NSString * const kOODefaultShipAIName				= @"nullAI.plist";
NSString * const kOODefaultEscortRole				= @"escort";
NSString * const kOODefaultDebrisRole				= @"boulder";

#define kKeyKey						((NSString *)@"key")
#define kProbabilityKey				((NSString *)@"probability")


@interface OOShipClass (OOPrivate)

- (BOOL) priv_loadFromLegacyPList:(NSDictionary *)legacyPList
					   knownShips:(NSDictionary *)knownShips
				  problemReporter:(id<OOProblemReporting>)issues;

@end


@implementation OOShipClass

- (id) init
{
	if ((self = [super init]))
	{
		// Set up non-zero defaults, prior to any likeShipping.
		_scanClass = CLASS_NOT_SET;
		_density = 1.0f;
		_cargoType = CARGO_NOT_CARGO;
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_likeShip);
	DESTROY(_shipKey);
	DESTROY(_name);
	DESTROY(_displayName);
	DESTROY(_beaconCode);
	DESTROY(_HUDName);
	DESTROY(_pilotKey);
	DESTROY(_escapePodRole);
	DESTROY(_scriptName);
	DESTROY(_AIName);
	DESTROY(_scriptInfo);
	DESTROY(_modelName);
	DESTROY(_materialDefinitions);
	DESTROY(_exhaustDefinitions);
	DESTROY(_scannerColors);
	DESTROY(_roles);
	DESTROY(_subentityDefinitions);
	DESTROY(_escortRoles);
	DESTROY(_customViews);
	DESTROY(_cargoCarried);
	DESTROY(_laserColor);
	DESTROY(_missileRoles);
	DESTROY(_equipment);
	DESTROY(_debrisRoles);
	DESTROY(_defenseShipRoles);
	DESTROY(_marketKey);
	
	[super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
	// OOShipClass is outwardly immutable.
	return [self retain];
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"%@ \"%@\"", [self shipKey], [self name]);
}


// MARK: Legacy plist support

static NSString *UniqueRoleForShipKey(NSString *key)
{
	return $sprintf(@"_oo_unique_role_for_%@", key);
}


static float ReadLegacyChance()
{
	
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
	
	/*	Note that many defaults/fallbacks are implemented in accessors and
		don’t need to be handled here. This is good because it means the same
		defaults will be applied regardless of how the data was loaded.
		If we want different behaviour for different sources, the exceptions
		should be handled in the loaders. Numerical defaults are explicit partly
		for this reason and partly because defining marker values for fallbacks
		is more trouble than it’s worth.
		
		On the other hand, everything specifies its existing value as the
		defaultValue:, to implement like_ship.
		
		If anything in this loader seems strange, remember that it’s designed
		for maximum compatibility with 1.76 and any behaviour changes should
		be made with that as the standard.
	*/
	
	#define READ_BOOL_D(NAME, KEY, DEFAULT) _##NAME = [shipdata oo_boolForKey:@KEY defaultValue:(likeShip != nil) ? [likeShip NAME] : DEFAULT]
	#define READ_BOOL(NAME, KEY) READ_BOOL_D(NAME, KEY, NO)
	
	#define READ_FUZZY_D(NAME, KEY, DEFAULT) _##NAME = ReadLegacyChance()
	#define READ_FUZZY(NAME, KEY) READ_FUZZY_D(NAME, KEY, NO)
	
	#define READ_STRING_D(NAME, KEY, DEFAULT) _##NAME = [[shipdata oo_stringForKey:@KEY defaultValue:(likeShip != nil) ? [likeShip NAME] : DEFAULT] copy]
	#define READ_STRING(NAME, KEY) READ_STRING_D(NAME, KEY, ((NSString *)nil))
	
	_isTemplate = [shipdata oo_boolForKey:@"is_template"];	// Does not inherit.
	_isExternalDependency = [shipdata oo_boolForKey:@"is_external_dependency"];	// Does not inherit; caller is responsible for testing.
	
	READ_STRING(name, "name");
	_displayName = [[shipdata oo_stringForKey:@"display_name"] copy];	// Does not inherit for 1.x.
	
	OOScanClass scanClass = OOScanClassFromString([shipdata oo_stringForKey:@"scan_class" defaultValue:@"CLASS_NOT_SET"]);
	if (scanClass == CLASS_NOT_SET)  scanClass = OOScanClassFromString([shipdata oo_stringForKey:@"scanClass" defaultValue:@"CLASS_NOT_SET"]);
	if (scanClass != CLASS_NOT_SET)  _scanClass = scanClass;
	else if (_likeShip != nil)  scanClass = [likeShip scanClass];
	
	READ_STRING(beaconCode, "beacon");
	READ_BOOL(isHulk, "is_hulk");
	READ_STRING(HUDName, "hud");
	
	READ_STRING(pilotKey, "pilot");
	id fuzzy = [shipdata objectForKey:@"unpiloted"];
	if (fuzzy != nil)  _unpilotedChance = OOFuzzyBooleanProbabilityFromObject(fuzzy, 0.0f);
	else if (_likeShip != nil)  _unpilotedChance = [likeShip unpilotedChance];
	_escapePodRole = [[shipdata oo_stringForKey:@"escape_pod_model" defaultValue:[likeShip escapePodRole]] copy];
	_countsAsKill = [shipdata oo_boolForKey:@"counts_as_kill" defaultValue:likeShip ? [likeShip countsAsKill] : YES];
	
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
	_scriptName = [[shipdata oo_stringForKey:@"script" defaultValue:[likeShip scriptName]] copy];
	_AIName = [[shipdata oo_stringForKey:@"ai_type" defaultValue:[likeShip AIName]] copy];
	_scriptInfo = [[shipdata oo_dictionaryForKey:@"script_info" defaultValue:[likeShip scriptInfo]] copy];
	
	_modelName = [[shipdata oo_stringForKey:@"model" defaultValue:[likeShip modelName]] copy];
	
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
			/*	Merge the two material dictionaries, with "shaders" overriding
				"materials" since 2.x always has shaders.
				FIXME: this might not be the right thing, since the actual shaders
				are expected to stop working in 2.x.
				-- Ahruman 2011-03-18
			*/
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
	_exhaustDefinitions = [[shipdata oo_arrayForKey:@"exhaust" defaultValue:_exhaustDefinitions] copy];
	
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
	
	_bounty = [shipdata oo_unsignedIntegerForKey:@"bounty" defaultValue:_bounty];
	_density = fmaxf(0.0f, [shipdata oo_floatForKey:@"density" defaultValue:_density]);
	
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
	_subentityDefinitions = [[shipdata oo_arrayForKey:@"subentities" defaultValue:_subentityDefinitions] copy];
	_escortCount = [shipdata oo_unsignedIntegerForKey:@"escorts" defaultValue:_escortCount];
	if (_escortCount > 16)  _escortCount = 16;	// 1.x limit, should stay 16 even if 2.0 limit is raised.
	
	/*	Set up escort roles. 1.x has two options here: escort_ship (a ship key)
		or escort_role, with escort_ship taking priority. For 2.x, we only
		support roles, but we also add each ship’s key as a hopefully-unique
		role.
	*/
	NSString *escort = [shipdata oo_stringForKey:@"escort_ship"];
	if (escort != nil)  _escortRoles = [[OORoleSet alloc] initWithRole:UniqueRoleForShipKey(escort) probability:1];
	else
	{
		escort = [shipdata oo_stringForKey:@"escort_role"];
		if (escort != nil)  _escortRoles = [[OORoleSet alloc] initWithRole:escort probability:1];
		else  _escortRoles = [[likeShip escortRoles] copy];
	}
	
	_forwardViewPosition = ReadLegacyVector(shipdata, @"view_position_forward", likeShip, @selector(forwardViewPosition), kZeroVector);
	_aftViewPosition = ReadLegacyVector(shipdata, @"view_position_aft", likeShip, @selector(aftViewPosition), kZeroVector);
	_portViewPosition = ReadLegacyVector(shipdata, @"view_position_port", likeShip, @selector(portViewPosition), kZeroVector);
	_starboardViewPosition = ReadLegacyVector(shipdata, @"view_position_starboard", likeShip, @selector(starboardViewPosition), kZeroVector);
	_customViews = [[shipdata oo_arrayForKey:@"custom_views" defaultValue:[likeShip customViews]] copy];
	
	_cargoSpaceCapacity = [shipdata oo_unsignedIntegerForKey:@"max_cargo" defaultValue:[likeShip cargoSpaceCapacity]];
	_cargoSpaceUsedMin = [likeShip cargoSpaceUsedMin];
	_cargoSpaceUsedMax = [shipdata oo_unsignedIntegerForKey:@"likely_cargo" defaultValue:[likeShip cargoSpaceUsedMax]];
	_cargoBayExpansionSize = [shipdata oo_unsignedIntegerForKey:@"extra_cargo" defaultValue:likeShip ? [likeShip cargoBayExpansionSize] : 15];
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
	
	_energyCapacity = [shipdata oo_floatForKey:@"max_energy" defaultValue:likeShip ? [likeShip energyCapacity] : 200.0f];
	_energyRechargeRate = [shipdata oo_floatForKey:@"energy_recharge_rate" defaultValue:likeShip ? [likeShip energyRechargeRate] : 1.0f];
	_fuelCapacity = 70;
	// Note: as per 1.x, fuel defaults to 0.
	_initialFuel = [shipdata oo_unsignedIntegerForKey:@"fuel" defaultValue:[likeShip initialFuel]];
	if (_initialFuel > _fuelCapacity)  _fuelCapacity = _initialFuel;	// 1.x has no explicit fuel capacity.	
	_fuelChargeRate = [shipdata oo_floatForKey:@"fuel_charge_rate" defaultValue:likeShip ? [likeShip fuelChargeRate] : 1.0];
	
	
	
	return YES;
}


// MARK: Property accessors

- (BOOL) isTemplate
{
	return _isTemplate;
}


- (BOOL) isExternalDependency
{
	return _isExternalDependency;
}


- (OOShipClass *) likeShip
{
	return _likeShip;
}


- (NSString *) shipKey
{
	return _shipKey;
}


- (NSString *) name
{
	return _name ?: [self shipKey];
}


- (NSString *) displayName
{
	return _displayName ?: [self name];
}


- (OOScanClass) scanClass
{
	return _scanClass;
}


- (NSString *) beaconCode
{
	return _beaconCode;
}


- (BOOL) isHulk
{
	return _isHulk;
}


- (NSString *) HUDName
{
	return _HUDName ?: kOODefaultHUDName;
}


- (NSString *) pilotKey
{
	return _pilotKey;	// Default depends on context.
}


- (float) unpilotedChance
{
	return _unpilotedChance;
}


- (BOOL) selectUnpiloted
{
	return randf() < [self unpilotedChance];
}


- (NSString *) escapePodRole
{
	return _escapePodRole ?: kOODefaultEscapePodRole;
}


- (BOOL) countsAsKill
{
	return _countsAsKill;
}


- (NSString *) scriptName
{
	return _scriptName ?: kOODefaultShipScriptName;
}


- (NSDictionary *) scriptInfo
{
	return _scriptInfo;
}


- (BOOL) hasScoopMessage
{
	return _hasScoopMessage;
}


- (NSString *) AIName
{
	return _AIName ?: kOODefaultShipAIName;
}


- (BOOL) trackContacts
{
	return _trackContacts;
}


- (BOOL) autoAI
{
	return _autoAI;
}


- (NSString *) modelName
{
	return _modelName;
}


- (BOOL) smooth
{
	return _smooth;
}


- (NSDictionary *) materialDefinitions
{
	return _materialDefinitions;
}


- (NSArray *) exhaustDefinitions
{
	return _exhaustDefinitions;
}


- (NSArray *) scannerColors
{
	return _scannerColors;
}


- (float) scannerRange
{
	return _scannerRange;
}


- (OOCreditsQuantity) bounty
{
	return _bounty;
}


- (float) density
{
	return _density;
}


- (OORoleSet *) roles
{
	return _roles;
}


- (NSArray *) subentityDefinitions
{
	return _subentityDefinitions;
}


- (BOOL) isFrangible
{
	return _isFrangible;
}


- (OOUInteger) escortCount
{
	return _escortCount;
}


- (OORoleSet *) escortRoles
{
	return _escortRoles;
}


- (NSString *) selectEscortShip
{
	OORoleSet *roleSet = [self escortRoles];
	NSString *role = nil;
	
	if (roleSet != nil)  role = [roleSet anyRole];
	if (role == nil)  role = kOODefaultEscortRole;
	
	if (role != nil)  return [[OOShipRegistry sharedRegistry] randomShipKeyForRole:role];
	return nil;
}


- (Vector) forwardViewPosition
{
	return _forwardViewPosition;
}


- (Vector) aftViewPosition
{
	return _aftViewPosition;
}


- (Vector) portViewPosition
{
	return _portViewPosition;
}


- (Vector) starboardViewPosition
{
	return _starboardViewPosition;
}


- (NSArray *) customViews
{
	return _customViews;
}


- (NSUInteger) cargoSpaceCapacity
{
	return _cargoSpaceCapacity;
}


- (NSUInteger) cargoSpaceUsedMin
{
	return _cargoSpaceUsedMin;
}


- (NSUInteger) cargoSpaceUsedMax
{
	return _cargoSpaceUsedMax;
}


- (NSUInteger) selectCargoSpaceUsed
{
	NSUInteger max = MIN([self cargoSpaceUsedMax], [self cargoSpaceCapacity]);
	NSUInteger min = MIN([self cargoSpaceUsedMin], max);
	if (min == max)  return max;
	
	return min + Ranrot() % (max - min);
}


- (NSUInteger) cargoBayExpansionSize
{
	return _cargoBayExpansionSize;
}


- (OOCargoType) cargoType
{
	return _cargoType;
}


- (NSString *) cargoCarried
{
	return _cargoCarried;
}


- (float) energyCapacity
{
	return _energyCapacity;
}


- (float) energyRechargeRate
{
	return _energyRechargeRate;
}


- (OOFuelQuantity) fuelCapacity
{
	return _fuelCapacity;
}


- (OOFuelQuantity) initialFuel
{
	return _initialFuel;
}


- (float) fuelChargeRate
{
	return _fuelChargeRate;
}


- (float) heatInsulation
{
	return _heatInsulation;
}


- (float) maxFlightSpeed
{
	return _maxFlightSpeed;
}


- (float) maxFlightRoll
{
	return _maxFlightRoll;
}


- (float) maxFlightPitch
{
	return _maxFlightPitch;
}


- (float) maxFlightYaw
{
	return _maxFlightYaw;
}


- (float) maxThrust
{
	return _maxThrust;
}


- (BOOL) hasHyperspaceMotor
{
	return _hasHyperspaceMotor;
}


- (float) hyperspaceMotorSpinTime
{
	return _hyperspaceMotorSpinTime;
}


- (float) accuracy
{
	return _accuracy;
}


- (OOWeaponType) forwardWeaponType
{
	return _forwardWeaponType;
}


- (OOWeaponType) aftWeaponType
{
	return _aftWeaponType;
}


- (OOWeaponType) portWeaponType
{
	return _portWeaponType;
}


- (OOWeaponType) starboardWeaponType
{
	return _starboardWeaponType;
}


- (Vector) forwardWeaponPosition
{
	return _forwardWeaponPosition;
}


- (Vector) aftWeaponPosition
{
	return _aftWeaponPosition;
}


- (Vector) portWeaponPosition
{
	return _portWeaponPosition;
}


- (Vector) starboardWeaponPosition
{
	return _starboardWeaponPosition;
}


- (float) weaponEnergy
{
	return _weaponEnergy;
}


- (float) weaponRange
{
	return _weaponRange;
}


- (OOColor *) laserColor
{
	return _laserColor;
}


- (NSUInteger) missileCapacity
{
	return _missileCapacity;
}


- (NSUInteger) missileCountMin
{
	return _missileCountMin;
}


- (NSUInteger) missileCountMax
{
	return _missileCountMax;
}


- (NSUInteger) selectMissileCount
{
	NSUInteger max = MIN([self missileCountMax], [self missileCapacity]);
	NSUInteger min = MIN([self missileCountMin], max);
	if (min == max)  return max;
	
	return min + Ranrot() % (max - min);
}


- (OORoleSet *) missileRoles
{
	if (_missileRoles != nil)  return _missileRoles;
	
	static OORoleSet *defaultMissileRoles = nil;
	if (defaultMissileRoles == nil)
	{
		defaultMissileRoles = [[OORoleSet alloc] initWithRoleString:@"EQ_MISSILE(8) missile(2)"];
	}
	return defaultMissileRoles;
}


- (NSMutableArray *) selectMissiles
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self missileCapacity]];
	NSUInteger count = [self selectMissileCount];
	
	if (count != 0)
	{
		OORoleSet *missileRoles = [self missileRoles];
		do
		{
			NSString *role = [missileRoles anyRole];
			NSString *shipKey = [UNIVERSE randomShipKeyForRoleRespectingConditions:role];
			if (shipKey == nil)
			{
				OOLogERR(@"ship.setUp.missiles.invalid", @"Missile role %@ for ship %@ does not specify a ship.", role, [self shipKey]);
			}
			else
			{
				NSString *eqKey = [OOEquipmentType getMissileRegistryRoleForShip:shipKey];
				if (eqKey == nil)
				{
					OOLogERR(@"ship.setUp.missiles.invalid", @"Missile role %@ for ship %@ does not resolve to an equipment type.", role, [self shipKey]);
				}
				else
				{
					OOEquipmentType *eqType = [OOEquipmentType equipmentTypeWithIdentifier:eqKey];
					if (![eqType isMissileOrMine])
					{
						OOLogERR(@"ship.setUp.missiles.invalid", @"Missile role %@ for ship %@ does not resolve to a missile equipment type.", role, [self shipKey]);
					}
					else
					{
						[result addObject:eqType];
					}
				}
			}
		} while (--count);
	}
	
	return result;
}


- (BOOL) isSubmunition
{
	return _isSubmunition;
}


- (BOOL) cloakIsPassive
{
	return _cloakIsPassive;
}


- (BOOL) cloakIsAutomatic
{
	return _cloakIsAutomatic;
}


- (NSArray *) equipment
{
	return _equipment;
}


- (NSArray *) selectEquipment
{
	NSArray			*eqDefs = [self equipment];
	NSMutableArray	*result = [NSMutableArray arrayWithCapacity:[eqDefs count]];
	NSDictionary	*eqDict = nil;
	
	foreach (eqDict, eqDefs)
	{
		NSAssert([eqDict isKindOfClass:[NSDictionary class]], @"Non-NSDictionary in ostensibly sanitized OOShipClass equipment array.");
		
		NSString		*key = [eqDict oo_stringForKey:kKeyKey];
		OOEquipmentType	*eqType = [OOEquipmentType equipmentTypeWithIdentifier:key];
		float			probability = OOClamp_0_1_f([eqDict oo_floatForKey:kProbabilityKey]);
		
		if (eqType == nil)
		{
			OOLogERR(@"ship.setUp.equipment.invalid", @"Ship %@ specifies unknown equipment type %@.", [self shipKey], key);
		}
		else if (randf() < probability)
		{
			[result addObject:eqType];
		}
	}
	
#ifndef NDEBUG
	return [[result copy] autorelease];
#else
	return result;
#endif
}


- (float) fragmentChance
{
	return _fragmentChance;
}


- (BOOL) selectCanFragment
{
	return randf() < [self fragmentChance];
}


- (float) noBouldersChance
{
	return _fragmentChance;
}


- (BOOL) selectNoBoulders
{
	return randf() < _noBouldersChance;
}


- (OORoleSet *) debrisRoles
{
	return _debrisRoles;
}


- (NSString *) selectDebrisRole
{
	return [[self debrisRoles] anyRole] ?: kOODefaultDebrisRole;
}


- (BOOL) isRotating
{
	return _isRotating;
}


- (Quaternion) rotationalVelocity
{
	return _rotationalVelocity;
}


- (Vector) scoopPosition
{
	return _scoopPosition;
}


- (Vector) aftEjectPosition
{
	return _aftEjectPosition;
}


- (BOOL) isCarrier
{
	return _isCarrier;
}


- (float) stationRoll
{
	return [self isCarrier] ? _stationRoll : 0.0f;
}


- (float) hasNPCTrafficChance
{
	return [self isCarrier] ? _hasNPCTrafficChance : 0.0f;
}


- (BOOL) selectHasNPCTraffic
{
	return randf() < [self hasNPCTrafficChance];
}


- (float) hasPatrolShipsChance
{
	return [self isCarrier] ? _hasPatrolShipsChance : 0.0f;	
}


- (BOOL) selectHasPatrolShips
{
	return randf() < [self hasPatrolShipsChance];
}


- (NSUInteger) maxScavengers
{
	return [self isCarrier] ? _maxScavengers : 0;
}


- (NSUInteger) maxDefenseShips
{
	return [self isCarrier] ? _maxDefenseShips : 0;
}


- (OORoleSet *) defenseShipRoles
{
	return _defenseShipRoles;
}


- (NSUInteger) maxPolice
{
	return _maxPolice;
}


- (OOTechLevelID) equivalentTechLevel
{
	return _equivalentTechLevel;
}


- (float) equipmentPriceFactor
{
	return _equipmentPriceFactor;
}


- (NSString *) marketKey
{
	return _marketKey;
}


- (BOOL) hasShipyard
{
	return _hasShipyard;
}


- (BOOL) requiresDockingClearance
{
	return _requiresDockingClearance;
}


- (BOOL) allowsInterstellarUndocking
{
	return _allowsInterstellarUndocking;
}


- (BOOL) allowsAutoDocking
{
	return _allowsAutoDocking;
}


- (BOOL) allowsFastDocking
{
	return _allowsFastDocking;
}


- (NSUInteger) dockingTunnelCorners
{
	return _dockingTunnelCorners;
}


- (float) dockingTunnelStartAngle
{
	return _dockingTunnelStartAngle;
}


- (float) dockingTunnelAspectRatio
{
	return _dockingTunnelAspectRatio;
}

@end
