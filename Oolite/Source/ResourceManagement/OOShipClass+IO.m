/*

OOShipClass+IO.m


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

#import "OOShipClass+IO.h"
#import "OORoleSet.h"
#import "OOConstToString.h"


// MARK: Keys

#define kKey_likeShip						@"likeShip"
#define kKey_isTemplate						@"isTemplate"
#define kKey_isExternalDependency			@"isExternalDependency"
#define kKey_name							@"name"
#define kKey_displayName					@"displayName"
#define kKey_scanClass						@"scanClass"
#define kKey_beaconCode						@"beaconCode"
#define kKey_isHulk							@"isHulk"
#define kKey_HUDName						@"hud"
#define kKey_pilotKey						@"pilot"
#define kKey_unpilotedChance				@"unpiloted"
#define kKey_escapePodCount					@"escapePodCount"
#define kKey_escapePodRoles					@"escapePodRoles"
#define kKey_countsAsKill					@"countsAsKill"
#define kKey_scriptName						@"script"
#define kKey_scriptInfo						@"scriptInfo"
#define kKey_AIName							@"AI"
#define kKey_autoAI							@"autoAI"
#define kKey_trackCloseContacts				@"trackCloseContacts"
#define kKey_modelName						@"model"
#define kKey_smooth							@"smooth"
#define kKey_materialDefinitions			@"materials"
#define kKey_exhaustDefinitions				@"exhaust"
#define kKey_scannerColors					@"scannerColors"
#define kKey_bounty							@"bounty"
#define kKey_density						@"density"
#define kKey_roles							@"roleWeights"
#define kKey_subentityDefinitions			@"subentities"
#define kKey_isFrangible					@"isFrangible"
#define kKey_escortCount					@"escortCount"
#define kKey_escortRoles					@"escortRoles"
#define kKey_forwardViewPosition			@"forwardViewPosition"
#define kKey_aftViewPosition				@"aftViewPosition"
#define kKey_portViewPosition				@"portViewPosition"
#define kKey_starboardViewPosition			@"starboardViewPosition"
#define kKey_customViews					@"customViews"
#define kKey_cargoSpaceCapacity				@"cargoSpaceCapacity"
#define kKey_cargoSpaceUsed					@"cargoSpaceUsed"
#define kKey_cargoBayExpansionSize			@"cargoBayExpansionSize"
#define kKey_cargoType						@"cargoType"
#define kKey_energyCapacity					@"energyCapacity"
#define kKey_energyRechargeRate				@"energyChargeRate"
#define kKey_fuelCapacity					@"fuelCapacity"
#define kKey_initialFuel					@"fuel"
#define kKey_fuelChargeRate					@"fuelChargeRate"
#define kKey_heatInsulation					@"heatInsulation"
#define kKey_maxFlightSpeed					@"maxFlightSpeed"
#define kKey_maxFlightRoll					@"maxFlightRoll"
#define kKey_maxFlightPitch					@"maxFlightPitch"
#define kKey_maxFlightYaw					@"maxFlightYaw"
#define kKey_maxThrust						@"maxThrust"
#define kKey_hasHyperspaceMotor				@"hasHyperspaceMotor"
#define kKey_hyperspaceMotorSpinTime		@"hyperspaceMotorSpinTime"
#define kKey_accuracy						@"accuracy"
#define kKey_forwardWeaponType				@"forwardWeaponType"		
#define kKey_aftWeaponType					@"aftWeaponType"
#define kKey_portWeaponType					@"portWeaponType"
#define kKey_starboardWeaponType			@"starboardWeaponType"
#define kKey_forwardWeaponPosition			@"forwardWeaponPosition"
#define kKey_aftWeaponPosition				@"aftWeaponPosition"
#define kKey_portWeaponPosition				@"portWeaponPosition"
#define kKey_starboardWeaponPosition		@"starboardWeaponPosition"
#define kKey_weaponEnergy					@"weaponEnergy"
#define kKey_turretRange					@"turretRange"
#define kKey_laserColor						@"laserColor"
#define kKey_missileCount					@"missileCount"
#define kKey_missileCapacity				@"missileCapacity"
#define kKey_missileRoles					@"missileRoles"
#define kKey_isSubmunition					@"isSubmunition"
#define kKey_cloakIsPassive					@"isCloakPassive"
#define kKey_cloakIsAutomatic				@"isCloakAutomatic"
#define kKey_fragmentChance					
#define kKey_noBouldersChance				
#define kKey_debrisRoles					
#define kKey_scoopPosition					
#define kKey_aftEjectPosition				
#define kKey_rotationalVelocity				
#define kKey_isCarrier1						
#define kKey_isCarrier2						
#define kKey_isRotating						
#define kKey_stationRoll					
#define kKey_hasNPCTrafficChance			
#define kKey_hasPatrolShipsChance			
#define kKey_maxScavengers					
#define kKey_maxDefenseShips				
#define kKey_maxPolice						
#define kKey_defenseShip					
#define kKey_defenseShipRoles				
#define kKey_equivalentTechLevel			
#define kKey_equipmentPriceFactor			
#define kKey_marketKey						
#define kKey_hasShipyard1					
#define kKey_hasShipyard2					
#define kKey_requiresDockingClearance		
#define kKey_allowsInterstellarUndocking	
#define kKey_allowsAutoDocking				
#define kKey_allowsFastDocking				
#define kKey_dockingTunnelCorners			
#define kKey_dockingTunnelStartAngle		
#define kKey_dockingTunnelAspectRatio		
#define kKey_extraEquipment					


// MARK: Defaults

#define kDefault_name						nil
#define kDefault_scanClass					CLASS_NEUTRAL
#define kDefault_beaconCode					nil
#define kDefault_isHulk						NO
#define kDefault_HUDName					@"hud.plist"
#define kDefault_pilotKey					nil
#define kDefault_unpilotedChance			0
#define kDefault_escapePodCount				0
#define kDefault_escapePodRoles				@"escape-capsule"
#define kDefault_countsAsKill				YES
#define kDefault_scriptName					@"oolite-default-ship-script.js"
#define kDefault_scriptInfo					nil
#define kDefault_hasScoopMessage			NO
#define kDefault_AIName						@"nullAI.plist"
#define kDefault_trackCloseContacts			NO
#define kDefault_autoAI						YES
#define kDefault_modelName					nil
#define kDefault_smooth						NO
#define kDefault_materialDefinitions		nil
#define kDefault_exhaustDefinitions			nil
#define kDefault_scannerColors				nil
#define kDefault_bounty						0
#define kDefault_density					1
#define kDefault_roles						nil

#define kDefault_subentityDefinitions		nil
#define kDefault_isFrangible				YES
#define kDefault_escortCount				0
#define kDefault_escortRoles				@"escort"
#define kDefault_forwardViewPosition		kZeroVector
#define kDefault_aftViewPosition			kZeroVector
#define kDefault_portViewPosition			kZeroVector
#define kDefault_starboardViewPosition		kZeroVector
#define kDefault_customViews				nil
#define kDefault_cargoSpaceCapacity			0
#define kDefault_cargoSpaceUsedMin			0
#define kDefault_cargoSpaceUsedMax			0
#define kDefault_cargoBayExpansionSize		15
#define kDefault_cargoType					CARGO_NOT_CARGO
#define kDefault_energyCapacity				200
#define kDefault_energyRechargeRate			1
#define kDefault_fuelCapacity				70
#define kDefault_initialFuel				_fuelCapacity	// NOTE: different from 1.x, where it's 0.
#define kDefault_fuelChargeRate				1
#define kDefault_heatInsulation				1
#define kDefault_maxFlightSpeed				0				// NOTE: 1.x has arbitrary default speed limits, 2.x defaults to 0.
#define kDefault_maxFlightRoll				0
#define kDefault_maxFlightPitch				0
#define kDefault_maxFlightYaw				0
#define kDefault_maxThrust					0
#define kDefault_hasHyperspaceMotor			YES
#define kDefault_hyperspaceMotorSpinTime	15
#define kDefault_accuracy					-100
#define kDefault_forwardWeaponType			WEAPON_NONE
#define kDefault_aftWeaponType				WEAPON_NONE
#define kDefault_portWeaponType				WEAPON_NONE
#define kDefault_starboardWeaponType		WEAPON_NONE
#define kDefault_forwardWeaponPosition		kZeroVector
#define kDefault_aftWeaponPosition			kZeroVector
#define kDefault_portWeaponPosition			kZeroVector
#define kDefault_starboardWeaponPosition	kZeroVector
#define kDefault_weaponEnergy				0
#define kDefault_turretRange				6000
#define kDefault_laserColor					$array($int(1), $int(0), $int(0))
#define kDefault_missileCapacity			0
#define kDefault_missileCountMax			_missileCapacity
#define kDefault_missileCountMin			0
#define kDefault_missileRoles				@"EQ_MISSILE(8) missile(2)"
#define kDefault_isSubmunition				NO
#define kDefault_cloakIsPassive				NO
#define kDefault_cloakIsAutomatic			YES
#define kDefault_fragmentChance				0.9
#define kDefault_noBouldersChance			0
#define kDefault_debrisRoles				@"boulder"
#define kDefault_scoopPosition				kZeroVector
#define kDefault_aftEjectPosition			kZeroVector
#define kDefault_rotationalVelocity			kIdentityQuaternion
#define kDefault_isCarrier					NO
#define kDefault_stationRoll				0.4
#define kDefault_hasNPCTrafficChance		YES
#define kDefault_hasPatrolShipsChance		NO
#define kDefault_maxScavengers				3
#define kDefault_maxDefenseShips			3
#define kDefault_maxPolice					8
#define kDefault_defenseShipRoles			nil
#define kDefault_equivalentTechLevel		NSNotFound
#define kDefault_equipmentPriceFactor		1
#define kDefault_marketKey					nil
#define kDefault_hasShipyard				NO
#define kDefault_requiresDockingClearance	NO
#define kDefault_allowsInterstellarUndocking NO
#define kDefault_allowsAutoDocking			YES
#define kDefault_allowsFastDocking			NO
#define kDefault_dockingTunnelCorners		4
#define kDefault_dockingTunnelStartAngle	45
#define kDefault_dockingTunnelAspectRatio	2.67


@implementation OOShipClass (IO)



// MARK: Export
#if !OOLITE_LEAN

OOINLINE BOOL ObjectIsOverride(id value, OOShipClass *likeShip, SEL likeSelector, id defaultValue)
{
	if (likeShip != nil)
	{
		defaultValue = [[likeShip performSelector:likeSelector] ja_propertyListRepresentation];
	}
	
	if (value == defaultValue || [value isEqual:defaultValue])  return NO;	// == test is primarily for nils.
	return YES;
}


static void WriteObject(NSMutableDictionary *result, NSString *key, id value, OOShipClass *likeShip, SEL likeSelector, id defaultValue)
{
	value = [value ja_propertyListRepresentation];
	if (ObjectIsOverride(value, likeShip, likeSelector, defaultValue))
	{
		[result setObject:(value ?: [NSNull null]) forKey:key];
	}
}


OOINLINE BOOL BoolIsOverride(BOOL value, OOShipClass *likeShip, SEL likeSelector, BOOL defaultValue)
{
	if (likeShip != nil)
	{
		typedef BOOL (*BOOLGetterIMP)(id self, SEL _cmd);
		BOOLGetterIMP getter = (BOOLGetterIMP)[likeShip methodForSelector:likeSelector];
		defaultValue = getter(likeShip, likeSelector);
	}
	
	return !value != !defaultValue;
}


static void WriteBool(NSMutableDictionary *result, NSString *key, BOOL value, OOShipClass *likeShip, SEL likeSelector, BOOL defaultValue)
{
	if (BoolIsOverride(value, likeShip, likeSelector, defaultValue))
	{
		[result oo_setBool:value forKey:key];
	}
}


OOINLINE BOOL FloatIsOverride(float value, OOShipClass *likeShip, SEL likeSelector, float defaultValue)
{
	if (likeShip != nil)
	{
		typedef float (*FloatGetterIMP)(id self, SEL _cmd);
		FloatGetterIMP getter = (FloatGetterIMP)[likeShip methodForSelector:likeSelector];
		defaultValue = getter(likeShip, likeSelector);
	}
	
	return value != defaultValue;
}


static void WriteFloat(NSMutableDictionary *result, NSString *key, float value, OOShipClass *likeShip, SEL likeSelector, float defaultValue)
{
	if (FloatIsOverride(value, likeShip, likeSelector, defaultValue))
	{
		[result oo_setFloatSingle:value forKey:key];
	}
}


static void WriteFuzzyBool(NSMutableDictionary *result, NSString *key, float value, OOShipClass *likeShip, SEL likeSelector, float defaultValue)
{
	if (FloatIsOverride(value, likeShip, likeSelector, defaultValue))
	{
		if (value == 0 || value >= 1)  [result oo_setBool:value forKey:key];
		else  [result oo_setFloat:value forKey:key];
	}
}


OOINLINE BOOL QuaternionIsOverride(Quaternion value, OOShipClass *likeShip, SEL likeSelector, Quaternion defaultValue)
{
	if (likeShip != nil)
	{
		typedef Quaternion (*QuaternionGetterIMP)(id self, SEL _cmd);
		QuaternionGetterIMP getter = (QuaternionGetterIMP)[likeShip methodForSelector:likeSelector];
		defaultValue = getter(likeShip, likeSelector);
	}
	
	return !quaternion_equal(value, defaultValue);
}


static void WriteQuaternion(NSMutableDictionary *result, NSString *key, Quaternion value, OOShipClass *likeShip, SEL likeSelector, Quaternion defaultValue)
{
	if (QuaternionIsOverride(value, likeShip, likeSelector, defaultValue))
	{
		[result setObject:$array($float(value.x), $float(value.y), $float(value.z)) forKey:key];
	}
}


OOINLINE BOOL UnsignedIntegerIsOverride(NSUInteger value, OOShipClass *likeShip, SEL likeSelector, NSUInteger defaultValue)
{
	if (likeShip != nil)
	{
		typedef float (*NSUIntegerGetterIMP)(id self, SEL _cmd);
		NSUIntegerGetterIMP getter = (NSUIntegerGetterIMP)[likeShip methodForSelector:likeSelector];
		defaultValue = getter(likeShip, likeSelector);
	}
	
	return value != defaultValue;
}


static void WriteUnsignedInteger(NSMutableDictionary *result, NSString *key, NSUInteger value, OOShipClass *likeShip, SEL likeSelector, NSUInteger defaultValue)
{
	if (UnsignedIntegerIsOverride(value, likeShip, likeSelector, defaultValue))
	{
		[result oo_setUnsignedInteger:value forKey:key];
	}
}


OOINLINE BOOL VectorIsOverride(Vector value, OOShipClass *likeShip, SEL likeSelector, Vector defaultValue)
{
	if (likeShip != nil)
	{
		typedef Vector (*VectorGetterIMP)(id self, SEL _cmd);
		VectorGetterIMP getter = (VectorGetterIMP)[likeShip methodForSelector:likeSelector];
		defaultValue = getter(likeShip, likeSelector);
	}
	
	return !vector_equal(value, defaultValue);
}


static void WriteVector(NSMutableDictionary *result, NSString *key, Vector value, OOShipClass *likeShip, SEL likeSelector, Vector defaultValue)
{
	if (VectorIsOverride(value, likeShip, likeSelector, defaultValue))
	{
		[result setObject:$array($float(value.x), $float(value.y), $float(value.z)) forKey:key];
	}
}


static void WriteRoles(NSMutableDictionary *result, NSString *key, OORoleSet *value, OOShipClass *likeShip, SEL likeSelector, NSString *defaultString)
{
	OORoleSet *defaultValue = nil;
	if (likeShip != nil)
	{
		defaultValue = [likeShip performSelector:likeSelector];
	}
	else if (defaultString != nil)
	{
		defaultValue = [OORoleSet roleSetWithString:defaultString];
	}
	
	if (value == defaultValue || [value isEqual:defaultValue])  return;	// == test is primarily for nils.
	
	if (value != nil)  [result setObject:[value ja_propertyListRepresentation] forKey:key];
	else if (defaultValue != nil)  [result setObject:[NSNull null] forKey:key];
}


static void WriteRange(NSMutableDictionary *result, NSString *key, NSUInteger valueMin, NSUInteger valueMax, OOShipClass *likeShip, SEL likeSelectorMin, SEL likeSelectorMax, NSUInteger defaultValueMin, NSUInteger defaultValueMax)
{
	if (UnsignedIntegerIsOverride(valueMin, likeShip, likeSelectorMin, defaultValueMin) || UnsignedIntegerIsOverride(valueMax, likeShip, likeSelectorMax, defaultValueMax))
	{
		if (valueMin == valueMax)
		{
			[result oo_setUnsignedInteger:valueMax forKey:key];
		}
		else
		{
			[result setObject:$dict(@"min", $int(valueMin), @"max", $int(valueMax)) forKey:key];
		}
	}
}


static void WriteEnumeration(NSMutableDictionary *result, NSString *key, OOShipClass *ship, OOShipClass *likeShip, SEL selector, NSString *defaultValue)
{
	WriteObject(result, key, [ship performSelector:selector], likeShip, selector, defaultValue);
}


#define STRINGIZE_VAL(v)	#v
#define STRINGIZE_TOK(t)	STRINGIZE_VAL(t)

#define WRIT_OBJECT(NAME)	WriteObject(result, kKey_##NAME, _##NAME, likeShip, @selector(NAME), kDefault_##NAME)
#define WRIT_ARRAY(NAME)	WRIT_OBJECT(NAME)
#define WRIT_DICT(NAME)		WRIT_OBJECT(NAME)
#define WRIT_ENUM(NAME)		WriteEnumeration(result, kKey_##NAME, self, likeShip, @selector(priv_##NAME##AsString), @STRINGIZE_TOK(kDefault_##NAME))
#define WRIT_BOOL(NAME)		WriteBool(result, kKey_##NAME, _##NAME, likeShip, @selector(NAME), kDefault_##NAME)
#define WRIT_FLOAT(NAME)	WriteFloat(result, kKey_##NAME, _##NAME, likeShip, @selector(NAME), kDefault_##NAME)
#define WRIT_FUZZY(NAME)	WriteFuzzyBool(result, kKey_##NAME, _##NAME, likeShip, @selector(NAME), kDefault_##NAME)
#define WRIT_PFLOAT(NAME)	WriteFloat(result, kKey_##NAME, fmaxf(0.0f, _##NAME), likeShip, @selector(NAME), kDefault_##NAME)
#define WRIT_QUAT(NAME)		WriteQuaternion(result, kKey_##NAME, _##NAME, likeShip, @selector(NAME), kDefault_##NAME)
#define WRIT_RANGE(NAME)	WriteRange(result, kKey_##NAME, _##NAME##Min, _##NAME##Max, likeShip, @selector(NAME##Min), @selector(NAME##Max), kDefault_##NAME##Min, kDefault_##NAME##Max)
#define WRIT_ROLES(NAME)	WriteRoles(result, kKey_##NAME, _##NAME, likeShip, @selector(NAME), kDefault_##NAME)
#define WRIT_STRING(NAME)	WRIT_OBJECT(NAME)
#define WRIT_UINT(NAME)		WriteUnsignedInteger(result, kKey_##NAME, _##NAME, likeShip, @selector(NAME), kDefault_##NAME)
#define WRIT_VECTOR(NAME)	WriteVector(result, kKey_##NAME, _##NAME, likeShip, @selector(NAME), kDefault_##NAME)


- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	OOShipClass			*likeShip = [self likeShip];
	
	// These properties aren’t inherited.
	if (_likeShipKey != nil)  [result setObject:_likeShipKey forKey:kKey_likeShip];
	if (_isTemplate)  [result oo_setBool:YES forKey:kKey_isTemplate];
	if (_isExternalDependency)  [result oo_setBool:YES forKey:kKey_isExternalDependency];
	if (_displayName != nil && ![_displayName isEqualToString:_name])  [result setObject:_displayName forKey:kKey_displayName];
	
	WRIT_STRING	(name);
	
	WRIT_ENUM	(scanClass);
	
	WRIT_STRING	(beaconCode);
	WRIT_BOOL	(isHulk);
	WRIT_STRING	(HUDName);
	
	WRIT_STRING	(pilotKey);
	WRIT_FUZZY	(unpilotedChance);
	WRIT_UINT	(escapePodCount);
	WRIT_ROLES	(escapePodRoles);
	WRIT_BOOL	(countsAsKill);
	
	WRIT_STRING	(scriptName);
	WRIT_DICT	(scriptInfo);
	WRIT_STRING	(AIName);
	WRIT_BOOL	(trackCloseContacts);
	
	WRIT_STRING	(modelName);
	WRIT_BOOL	(smooth);
	WRIT_DICT	(materialDefinitions);
	
	WRIT_ARRAY	(exhaustDefinitions);
	WRIT_ARRAY	(scannerColors);
	
	WRIT_UINT	(bounty);
	WRIT_FLOAT	(density);
	
	WRIT_ROLES	(roles);
	
	WRIT_ARRAY	(subentityDefinitions);	// FIXME: definitely needs item-by-item defaulting.
	WRIT_BOOL	(isFrangible);
	
	WRIT_UINT	(escortCount);
	WRIT_ROLES	(escortRoles);
	
	WRIT_VECTOR	(forwardViewPosition);
	WRIT_VECTOR	(aftViewPosition);
	WRIT_VECTOR	(portViewPosition);
	WRIT_VECTOR	(starboardViewPosition);
	WRIT_ARRAY	(customViews);
	
	WRIT_UINT	(cargoSpaceCapacity);
	WRIT_RANGE	(cargoSpaceUsed);
	WRIT_UINT	(cargoBayExpansionSize);
	WRIT_ENUM	(cargoType);
	
	WRIT_PFLOAT	(energyCapacity);
	WRIT_PFLOAT	(energyRechargeRate);
	
	WRIT_UINT	(fuelCapacity);
	WRIT_UINT	(initialFuel);
	WRIT_PFLOAT	(fuelChargeRate);
	
	WRIT_PFLOAT	(heatInsulation);
	
	WRIT_PFLOAT	(maxFlightSpeed);
	WRIT_PFLOAT	(maxFlightRoll);
	WRIT_PFLOAT	(maxFlightPitch);
	WRIT_PFLOAT	(maxFlightYaw);
	WRIT_PFLOAT	(maxThrust);
	WRIT_BOOL	(hasHyperspaceMotor);
	WRIT_PFLOAT	(hyperspaceMotorSpinTime);
	
	WRIT_FLOAT	(accuracy);
	WRIT_ENUM	(forwardWeaponType);
	WRIT_ENUM	(aftWeaponType);
	WRIT_ENUM	(portWeaponType);
	WRIT_ENUM	(starboardWeaponType);
	WRIT_VECTOR	(forwardWeaponPosition);
	WRIT_VECTOR	(aftWeaponPosition);
	WRIT_VECTOR	(portWeaponPosition);
	WRIT_VECTOR	(starboardWeaponPosition);
	WRIT_PFLOAT	(weaponEnergy);
	WRIT_PFLOAT	(turretRange);
	WRIT_OBJECT	(laserColor);
	
	WRIT_RANGE	(missileCount);
	WRIT_UINT	(missileCapacity);
	WRIT_ROLES	(missileRoles);
	
	WRIT_BOOL	(isSubmunition);
	
	return result;
}


- (NSString *) priv_scanClassAsString
{
	return OOStringFromScanClass(_scanClass);
}


- (NSString *) priv_cargoTypeAsString
{
	return CargoTypeToString(_cargoType);
}


- (NSString *) priv_forwardWeaponTypeAsString
{
	return OOStringFromWeaponType(_forwardWeaponType);
}


- (NSString *) priv_aftWeaponTypeAsString
{
	return OOStringFromWeaponType(_aftWeaponType);
}


- (NSString *) priv_portWeaponTypeAsString
{
	return OOStringFromWeaponType(_portWeaponType);
}


- (NSString *) priv_starboardWeaponTypeAsString
{
	return OOStringFromWeaponType(_starboardWeaponType);
}

#endif
				 
@end
