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


@interface OOShipClass (OOPrivate)

@end


@implementation OOShipClass

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
	DESTROY(_escortShipKey);
	DESTROY(_escortRole);
	DESTROY(_customViews);
	DESTROY(_cargoType);
	DESTROY(_laserColor);
	DESTROY(_missileRoles);
	DESTROY(_missiles);
	DESTROY(_equipment);
	DESTROY(_debrisRoles);
	DESTROY(_defenseShipRole);
	DESTROY(_defenseShipKey);
	DESTROY(_marketKey);
	
	[super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
	// OOShipClass is outwardly immutable.
	return [self retain];
}

@end
