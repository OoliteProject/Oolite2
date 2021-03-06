/*

OOStationEntity.m

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

#import "OOStationEntity.h"
#import "OOShipEntity+AI.h"
#import "OOStringParsing.h"

#import "OOUniverse.h"
#import "HeadUpDisplay.h"

#import "OOPlanetEntity.h"
#import "OOShipGroup.h"
#import "OOQuiriumCascadeEntity.h"

#import "AI.h"
#import "OOCharacter.h"

#import "OOJSScript.h"
#import "OODebugGLDrawing.h"
#import "OODebugFlags.h"
#import "OOGeometryGLHelpers.h"


static NSDictionary* DockingInstructions(OOStationEntity *station, Vector coords, float speed, float range, NSString* ai_message, NSString* comms_message, BOOL match_rotation);

@interface OOStationEntity (private)

- (void)clearIdLocks:(OOShipEntity*)ship;
- (void) pullInShipIfPermitted:(OOShipEntity *)ship;

@end

#ifndef NDEBUG
@interface OOStationEntity (mwDebug)
- (NSArray *) dbgGetShipsOnApproach;
- (NSArray *) dbgGetIdLocks;
- (NSString *) dbgDumpIdLocks;
@end
#endif

@implementation OOStationEntity

- (OOTechLevelID) equivalentTechLevel
{
	return equivalentTechLevel;
}


- (void) setEquivalentTechLevel:(OOTechLevelID) value
{
	equivalentTechLevel = value;
}


- (Vector) getPortPosition
{
	Vector result = position;
	result.x += port_position.x * v_right.x + port_position.y * v_up.x + port_position.z * v_forward.x;
	result.y += port_position.x * v_right.y + port_position.y * v_up.y + port_position.z * v_forward.y;
	result.z += port_position.x * v_right.z + port_position.y * v_up.z + port_position.z * v_forward.z;
	return result;
}


- (Vector) getBeaconPosition
{
	double buoy_distance = 10000.0;				// distance from station entrance
	Vector result = position;
	Vector v_f = vector_forward_from_quaternion(orientation);
	result.x += buoy_distance * v_f.x;
	result.y += buoy_distance * v_f.y;
	result.z += buoy_distance * v_f.z;
	return result;
}


- (float) equipmentPriceFactor
{
	return equipmentPriceFactor;
}


- (NSMutableArray *) localMarket
{
	return localMarket;
}


- (void) setLocalMarket:(NSArray *) some_market
{
	if (localMarket)
		[localMarket release];
	localMarket = [[NSMutableArray alloc] initWithArray:some_market];
}


- (NSMutableArray *) localPassengers
{
	return localPassengers;
}


- (void) setLocalPassengers:(NSArray *) some_market
{
	if (localPassengers)
		[localPassengers release];
	localPassengers = [[NSMutableArray alloc] initWithArray:some_market];
}


- (NSMutableArray *) localContracts
{
	return localContracts;
}


- (void) setLocalContracts:(NSArray *) some_market
{
	if (localContracts)
		[localContracts release];
	localContracts = [[NSMutableArray alloc] initWithArray:some_market];
}


- (NSMutableArray *) localShipyard
{
	return localShipyard;
}


- (void) setLocalShipyard:(NSArray *) some_market
{
	if (localShipyard)
		[localShipyard release];
	localShipyard = [[NSMutableArray alloc] initWithArray:some_market];
}


- (NSMutableArray *) initialiseLocalMarketWithRandomFactor:(int) random_factor
{
	return [self initialiseMarketWithSeed:[PLAYER system_seed] andRandomFactor:random_factor];
}


- (NSMutableArray *) initialiseMarketWithSeed:(Random_Seed) s_seed andRandomFactor:(int) random_factor
{
	int tmp_seed = ranrot_rand();
	int rf = (random_factor ^ universalID) & 0xff;
	int economy = [[UNIVERSE generateSystemData:s_seed] oo_intForKey:KEY_ECONOMY];
	if (localMarket)
		[localMarket release];
	localMarket = [[NSMutableArray alloc] initWithArray:[UNIVERSE commodityDataForEconomy:economy andStation:self andRandomFactor:rf]];
	ranrot_srand(tmp_seed);
	return localMarket;
}


- (void) setPlanet:(OOPlanetEntity *)planet
{
	if (planet != [_planet weakRefUnderlyingObject])
	{
		DESTROY(_planet);
		_planet = [planet weakRetain];
	}
}


- (OOPlanetEntity *) planet
{
	OOPlanetEntity *planet = [_planet weakRefUnderlyingObject];
	if (planet == nil && _planet != nil)  DESTROY(_planet);
	return planet;
}


- (unsigned) dockedContractors
{
	return max_scavengers > scavengers_launched ? max_scavengers - scavengers_launched : 0;
}


- (unsigned) dockedPolice
{
	return max_police > defenders_launched ? max_police - defenders_launched : 0;
}


- (unsigned) dockedDefenders
{
	return max_defense_ships > defenders_launched ? max_defense_ships - defenders_launched : 0;
}


- (void) sanityCheckShipsOnApproach
{
	unsigned i;
	NSArray*	ships = [shipsOnApproach allKeys];
	
	// Remove dead entities.
	// No enumerator because we mutate the dictionary.
	for (i = 0; i < [ships count]; i++)
	{
		int sid = [[ships objectAtIndex:i] intValue];
		if ((sid == NO_TARGET)||(![UNIVERSE entityForUniversalID:sid]))
		{
			[shipsOnApproach removeObjectForKey:[ships objectAtIndex:i]];
			if ([shipsOnApproach count] == 0)
				[shipAI message:@"DOCKING_COMPLETE"];
		}
	}
	
	if ([shipsOnApproach count] == 0)
	{
		if (last_launch_time < [UNIVERSE gameTime])
		{
			last_launch_time = [UNIVERSE gameTime];
		}
		approach_spacing = 0.0;
	}
	
	ships = [shipsOnHold allKeys];
	for (i = 0; i < [ships count]; i++)
	{
		int sid = [[ships objectAtIndex:i] intValue];
		if ((sid == NO_TARGET)||(![UNIVERSE entityForUniversalID:sid]))
		{
			[shipsOnHold removeObjectForKey:[ships objectAtIndex:i]];
		}
	}
}


// Exposed to AI
- (void) abortAllDockings
{
	unsigned i;
	NSArray*	ships = [shipsOnApproach allKeys];
	no_docking_while_launching = YES;

	for (i = 0; i < [ships count]; i++)
	{
		int sid = [[ships objectAtIndex:i] intValue];
		if ([UNIVERSE entityForUniversalID:sid])
			[[[UNIVERSE entityForUniversalID:sid] getAI] message:@"DOCKING_ABORTED"];
	}
	[shipsOnApproach removeAllObjects];

	OOPlayerShipEntity *player = PLAYER;
	BOOL isDockingStation = (self == [player getTargetDockStation]);
	if (isDockingStation && [player status] == STATUS_IN_FLIGHT &&
			[player getDockingClearanceStatus] >= DOCKING_CLEARANCE_STATUS_REQUESTED)
	{
		[self sendExpandedMessage:DESC(@"station-docking-clearance-abort-cancelled") toShip:player];
		[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_NONE];
	}
	
	ships = [shipsOnHold allKeys];
	for (i = 0; i < [ships count]; i++)
	{
		int sid = [[ships objectAtIndex:i] intValue];
		if ([UNIVERSE entityForUniversalID:sid])
			[[[UNIVERSE entityForUniversalID:sid] getAI] message:@"DOCKING_ABORTED"];
	}
	[shipsOnHold removeAllObjects];
	
	[shipAI message:@"DOCKING_COMPLETE"];
	last_launch_time = [UNIVERSE gameTime];
	approach_spacing = 0.0;
}


- (void) autoDockShipsInQueue:(NSMutableDictionary *)queue
{
	NSArray		*ships = [queue allKeys];
	unsigned	i, count = [ships count];
	
	for (i = 0; i < count; i++)
	{
		OOShipEntity *ship = [UNIVERSE entityForUniversalID:[ships oo_unsignedIntAtIndex:i]];
		if ([ship isShip])
		{
			[self pullInShipIfPermitted:ship];
		}
	}
	
	[queue removeAllObjects];
}


- (void) autoDockShipsOnApproach
{
	[self autoDockShipsInQueue:shipsOnApproach];
	[self autoDockShipsInQueue:shipsOnHold];
	
	[shipAI message:@"DOCKING_COMPLETE"];
}

static NSDictionary* DockingInstructions(OOStationEntity *station, Vector coords, float speed, float range, NSString* ai_message, NSString* comms_message, BOOL match_rotation)
{
	NSMutableDictionary *acc = [NSMutableDictionary dictionaryWithCapacity:8];
	[acc setObject:[NSString stringWithFormat:@"%.2f %.2f %.2f", coords.x, coords.y, coords.z] forKey:@"destination"];
	[acc setObject:[NSNumber numberWithFloat:speed] forKey:@"speed"];
	[acc setObject:[NSNumber numberWithFloat:range] forKey:@"range"];
	[acc setObject:[station weakRetain] forKey:@"station"];
	[acc setObject:[NSNumber numberWithBool:match_rotation] forKey:@"match_rotation"];
	if (ai_message)
		[acc setObject:ai_message forKey:@"ai_message"];
	if (comms_message)
		[acc setObject:comms_message forKey:@"comms_message"];
	//
	return [NSDictionary dictionaryWithDictionary:acc];
}

// this routine does more than set coordinates - it provides a whole set of docking instructions and messages at each stage..
//
- (NSDictionary *) dockingInstructionsForShip:(OOShipEntity *) ship
{	
	Vector		coords;
	
	int			ship_id = [ship universalID];
	NSNumber	*shipID = [NSNumber numberWithUnsignedShort:ship_id];

	Vector launchVector = vector_forward_from_quaternion(quaternion_multiply(port_orientation, orientation));
	Vector temp = (fabsf(launchVector.x) < 0.8)? make_vector(1,0,0) : make_vector(0,1,0);
	temp = cross_product(launchVector, temp);	// 90 deg to launchVector & temp
	Vector vi = cross_product(launchVector, temp);
	Vector vj = cross_product(launchVector, vi);
	Vector vk = launchVector;
	
	if (!ship)
		return nil;
	
	if ((ship->isPlayer)&&([ship legalStatus] > 50))	// note: non-player fugitives dock as normal
	{
		// refuse docking to the fugitive player
		return DockingInstructions(self, ship->position, 0, 100, @"DOCKING_REFUSED", @"[station-docking-refused-to-fugitive]", NO);
	}
	
	if (no_docking_while_launching)
	{
		return DockingInstructions(self, ship->position, 0, 100, @"TRY_AGAIN_LATER", nil, NO);
	}

	OOBoundingBox bb = [ship boundingBox];
	if ((port_dimensions.x < (bb.max.x - bb.min.x) || port_dimensions.y < (bb.max.y - bb.min.y)) && 
		(port_dimensions.y < (bb.max.x - bb.min.x) || port_dimensions.x < (bb.max.y - bb.min.y)))
	{
		return DockingInstructions(self, ship->position, 0, 100, @"TOO_BIG_TO_DOCK", nil, NO);
	}
	
	// If the ship is not on its docking approach and the player has
	// requested or even been granted docking clearance, then tell the
	// ship to wait.
	OOPlayerShipEntity *player = PLAYER;
	BOOL isDockingStation = self == [player getTargetDockStation];
	if (isDockingStation && ![shipsOnApproach objectForKey:shipID] &&
			player && [player status] == STATUS_IN_FLIGHT &&
			[player getDockingClearanceStatus] >= DOCKING_CLEARANCE_STATUS_REQUESTED)
	{
		return DockingInstructions(self, ship->position, 0, 100, @"TRY_AGAIN_LATER", nil, NO);
	}
	
	[shipAI reactToMessage:@"DOCKING_REQUESTED" context:@"requestDockingCoordinates"];	// react to the request	
	
	if	(magnitude2([self velocity]) > 1.0)		// no docking while moving
	{
		if (![shipsOnHold objectForKey:shipID])
			[self sendExpandedMessage: @"[station-acknowledges-hold-position]" toShip: ship];
		[shipsOnHold setObject: shipID forKey: shipID];
		//[self performStop]; // This should be handled by "DOCKING_REQUESTED" in the AI itself.
		return DockingInstructions(self, ship->position, 0, 100, @"HOLD_POSITION", nil, NO);
	}
	
	if	(fabs(flightPitch) > 0.01)		// no docking while pitching
	{
		if (![shipsOnHold objectForKey:shipID])
			[self sendExpandedMessage: @"[station-acknowledges-hold-position]" toShip: ship];
		[shipsOnHold setObject: shipID forKey: shipID];
		//[self performStop];
		return DockingInstructions(self, ship->position, 0, 100, @"HOLD_POSITION", nil, NO);
	}
	
	// rolling is okay for some
	if	(fabs(flightRoll) > 0.01 && ![self isRotatingStation])		// rolling
	{
		Vector portPos = [self getPortPosition];
		Vector portDir = vector_forward_from_quaternion(port_orientation);		
		BOOL isOffCentre = (fabs(portPos.x) + fabs(portPos.y) > 0.0f)|(fabs(portDir.x) + fabs(portDir.y) > 0.0f);

		if (isOffCentre)
		{
			if (![shipsOnHold objectForKey:shipID])
				[self sendExpandedMessage: @"[station-acknowledges-hold-position]" toShip: ship];
			[shipsOnHold setObject: shipID forKey: shipID];
			//[self performStop];
			return DockingInstructions(self, ship->position, 0, 100, @"HOLD_POSITION", nil, NO);
		}
	}
	
	// we made it thorugh holding!
	//
	if ([shipsOnHold objectForKey:shipID])
		[shipsOnHold removeObjectForKey:shipID];
	
	// check if this is a new ship on approach
	//
	if (![shipsOnApproach objectForKey:shipID])
	{
		Vector	delta = vector_subtract([ship position], [self position]);
		float	ship_distance = magnitude(delta);

		if (ship_distance > SCANNER_MAX_RANGE)	// too far away - don't claim a docking slot by not putting on approachlist for now.
			return DockingInstructions(self, position, 0, 10000, @"APPROACH", nil, NO);

		[self addShipToShipsOnApproach: ship];
		
		if (ship_distance < 1000.0 + collision_radius + ship->collision_radius)	// too close - back off
			return DockingInstructions(self, position, 0, 5000, @"BACK_OFF", nil, NO);
		
		if (ship_distance > 12500.0)	// long way off - approach more closely
			return DockingInstructions(self, position, 0, 10000, @"APPROACH", nil, NO);
	}
	
	if (![shipsOnApproach objectForKey:shipID])
	{
		// some error has occurred - log it, and send the try-again message
		OOLogERR(@"station.issueDockingInstructions.failed", @"couldn't addShipToShipsOnApproach:%@ in %@, retrying later -- shipsOnApproach:\n%@", ship, self, shipsOnApproach);
		//
		return DockingInstructions(self, ship->position, 0, 100, @"TRY_AGAIN_LATER", nil, NO);
	}


	//	shipsOnApproach now has an entry for the ship.
	//
	NSMutableArray* coordinatesStack = [shipsOnApproach objectForKey:shipID];

	if ([coordinatesStack count] == 0)
	{
		OOLogERR(@"station.issueDockingInstructions.failed", @" -- coordinatesStack = %@", coordinatesStack);
		
		return DockingInstructions(self, ship->position, 0, 100, @"HOLD_POSITION", nil, NO);
	}
	
	// get the docking information from the instructions	
	NSMutableDictionary* nextCoords = (NSMutableDictionary *)[coordinatesStack objectAtIndex:0];
	int docking_stage = [nextCoords oo_intForKey:@"docking_stage"];
	float speedAdvised = [nextCoords oo_floatForKey:@"speed"];
	float rangeAdvised = [nextCoords oo_floatForKey:@"range"];
	
	// calculate world coordinates from relative coordinates
	Vector rel_coords;
	rel_coords.x = [nextCoords oo_floatForKey:@"rx"];
	rel_coords.y = [nextCoords oo_floatForKey:@"ry"];
	rel_coords.z = [nextCoords oo_floatForKey:@"rz"];
	coords = [self getPortPosition];
	coords.x += rel_coords.x * vi.x + rel_coords.y * vj.x + rel_coords.z * vk.x;
	coords.y += rel_coords.x * vi.y + rel_coords.y * vj.y + rel_coords.z * vk.y;
	coords.z += rel_coords.x * vi.z + rel_coords.y * vj.z + rel_coords.z * vk.z;
	
	// check if the ship is at the control point
	double max_allowed_range = 2.0 * rangeAdvised + ship->collision_radius;	// maximum distance permitted from control point - twice advised range
	Vector delta = ship->position;
	delta.x -= coords.x;	delta.y -= coords.y;	delta.z -= coords.z;

	if (magnitude2(delta) > max_allowed_range * max_allowed_range)	// too far from the coordinates - do not remove them from the stack!
	{
		if ((docking_stage == 1) &&(magnitude2(delta) < 1000000.0))	// 1km*1km
			speedAdvised *= 0.5;	// half speed
		
		return DockingInstructions(self, coords, speedAdvised, rangeAdvised, @"APPROACH_COORDINATES", nil, NO);
	}
	else
	{
		// reached the current coordinates okay..
	
		// get the NEXT coordinates
		nextCoords = (NSMutableDictionary *)[coordinatesStack oo_dictionaryAtIndex:1];
		if (nextCoords == nil)
		{
			return nil;
		}
		
		docking_stage = [nextCoords oo_intForKey:@"docking_stage"];
		speedAdvised = [nextCoords oo_floatForKey:@"speed"];
		rangeAdvised = [nextCoords oo_floatForKey:@"range"];
		BOOL match_rotation = [nextCoords oo_boolForKey:@"match_rotation"];
		NSString *comms_message = [nextCoords oo_stringForKey:@"comms_message"];
		
		if (comms_message)
		{
			[self sendExpandedMessage: comms_message toShip: ship];
		}
				
		// calculate world coordinates from relative coordinates
		rel_coords.x = [nextCoords oo_floatForKey:@"rx"];
		rel_coords.y = [nextCoords oo_floatForKey:@"ry"];
		rel_coords.z = [nextCoords oo_floatForKey:@"rz"];
		coords = [self getPortPosition];
		coords.x += rel_coords.x * vi.x + rel_coords.y * vj.x + rel_coords.z * vk.x;
		coords.y += rel_coords.x * vi.y + rel_coords.y * vj.y + rel_coords.z * vk.y;
		coords.z += rel_coords.x * vi.z + rel_coords.y * vj.z + rel_coords.z * vk.z;
		
		if( ([id_lock[docking_stage] weakRefUnderlyingObject] == nil)
		   &&([id_lock[docking_stage + 1] weakRefUnderlyingObject] == nil)
		   &&([id_lock[docking_stage + 2] weakRefUnderlyingObject] == nil))	// check three stages ahead
		{
			// approach is clear - move to next position
			//
			
			// clear any previously owned docking stages
			[self clearIdLocks:ship];
					
			if (docking_stage > 1)	// don't claim first docking stage
			{
				[id_lock[docking_stage] release];
				id_lock[docking_stage] = [ship weakRetain];	// otherwise - claim this docking stage
			}
			
			//remove the previous stage from the stack
			[coordinatesStack removeObjectAtIndex:0];
			
			return DockingInstructions(self, coords, speedAdvised, rangeAdvised, @"APPROACH_COORDINATES", nil, match_rotation);
		}
		else
		{
			// approach isn't clear - hold position..
			//
			[[ship getAI] message:@"HOLD_POSITION"];
			
			if (![nextCoords objectForKey:@"hold_message_given"])
			{
				// COMM-CHATTER
				[UNIVERSE clearPreviousMessage];
				[self sendExpandedMessage: @"[station-hold-position]" toShip: ship];
				[nextCoords setObject:@"YES" forKey:@"hold_message_given"];
			}

			return DockingInstructions(self, ship->position, 0, 100, @"HOLD_POSITION", nil, NO);
		}
	}
	
	// we should never reach here.
	return DockingInstructions(self, coords, 50, 10, @"APPROACH_COORDINATES", nil, NO);
}


- (void) addShipToShipsOnApproach:(OOShipEntity *) ship
{		
	int			corridor_distance[] =	{	-1,	1,	3,	5,	7,	9,	11,	12,	12};
	int			corridor_offset[] =		{	0,	0,	0,	0,	0,	0,	1,	3,	12};
	int			corridor_speed[] =		{	48,	48,	48,	48,	36,	48,	64,	128, 512};	// how fast to approach the next point
	int			corridor_range[] =		{	24,	12,	6,	4,	4,	6,	15,	38,	96};	// how close you have to get to the target point
	int			corridor_rotate[] =		{	1,	1,	1,	1,	0,	0,	0,	0,	0};		// whether to match the station rotation
	int			corridor_count = 9;
	int			corridor_final_approach = 3;
	
	NSNumber	*shipID = [NSNumber numberWithUnsignedShort:[ship universalID]];
	
	Vector launchVector = vector_forward_from_quaternion(quaternion_multiply(port_orientation, orientation));
	Vector temp = (fabsf(launchVector.x) < 0.8)? make_vector(1,0,0) : make_vector(0,1,0);
	temp = cross_product(launchVector, temp);	// 90 deg to launchVector & temp
	Vector rightVector = cross_product(launchVector, temp);
	Vector upVector = cross_product(launchVector, rightVector);
	
	// will select a direction for offset based on the entity personality (was ship ID)
	int offset_id = [ship entityPersonalityInt] & 0xf;	// 16  point compass
	double c = cos(offset_id * M_PI / 8.0);
	double s = sin(offset_id * M_PI / 8.0);
	
	// test if this points at the ship
	Vector point1 = [self getPortPosition];
	point1.x += launchVector.x * corridor_offset[corridor_count - 1];
	point1.y += launchVector.x * corridor_offset[corridor_count - 1];
	point1.z += launchVector.x * corridor_offset[corridor_count - 1];
	Vector alt1 = point1;
	point1.x += c * upVector.x * corridor_offset[corridor_count - 1] + s * rightVector.x * corridor_offset[corridor_count - 1];
	point1.y += c * upVector.y * corridor_offset[corridor_count - 1] + s * rightVector.y * corridor_offset[corridor_count - 1];
	point1.z += c * upVector.z * corridor_offset[corridor_count - 1] + s * rightVector.z * corridor_offset[corridor_count - 1];
	alt1.x -= c * upVector.x * corridor_offset[corridor_count - 1] + s * rightVector.x * corridor_offset[corridor_count - 1];
	alt1.y -= c * upVector.y * corridor_offset[corridor_count - 1] + s * rightVector.y * corridor_offset[corridor_count - 1];
	alt1.z -= c * upVector.z * corridor_offset[corridor_count - 1] + s * rightVector.z * corridor_offset[corridor_count - 1];
	if (distance2(alt1, ship->position) < distance2(point1, ship->position))
	{
		s = -s;
		c = -c;	// turn 180 degrees
	}
	
	//
	NSMutableArray*		coordinatesStack =  [NSMutableArray arrayWithCapacity: MAX_DOCKING_STAGES];
	double port_depth = 250;	// 250m deep standard port.
	
	//
	int i;
	double corridor_length;
	for (i = corridor_count - 1; i >= 0; i--)
	{
		NSMutableDictionary*	nextCoords =	[NSMutableDictionary dictionaryWithCapacity:3];
		
		int offset = corridor_offset[i];
		
		// space out first coordinate further if there are many ships
		if ((i == corridor_count - 1) && offset)
			offset += approach_spacing / port_depth;
		
		[nextCoords setObject:[NSNumber numberWithInt: corridor_count - i] forKey:@"docking_stage"];

		[nextCoords setObject:[NSNumber numberWithFloat: s * port_depth * offset]	forKey:@"rx"];
		[nextCoords setObject:[NSNumber numberWithFloat: c * port_depth * offset]	forKey:@"ry"];
		corridor_length = port_depth * corridor_distance[i];
		 // add the lenght inside the station to the corridor, except for the final position, inside the dock.
		if (corridor_distance[i] > 0) corridor_length += port_corridor;
		[nextCoords setObject:[NSNumber numberWithFloat: corridor_length]	forKey:@"rz"];
		[nextCoords setObject:[NSNumber numberWithFloat: corridor_speed[i]] forKey:@"speed"];
		[nextCoords setObject:[NSNumber numberWithFloat: corridor_range[i]] forKey:@"range"];
		
		if (corridor_rotate[i])
			[nextCoords setObject:@"YES" forKey:@"match_rotation"];
		
		if (i == corridor_final_approach)
		{
			if (self == [UNIVERSE station])
				[nextCoords setObject:@"[station-begin-final-aproach]" forKey:@"comms_message"];
			else
				[nextCoords setObject:@"[docking-begin-final-aproach]" forKey:@"comms_message"];
		}

		[coordinatesStack addObject:nextCoords];
	}
	
	[shipsOnApproach setObject:coordinatesStack forKey:shipID];
	
	approach_spacing += 500;  // space out incoming ships by 500m
	
	// COMM-CHATTER
	if (self == [UNIVERSE station])
		[self sendExpandedMessage: @"[station-welcome]" toShip: ship];
	else
		[self sendExpandedMessage: @"[docking-welcome]" toShip: ship];

}


- (void) abortDockingForShip:(OOShipEntity *) ship
{
	int			ship_id = [ship universalID];
	NSNumber	*shipID = [NSNumber numberWithUnsignedShort:ship_id];
	if ([UNIVERSE entityForUniversalID:[ship universalID]])
		[[[UNIVERSE entityForUniversalID:[ship universalID]] getAI] message:@"DOCKING_ABORTED"];
	
	if ([shipsOnHold objectForKey:shipID])
		[shipsOnHold removeObjectForKey:shipID];
	
	if ([shipsOnApproach objectForKey:shipID])
	{
		[shipsOnApproach removeObjectForKey:shipID];
		if ([shipsOnApproach count] == 0)
			[shipAI message:@"DOCKING_COMPLETE"];
	}
		
	// clear any previously owned docking stages
	[self clearIdLocks:ship];
}


- (Vector) portUpVector
{
	if (port_dimensions.x > port_dimensions.y)
	{
		return vector_up_from_quaternion(quaternion_multiply(port_orientation, orientation));
	}
	else
	{
		return vector_right_from_quaternion(quaternion_multiply(port_orientation, orientation));
	}
}


- (Vector) portUpVectorForShipsBoundingBox:(OOBoundingBox) bb
{
	BOOL twist = ((port_dimensions.x < port_dimensions.y) ^ (bb.max.x - bb.min.x < bb.max.y - bb.min.y));

	if (!twist)
	{
		return vector_up_from_quaternion(quaternion_multiply(port_orientation, orientation));
	}
	else
	{
		return vector_right_from_quaternion(quaternion_multiply(port_orientation, orientation));
	}
}


- (id)initWithKey:(NSString *)key definition:(NSDictionary *)dict
{
	OOJS_PROFILE_ENTER
	
	self = [super initWithKey:key definition:dict];
	if (self != nil)
	{
		// FIXME: why aren't these in setup?
		isStation = YES;
		
		shipsOnApproach = [[NSMutableDictionary alloc] init];
		shipsOnHold = [[NSMutableDictionary alloc] init];
		launchQueue = [[NSMutableArray alloc] init];
	}
	
	return self;
	
	OOJS_PROFILE_EXIT
}


- (void) dealloc
{
	DESTROY(shipsOnApproach);
	DESTROY(shipsOnHold);
	DESTROY(launchQueue);
	[self clearIdLocks:nil];
	
	DESTROY(_planet);
	DESTROY(localMarket);
	DESTROY(localPassengers);
	DESTROY(localContracts);
	DESTROY(localShipyard);
	
	[super dealloc];
}

- (void) clearIdLocks:(OOShipEntity *)ship
{
	int i;
	for (i = 1; i < MAX_DOCKING_STAGES; i++)
	{
		if (ship == nil || ship == [id_lock[i] weakRefUnderlyingObject])
		{
			DESTROY(id_lock[i]);
		}
	}
}


- (BOOL) setUpShipWithShipClass:(OOShipClass *)shipClass andDictionary:(NSDictionary *)dict
{
	OOJS_PROFILE_ENTER
	
	isShip = YES;
	isStation = YES;
	alertLevel = STATION_ALERT_LEVEL_GREEN;
	
	port_position = kBasisZVector;
	port_dimensions = kZeroVector;
	port_orientation = kIdentityQuaternion;
	port_corridor = 0;
	
	if (![super setUpShipWithShipClass:shipClass andDictionary:dict])  return NO;
	
	equivalentTechLevel = [dict oo_unsignedIntegerForKey:@"equivalent_tech_level" defaultValue:NSNotFound];
	max_scavengers = [dict oo_unsignedIntForKey:@"max_scavengers" defaultValue:3];
	max_defense_ships = [dict oo_unsignedIntForKey:@"max_defense_ships" defaultValue:3];
	max_police = [dict oo_unsignedIntForKey:@"max_police" defaultValue:STATION_MAX_POLICE];
	equipmentPriceFactor = [dict oo_nonNegativeFloatForKey:@"equipment_price_factor" defaultValue:1.0];
	equipmentPriceFactor = fmaxf(equipmentPriceFactor, 0.5f);
	hasNPCTraffic = [dict oo_fuzzyBooleanForKey:@"has_npc_traffic" defaultValue:YES];
	hasPatrolShips = [dict oo_fuzzyBooleanForKey:@"has_patrol_ships" defaultValue:NO];
	suppress_arrival_reports = [dict oo_boolForKey:@"suppress_arrival_reports" defaultValue:NO];
	NSDictionary *universalInfo = [[UNIVERSE planetInfo] oo_dictionaryForKey:PLANETINFO_UNIVERSAL_KEY];
	
	// Non main stations may have requiresDockingClearance set to yes as a result of the code below,
	// but this variable should be irrelevant for them, as they do not make use of it anyway.
	requiresDockingClearance = [dict oo_boolForKey:@"requires_docking_clearance" defaultValue:
		universalInfo != nil ?	[universalInfo oo_boolForKey:@"stations_require_docking_clearance" defaultValue:NO] : NO];
	
	allowsFastDocking = [dict oo_boolForKey:@"allows_fast_docking" defaultValue:NO];
	
	allowsAutoDocking = [dict oo_boolForKey:@"allows_auto_docking" defaultValue:YES];
	
	interstellarUndockingAllowed = [dict oo_boolForKey:@"interstellar_undocking" defaultValue:NO];
	
	double unitime = [UNIVERSE gameTime];

	if ([self isRotatingStation] && [self hasNPCTraffic])
	{
		docked_shuttles = ranrot_rand() & 3;   // 0..3;
		shuttle_launch_interval = OOMINUTES(15.0);
		last_shuttle_launch_time = unitime - (ranrot_rand() & 63) * shuttle_launch_interval / kOOSecondsPerMinute;
		
		docked_traders = 3 + (ranrot_rand() & 7);   // 1..3;
		trader_launch_interval = kOOSecondsPerHour / docked_traders;  // every few minutes
		last_trader_launch_time = unitime + kOOSecondsPerMinute - trader_launch_interval; // in one minute's time
	}
	else
	{
		docked_shuttles = 0;
		docked_traders = 0;   // 1..3;
	}
	
	patrol_launch_interval = OOMINUTES(5.0);
	last_patrol_report_time = unitime - patrol_launch_interval;
	
	[self setCrew:[NSArray arrayWithObject:[OOCharacter characterWithRole:@"police" andOriginalSystem:[UNIVERSE systemSeed]]]];
	
	if ([self group] == nil)
	{
		[self setGroup:[self stationGroup]];
	}
	return YES;
	
	OOJS_PROFILE_EXIT
}


- (void) setDockingPortModel:(OOShipEntity*) dock_model :(Vector) dock_pos :(Quaternion) dock_q
{
	port_model = dock_model;
	
	port_position = dock_pos;
	port_orientation = dock_q;

	OOBoundingBox bb = [port_model boundingBox];
	port_dimensions = make_vector(bb.max.x - bb.min.x, bb.max.y - bb.min.y, bb.max.z - bb.min.z);

	Vector vk = vector_forward_from_quaternion(dock_q);
	
	if (bb.max.z > 0.0)
	{
		port_position.x += bb.max.z * vk.x;
		port_position.y += bb.max.z * vk.y;
		port_position.z += bb.max.z * vk.z;
	}
	
	// check if start is within bounding box...
	Vector start = port_position;
	while (	(start.x > boundingBox.min.x)&&(start.x < boundingBox.max.x)&&
		   (start.y > boundingBox.min.y)&&(start.y < boundingBox.max.y)&&
		   (start.z > boundingBox.min.z)&&(start.z < boundingBox.max.z) )
	{
		start = vector_add(start, vector_multiply_scalar(vk, port_dimensions.z));
	}
	port_corridor = start.z - port_position.z; // length of the docking tunnel.
}


- (BOOL) shipIsInDockingCorridor:(OOShipEntity *)ship
{
	if (![ship isShip])  return NO;
	if ([ship isPlayer] && [ship status] == STATUS_DEAD)  return NO;
	
	Quaternion q0 = quaternion_multiply(port_orientation, orientation);
	Vector vi = vector_right_from_quaternion(q0);
	Vector vj = vector_up_from_quaternion(q0);
	Vector vk = vector_forward_from_quaternion(q0);
	
	Vector port_pos = [self getPortPosition];
	
	OOBoundingBox shipbb = [ship boundingBox];
	OOBoundingBox arbb = [ship findBoundingBoxRelativeToPosition: port_pos InVectors: vi : vj : vk];
	
	// port dimensions..
	GLfloat ww = port_dimensions.x;
	GLfloat hh = port_dimensions.y;
	GLfloat dd = port_dimensions.z;

	while (shipbb.max.x - shipbb.min.x > ww * 0.90)	ww *= 1.25;
	while (shipbb.max.y - shipbb.min.y > hh * 0.90)	hh *= 1.25;
	
	ww *= 0.5;
	hh *= 0.5;
	
#ifndef NDEBUG
	if ([ship isPlayer] && (gDebugFlags & DEBUG_DOCKING))
	{
		BOOL			inLane;
		float			range;
		unsigned		laneFlags = 0;
		
		if (arbb.max.x < ww)   laneFlags |= 1;
		if (arbb.min.x > -ww)  laneFlags |= 2;
		if (arbb.max.y < hh)   laneFlags |= 4;
		if (arbb.min.y > -hh)  laneFlags |= 8;
		inLane = laneFlags == 0xF;
		range = 0.90 * arbb.max.z + 0.10 * arbb.min.z;
		
		OOLog(@"docking.debug", @"Normalised port dimensions are %g x %g x %g.  Player bounding box is at %@-%@ -- %s (%X), range: %g",
			ww * 2.0, hh * 2.0, dd,
			OOVectorDescription(arbb.min), OOVectorDescription(arbb.max),
			inLane ? "in lane" : "out of lane", laneFlags,
			range);
	}
#endif

	if (arbb.max.z < -dd)
		return NO;

	if ((arbb.max.x < ww)&&(arbb.min.x > -ww)&&(arbb.max.y < hh)&&(arbb.min.y > -hh))
	{
		// in lane
		if (0.90 * arbb.max.z + 0.10 * arbb.min.z < 0.0)	// we're 90% in docking position!
		{
			[self pullInShipIfPermitted:ship];
		}
		return YES;
	}
	
	if ([ship status] == STATUS_LAUNCHING)
	{
		return YES;
	}
	
	// if close enough (within 50%) correct and add damage
	//
	if  ((arbb.min.x > -1.5 * ww)&&(arbb.max.x < 1.5 * ww)&&(arbb.min.y > -1.5 * hh)&&(arbb.max.y < 1.5 * hh))
	{
		if (arbb.min.z < 0.0)	// got our nose inside
		{
			GLfloat correction_factor = -arbb.min.z / (arbb.max.z - arbb.min.z);	// proportion of ship inside
		
			// damage the ship according to velocity - don't send collision messages to AIs to avoid problems.
			[ship takeScrapeDamage: 5 * [UNIVERSE timeDelta]*[ship flightSpeed] from:self];
			[self doScriptEvent:OOJSID("shipCollided") withArgument:ship]; // no COLLISION message to station AI, carriers would move away!
			[ship doScriptEvent:OOJSID("shipCollided") withArgument:self]; // no COLLISION message to ship AI, dockingAI.plist would abort.
			
			Vector delta;
			delta.x = 0.5 * (arbb.max.x + arbb.min.x) * correction_factor;
			delta.y = 0.5 * (arbb.max.y + arbb.min.y) * correction_factor;
			
			if (arbb.max.x < ww && arbb.min.x > -ww)	// x is okay - no need to correct
				delta.x = 0;
			if (arbb.max.y > hh && arbb.min.x > -hh)	// y is okay - no need to correct
				delta.y = 0;
				
			// adjust the ship back to the center of the port
			Vector pos = ship->position;
			pos.x -= delta.y * vj.x + delta.x * vi.x;
			pos.y -= delta.y * vj.y + delta.x * vi.y;
			pos.z -= delta.y * vj.z + delta.x * vi.z;
			[ship setPosition:pos];
		}
		
		// if far enough in - dock
		if (0.90 * arbb.max.z + 0.10 * arbb.min.z < 0.0)
		{
			[self pullInShipIfPermitted:ship];
		}
		
		return YES;	// okay NOW we're in the docking corridor!
	}
	
	return NO;
}


- (void) pullInShipIfPermitted:(OOShipEntity *)ship
{
#if 0
	/*
		Experiment: allow station script to deny physical docking capability.
		Doesn't work properly because the collision detection for docking ports
		isn't designed to support this, and you can fly past the back and
		sometimes straight through.
		-- Ahruman 2011-01-29
	*/
	if (EXPECT_NOT(ship == nil))  return;
	
	JSContext	*context = OOJSAcquireContext();
	jsval		rval = JSVAL_VOID;
	jsval		args[] = { OOJSValueFromNativeObject(context, ship) };
	JSBool		permit = YES;
	
	BOOL OK = [[self script] callMethod:OOJSID("permitDocking") inContext:context withArguments:args count:1 result:&rval];
	if (OK)  OK = JS_ValueToBoolean(context, rval, &permit);
	if (!OK)  permit = YES; // In case of error, default to common behaviour.
#else
	BOOL permit = YES;
#endif
	if (permit)  [ship enterDock:self];
}


- (BOOL) dockingCorridorIsEmpty
{
	double unitime = [UNIVERSE gameTime];
	
	if (unitime < last_launch_time + STATION_DELAY_BETWEEN_LAUNCHES)	// leave sufficient pause between launches
	{
		return NO;
	}
	
	// check against all ships
	BOOL		isEmpty = YES;
	int			ent_count =		UNIVERSE->n_entities;
	OOEntity**	uni_entities =	UNIVERSE->sortedEntities;	// grab the public sorted list
	OOEntity*		my_entities[ent_count];
	int i;
	int ship_count = 0;
	for (i = 0; i < ent_count; i++)
		//on red alert, launch even if the player is trying block the corridor. Ignore cargopods or other small debris.
		if ([uni_entities[i] isShip] && (alertLevel < STATION_ALERT_LEVEL_RED || ![uni_entities[i] isPlayer]) && [uni_entities[i] mass] > 1000)
			my_entities[ship_count++] = [uni_entities[i] retain];		//	retained

	for (i = 0; (i < ship_count)&&(isEmpty); i++)
	{
		OOShipEntity*	ship = (OOShipEntity*)my_entities[i];
		double		d2 = distance2(position, ship->position);
		if ((ship != self)&&(d2 < 25000000)&&([ship status] != STATUS_DOCKED))	// within 5km
		{
			Vector ppos = [self getPortPosition];
			d2 = distance2(ppos, ship->position);
			if (d2 < 4000000)	// within 2km of the port entrance
			{
				Quaternion q1 = orientation;
				q1 = quaternion_multiply(port_orientation, q1);
				//
				Vector v_out = vector_forward_from_quaternion(q1);
				Vector r_pos = make_vector(ship->position.x - ppos.x, ship->position.y - ppos.y, ship->position.z - ppos.z);
				if (r_pos.x||r_pos.y||r_pos.z)
					r_pos = vector_normal(r_pos);
				else
					r_pos.z = 1.0;
				//
				double vdp = dot_product(v_out, r_pos); //== cos of the angle between r_pos and v_out
				//
				if (vdp > 0.86)
				{
					isEmpty = NO;
					last_launch_time = unitime - STATION_DELAY_BETWEEN_LAUNCHES + STATION_LAUNCH_RETRY_INTERVAL;
				}
			}
		}
	}
	
	for (i = 0; i < ship_count; i++)
		[my_entities[i] release];		//released

	return isEmpty;
}


- (void) clearDockingCorridor
{
	if (!UNIVERSE)
		return;
		
	// check against all ships
	BOOL		isClear = YES;
	int			ent_count =		UNIVERSE->n_entities;
	OOEntity**	uni_entities =	UNIVERSE->sortedEntities;	// grab the public sorted list
	OOEntity*		my_entities[ent_count];
	int i;
	int ship_count = 0;
	for (i = 0; i < ent_count; i++)
		if (uni_entities[i]->isShip)
			my_entities[ship_count++] = [uni_entities[i] retain];		//	retained

	for (i = 0; i < ship_count; i++)
	{
		OOShipEntity*	ship = (OOShipEntity*)my_entities[i];
		double		d2 = distance2(position, ship->position);
		if ((ship != self)&&(d2 < 25000000)&&([ship status] != STATUS_DOCKED))	// within 5km
		{
			Vector ppos = [self getPortPosition];
			float time_out = -15.00;	// 15 secs
			do
			{
				isClear = YES;
				d2 = distance2(ppos, ship->position);
				if (d2 < 4000000)	// within 2km of the port entrance
				{
					Quaternion q1 = orientation;
					q1 = quaternion_multiply(port_orientation, q1);
					//
					Vector v_out = vector_forward_from_quaternion(q1);
					Vector r_pos = make_vector(ship->position.x - ppos.x, ship->position.y - ppos.y, ship->position.z - ppos.z);
					if (r_pos.x||r_pos.y||r_pos.z)
						r_pos = vector_normal(r_pos);
					else
						r_pos.z = 1.0;
					//
					double vdp = dot_product(v_out, r_pos); //== cos of the angle between r_pos and v_out
					//
					if (vdp > 0.86)
					{
						isClear = NO;
						
						// okay it's in the way .. give it a wee nudge (0.25s)
						[ship update: 0.25];
						time_out += 0.25;
					}
					if (time_out > 0)
					{
						Vector v1 = vector_forward_from_quaternion(port_orientation);
						Vector spos = ship->position;
						spos.x += 3000.0 * v1.x;	spos.y += 3000.0 * v1.y;	spos.z += 3000.0 * v1.z; 
						[ship setPosition:spos]; // move 3km out of the way
					}
				}
			} while (!isClear);
		}
	}
	
	for (i = 0; i < ship_count; i++)
		[my_entities[i] release];		//released

	return;
}


- (void) update:(OOTimeDelta) delta_t
{
	BOOL isRockHermit = (scanClass == CLASS_ROCK);
	BOOL isMainStation = (self == [UNIVERSE station]);
	
	double unitime = [UNIVERSE gameTime];
	
	[super update:delta_t];
	
	OOPlayerShipEntity *player = PLAYER;
	BOOL isDockingStation = (self == [player getTargetDockStation]);
	if (isDockingStation && [player status] == STATUS_IN_FLIGHT)
	{
		if ([player getDockingClearanceStatus] >= DOCKING_CLEARANCE_STATUS_GRANTED)
		{
			if (last_launch_time - 30 < unitime && [player getDockingClearanceStatus] != DOCKING_CLEARANCE_STATUS_TIMING_OUT)
			{
				[self sendExpandedMessage:DESC(@"station-docking-clearance-about-to-expire") toShip:player];
				[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_TIMING_OUT];
			}
			else if (last_launch_time < unitime)
			{
				[self sendExpandedMessage:DESC(@"station-docking-clearance-expired") toShip:player];
				[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_NONE];	// Docking clearance for player has expired.
				if ([shipsOnApproach count] == 0) [shipAI message:@"DOCKING_COMPLETE"];
			}
		}

		else if ([player getDockingClearanceStatus] == DOCKING_CLEARANCE_STATUS_NOT_REQUIRED)
		{
			if (last_launch_time < unitime)
			{
				[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_NONE];
				if ([shipsOnApproach count] == 0) [shipAI message:@"DOCKING_COMPLETE"];
			}
		}

		else if ([player getDockingClearanceStatus] == DOCKING_CLEARANCE_STATUS_REQUESTED &&
				[shipsOnApproach count] == 0 && [launchQueue count] == 0)
		{
			last_launch_time = unitime + DOCKING_CLEARANCE_WINDOW;
			[self sendExpandedMessage:[NSString stringWithFormat:
					DESC(@"station-docking-clearance-granted-until-@"),
						ClockToString([player clockTime] + DOCKING_CLEARANCE_WINDOW, NO)]
					toShip:player];
			[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_GRANTED];
		}
	}
	
	if (([launchQueue count] > 0)&&([shipsOnApproach count] == 0)&&[self dockingCorridorIsEmpty])
	{
		OOShipEntity *se=(OOShipEntity *)[launchQueue objectAtIndex:0];
		[self launchShip:se];
		[launchQueue removeObjectAtIndex:0];
	}
	if (([launchQueue count] == 0)&&(no_docking_while_launching))
		no_docking_while_launching = NO;	// launching complete
	if (approach_spacing > 0.0)
	{
		approach_spacing -= delta_t * 10.0;	// reduce by 10 m/s
		if (approach_spacing < 0.0)   approach_spacing = 0.0;
	}
	if ((docked_shuttles > 0)&&(!isRockHermit))
	{
		if (unitime > last_shuttle_launch_time + shuttle_launch_interval)
		{
			if (([self hasNPCTraffic])&&(aegis_status != AEGIS_NONE))
			{
				[self launchShuttle];
				docked_shuttles--;
			}
			last_shuttle_launch_time = unitime;
		}
	}

	if ((docked_traders > 0)&&(!isRockHermit))
	{
		if (unitime > last_trader_launch_time + trader_launch_interval)
		{
			if ([self hasNPCTraffic])
			{
				[self launchIndependentShip:@"trader"];
				docked_traders--;
			}
			last_trader_launch_time = unitime;
		}
	}
	
	// testing patrols
	if (unitime > (last_patrol_report_time + patrol_launch_interval))
	{
		if (!((isMainStation && [self hasNPCTraffic]) || hasPatrolShips) || [self launchPatrol] != nil)
			last_patrol_report_time = unitime;
	}
}


- (void) clear
{
	if (launchQueue)
		[launchQueue removeAllObjects];
	if (shipsOnApproach)
		[shipsOnApproach removeAllObjects];
	if (shipsOnHold)
		[shipsOnHold removeAllObjects];
}


- (void) addShipToLaunchQueue:(OOShipEntity *) ship :(BOOL) priority
{
	[self sanityCheckShipsOnApproach];
	if (!launchQueue)
		launchQueue = [[NSMutableArray alloc] init]; // retained
	if (ship)
	{
		[ship setStatus: STATUS_DOCKED];
		if (priority)
			[launchQueue insertObject: ship atIndex: 0];
		else 
			[launchQueue addObject:ship];
	}
}


- (unsigned) countShipsInLaunchQueueWithPrimaryRole:(NSString *)role
{
	unsigned i, count, result = 0;
	count = [launchQueue count];
	
	for (i = 0; i < count; i++)
	{
		if ([[launchQueue objectAtIndex:i] hasPrimaryRole:role])  result++;
	}
	return result;
}


- (void) launchShip:(OOShipEntity *) ship
{
	if (![ship isShip])  return;
	
	OOBoundingBox bb = [ship boundingBox];
	if ((port_dimensions.x < (bb.max.x - bb.min.x) || port_dimensions.y < (bb.max.y - bb.min.y)) && 
		(port_dimensions.y < (bb.max.x - bb.min.x) || port_dimensions.x < (bb.max.y - bb.min.y)) && ![ship isPlayer])
	{
		[self addShipToStationCount: ship]; // restore ship count for station.
		OOLog(@"station.launchShip.failed", @"Cancelled launch for a %@ with role %@, as it is too large for the docking port of the %@.",
			  [ship displayName], [ship primaryRole], [self displayName]);
		return;
	}
	
	Vector launchPos = position;
	Vector launchVel = velocity;
	double launchSpeed = 0.5 * [ship maxFlightSpeed];
	if (maxFlightSpeed > 0 && flightSpeed > 0) // is self a carrier in flight.
	{
		launchSpeed = 0.5 * [ship maxFlightSpeed] * (1.0 + flightSpeed/maxFlightSpeed);
	}
	Quaternion q1 = orientation;
	q1 = quaternion_multiply(port_orientation, q1);
	Vector launchVector = vector_forward_from_quaternion(q1);
	
	// launch orientation
	if ((port_dimensions.x < port_dimensions.y) ^ (bb.max.x - bb.min.x < bb.max.y - bb.min.y))
	{
		quaternion_rotate_about_axis(&q1, launchVector, M_PI*0.5);  // to account for the slot being at 90 degrees to vertical
	}
	if ([ship isPlayer]) q1.w = -q1.w; // need this as a fix for the player and before shipWillLaunchFromStation.
	[ship setOrientation:q1];
	// launch position
	launchPos.x += port_position.x * v_right.x + port_position.y * v_up.x + port_position.z * v_forward.x;
	launchPos.y += port_position.x * v_right.y + port_position.y * v_up.y + port_position.z * v_forward.y;
	launchPos.z += port_position.x * v_right.z + port_position.y * v_up.z + port_position.z * v_forward.z;
	[ship setPosition:launchPos];
	if([ship pendingEscortCount] > 0) [ship setPendingEscortCount:0]; // Make sure no extra escorts are added after launch. (e.g. for miners etc.)
	if ([ship hasEscorts]) no_docking_while_launching = YES;
	// launch speed
	launchVel = vector_add(launchVel, vector_multiply_scalar(launchVector, launchSpeed));
	launchSpeed = magnitude(launchVel);
	[ship setSpeed:launchSpeed];
	[ship setVelocity:launchVel];
	// launch roll/pitch
	[ship setRoll:flightRoll];
	[ship setPitch:0.0];
	[UNIVERSE addEntity:ship];
	[ship setStatus: STATUS_LAUNCHING];
	[ship setDesiredSpeed:launchSpeed]; // must be set after initialising the AI to correct any speed set by AI
	last_launch_time = [UNIVERSE gameTime];
	double delay = (port_corridor + 2 * port_dimensions.z)/launchSpeed; // pause until 2 portlengths outside of the station.
	[ship setLaunchDelay:delay];
	[[ship getAI] setNextThinkTime:last_launch_time + delay]; // pause while launching
	
	[ship resetExhaustPlumes];	// resets stuff for tracking/exhausts
	
	[ship doScriptEvent:OOJSID("shipWillLaunchFromStation") withArgument:self];
	[self doScriptEvent:OOJSID("stationLaunchedShip") withArgument:ship andReactToAIMessage: @"STATION_LAUNCHED_SHIP"];
}


- (void) noteDockedShip:(OOShipEntity *) ship
{
	if (ship == nil)  return;	
	
	// set last launch time to avoid clashes with outgoing ships
	last_launch_time = [UNIVERSE gameTime];
	[self addShipToStationCount: ship];
	
	OOUniversalID	ship_id = [ship universalID];
	NSNumber		*shipID = [NSNumber numberWithUnsignedShort:ship_id];
	
	[shipsOnApproach removeObjectForKey:shipID];
	if ([shipsOnApproach count] == 0)
		[shipAI message:@"DOCKING_COMPLETE"];
	
	// clear any previously owned docking stages
	[self clearIdLocks:ship];
	
	[self doScriptEvent:OOJSID("otherShipDocked") withArgument:ship];
	
	OOPlayerShipEntity *player = PLAYER;
	BOOL isDockingStation = (self == [player getTargetDockStation]);
	if (isDockingStation && [player status] == STATUS_IN_FLIGHT &&
			[player getDockingClearanceStatus] == DOCKING_CLEARANCE_STATUS_REQUESTED)
	{
		if ([shipsOnApproach count])
		{
			[self sendExpandedMessage:[NSString stringWithFormat:
				DESC(@"station-docking-clearance-holding-d-ships-approaching"),
				[shipsOnApproach count]+1] toShip:player];
		}
		else if([launchQueue count])
		{
			[self sendExpandedMessage:[NSString stringWithFormat:
				DESC(@"station-docking-clearance-holding-d-ships-departing"),
				[launchQueue count]+1] toShip:player];
		}
	}
}

- (void) addShipToStationCount:(OOShipEntity *) ship
{
 	if ([ship isShuttle])  docked_shuttles++;
	else if ([ship isTrader] && ![ship isPlayer])  docked_traders++;
	else if (([ship isPolice] && ![ship isEscort]) || [ship hasPrimaryRole:@"defense_ship"])
	{
		if (0 < defenders_launched)  defenders_launched--;
	}
	else if ([ship hasPrimaryRole:@"scavenger"] || [ship hasPrimaryRole:@"miner"])	// treat miners and scavengers alike!
	{
		if (0 < scavengers_launched)  scavengers_launched--;
	}
}


- (BOOL) interstellarUndockingAllowed
{
	return interstellarUndockingAllowed;
}


- (BOOL)hasNPCTraffic
{
	return hasNPCTraffic;
}


- (void)setHasNPCTraffic:(BOOL)flag
{
	hasNPCTraffic = flag != NO;
}


- (BOOL) collideWithShip:(OOShipEntity *)other
{
	// 2010.06.10 - Micha. Commented out as there doesn't appear to be a good
	//				reason for it and it interferes with docking clearance.
	//[self abortAllDockings];
	return [super collideWithShip:other];
}


- (BOOL) hasHostileTarget
{
	return [super hasHostileTarget] || (alertLevel == STATION_ALERT_LEVEL_YELLOW) || (alertLevel == STATION_ALERT_LEVEL_RED);
}

- (void) takeEnergyDamage:(double)amount from:(OOEntity *)ent becauseOf:(OOEntity *)other
{
	//stations must ignore friendly fire, otherwise the defenders' AI gets stuck.
	BOOL			isFriend = NO;
	OOShipGroup		*group = [self group];
	
	if ([other isShip] && group != nil)
	{
		OOShipGroup *otherGroup = [(OOShipEntity *)other group];
		isFriend = otherGroup == group || [otherGroup leader] == self;
	}
	
	// If this is the system's main station...
	if (self == [UNIVERSE station] && !isFriend)
	{
		//...get angry

		BOOL isEnergyMine = [ent isCascadeWeapon];
		unsigned b=isEnergyMine ? 96 : 64;
		if ([(OOShipEntity*)other bounty] >= b)	//already a hardened criminal?
		{
			b *= 1.5; //bigger bounty!
		}
		[(OOShipEntity*)other markAsOffender:b];
		
		[self setPrimaryAggressor:other];
		[self setFoundTarget:other];
		[self launchPolice];

		if (isEnergyMine) //don't blow up!
		{
			[self increaseAlertLevel];
			[self respondToAttackFrom:ent becauseOf:other];
			return;
		}
	}
	// Stop damage if main station & close to death!
	if (!isFriend && (self != [UNIVERSE station] || amount < energy) )
	{
		// Handle damage like a ship.
		[super takeEnergyDamage:amount from:ent becauseOf:other];
	}
}

- (void) adjustVelocity:(Vector) xVel
{
	if (self != [UNIVERSE station])  [super adjustVelocity:xVel]; //dont get moved
}

- (void)takeScrapeDamage:(double)amount from:(OOEntity *)ent
{
	// Stop damage if main station
	if (self != [UNIVERSE station])  [super takeScrapeDamage:amount from:ent];
}


- (void) takeHeatDamage:(double)amount
{
	// Stop damage if main station
	if (self != [UNIVERSE station])  [super takeHeatDamage:amount];
}


- (OOStationAlertLevel) alertLevel
{
	return alertLevel;
}


- (void) setAlertLevel:(OOStationAlertLevel)level signallingScript:(BOOL)signallingScript
{
	if (level < STATION_ALERT_LEVEL_GREEN)  level = STATION_ALERT_LEVEL_GREEN;
	if (level > STATION_ALERT_LEVEL_RED)  level = STATION_ALERT_LEVEL_RED;
	
	if (alertLevel != level)
	{
		OOStationAlertLevel oldLevel = alertLevel;
		alertLevel = level;
		if (signallingScript)
		{
			ShipScriptEventNoCx(self, "alertConditionChanged", INT_TO_JSVAL(level), INT_TO_JSVAL(oldLevel));
		}
		switch (level)
		{
			case STATION_ALERT_LEVEL_GREEN:
				[shipAI reactToMessage:@"GREEN_ALERT" context:nil];
				break;
				
			case STATION_ALERT_LEVEL_YELLOW:
				[shipAI reactToMessage:@"YELLOW_ALERT" context:nil];
				break;
				
			case STATION_ALERT_LEVEL_RED:
				[shipAI reactToMessage:@"RED_ALERT" context:nil];
				break;
		}
	}
}


// Exposed to AI
- (OOShipEntity *) launchIndependentShip:(NSString*) role
{
	BOOL			trader = [role isEqualToString:@"trader"];
	BOOL			sunskimmer = ([role isEqualToString:@"sunskim-trader"]);
	OOShipEntity		*ship = nil;
	NSString		*defaultRole = @"escort";
	NSString		*escortRole = nil;
	NSString		*escortShipKey = nil;
	NSDictionary	*traderDict = nil;
	
	if((trader && (randf() < 0.1)) || sunskimmer) 
	{
		ship = [UNIVERSE newShipWithRole:@"sunskim-trader"];
		sunskimmer = true;
		trader = true;
		role = @"trader"; // make sure also sunskimmers get trader role.
	}
	else
	{
		ship = [UNIVERSE newShipWithRole:role];
	}

	if (ship)
	{
		traderDict = [ship shipInfoDictionary];
		if (![ship crew])
			[ship setCrew:[NSArray arrayWithObject:
				[OOCharacter randomCharacterWithRole: role
				andOriginalSystem: [UNIVERSE systemSeed]]]];
				
		[ship setPrimaryRole:role];

		if(trader || ship->scanClass == CLASS_NOT_SET) [ship setScanClass: CLASS_NEUTRAL]; // keep defined scanclasses for non-traders.
		
		if (trader)
		{
			[ship setBounty:0];
			[ship setCargoFlag:CARGO_FLAG_FULL_PLENTIFUL];
			if (sunskimmer) 
			{
				[UNIVERSE makeSunSkimmer:ship andSetAI:YES];
			}
			else
			{
				[ship switchAITo:@"exitingTraderAI.plist"];
				if([ship fuel] == 0) [ship setFuel:70];
			}
		}
		
		[self addShipToLaunchQueue:ship :NO];

		OOShipGroup *escortGroup = [ship escortGroup];
		if ([ship group] == nil) [ship setGroup:escortGroup];
		// Eric: Escorts are defined both as _group and as _escortGroup because friendly attacks are only handled withing _group.
		[escortGroup setLeader:ship];
				
		// add escorts to the trader
		unsigned escorts = [ship pendingEscortCount];
		if(escorts > 0)
		{
			escortRole = [traderDict oo_stringForKey:@"escort_role" defaultValue:nil];
			if (escortRole == nil)
				escortRole = [traderDict oo_stringForKey:@"escort-role" defaultValue:defaultRole];
			if (![escortRole isEqualToString: defaultRole])
			{
				if (![[UNIVERSE newShipWithRole:escortRole] autorelease])
				{
					escortRole = defaultRole;
				}
			}
			
			escortShipKey = [traderDict oo_stringForKey:@"escort_ship" defaultValue:nil];
			if (escortShipKey == nil)
				escortShipKey = [traderDict oo_stringForKey:@"escort-ship"];
			
			if (escortShipKey != nil)
			{
				if (![[UNIVERSE newShipWithName:escortShipKey] autorelease])
				{
					escortShipKey = nil;
				}
			}
				
			while (escorts--)
			{
				OOShipEntity  *escort_ship;

				if (escortShipKey)
				{
					escort_ship = [UNIVERSE newShipWithName:escortShipKey];	// retained
				}
				else
				{
					escort_ship = [UNIVERSE newShipWithRole:escortRole];	// retained
				}
				
				if (escort_ship)
				{
					if (![escort_ship crew] && ![escort_ship isUnpiloted])
						[escort_ship setCrew:[NSArray arrayWithObject:
							[OOCharacter randomCharacterWithRole: @"hunter"
							andOriginalSystem: [UNIVERSE systemSeed]]]];
							
					[escort_ship setScanClass: CLASS_NEUTRAL];
					[escort_ship setCargoFlag: CARGO_FLAG_FULL_PLENTIFUL];
					[escort_ship setPrimaryRole:@"escort"];					
					if (sunskimmer && [escort_ship effectiveHeatInsulation] < [ship effectiveHeatInsulation])
					{
						[escort_ship setEffectiveHeatInsulation:[ship effectiveHeatInsulation]];
					}
					
					[escort_ship setGroup:escortGroup];
					[escort_ship setOwner:ship];
					
					[escort_ship switchAITo:@"escortAI.plist"];
					[self addShipToLaunchQueue:escort_ship :NO];
					
					[escort_ship release];
				}
			}
		}
		
		[ship setPendingEscortCount:0];
		[ship autorelease];
	}
	return ship;
}


//////////////////////////////////////////////// extra AI routines


// Exposed to AI
- (void) increaseAlertLevel
{
	[self setAlertLevel:[self alertLevel] + 1 signallingScript:YES];
}


// Exposed to AI
- (void) decreaseAlertLevel
{
	[self setAlertLevel:[self alertLevel] - 1 signallingScript:YES];
}


// Exposed to AI
- (NSArray *) launchPolice
{
	OOEntity			*target = [self primaryTarget];
	if (target == nil)
	{
		[self noteLostTarget];
		return [NSArray array];
	}
	
	unsigned		i;
	NSMutableArray	*result = nil;
	OOTechLevelID	techlevel = [self equivalentTechLevel];
	if (techlevel == NSNotFound)  techlevel = 6;
	
	result = [NSMutableArray arrayWithCapacity:4];
	
	for (i = 0; (i < 4)&&(defenders_launched < max_police) ; i++)
	{
		OOShipEntity  *police_ship = nil;
		
		if ((Ranrot() & 7) + 6 <= techlevel)
		{
			police_ship = [UNIVERSE newShipWithRole:@"interceptor"];   // retain count = 1
		}
		else
		{
			police_ship = [UNIVERSE newShipWithRole:@"police"];   // retain count = 1
		}
		
		if (police_ship)
		{
			if (![police_ship crew])
			{
				[police_ship setCrew:[NSArray arrayWithObject:
					[OOCharacter randomCharacterWithRole: @"police"
									   andOriginalSystem: [UNIVERSE systemSeed]]]];
			}
			
			[police_ship setGroup:[self stationGroup]];	// who's your Daddy
			[police_ship setPrimaryRole:@"police"];
			[police_ship addTarget:target];
			[police_ship setScanClass:CLASS_POLICE];
			[police_ship setBounty:0];
			[police_ship switchAITo:@"policeInterceptAI.plist"];
			[self addShipToLaunchQueue:police_ship :YES];
			[police_ship autorelease];
			defenders_launched++;
			[result addObject:police_ship];
		}
	}
	[self abortAllDockings];
	return result;
}


// Exposed to AI
- (OOShipEntity *) launchDefenseShip
{
	OOEntity			*target = [self primaryTarget];
	if (target == nil)
	{
		[self noteLostTarget];
		return [NSArray array];
	}
	
	OOShipEntity		*defense_ship = nil;
	NSString		*defense_ship_key = nil,
					*defense_ship_role = nil,
					*default_defense_ship_role = nil;
	NSString		*defense_ship_ai = @"policeInterceptAI.plist";
	
	OOTechLevelID	techlevel;
	
	techlevel = [self equivalentTechLevel];
	if (techlevel == NSNotFound)  techlevel = 6;
	if ((Ranrot() & 7) + 6 <= techlevel)
		default_defense_ship_role	= @"interceptor";
	else
		default_defense_ship_role	= @"police";
	
	if (defenders_launched >= max_defense_ships)   // shuttles are to rockhermits what police ships are to stations
		return nil;
	
	defense_ship_key = [[self shipInfoDictionary] oo_stringForKey:@"defense_ship"];
	if (defense_ship_key != nil)
	{
		defense_ship = [UNIVERSE newShipWithName:defense_ship_key];
	}
	if (!defense_ship)
	{
		defense_ship_role = [[self shipInfoDictionary] oo_stringForKey:@"defense_ship_role" defaultValue:default_defense_ship_role];
		defense_ship = [UNIVERSE newShipWithRole:defense_ship_role];
	}
	
	if (!defense_ship && default_defense_ship_role != defense_ship_role)
		defense_ship = [UNIVERSE newShipWithRole:default_defense_ship_role];
	if (!defense_ship)
		return nil;
	
	if ([defense_ship isPolice] || [defense_ship hasPrimaryRole:@"hermit-ship"])
	{
		[defense_ship switchAITo:defense_ship_ai];
	}
	
	[defense_ship setPrimaryRole:@"defense_ship"];
	
	defenders_launched++;
	
	if (![defense_ship crew])
	{
		[defense_ship setCrew:[NSArray arrayWithObject:
			[OOCharacter randomCharacterWithRole: @"hunter"
			andOriginalSystem: [UNIVERSE systemSeed]]]];
	}
				
	[defense_ship setOwner: self];
	if ([self group] == nil)
	{
		[self setGroup:[self stationGroup]];	
	}
	[defense_ship setGroup:[self stationGroup]];	// who's your Daddy
	
	[defense_ship addTarget:target];

	if ((scanClass != CLASS_ROCK)&&(scanClass != CLASS_STATION))
		[defense_ship setScanClass: scanClass];	// same as self
	
	[self addShipToLaunchQueue:defense_ship :YES];
	[defense_ship autorelease];
	[self abortAllDockings];
	
	return defense_ship;
}


// Exposed to AI
- (OOShipEntity *) launchScavenger
{
	unsigned scavs = [UNIVERSE countShipsWithPrimaryRole:@"scavenger" inRange:SCANNER_MAX_RANGE ofEntity:self] + [self countShipsInLaunchQueueWithPrimaryRole:@"scavenger"];
	
	if (scavs >= max_scavengers)  return nil;
	if (scavengers_launched >= max_scavengers)  return nil;
	
	scavengers_launched++;
		
	OOShipEntity *scavenger_ship = [UNIVERSE newShipWithRole:@"scavenger"];   // retain count = 1
	if (scavenger_ship != nil)
	{
		if (![scavenger_ship crew])
			[scavenger_ship setCrew:[NSArray arrayWithObject:
				[OOCharacter randomCharacterWithRole: @"hunter"
				andOriginalSystem: [UNIVERSE systemSeed]]]];
				
		[scavenger_ship setScanClass: CLASS_NEUTRAL];
		[scavenger_ship setGroup:[self stationGroup]];	// who's your Daddy -- FIXME: should we have a separate group for non-escort auxiliaires?
		[scavenger_ship switchAITo:@"scavengerAI.plist"];
		[self addShipToLaunchQueue:scavenger_ship :NO];
		[scavenger_ship autorelease];
	}
	return scavenger_ship;
}


// Exposed to AI
- (OOShipEntity *) launchMiner
{
	OOShipEntity  *miner_ship;
	
	int		n_miners = [UNIVERSE countShipsWithPrimaryRole:@"miner" inRange:SCANNER_MAX_RANGE ofEntity:self] + [self countShipsInLaunchQueueWithPrimaryRole:@"miner"];
	
	if (n_miners >= 1)	// just the one
		return nil;
	
	// count miners as scavengers...
	if (scavengers_launched >= max_scavengers)  return nil;
	
	miner_ship = [UNIVERSE newShipWithRole:@"miner"];   // retain count = 1
	if (miner_ship)
	{
		if (![miner_ship crew])
			[miner_ship setCrew:[NSArray arrayWithObject:
				[OOCharacter randomCharacterWithRole: @"miner"
				andOriginalSystem: [UNIVERSE systemSeed]]]];
				
		scavengers_launched++;
		[miner_ship setScanClass:CLASS_NEUTRAL];
		[miner_ship setGroup:[self stationGroup]];	// who's your Daddy -- FIXME: should we have a separate group for non-escort auxiliaires?
		[miner_ship switchAITo:@"minerAI.plist"];
		[self addShipToLaunchQueue:miner_ship :NO];
		[miner_ship autorelease];
	}
	return miner_ship;
}

/**Lazygun** added the following method. A complete rip-off of launchDefenseShip. 
 */
// Exposed to AI
- (OOShipEntity *) launchPirateShip
{
	OOEntity			*target = [self primaryTarget];
	if (target == nil)
	{
		[self noteLostTarget];
		return [NSArray array];
	}
	
	//Pirate ships are launched from the same pool as defence ships.
	if (defenders_launched >= max_defense_ships)  return nil;   // shuttles are to rockhermits what police ships are to stations
	defenders_launched++;
	
	// Yep! The standard hermit defence ships, even if they're the aggressor.
	OOShipEntity *pirateShip = [UNIVERSE newShipWithRole:@"pirate"];   // retain count = 1
	// Nope, use standard pirates in a generic method.
	
	if (pirateShip)
	{
		if (![pirateShip crew])
		{
			[pirateShip setCrew:[NSArray arrayWithObject:
								 [OOCharacter randomCharacterWithRole:@"pirate"
													andOriginalSystem:[UNIVERSE systemSeed]]]];
		}
		
		// set the owner of the ship to the station so that it can check back for docking later
		[pirateShip setOwner:self];
		[pirateShip setGroup:[self stationGroup]];	// who's your Daddy
		[pirateShip setPrimaryRole:@"defense_ship"];
		[pirateShip addTarget:target];
		[pirateShip setScanClass: CLASS_NEUTRAL];
		//**Lazygun** added 30 Nov 04 to put a bounty on those pirates' heads.
		[pirateShip setBounty: 10 + floor(randf() * 20)];	// modified for variety

		[self addShipToLaunchQueue:pirateShip :NO];
		[pirateShip autorelease];
		[self abortAllDockings];
	}
	return pirateShip;
}


// Exposed to AI
- (OOShipEntity *) launchShuttle
{
	OOShipEntity  *shuttle_ship;
		
	shuttle_ship = [UNIVERSE newShipWithRole:@"shuttle"];   // retain count = 1
	
	if (shuttle_ship)
	{
		if (![shuttle_ship crew])
			[shuttle_ship setCrew:[NSArray arrayWithObject:
				[OOCharacter randomCharacterWithRole: @"trader"
				andOriginalSystem: [UNIVERSE systemSeed]]]];
				
		[shuttle_ship setScanClass: CLASS_NEUTRAL];
		[shuttle_ship setCargoFlag:CARGO_FLAG_FULL_SCARCE];
		[shuttle_ship switchAITo:@"fallingShuttleAI.plist"];
		[self addShipToLaunchQueue:shuttle_ship :NO];
		
		[shuttle_ship autorelease];
	}
	return shuttle_ship;
}


// Exposed to AI
- (void) launchEscort
{
	OOShipEntity  *escort_ship;
		
	escort_ship = [UNIVERSE newShipWithRole:@"escort"];   // retain count = 1
	
	if (escort_ship)
	{
		if (![escort_ship crew] && ![escort_ship isUnpiloted])
			[escort_ship setCrew:[NSArray arrayWithObject:
				[OOCharacter randomCharacterWithRole: @"hunter"
				andOriginalSystem: [UNIVERSE systemSeed]]]];
				
		[escort_ship setScanClass: CLASS_NEUTRAL];
		[escort_ship setCargoFlag: CARGO_FLAG_FULL_PLENTIFUL];
		[escort_ship switchAITo:@"escortAI.plist"];
		[self addShipToLaunchQueue:escort_ship :NO];
		
		[escort_ship release];
	}
}


// Exposed to AI
- (OOShipEntity *) launchPatrol
{
	if (defenders_launched < max_police)
	{
		OOShipEntity		*patrol_ship = nil;
		OOTechLevelID	techlevel;
		
		techlevel = [self equivalentTechLevel];
		if (techlevel == NSNotFound)
			techlevel = 6;
			
		defenders_launched++;
		
		if ((Ranrot() & 7) + 6 <= techlevel)
			patrol_ship = [UNIVERSE newShipWithRole:@"interceptor"];   // retain count = 1
		else
			patrol_ship = [UNIVERSE newShipWithRole:@"police"];   // retain count = 1
		if (patrol_ship)
		{
			if (![patrol_ship crew])
				[patrol_ship setCrew:[NSArray arrayWithObject:
					[OOCharacter randomCharacterWithRole: @"police"
					andOriginalSystem: [UNIVERSE systemSeed]]]];
				
			[patrol_ship switchLightsOff];
			[patrol_ship setScanClass: CLASS_POLICE];
			[patrol_ship setPrimaryRole:@"police"];
			[patrol_ship setBounty:0];
			[patrol_ship setGroup:[self stationGroup]];	// who's your Daddy
			[patrol_ship switchAITo:@"planetPatrolAI.plist"];
			[self addShipToLaunchQueue:patrol_ship :NO];
			[self acceptPatrolReportFrom:patrol_ship];
			[patrol_ship autorelease];
			return patrol_ship;
		}
	}
	return nil;
}


// Exposed to AI
- (void) launchShipWithRole:(NSString*) role
{
	OOShipEntity  *ship = [UNIVERSE newShipWithRole: role];   // retain count = 1
	if (ship)
	{
		if (![ship crew])
			[ship setCrew:[NSArray arrayWithObject:
				[OOCharacter randomCharacterWithRole: role
				andOriginalSystem: [UNIVERSE systemSeed]]]];
		if (ship->scanClass == CLASS_NOT_SET) [ship setScanClass: CLASS_NEUTRAL];
		[ship setPrimaryRole:role];
		[ship setGroup:[self stationGroup]];	// who's your Daddy
		[self addShipToLaunchQueue:ship :NO];
		[ship release];
	}
}


// Exposed to AI
- (void) becomeExplosion
{
	if (self == [UNIVERSE station])  return;
	
	// launch docked ships if possible
	OOPlayerShipEntity* player = PLAYER;
	if ((player)&&([player status] == STATUS_DOCKED)&&([player dockedStation] == self))
	{
		// undock the player!
		[player leaveDock:self];
		[UNIVERSE setViewDirection:VIEW_FORWARD];
		[UNIVERSE setDisplayCursor:NO];
		[player warnAboutHostiles];	// sound a klaxon
	}
	
	if (scanClass == CLASS_ROCK)	// ie we're a rock hermit or similar
	{
		// set the role so that we break up into rocks!
		[self setPrimaryRole:@"asteroid"];
		being_mined = YES;
	}
	
	// finally bite the bullet
	[super becomeExplosion];
}


// Exposed to AI
- (void) becomeEnergyBlast
{
	if (self == [UNIVERSE station])  return;
	[super becomeEnergyBlast];
}


- (void) becomeLargeExplosion:(double) factor
{
	if (self == [UNIVERSE station])  return;
	[super becomeLargeExplosion:factor];
}


- (void) acceptPatrolReportFrom:(OOShipEntity*) patrol_ship
{
	last_patrol_report_time = [UNIVERSE gameTime];
}


- (NSString *) acceptDockingClearanceRequestFrom:(OOShipEntity *)other
{
	NSString	*result = nil;
	double		timeNow = [UNIVERSE gameTime];
	OOPlayerShipEntity	*player = PLAYER;
	
	[UNIVERSE clearPreviousMessage];

	[self sanityCheckShipsOnApproach];

	// Docking clearance not required - clear it just in case it's been
	// set for another nearby station.
	if (![self requiresDockingClearance])
	{
		// TODO: We're potentially cancelling docking at another station, so
		//       ensure we clear the timer to allow NPC traffic.  If we
		//       don't, normal traffic will resume once the timer runs out.
		
		// No clearance is needed, but don't send friendly messages to hostile ships!
		if (!(([other isPlayer] && [other hasHostileTarget]) || (self == [UNIVERSE station] && [other bounty] > 50)))
			[self sendExpandedMessage:DESC(@"station-docking-clearance-not-required") toShip:other];
		if ([other isPlayer])
			[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_NOT_REQUIRED];
		[shipAI reactToMessage:@"DOCKING_REQUESTED" context:nil];	// react to the request	
		last_launch_time = timeNow + DOCKING_CLEARANCE_WINDOW;
		result = @"DOCKING_CLEARANCE_NOT_REQUIRED";
	}

	// Docking clearance already granted for this station - check for
	// time-out or cancellation (but only for the Player).
	if( result == nil && [other isPlayer] && self == [player getTargetDockStation])
	{
		switch( [player getDockingClearanceStatus] )
		{
			case DOCKING_CLEARANCE_STATUS_TIMING_OUT:
				last_launch_time = timeNow + DOCKING_CLEARANCE_WINDOW;
				[self sendExpandedMessage:[NSString stringWithFormat:
					DESC(@"station-docking-clearance-extended-until-@"),
						ClockToString([player clockTime] + DOCKING_CLEARANCE_WINDOW, NO)]
					toShip:other];
				[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_GRANTED];
				result = @"DOCKING_CLEARANCE_EXTENDED";
				break;
			case DOCKING_CLEARANCE_STATUS_REQUESTED:
			case DOCKING_CLEARANCE_STATUS_GRANTED:
				last_launch_time = timeNow;
				[self sendExpandedMessage:DESC(@"station-docking-clearance-cancelled") toShip:other];
				[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_NONE];
				result = @"DOCKING_CLEARANCE_CANCELLED";
				if ([shipsOnApproach count] == 0) [shipAI message:@"DOCKING_COMPLETE"];
				break;
			case DOCKING_CLEARANCE_STATUS_NONE:
			case DOCKING_CLEARANCE_STATUS_NOT_REQUIRED:
				break;
		}
	}

	// First we must set the status to REQUESTED to avoid problems when 
	// switching docking targets - even if we later set it back to NONE.
	if (result == nil && [other isPlayer] && self != [player getTargetDockStation])
	{
		[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_REQUESTED];
	}

	// Deny docking for fugitives at the main station
	// TODO: Should this be another key in shipdata.plist and/or should this
	//  apply to all stations?
	if (result == nil && self == [UNIVERSE station] && [other bounty] > 50)	// do not grant docking clearance to fugitives
	{
		[self sendExpandedMessage:DESC(@"station-docking-clearance-H-clearance-refused") toShip:other];
		if ([other isPlayer])
			[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_NONE];
		result = @"DOCKING_CLEARANCE_DENIED_SHIP_FUGITIVE";
	}
	
	if (result == nil && [other hasHostileTarget]) // do not grant docking clearance to hostile ships.
	{
		[self sendExpandedMessage:DESC(@"station-docking-clearance-denied") toShip:other];
		if ([other isPlayer])
			[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_NONE];
		result = @"DOCKING_CLEARANCE_DENIED_SHIP_HOSTILE";
	}

	// Put ship in queue if we've got incoming or outgoing traffic
	if (result == nil && [shipsOnApproach count] && last_launch_time < timeNow)
	{
		[self sendExpandedMessage:[NSString stringWithFormat:
			DESC(@"station-docking-clearance-acknowledged-d-ships-approaching"),
			[shipsOnApproach count]+1] toShip:other];
		// No need to set status to REQUESTED as we've already done that earlier.
		result = @"DOCKING_CLEARANCE_DENIED_TRAFFIC_INBOUND";
	}
	if (result == nil && [launchQueue count] && last_launch_time < timeNow)
	{
		[self sendExpandedMessage:[NSString stringWithFormat:
			DESC(@"station-docking-clearance-acknowledged-d-ships-departing"),
			[launchQueue count]+1] toShip:other];
		// No need to set status to REQUESTED as we've already done that earlier.
		result = @"DOCKING_CLEARANCE_DENIED_TRAFFIC_OUTBOUND";
	}

	// Ship has passed all checks - grant docking!
	if (result == nil)
	{
		last_launch_time = timeNow + DOCKING_CLEARANCE_WINDOW;
		[self sendExpandedMessage:[NSString stringWithFormat:
				DESC(@"station-docking-clearance-granted-until-@"),
					ClockToString([player clockTime] + DOCKING_CLEARANCE_WINDOW, NO)]
				toShip:other];
		if ([other isPlayer])
			[player setDockingClearanceStatus:DOCKING_CLEARANCE_STATUS_GRANTED];
		result = @"DOCKING_CLEARANCE_GRANTED";
		[shipAI reactToMessage:@"DOCKING_REQUESTED" context:nil];	// react to the request	
	}
	return result;
}


- (BOOL) requiresDockingClearance
{
	return requiresDockingClearance;
}


- (void) setRequiresDockingClearance:(BOOL)newValue
{
	requiresDockingClearance = !!newValue;	// Ensure yes or no
}


- (BOOL) allowsFastDocking
{
	return allowsFastDocking;
}


- (void) setAllowsFastDocking:(BOOL)newValue
{
	allowsFastDocking = !!newValue;	// Ensure yes or no
}


- (BOOL) allowsAutoDocking
{
	return allowsAutoDocking;
}


- (void) setAllowsAutoDocking:(BOOL)newValue
{
	allowsAutoDocking = !!newValue; // Ensure yes or no
}


- (BOOL) isRotatingStation
{
	if ([[self shipInfoDictionary] oo_boolForKey:@"rotating" defaultValue:NO])  return YES;
	return [[[self shipInfoDictionary] objectForKey:@"roles"] rangeOfString:@"rotating-station"].location != NSNotFound;	// legacy
}


- (NSString *) marketOverrideName
{
	// 2010.06.14 - Micha - we can't default to the primary role as otherwise the logic
	//				generating the market in [OOUniverse commodityDataForEconomy:] doesn't
	//				work properly with the various overrides.  The primary role will get
	//				used if either there is no market override, or the market wasn't
	//				defined.
	return [[self shipInfoDictionary] oo_stringForKey:@"market"];
}


- (BOOL) hasShipyard
{
	if ([UNIVERSE station] == self)  return YES;
	
	id	determinant = [[self shipInfoDictionary] objectForKey:@"has_shipyard"];

	if (!determinant)
		determinant = [[self shipInfoDictionary] objectForKey:@"hasShipyard"];
	
	if (determinant)
	{
		return OOFuzzyBooleanFromObject(determinant, 0.0f);
	}
	else
	{
		return NO;
	}
}


- (BOOL) suppressArrivalReports
{
	return suppress_arrival_reports;
}


- (void) setSuppressArrivalReports:(BOOL)newValue
{
	suppress_arrival_reports = !!newValue;	// ensure YES or NO
}


- (void)dumpSelfState
{
	NSMutableArray		*flags = nil;
	NSString			*flagsString = nil;
	NSString			*alertString = nil;
	
	[super dumpSelfState];
	
	switch (alertLevel)
	{
		case STATION_ALERT_LEVEL_GREEN:
			alertString = @"green";
			break;
		
		case STATION_ALERT_LEVEL_YELLOW:
			alertString = @"yellow";
			break;
		
		case STATION_ALERT_LEVEL_RED:
			alertString = @"red";
			break;
		
		default:
			alertString = @"*** ERROR: UNKNOWN ALERT LEVEL ***";
	}
	
	OOLog(@"dumpState.stationEntity", @"Alert level: %@", alertString);
	OOLog(@"dumpState.stationEntity", @"Max police: %u", max_police);
	OOLog(@"dumpState.stationEntity", @"Max defense ships: %u", max_defense_ships);
	OOLog(@"dumpState.stationEntity", @"Defenders launched: %u", defenders_launched);
	OOLog(@"dumpState.stationEntity", @"Max scavengers: %u", max_scavengers);
	OOLog(@"dumpState.stationEntity", @"Scavengers launched: %u", scavengers_launched);
	OOLog(@"dumpState.stationEntity", @"Docked shuttles: %u", docked_shuttles);
	OOLog(@"dumpState.stationEntity", @"Docked traders: %u", docked_traders);
	OOLog(@"dumpState.stationEntity", @"Equivalent tech level: %i", equivalentTechLevel);
	OOLog(@"dumpState.stationEntity", @"Equipment price factor: %g", equipmentPriceFactor);
	
	flags = [NSMutableArray array];
	#define ADD_FLAG_IF_SET(x)		if (x) { [flags addObject:@#x]; }
	ADD_FLAG_IF_SET(no_docking_while_launching);
	if ([self isRotatingStation]) { [flags addObject:@"rotatingStation"]; }
	if (![self dockingCorridorIsEmpty]) { [flags addObject:@"dockingCorridorIsBusy"]; }
	flagsString = [flags count] ? [flags componentsJoinedByString:@", "] : (NSString *)@"none";
	OOLog(@"dumpState.stationEntity", @"Flags: %@", flagsString);
	
	// approach and hold lists.
	unsigned i;
	OOShipEntity		*ship = nil;
	NSArray*	ships = [shipsOnApproach allKeys];
	if([ships count] > 0 ) OOLog(@"dumpState.stationEntity", @"%i Ships on approach (unsorted):", [ships count]);
	for (i = 0; i < [ships count]; i++)
	{
		int sid = [[ships objectAtIndex:i] intValue];
		if ([UNIVERSE entityForUniversalID:sid])
		{
			ship = [UNIVERSE entityForUniversalID:sid];
			OOLog(@"dumpState.stationEntity", @"Nr %i: %@ at distance %g with role: %@", i+1, [ship displayName], 
																			sqrtf(distance2(position, [ship position])),
																					[ship primaryRole]);
		}
	}

	ships = [shipsOnHold allKeys];  // only used with moving stations (= carriers)
	if([ships count] > 0 ) OOLog(@"dumpState.stationEntity", @"%i Ships on hold (unsorted):", [ships count]);
	for (i = 0; i < [ships count]; i++)
	{
		int sid = [[ships objectAtIndex:i] intValue];
		if ([UNIVERSE entityForUniversalID:sid])
		{
			ship = [UNIVERSE entityForUniversalID:sid];
			OOLog(@"dumpState.stationEntity", @"Nr %i: %@ at distance %g with role: %@", i+1, [ship displayName], 
																			sqrtf(distance2(position, [ship position])),
																					[ship primaryRole]);
		}
	}
}

@end


#ifndef NDEBUG

@implementation OOStationEntity (OOWireframeDockingBox)

- (void)drawEntity:(BOOL)immediate :(BOOL)translucent
{
	Vector				adjustedPosition;
	Vector				halfDimensions;
	
	[super drawEntity:immediate:translucent];
	
	if (gDebugFlags & DEBUG_BOUNDING_BOXES)
	{
		OODebugDrawBasisAtOrigin(50.0f);
		
		OOMatrix matrix;
		matrix = OOMatrixForQuaternionRotation(port_orientation);
		OOGL(glPushMatrix());
		GLMultOOMatrix(matrix);
		
		halfDimensions = vector_multiply_scalar(port_dimensions, 0.5f);
		adjustedPosition = port_position;
		adjustedPosition.z -= halfDimensions.z;
		
		OODebugDrawColoredBoundingBoxBetween(vector_subtract(adjustedPosition, halfDimensions), vector_add(adjustedPosition, halfDimensions), [OOColor redColor]);
		OODebugDrawBasisAtOrigin(30.0f);
		
		OOGL(glPopMatrix());
	}
}


// Added to test exception wrapping in JS engine. If this is an ancient issue, delete this method. -- Ahruman 2010-06-21
- (void) TEMPExceptionTest
{
	[NSException raise:@"TestException" format:@"This is a test exception which shouldn't crash the game."];
}

@end

#endif
