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
#import "ShipEntity.h"	// For OOWeaponType

@class OORoleSet;


@interface OOShipClass: NSObject <NSCopying>
{
@private
	OOShipClass			*_likeShip;
	NSString			*_shipKey;
	NSString			*_name;
	NSString			*_displayName;
	OOScanClass			_scanClass;
	NSString			*_beaconCode;
	NSString			*_HUDName;
	
	NSString			*_pilotKey;
	float				_unpilotedChance;
	NSString			*_escapePodRole;
	
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
	NSArray				*_subentityDefinitions;
	
	OOUInteger			_escortCount;
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
	float				_fuelChargeRate;
	
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
	float				_weaponRange;
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
						_trackContacts: 1,
						_autoAI: 1,
						_hasHyperspaceMotor: 1,
						_isSubmunition: 1,
						_cloakIsPassive: 1,
						_cloakIsAutomatic: 1,
						_hasScoopMessage: 1,
						_isRotating: 1,
						_countsAsKill: 1,
						_hasShipyard: 1,
						_requiresDockingClearance: 1,
						_allowsInterstellarUndocking: 1,
						_allowsAutoDocking: 1,
						_allowsFastDocking: 1;
}

/*
	Create an OOShipClass from an Oolite 1.x shipdata.plist entry.
	
	key: the shipdata.plist key.
	legacyPList: the shipdata.plist value.
	knownShips: dictionary of previously-loaded OOShipClasses, for like_ship
	support. The caller is responsible for ensuring dependencies are loaded in
	advance.
*/
- (id) initWithKey:(NSString *)key
	   legacyPList:(NSDictionary *)legacyPList
		knownShips:(NSDictionary *)knownShips
   problemReporter:(id<OOProblemReporting>)issues;


- (BOOL) isTemplate;
- (BOOL) isExternalDependency;
- (OOShipClass *) likeShip;
- (NSString *) shipKey;
- (NSString *) name;
- (NSString *) displayName;
- (OOScanClass) scanClass;
- (NSString *) beaconCode;
- (BOOL) isHulk;
- (NSString *) HUDName;	// FIXME: this should be shipyard info, although we might want to fold that in.

- (NSString *) pilotKey;
- (float) unpilotedChance;
- (BOOL) selectUnpiloted;
- (NSString *) escapePodRole;	// FIXME: should be role set.
- (BOOL) countsAsKill;

- (NSString *) scriptName;
- (NSDictionary *) scriptInfo;
- (BOOL) hasScoopMessage;		// FIXME: remove, this should be scripted.
- (NSString *) AIName;
- (BOOL) trackContacts;
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
- (NSArray *) subentityDefinitions;
- (BOOL) isFrangible;			// FIXME: make subentity isBreakable attribute instead.

- (OOUInteger) escortCount;
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
- (float) fuelChargeRate;	// NOTE: this is the value in the config file, not adjusted for mass-dependent rules.

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
- (float) weaponRange;
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
- (float) noBouldersChance;
- (BOOL) selectNoBoulders;
- (OORoleSet *) debrisRoles;
- (NSString *) selectDebrisRole;

- (BOOL) isRotating;
- (Quaternion) rotationalVelocity;
- (Vector) scoopPosition;
- (Vector) aftEjectPosition;

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

@end


extern NSString * const kOODefaultHUDName;
extern NSString * const kOODefaultEscapePodRole;
extern NSString * const kOODefaultShipScriptName;
extern NSString * const kOODefaultShipAIName;
extern NSString * const kOODefaultEscortRole;
extern NSString * const kOODefaultDebrisRole;
