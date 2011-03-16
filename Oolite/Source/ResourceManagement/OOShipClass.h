/*

OOShipClass.h

Abstract representation of a type of ship.


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
	NSString			*_shipKey;
	NSString			*_name;
	NSString			*_displayName;
	OOScanClass			_scanClass;
	NSString			*_beaconCode;
	NSString			*_HUDName;	// FIXME: this should be shipyard info, although we might want to fold that in.
	
	NSString			*_pilotKey;
	float				_unpilotedChance;
	NSString			*_escapePodRole;
	
	NSString			*_scriptName;
	NSString			*_AIName;
	NSDictionary		*_scriptInfo;
	
	NSString			*_modelName;
	NSDictionary		*_materialDefinitions;
	NSArray				*_exhaustDefinition;
	NSArray				*_scannerColors;
	
	OOCreditsQuantity	_bounty;
	float				_density;
	OORoleSet			*_roles;
	NSArray				*_subentityDefinitions;
	
	OOUInteger			_escortCount;
	NSString			*_escortShipKey;
	NSString			*_escortRole;
	
	// Views
	Vector				_forwardViewPosition;
	Vector				_aftViewPosition;
	Vector				_portViewPosition;
	Vector				_starboardViewPosition;
	NSArray				*_customViews;
	
	// Cargo
	NSUInteger			_cargoSpaceCapacity;	// max_cargo
	NSUInteger			_cargoSpaceUsedMin;
	NSUInteger			_cargoSpaceUsedMax;		// likely_cargo
	NSUInteger			_cargoBayExpansionSize;	// extra_cargo
	NSString			*_cargoType;			// cargo_carried
	
	// Flags (non-fuzzy booleans)
	BOOL				_isTemplate: 1,
						_isExternalDependency: 1,
						_isCarrier: 1,
						_smooth: 1,				// FIXME: eliminate with new model format.
						_isHulk: 1,
						_isFrangible: 1,		// FIXME: make subentity isBreakable attribute instead.
						_trackContacts: 1,
						_autoAI: 1,
						_hasHyperspaceMotor: 1,
						_isSubmunition: 1,
						_cloakPassive: 1,
						_cloakAutomatic: 1,
						_hasScoopMessage: 1,	// FIXME: remove, this should be scripted.
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
	
	float				_hyperspaceMotorSpinTime;
	
	// Flight parameters
	float				_maxFlightSpeed;
	float				_maxFlightRoll;
	float				_maxFlightPitch;
	float				_maxFlightYaw;
	float				_maxThrust;
	
	// Weapons
	float				_accuracy;
	// FIXME: these should be equipment types.
	OOWeaponType		_forwardWeaponType;
	OOWeaponType		_aftWeaponType;
	OOWeaponType		_portWeaponType;
	OOWeaponType		_starboardWeaponType;
	Vector				_forwardWeaponPosition;
	Vector				_aftWeaponPosition;
	Vector				_portWeaponPosition;
	Vector				_starboardWeaponPosition;
	// FIXME: these should be attributes of weapons, not ships.
	float				_weaponEnergy;
	float				_weaponRange;
	OOColor				*_laserColor;
	
	NSUInteger			_missileCapacity;
	NSUInteger			_missileCount;	// FIXME: should generate missiles array if missileCount is specified but not missiles.
	NSString			*_missileRole;
	NSArray				*_missiles;
	
	float				_scannerRange;
	
	// Array of { equipmentKey: String, probability: Number }.
	NSArray				*_equipment;
	
	// On the subject of falling apart
	float				_fragmentChance;
	float				_noBouldersChance;
	NSString			*_debrisRole;
	
	Quaternion			_rotationalVelocity;
	Vector				_scoopPosition;
	Vector				_aftEjectPosition;
	
	// Carrier-specific
	float				_stationRoll;	// Can we fold this into _rotationalVelocity?
	float				_NPCTrafficChance;
	float				_patrolShipChance;
	NSUInteger			_maxScavengers;
	NSUInteger			_maxDefenseShips;
	NSString			*_defenseShipRole;
	NSString			*_defenseShipKey;
	NSUInteger			_maxPolice;
	// FIXME: we can probably drop these in favour of using a docking port subentity (which has been the normal way for a long time).
	float				_portRadius;
	Vector				_portDimensions;
	OOTechLevelID		_equivalentTechLevel;
	float				equipmentPriceFactor;
	NSUInteger			_dockingTunnelCorners;
	float				_dockingTunnelStartAngle;
	float				_dockingTunnelAspectRatio;
	NSString			*_marketKey;
}



@end
