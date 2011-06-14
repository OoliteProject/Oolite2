/*

OOShipDescription.m


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

#import "OOShipDescription.h"
#import "OOShipClass.h"
#import "OOShipEntity.h"


@implementation OOShipDescription

- (id) initWithClass:(OOShipClass *)shipClass
{
	if ((self = [super init]))
	{
		_shipClass = [shipClass retain];
		
		//	Set initial values for random properties.
		_personality = Ranrot() & ENTITY_PERSONALITY_MAX;
		
		_missiles = [[shipClass selectMissiles] retain];
		_equipment = [[shipClass selectEquipment] mutableCopy];
		
		NSUInteger escortCount = [shipClass escortCount];
		while (escortCount-- > 0)
		{
			[self addObjectToEscorts:[shipClass selectEscortShip]];
		}
		
		[self setUnpiloted:[shipClass selectUnpiloted]];
		[self setCargoSpaceUsed:[shipClass selectCargoSpaceUsed]];
		[self setCanFragment:[shipClass selectCanFragment]];
		[self setNoBoulders:[shipClass selectNoBoulders]];
		[self setDebrisRole:[shipClass selectDebrisRole]];
		
		if ([shipClass isCarrier])
		{
			[self setHasNPCTraffic:[shipClass selectHasNPCTraffic]];
			[self setHasPatrolShips:[shipClass selectHasPatrolShips]];
		}
	}
	
	return self;
}


- (void)dealloc
{
	DESTROY(_shipClass);
	DESTROY(_attributes);
	DESTROY(_missiles);
	DESTROY(_equipment);
	DESTROY(_escorts);
	DESTROY(_debrisRole);
	
    [super dealloc];
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"%@", [self shipKey]);
}


- (OOShipClass *) shipClass
{
	return _shipClass;
}


- (NSString *) shipKey
{
	return [[self shipClass] shipKey];
}


- (uint16_t) personality
{
	return _personality;
}


- (void) setPersonality:(uint16_t)value
{
	_personality = value;
}


#define MUTABLE_ARRAY_ACCESSORS(TYPE, NAME, CAPNAME) \
- (NSArray *) NAME  { return _##NAME ?: [NSArray array]; } \
- (NSUInteger) countOf##CAPNAME  { return [_##NAME count]; } \
- (TYPE *) objectIn##CAPNAME##AtIndex:(NSUInteger)idx { return [_##NAME objectAtIndex:idx]; } \
- (void) insertObject:(TYPE *)value in##CAPNAME##AtIndex:(NSUInteger)idx \
{ \
	if (_##NAME == nil)  _##NAME = [[NSMutableArray alloc] init]; \
	[_##NAME insertObject:value atIndex:idx]; \
} \
- (void) addObjectTo##CAPNAME:(TYPE *)value { [self insertObject:value in##CAPNAME##AtIndex:0]; } \
- (void) removeObjectFrom##CAPNAME##AtIndex:(NSUInteger)idx  { [_##NAME removeObjectAtIndex:idx]; } \
- (void) replaceObjectIn##CAPNAME##AtIndex:(NSUInteger)idx withObject:(TYPE *)value \
{ \
	if (_##NAME == nil)  _##NAME = [[NSMutableArray alloc] init]; \
	[_##NAME replaceObjectAtIndex:idx withObject:value]; \
} \
- (void) removeAll##CAPNAME  { DESTROY(_##NAME); }

MUTABLE_ARRAY_ACCESSORS(OOEquipmentType, missiles, Missiles)
MUTABLE_ARRAY_ACCESSORS(OOEquipmentType, equipment, Equipment)
MUTABLE_ARRAY_ACCESSORS(NSString, escorts, Escorts)

- (BOOL) isUnpiloted
{
	return _isUnpiloted;
}


- (void) setUnpiloted:(BOOL)value
{
	_isUnpiloted = !!value;
}


- (NSUInteger) cargoSpaceUsed
{
	return _cargoSpaceUsed;
}


- (void) setCargoSpaceUsed:(NSUInteger)value
{
	_cargoSpaceUsed = MIN(MAX(value, [[self shipClass] cargoSpaceUsedMin]), [[self shipClass] cargoSpaceUsedMax]);
}


- (BOOL) canFragment
{
	return _canFragment;
}


- (void) setCanFragment:(BOOL)value
{
	_canFragment = !!value;
}


- (BOOL) noBoulders
{
	return _noBoulders;
}


- (void) setNoBoulders:(BOOL)value
{
	_noBoulders = !!value;
}


- (NSString *) debrisRole
{
	return _debrisRole;
}


- (void) setDebrisRole:(NSString *)value
{
	[_debrisRole autorelease];
	_debrisRole = [value copy];
}


- (BOOL) hasNPCTraffic
{
	return _hasNPCTraffic;
}


- (void) setHasNPCTraffic:(BOOL)value
{
	_hasNPCTraffic = !!value;
}


- (BOOL) hasPatrolShips
{
	return _hasPatrolShips;
}


- (void) setHasPatrolShips:(BOOL)value
{
	_hasPatrolShips = !!value;
}


- (id) attributeValueForKey:(NSString *)key
{
	return [_attributes objectForKey:key];
}


- (void) setAttributeValue:(id)value forKey:(NSString *)key
{
	NSParameterAssert(key != nil);
	
	if (_attributes == nil && value != nil)
	{
		_attributes = [[NSMutableDictionary alloc] init];
	}
	
	if (value != nil)
	{
		[_attributes setObject:value forKey:key];
	}
	else
	{
		[_attributes removeObjectForKey:key];
	}
}

@end
