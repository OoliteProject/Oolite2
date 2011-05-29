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
#import "OOConstToString.h"
#import "OOShipRegistry.h"


NSString * const kOODefaultHUDName			= @"hud.plist";
NSString * const kOODefaultEscapePodRole	= @"escape-capsule";
NSString * const kOODefaultShipScriptName	= @"oolite-default-ship-script.js";
NSString * const kOODefaultShipAIName		= @"nullAI.plist";
NSString * const kOODefaultEscortRole		= @"escort";
NSString * const kOODefaultDebrisRole		= @"boulder";

NSString * const kOOShipClassEquipmentKeyKey = @"key";
NSString * const kOOShipClassEquipmentChanceKey = @"chance";


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
	DESTROY(_likeShipKey);
	DESTROY(_shipKey);
	DESTROY(_name);
	DESTROY(_displayName);
	DESTROY(_beaconCode);
	DESTROY(_HUDName);
	DESTROY(_pilotKey);
	DESTROY(_escapePodRoles);
	DESTROY(_scriptName);
	DESTROY(_AIName);
	DESTROY(_scriptInfo);
	DESTROY(_modelName);
	DESTROY(_materialDefinitions);
	DESTROY(_exhaustDefinitions);
	DESTROY(_scannerColors);
	DESTROY(_roles);
	DESTROY(_subEntityDefinitions);
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


// MARK: Property accessors

- (NSString *) likeShipKey
{
	return _likeShipKey;
}


- (OOShipClass *) likeShip
{
	return (_likeShipKey == nil) ? nil : [[OOShipRegistry sharedRegistry] shipClassForKey:_likeShipKey];
}


- (BOOL) isTemplate
{
	return _isTemplate;
}


- (BOOL) isExternalDependency
{
	return _isExternalDependency;
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


- (NSUInteger) escapePodCount
{
	return _escapePodCount;
}


- (OORoleSet *) escapePodRoles
{
	if (_escapePodRoles != nil)  return _escapePodRoles;
	
	static OORoleSet *defaultEscapePodRoleSet = nil;
	if (defaultEscapePodRoleSet == nil)
	{
		defaultEscapePodRoleSet = [[OORoleSet alloc] initWithRole:kOODefaultEscapePodRole probability:1];
	}
	return defaultEscapePodRoleSet;
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


- (BOOL) trackCloseContacts
{
	return _trackCloseContacts;
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


- (NSArray *) subEntityDefinitions
{
	return _subEntityDefinitions;
}


- (BOOL) isFrangible
{
	return _isFrangible;
}


- (OOUInteger) escortCount
{
	return MIN(_escortCount, MAX_ESCORTS);
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


- (float) turretRange
{
	return _turretRange;
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
		
		NSString		*key = [eqDict oo_stringForKey:kOOShipClassEquipmentKeyKey];
		OOEquipmentType	*eqType = [OOEquipmentType equipmentTypeWithIdentifier:key];
		float			probability = OOClamp_0_1_f([eqDict oo_floatForKey:kOOShipClassEquipmentChanceKey]);
		
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
	return _noBouldersChance;
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


- (BOOL) isBallTurret
{
	return _isBallTurret;
}

@end


@implementation OOShipExhaustDefinition

- (id) initWithPosition:(Vector)position width:(float)width height:(float)height
{
	if ((self = [super init]))
	{
		_position = position;
		_width = width;
		_height = height;
	}
	
	return self;
}


- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}


- (Vector) position
{
	return _position;
}


- (float) width
{
	return _width;
}


- (float) height
{
	return _height;
}

@end


@interface OOSolidSubEntityDefinition: OOShipSubEntityDefinition <JAPropertyListRepresentation>
{
@private
	OOSubEntityType		_type;
	NSString			*_shipKey;
	Quaternion			_orientation;
}

- (id) initWithType:(OOSubEntityType)type
			shipKey:(NSString *)key
		   position:(Vector)position
		orientation:(Quaternion)orientation;

@end


@interface OOBallTurretSubEntityDefinition: OOSolidSubEntityDefinition
{
@private
	float				_fireRate;
}

- (id) initWithShipKey:(NSString *)shipKey
			  position:(Vector)position
		   orientation:(Quaternion)orientation
			  fireRate:(float)fireRate;

@end


@interface OOFlasherSubEntityDefinition: OOShipSubEntityDefinition <JAPropertyListRepresentation>
{
@private
	NSArray				*_colors;
	float				_frequency;
	float				_phase;
	float				_size;
	BOOL				_initiallyOn;
}

- (id) initWithPosition:(Vector)position
				 colors:(NSArray *)colors
			  frequency:(float)frequency
				  phase:(float)phase
				   size:(float)size
			initiallyOn:(BOOL)initiallyOn;

@end


@implementation OOShipSubEntityDefinition

+ (id) definitionWithType:(OOSubEntityType)type shipKey:(NSString *)key position:(Vector)position orientation:(Quaternion)orientation
{
	if (type == kOOSubEntityBallTurret)
	{
		return [[[OOBallTurretSubEntityDefinition alloc] initWithShipKey:key position:position orientation:orientation fireRate:kOOBallTurretDefaultFireRate] autorelease];
	}
	else
	{
		return [[[OOSolidSubEntityDefinition alloc] initWithType:type shipKey:key position:position orientation:orientation] autorelease];
	}
}


+ (id) definitionForBallTurretWithShipKey:(NSString *)key position:(Vector)position orientation:(Quaternion)orientation fireRate:(float)fireRate
{
	return [[[OOBallTurretSubEntityDefinition alloc] initWithShipKey:key position:position orientation:orientation fireRate:fireRate] autorelease];
}


+ (id) definitionForFlasherWithPosition:(Vector)position colors:(NSArray *)colors frequency:(float)frequency phase:(float)phase size:(float)size initiallyOn:(BOOL)initiallyOn
{
	return [[[OOFlasherSubEntityDefinition alloc] initWithPosition:position colors:colors frequency:frequency phase:phase size:size initiallyOn:initiallyOn] autorelease];
}


- (id) initWithPosition:(Vector)position
{
	if ((self = [super init]))
	{
		_position = position;
	}
	
	return self;
}


- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}


static NO_RETURN_FUNC void RaiseNotApplicable(const char *function)
{
	[NSException raise:NSInternalInconsistencyException format:@"%s is not applicable.", function];
	OO_UNREACHABLE();
}


- (Vector) position
{
	return _position;
}


- (OOSubEntityType) type
{
	RaiseNotApplicable(__FUNCTION__);
}


- (NSString *) shipKey
{
	RaiseNotApplicable(__FUNCTION__);
}


- (OOShipClass *) shipClass
{
	RaiseNotApplicable(__FUNCTION__);
}


- (Quaternion) orientation
{
	RaiseNotApplicable(__FUNCTION__);
}


- (float) fireRate
{
	RaiseNotApplicable(__FUNCTION__);
}


- (NSArray *) colors
{
	RaiseNotApplicable(__FUNCTION__);
}


- (float) frequency
{
	RaiseNotApplicable(__FUNCTION__);
}


- (float) phase
{
	RaiseNotApplicable(__FUNCTION__);
}


- (float) size
{
	RaiseNotApplicable(__FUNCTION__);
}


- (BOOL) initiallyOn
{
	RaiseNotApplicable(__FUNCTION__);
}

@end


@implementation OOSolidSubEntityDefinition

- (id) initWithType:(OOSubEntityType)type
			shipKey:(NSString *)key
		   position:(Vector)position
		orientation:(Quaternion)orientation
{
	NSParameterAssert(type == kOOSubEntityNormal || type == kOOSubEntityBallTurret || type == kOOSubEntityDock);
	NSParameterAssert(key != nil);
	
	if ((self = [super initWithPosition:position]))
	{
		_type = type;
		_shipKey = [key copy];
		if (!quaternion_equal(orientation, kZeroQuaternion))
		{
			_orientation = orientation;
		}
		else
		{
			_orientation = kIdentityQuaternion;
		}
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_shipKey);
	
	[super dealloc];
}


- (NSString *) shipKey
{
	return _shipKey;
}


- (OOShipClass *) shipClass
{
	return [[OOShipRegistry sharedRegistry] shipClassForKey:_shipKey];
}


- (Quaternion) orientation
{
	return _orientation;
}


- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	if (_type != kOOSubEntityNormal)
	{
		[result setObject:OOStringFromSubEntityType(_type) forKey:@"type"];
	}
	if (!vector_equal([self position], kZeroVector))
	{
		[result oo_setVector:[self position] forKey:@"position"];
	}
	
	if (!quaternion_equal(_orientation, kIdentityQuaternion))
	{
		[result oo_setQuaternion:_orientation forKey:@"orientation"];
	}
	
	[result setObject:[self shipKey] forKey:@"shipKey"];
	
	if (_type == kOOSubEntityBallTurret)
	{
		float fireRate = [self fireRate];
		if (fireRate != kOOBallTurretDefaultFireRate)
		{
			[result oo_setFloat:fireRate forKey:@"fireRate"];
		}
	}
	
	return result;
}

@end


@implementation OOFlasherSubEntityDefinition

- (id) initWithPosition:(Vector)position
				 colors:(NSArray *)colors
			  frequency:(float)frequency
				  phase:(float)phase
				   size:(float)size
			initiallyOn:(BOOL)initiallyOn
{
#ifndef NDEBUG
	NSParameterAssert([colors count] >= 1);
	id color = nil;
	foreach (color, colors)
	{
		NSParameterAssert([color isKindOfClass:[OOColor class]]);
	}
#endif
	
	if ((self = [super initWithPosition:position]))
	{
		_colors = [colors copy];
		_frequency = frequency;
		_phase = phase;
		_size = size;
		_initiallyOn = initiallyOn;
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_colors);
	
	[super dealloc];
}


- (OOSubEntityType) type
{
	return kOOSubEntityFlasher;
}


- (NSArray *) colors
{
	return _colors;
}


- (float) frequency
{
	return _frequency;
}


- (float) phase
{
	return _phase;
}


- (float) size
{
	return _size;
}


- (BOOL) initiallyOn
{
	return _initiallyOn;
}


- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	[result setObject:OOStringFromSubEntityType([self type]) forKey:@"type"];
	[result oo_setVector:[self position] forKey:@"position"];
	
	[result setObject:[_colors ja_propertyListRepresentationWithContext:context] forKey:@"colors"];
	
	[result oo_setFloat:_frequency forKey:@"frequency"];
	if (_phase != 0)  [result oo_setFloat:_phase forKey:@"phase"];
	[result oo_setFloat:_size forKey:@"size"];
	
	if (!_initiallyOn)  [result oo_setBool:_initiallyOn forKey:@"initiallyOn"];
	
	return result;
}

@end


@implementation OOBallTurretSubEntityDefinition

- (id) initWithShipKey:(NSString *)shipKey
			  position:(Vector)position
		   orientation:(Quaternion)orientation
			  fireRate:(float)fireRate
{
	if ((self = [super initWithType:kOOSubEntityBallTurret shipKey:shipKey position:position orientation:orientation]))
	{
		_fireRate = fmax(fireRate, kOOBallTurretMinimumFireRate);
	}
	
	return self;
}

@end


NSString *OOStringFromSubEntityType(OOSubEntityType type)
{
	switch (type)
	{
		case kOOSubEntityNormal:
			return @"normal";
			
		case kOOSubEntityBallTurret:
			return @"ballTurret";
			
		case kOOSubEntityDock:
			return @"dock";
			
		case kOOSubEntityFlasher:
			return @"flasher";
	}
}
