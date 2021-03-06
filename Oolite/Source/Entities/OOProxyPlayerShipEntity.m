/*

OOProxyPlayerShipEntity.m


Oolite
Copyright (C) 2004-2011 Giles C Williams and contributors

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

#import "OOProxyPlayerShipEntity.h"


@implementation OOProxyPlayerShipEntity

- (id)initWithKey:(NSString *)key definition:(NSDictionary *)dict
{
	self = [super initWithKey:key definition:dict];
	if (self != nil)
	{
		[self setDialForwardShield:1.0f];
		[self setDialAftShield:1.0f];
		[self setDialFuelScoopStatus:[self hasScoop] ? SCOOP_STATUS_OKAY : SCOOP_STATUS_NOT_INSTALLED];
		[self setCompassMode:[self hasEquipmentItem:@"EQ_ADVANCED_COMPASS"] ? COMPASS_MODE_PLANET : COMPASS_MODE_BASIC];
	}
	
	return self;
}


- (void) copyValuesFromPlayer:(OOPlayerShipEntity *)player
{
	if (player == nil)  return;
	
	[self setFuelLeakRate:[player fuelLeakRate]];
	[self setMassLocked:[player massLocked]];
	[self setAtHyperspeed:[player atHyperspeed]];
	[self setDialForwardShield:[player dialForwardShield]];
	[self setDialAftShield:[player dialAftShield]];
	[self setDialMissileStatus:[player dialMissileStatus]];
	[self setDialFuelScoopStatus:[player dialFuelScoopStatus]];
	[self setCompassMode:[player compassMode]];
	[self setIdentEngaged:[player dialIdentEngaged]];
	[self setAlertCondition:[player alertCondition]];
	[self setTrumbleCount:[player trumbleCount]];
}


- (BOOL) isPlayerLikeShip
{
	return YES;
}


- (float) fuelLeakRate
{
	return _fuelLeakRate;
}

- (void) setFuelLeakRate:(float)value
{
	_fuelLeakRate = fmaxf(value, 0.0f);
}


- (BOOL) massLocked
{
	return _massLocked;
}

- (void) setMassLocked:(BOOL)value
{
	_massLocked = !!value;
}


- (BOOL) atHyperspeed
{
	return _atHyperspeed;
}

- (void) setAtHyperspeed:(BOOL)value
{
	_atHyperspeed = !!value;
}


- (GLfloat) dialForwardShield
{
	return _dialForwardShield;
}

- (void) setDialForwardShield:(GLfloat)value
{
	_dialForwardShield = value;
}


- (GLfloat) dialAftShield
{
	return _dialAftShield;
}

- (void) setDialAftShield:(GLfloat)value
{
	_dialAftShield = value;
}


- (OOMissileStatus) dialMissileStatus
{
	return _missileStatus;
}

- (void) setDialMissileStatus:(OOMissileStatus)value
{
	_missileStatus = value;
}


- (OOFuelScoopStatus) dialFuelScoopStatus
{
	return _fuelScoopStatus;
}

- (void) setDialFuelScoopStatus:(OOFuelScoopStatus)value
{
	_fuelScoopStatus = value;
}


- (OOCompassMode) compassMode
{
	return _compassMode;
}

- (void) setCompassMode:(OOCompassMode)value
{
	_compassMode = value;
}


- (BOOL) dialIdentEngaged
{
	return _dialIdentEngaged;
}

- (void) setIdentEngaged:(BOOL)value
{
	_dialIdentEngaged = !!value;
}


- (OOAlertCondition) alertCondition
{
	return _alertCondition;
}

- (void) setAlertCondition:(OOAlertCondition)value
{
	_alertCondition = value;
}


- (NSUInteger) trumbleCount
{
	return _trumbleCount;
}


- (void) setTrumbleCount:(NSUInteger)value
{
	_trumbleCount = value;
}


// If you're here to add more properties, don't forget to update -copyValuesFromPlayer:.

@end


@implementation OOEntity (ProxyPlayer)

- (BOOL) isPlayerLikeShip
{
	return NO;
}

@end


@implementation OOPlayerShipEntity (ProxyPlayer)

- (BOOL) isPlayerLikeShip
{
	return YES;
}

@end
