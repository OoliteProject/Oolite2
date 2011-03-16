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
	NSString			*_escortShipKey;
	NSString			*_escortRole;
	
	Vector				_forwardViewPosition;
	Vector				_aftViewPosition;
	Vector				_portViewPosition;
	Vector				_starboardViewPosition;
	NSArray				*_customViews;
	
	NSUInteger			_cargoSpaceCapacity;	// max_cargo
	NSUInteger			_cargoSpaceUsedMin;
	NSUInteger			_cargoSpaceUsedMax;		// likely_cargo
	NSUInteger			_cargoBayExpansionSize;	// extra_cargo
	NSString			*_cargoType;			// cargo_carried
	
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
						_cloakPassive: 1,
						_cloakAutomatic: 1,
						_hasScoopMessage: 1,
						_rotating: 1,
						_countsAsKill: 1,
	// Carrier flags
						_hasShipyard: 1,
						_requiresDockingClearance: 1,
						_allowsInterstellarUndocking: 1,
						_allowsAutoDocking: 1,
						_allowsFastDocking: 1;
	
	// Energy and fuel
	float				_maxEnergy;
	float				_energyRechargeRate;
	float				_maxFuel;
	float				_fuelChargeRate;
	
	float				_heatInsulation;
	
	// Flight parameters
	float				_maxFlightSpeed;
	float				_maxFlightRoll;
	float				_maxFlightPitch;
	float				_maxFlightYaw;
	float				_maxThrust;
	float				_hyperspaceMotorSpinTime;
	
	// Weapons
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
	NSUInteger			_missileCount;
	OORoleSet			*_missileRoles;
	NSArray				*_missiles;
	
	float				_scannerRange;
	
	NSArray				*_equipment;
	
	float				_fragmentChance;
	float				_noBouldersChance;
	OORoleSet			*_debrisRoles;
	
	Quaternion			_rotationalVelocity;
	Vector				_scoopPosition;
	Vector				_aftEjectPosition;
	
	// Carrier-specific
	float				_stationRoll;
	float				_NPCTrafficChance;
	float				_patrolShipChance;
	NSUInteger			_maxScavengers;
	NSUInteger			_maxDefenseShips;
	NSString			*_defenseShipRole;
	NSString			*_defenseShipKey;
	NSUInteger			_maxPolice;
	
	float				_portRadius;
	Vector				_portDimensions;
	
	OOTechLevelID		_equivalentTechLevel;
	float				_equipmentPriceFactor;
	NSString			*_marketKey;
	
	NSUInteger			_dockingTunnelCorners;
	float				_dockingTunnelStartAngle;
	float				_dockingTunnelAspectRatio;
}

- (OOShipClass *) likeShip;
- (NSString *) shipKey;
- (NSString *) name;
- (NSString *) displayName;
- (OOScanClass) scanClass;
- (NSString *) beaconCode;
- (NSString *) HUDName;	// FIXME: this should be shipyard info, although we might want to fold that in.

- (NSString *) pilotKey;
- (float) unpilotedChance;
- (NSString *) escapePodRole;

- (NSString *) scriptName;
- (NSString *) AIName;
- (NSDictionary *) scriptInfo;

- (NSString *) modelName;
- (NSDictionary *) materialDefinitions;
- (NSArray *) exhaustDefinitions;
- (NSArray *) scannerColors;

- (OOCreditsQuantity) bounty;
- (float) density;
- (OORoleSet *) roles;
- (NSArray *) subentityDefinitions;

- (OOUInteger) escortCount;
- (NSString *) escortShipKey;
- (NSString *) escortRole;

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
- (NSUInteger) cargoBayExpansionSize;
- (NSString *) cargoType;

- (BOOL) isTemplate;
- (BOOL) isExternalDependency;
- (BOOL) isCarrier;
- (BOOL) smooth;				// FIXME: eliminate with new model format.
- (BOOL) isHulk;
- (BOOL) isFrangible;			// FIXME: make subentity isBreakable attribute instead.
- (BOOL) trackContacts;
- (BOOL) autoAI;
- (BOOL) hasHyperspaceMotor;
- (BOOL) isSubmunition;
- (BOOL) cloakPassive;
- (BOOL) cloakAutomatic;
- (BOOL) hasScoopMessage;		// FIXME: remove, this should be scripted.
- (BOOL) rotating;
- (BOOL) countsAsKill;
- (BOOL) hasShipyard;

// Energy and fuel
- (float) maxEnergy;
- (float) energyRechargeRate;
- (float) maxFuel;
- (float) fuelChargeRate;

- (float) heatInsulation;


// Flight parameters
- (float) maxFlightSpeed;
- (float) maxFlightRoll;
- (float) maxFlightPitch;
- (float) maxFlightYaw;
- (float) maxThrust;
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
- (NSUInteger) missileCount;
- (OORoleSet *) missileRoles;
- (NSArray *) missiles;
- (NSMutableArray *) selectMissiles;	// Generate an array of missile types (OOEquipmentInfo *). May produce different results on multiple calls.

- (float) scannerRange;

- (NSArray *) equipment;				// Array of { equipmentKey: String, probability: Number }.
- (NSMutableArray *) selectEquipment;	// Generate an array of internal equipment (OOEquipmentInfo *). May produce different results on multiple calls.

// On the subject of falling apart
- (float) fragmentChance;
- (BOOL) selectCanFragment;
- (float) noBouldersChance;
- (BOOL) selectNoBoulders;
- (OORoleSet *) debrisRoles;
- (NSString *) selectDebrisRole;

- (Quaternion) rotationalVelocity;
- (Vector) scoopPosition;
- (Vector) aftEjectPosition;

// Carrier-specific
- (float) stationRoll;	// Can we fold this into rotationalVelocity?
- (float) NPCTrafficChance;
- (float) patrolShipChance;
- (NSUInteger) maxScavengers;
- (NSUInteger) maxDefenseShips;
- (NSString *) defenseShipRole;
- (NSString *) defenseShipKey;
- (NSUInteger) maxPolice;
// FIXME: we can probably drop these in favour of using a docking port subentity (which has been the normal way for a long time).
- (float) portRadius;
- (Vector) portDimensions;

- (OOTechLevelID) equivalentTechLevel;
- (float) equipmentPriceFactor;
- (NSString *) marketKey;

- (BOOL) requiresDockingClearance;
- (BOOL) allowsInterstellarUndocking;
- (BOOL) allowsAutoDocking;
- (BOOL) allowsFastDocking;
- (NSUInteger) dockingTunnelCorners;
- (float) dockingTunnelStartAngle;
- (float) dockingTunnelAspectRatio;

@end
