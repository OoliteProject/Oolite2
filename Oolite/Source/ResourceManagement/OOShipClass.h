/*

OOShipClass.h

Immutable, abstract representation of a type of ship.

In addition to represening the immediate shipdata entries, this class can also
resolve flexible attributes for a new ship. Methods beginning with “select” do
this, and can return different values each time they’re called. For instance,
-selectMissiles may randomly select among missile roles, and -selectWillFragment
returns true with probability -fragmentChance.


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

#import <OoliteBase/OoliteBase.h>
#import "Universe.h"
#import "OOShipEntity.h"	// For OOWeaponType

@class OORoleSet;


@interface OOShipClass: NSObject <NSCopying>
{
@private
	NSString			*_likeShipKey;
	NSString			*_shipKey;
	NSString			*_name;
	NSString			*_displayName;
	OOScanClass			_scanClass;
	NSString			*_beaconCode;
	NSString			*_HUDName;
	
	NSString			*_pilotKey;
	float				_unpilotedChance;
	NSUInteger			_escapePodCount;
	OORoleSet			*_escapePodRoles;
	
	NSString			*_scriptName;
	NSString			*_AIName;
	NSDictionary		*_scriptInfo;
	
	NSString			*_modelName;
	NSDictionary		*_materialDefinitions;
	NSArray				*_exhaustDefinitions;
	NSArray				*_scannerColors;
	
	OOCreditsQuantity	_bounty;
	float				_density;
	OORoleSet			*_roles;
	NSArray				*_subEntityDefinitions;
	
	NSUInteger			_escortCount;
	OORoleSet			*_escortRoles;
	
	Vector				_forwardViewPosition;
	Vector				_aftViewPosition;
	Vector				_portViewPosition;
	Vector				_starboardViewPosition;
	NSArray				*_customViews;
	
	NSUInteger			_cargoSpaceCapacity;	// max_cargo
	NSUInteger			_cargoSpaceUsedMin;
	NSUInteger			_cargoSpaceUsedMax;		// likely_cargo
	NSUInteger			_cargoBayExpansionSize;	// extra_cargo
	OOCargoType			_cargoType;
	NSString			*_cargoCarried;
	
	float				_energyCapacity;
	float				_energyRechargeRate;
	OOFuelQuantity		_fuelCapacity;
	OOFuelQuantity		_initialFuel;
	
	float				_heatInsulation;
	
	float				_maxFlightSpeed;
	float				_maxFlightRoll;
	float				_maxFlightPitch;
	float				_maxFlightYaw;
	float				_maxThrust;
	float				_hyperspaceMotorSpinTime;
	
	float				_accuracy;
	OOWeaponType		_forwardWeaponType;
	OOWeaponType		_aftWeaponType;
	OOWeaponType		_portWeaponType;
	OOWeaponType		_starboardWeaponType;
	Vector				_forwardWeaponPosition;
	Vector				_aftWeaponPosition;
	Vector				_portWeaponPosition;
	Vector				_starboardWeaponPosition;
	float				_weaponEnergy;
	float				_turretRange;
	OOColor				*_laserColor;
	
	NSUInteger			_missileCapacity;
	NSUInteger			_missileCountMin;
	NSUInteger			_missileCountMax;
	OORoleSet			*_missileRoles;
	
	float				_scannerRange;
	
	NSArray				*_equipment;
	
	float				_fragmentChance;
	float				_noBouldersChance;
	OORoleSet			*_debrisRoles;
	
	Quaternion			_rotationalVelocity;
	Vector				_scoopPosition;
	Vector				_aftEjectPosition;
	
	float				_stationRoll;
	float				_hasNPCTrafficChance;
	float				_hasPatrolShipsChance;
	NSUInteger			_maxScavengers;
	NSUInteger			_maxDefenseShips;
	OORoleSet			*_defenseShipRoles;
	NSUInteger			_maxPolice;
	
	OOTechLevelID		_equivalentTechLevel;
	float				_equipmentPriceFactor;
	NSString			*_marketKey;
	
	NSUInteger			_dockingTunnelCorners;
	float				_dockingTunnelStartAngle;
	float				_dockingTunnelAspectRatio;
	
	// Flags (non-fuzzy booleans)
	BOOL				_isTemplate: 1,
						_isExternalDependency: 1,
						_isCarrier: 1,
						_smooth: 1,
						_isHulk: 1,
						_isFrangible: 1,
						_trackCloseContacts: 1,
						_autoAI: 1,
						_hasHyperspaceMotor: 1,
						_isSubmunition: 1,
						_cloakIsPassive: 1,
						_cloakIsAutomatic: 1,
						_hasScoopMessage: 1,
						_countsAsKill: 1,
						_hasShipyard: 1,
						_requiresDockingClearance: 1,
						_allowsInterstellarUndocking: 1,
						_allowsAutoDocking: 1,
						_allowsFastDocking: 1,
						_isBallTurret: 1;
}

- (NSString *) likeShipKey;
- (OOShipClass *) likeShip;

- (BOOL) isTemplate;
- (BOOL) isExternalDependency;
- (OOShipClass *) likeShip;
- (NSString *) shipKey;
- (NSString *) name;
- (NSString *) displayName;
- (OOScanClass) scanClass;
- (NSString *) beaconCode;
- (BOOL) isHulk;
- (NSString *) HUDName;			// FIXME: this should be shipyard info, although we might want to fold that in.

- (NSString *) pilotKey;
- (float) unpilotedChance;		// FIXME: is the fuzziness of this actually desirable? It seems like an odd thing to want, and can be done by likeShipping and distributing role weights.
- (BOOL) selectUnpiloted;
- (NSUInteger) escapePodCount;	// FIXME: range
- (OORoleSet *) escapePodRoles;
- (BOOL) countsAsKill;

- (NSString *) scriptName;
- (NSDictionary *) scriptInfo;
- (BOOL) hasScoopMessage;		// FIXME: remove, this should be scripted.
- (NSString *) AIName;
- (BOOL) trackCloseContacts;
- (BOOL) autoAI;

- (NSString *) modelName;
- (BOOL) smooth;				// FIXME: eliminate with new model format.
- (NSDictionary *) materialDefinitions;
- (NSArray *) exhaustDefinitions;
- (NSArray *) scannerColors;
- (float) scannerRange;

- (OOCreditsQuantity) bounty;
- (float) density;
- (OORoleSet *) roles;
- (NSArray *) subEntityDefinitions;
- (BOOL) isFrangible;			// FIXME: make subentity isBreakable attribute instead.

- (NSUInteger) escortCount;
- (OORoleSet *) escortRoles;
- (NSString *) selectEscortShip;

// Views
- (Vector) forwardViewPosition;
- (Vector) aftViewPosition;
- (Vector) portViewPosition;
- (Vector) starboardViewPosition;
- (NSArray *) customViews;

// Cargo
- (NSUInteger) cargoSpaceCapacity;
- (NSUInteger) cargoSpaceUsedMin;
- (NSUInteger) cargoSpaceUsedMax;
- (NSUInteger) selectCargoSpaceUsed;
- (NSUInteger) cargoBayExpansionSize;
- (OOCargoType) cargoType;
- (NSString *) cargoCarried;

// Energy and fuel
- (float) energyCapacity;
- (float) energyRechargeRate;
- (OOFuelQuantity) fuelCapacity;
- (OOFuelQuantity) initialFuel;

- (float) heatInsulation;


// Flight parameters
- (float) maxFlightSpeed;
- (float) maxFlightRoll;
- (float) maxFlightPitch;
- (float) maxFlightYaw;
- (float) maxThrust;
- (BOOL) hasHyperspaceMotor;
- (float) hyperspaceMotorSpinTime;

// Weapons
- (float) accuracy;
// FIXME: these should be equipment types.
- (OOWeaponType) forwardWeaponType;
- (OOWeaponType) aftWeaponType;
- (OOWeaponType) portWeaponType;
- (OOWeaponType) starboardWeaponType;
- (Vector) forwardWeaponPosition;
- (Vector) aftWeaponPosition;
- (Vector) portWeaponPosition;
- (Vector) starboardWeaponPosition;
// FIXME: these should be attributes of weapons, not ships.
- (float) weaponEnergy;
- (float) turretRange;
- (OOColor *) laserColor;

- (NSUInteger) missileCapacity;
- (NSUInteger) missileCountMin;
- (NSUInteger) missileCountMax;
- (NSUInteger) selectMissileCount;
- (OORoleSet *) missileRoles;
- (NSMutableArray *) selectMissiles;	// Generate an array of missile types (OOEquipmentInfo *). May produce different results on multiple calls.

- (BOOL) isSubmunition;

- (BOOL) cloakIsPassive;
- (BOOL) cloakIsAutomatic;

- (NSArray *) equipment;		// Array of { key: String, probability: Number }.
- (NSArray *) selectEquipment;	// Generate an array of internal equipment (OOEquipmentInfo *). May produce different results on multiple calls. This does not validate that the equipment is appropriate for a given ship, so that needs to be done as an additional step.

// Asteroid/boulder properties
- (float) fragmentChance;
- (BOOL) selectCanFragment;
- (float) noBouldersChance;		// FIXME: should be a range or something, and name should involve “debris”. Conversion from 1.x will be approximate.
- (BOOL) selectNoBoulders;
- (OORoleSet *) debrisRoles;
- (NSString *) selectDebrisRole;
- (Vector) scoopPosition;
- (Vector) aftEjectPosition;

- (Quaternion) rotationalVelocity;

// Carrier properties
- (BOOL) isCarrier;
- (float) stationRoll;	// Can we fold this into rotationalVelocity?
- (float) hasNPCTrafficChance;
- (BOOL) selectHasNPCTraffic;
- (float) hasPatrolShipsChance;
- (BOOL) selectHasPatrolShips;
- (NSUInteger) maxScavengers;
- (NSUInteger) maxDefenseShips;
- (OORoleSet *) defenseShipRoles;
- (NSUInteger) maxPolice;

- (OOTechLevelID) equivalentTechLevel;
- (float) equipmentPriceFactor;
- (NSString *) marketKey;
- (BOOL) hasShipyard;

- (BOOL) requiresDockingClearance;
- (BOOL) allowsInterstellarUndocking;
- (BOOL) allowsAutoDocking;
- (BOOL) allowsFastDocking;
- (NSUInteger) dockingTunnelCorners;
- (float) dockingTunnelStartAngle;
- (float) dockingTunnelAspectRatio;


// Legacy-only properties to help updates.
- (BOOL) isBallTurret;		// Set if legacy setup_actions includes “initialiseTurret”.

@end


@interface OOShipExhaustDefinition: NSObject <NSCopying>
{
@private
	Vector				_position;
	float				_width;
	float				_height;
}

- (id) initWithPosition:(Vector)position width:(float)width height:(float)height;

- (Vector) position;
- (float) width;
- (float) height;

@end


typedef enum
{
	kOOSubEntityNormal,
	kOOSubEntityBallTurret,
	kOOSubEntityDock,
	kOOSubEntityFlasher
} OOSubEntityType;


NSString *OOStringFromSubEntityType(OOSubEntityType type);


@interface OOShipSubEntityDefinition: NSObject <NSCopying>
{
@private
	Vector				_position;
}

// Create a normal, ball turret or dock definition.
+ (id) definitionWithType:(OOSubEntityType)type shipKey:(NSString *)key position:(Vector)position orientation:(Quaternion)orientation;

// Create a ball turret definition.
+ (id) definitionForBallTurretWithShipKey:(NSString *)key position:(Vector)position orientation:(Quaternion)orientation fireRate:(float)fireRate;

// Create a flasher definition.
+ (id) definitionForFlasherWithPosition:(Vector)position
								 colors:(NSArray *)colors
							  frequency:(float)frequency
								  phase:(float)phase
								   size:(float)size
							initiallyOn:(BOOL)initiallyOn;

- (OOSubEntityType) type;

- (Vector) position;

// Apply to non-flashers.
- (NSString *) shipKey;
- (OOShipClass *) shipClass;
- (Quaternion) orientation;

// Applies to ball turrets.
- (float) fireRate;	// Actually delay between shots, in seconds.

// Apply to flashers.
- (NSArray *) colors;
- (float) frequency;
- (float) phase;
- (float) size;
- (BOOL) initiallyOn;

@end


@interface OOShipViewDescription: NSObject <NSCopying>
{
@private
	NSString				*_name;
	Vector					_position;
	Quaternion				_orientation;
	OOViewID				_weaponFacing;
}

- (id) initWithName:(NSString *)name
		   position:(Vector)position
		orientation:(Quaternion)orientation
	   weaponFacing:(OOViewID)weaponFacing;

- (NSString *) name;
- (Vector) position;
- (Quaternion) orientation;
- (OOViewID) weaponFacing;

@end


extern NSString * const kOODefaultHUDName;
extern NSString * const kOODefaultEscapePodRole;
extern NSString * const kOODefaultShipScriptName;
extern NSString * const kOODefaultShipAIName;
extern NSString * const kOODefaultEscortRole;
extern NSString * const kOODefaultDebrisRole;

extern NSString * const kOOShipClassEquipmentKeyKey;
extern NSString * const kOOShipClassEquipmentChanceKey;

#define kOOBallTurretDefaultFireRate		(0.5f)
#define kOOBallTurretMinimumFireRate		(0.25f)
