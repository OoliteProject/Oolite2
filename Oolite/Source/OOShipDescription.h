/*

OOShipDescription.h

Mutable, abstract representation of an individual ship.

This is currently used to represent ships in the shipyard; in future,
additional uses may be added.


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

@class OOShipClass, OOEquipmentType;


@interface OOShipDescription: NSObject
{
@private
	OOShipClass				*_shipClass;
	NSMutableDictionary		*_extras;
	NSMutableArray			*_missiles;
	NSMutableArray			*_equipment;
	NSMutableArray			*_escorts;
	NSString				*_debrisRole;
	
	NSUInteger				_cargoSpaceUsed;
	
	uint16_t				_personality;
	uint16_t				_isUnpiloted: 1,
							_canFragment: 1,
							_noBoulders: 1,
							_hasNPCTraffic: 1,
							_hasPatrolShips: 1;
}

- (id) initWithClass:(OOShipClass *)shipClass;

- (OOShipClass *) shipClass;
- (NSString *) shipKey;

/*
	These properties are selected randomly (within the constraints of the ship
	class) when the description is inited.
	Equipment is not validated until a ship is instantiated.
*/
- (uint16_t) personality;
- (void) setPersonality:(uint16_t)value;

- (NSArray *) missiles;
- (void) addObjectToMissiles:(OOEquipmentType *)missile;
- (void) insertObject:(OOEquipmentType *)missile inMissilesAtIndex:(NSUInteger)index;
- (void) removeObjectFromMissilesAtIndex:(NSUInteger)index;
- (void) replaceObjectInMissilesAtIndex:(NSUInteger)index withObject:(OOEquipmentType *)missile;
- (void) removeAllMissiles;

- (NSArray *) equipment;
- (void) addObjectToEquipment:(OOEquipmentType *)equipment;
- (void) insertObject:(OOEquipmentType *)equipment inEquipmentAtIndex:(NSUInteger)index;
- (void) removeObjectFromEquipmentAtIndex:(NSUInteger)index;
- (void) replaceObjectInEquipmentAtIndex:(NSUInteger)index withObject:(OOEquipmentType *)equipment;
- (void) removeAllEquipment;

- (NSArray *) escorts; // NSStrings (ship keys).
- (void) addObjectToEscorts:(NSString *)escort;
- (void) insertObject:(NSString *)equipment inEscortsAtIndex:(NSUInteger)index;
- (void) removeObjectFromEscortsAtIndex:(NSUInteger)index;
- (void) replaceObjectInEscortsAtIndex:(NSUInteger)index withObject:(NSString *)escort;
- (void) removeAllEscorts;

- (BOOL) isUnpiloted;
- (void) setUnpiloted:(BOOL)value;

- (NSUInteger) cargoSpaceUsed;
- (void) setCargoSpaceUsed:(NSUInteger)value;

- (BOOL) canFragment;
- (void) setCanFragment:(BOOL)value;

- (BOOL) noBoulders;
- (void) setNoBoulders:(BOOL)value;

- (NSString *) debrisRole;
- (void) setDebrisRole:(NSString *)value;

- (BOOL) hasNPCTraffic;
- (void) setHasNPCTraffic:(BOOL)value;

- (BOOL) hasPatrolShips;
- (void) setHasPatrolShips:(BOOL)value;

// Arbitrary associated data. Use nil value to remove objects.
- (id) valueForKey:(NSString *)key;
- (void) setValue:(id)value forKey:(NSString *)key;

@end
