/*

PlayerEntityScriptMethods.m

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

#import "PlayerEntityScriptMethods.h"
#import "PlayerEntityLoadSave.h"

#import "Universe.h"
#import "OOConstToString.h"

#ifndef NDEBUG
#import "ResourceManager.h"
#import "OOColor.h"
#endif


@interface Universe (Peek)

- (NSDictionary *) generateSystemDataForGalaxy:(OOGalaxyID)gnum planet:(OOSystemID)pnum;

@end


@implementation PlayerEntity (ScriptMethods)

- (NSString *) playerName
{
	return [[player_name retain] autorelease];
}


- (unsigned) score
{
	return ship_kills;
}


- (void) setScore:(unsigned)value
{
	ship_kills = value;
}


- (double)creditBalance
{
	return 0.1 * credits;
}


- (void)setCreditBalance:(double)value
{
	credits = OODeciCreditsFromDouble(value * 10.0);
}


- (NSString *) dockedStationName
{
	return [(OOShipEntity *)dockedStation name];
}


- (NSString *) dockedStationDisplayName
{
	return [(OOShipEntity *)dockedStation displayName];
}


- (BOOL) dockedAtMainStation
{
	return [self status] == STATUS_DOCKED && dockedStation == [UNIVERSE station];
}


- (BOOL) canAwardCargoType:(OOCargoType)type amount:(OOCargoQuantity)amount
{
	if (type == CARGO_NOT_CARGO)  return NO;
	if ([UNIVERSE unitsForCommodity:type] == UNITS_TONS)
	{
		if ([self specialCargo] != nil)  return NO;
		if (amount > [self availableCargoSpace])  return NO;
	}
	
	return YES;
}


- (void) awardCargoType:(OOCargoType)type amount:(OOCargoQuantity)amount
{
	OOMassUnit				unit;
	NSArray					*commodityArray = nil;
	
	commodityArray = [UNIVERSE commodityDataForType:type];
	if (commodityArray == nil)  return;
	
	OOLog(@"script.debug.note.awardCargo", @"Going to award cargo: %d x '%@'", amount, CommodityDisplayNameForCommodityArray(commodityArray));
	
	unit = [UNIVERSE unitsForCommodity:type];
	
	if ([self status] != STATUS_DOCKED)
	{
		// in-flight
		while (amount)
		{
			if (unit != UNITS_TONS)
			{
				if (specialCargo)
				{
					NSMutableArray* manifest =  [NSMutableArray arrayWithArray:shipCommodityData];
					NSMutableArray* manifest_commodity =	[NSMutableArray arrayWithArray:(NSArray *)[manifest objectAtIndex:type]];
					int manifest_quantity = [(NSNumber *)[manifest_commodity objectAtIndex:MARKET_QUANTITY] intValue];
					manifest_quantity += amount;
					amount = 0;
					[manifest_commodity replaceObjectAtIndex:MARKET_QUANTITY withObject:[NSNumber numberWithInt:manifest_quantity]];
					[manifest replaceObjectAtIndex:type withObject:[NSArray arrayWithArray:manifest_commodity]];
					[shipCommodityData release];
					shipCommodityData = [[NSArray arrayWithArray:manifest] retain];
				}
				else
				{
					int amount_per_container = (unit == UNITS_KILOGRAMS)? 1000 : 1000000;
					while (amount > 0)
					{
						int smaller_quantity = 1 + ((amount - 1) % amount_per_container);
						if ([cargo count] < max_cargo)
						{
							OOShipEntity* container = [UNIVERSE newShipWithRole:@"1t-cargopod"];
							if (container)
							{
								// the cargopod ship is just being set up. If ejected,  will call UNIVERSE addEntity
								// [container wasAddedToUniverse]; // seems to be not needed anymore for pods
								[container setScanClass: CLASS_CARGO];
								[container setStatus:STATUS_IN_HOLD];
								[container setCommodity:type andAmount:smaller_quantity];
								[cargo addObject:container];
								[container release];
							}
						}
						amount -= smaller_quantity;
					}
				}
			}
			else
			{
				// put each ton in a separate container
				while (amount)
				{
					if ([cargo count] < max_cargo)
					{
						OOShipEntity* container = [UNIVERSE newShipWithRole:@"1t-cargopod"];
						if (container)
						{
							// the cargopod ship is just being set up. If ejected, will call UNIVERSE addEntity
							// [container wasAddedToUniverse]; // seems to be not needed anymore for pods
							[container setScanClass: CLASS_CARGO];
							[container setStatus:STATUS_IN_HOLD];
							[container setCommodity:type andAmount:1];
							[cargo addObject:container];
							[container release];
						}
					}
					amount--;
				}
			}
		}
	}
	else
	{	// docked
		// like purchasing a commodity
		NSMutableArray* manifest = [NSMutableArray arrayWithArray:shipCommodityData];
		NSMutableArray* manifest_commodity = [NSMutableArray arrayWithArray:[manifest oo_arrayAtIndex:type]];
		int manifest_quantity = [manifest_commodity oo_intAtIndex:MARKET_QUANTITY];
		while ((amount)&&(current_cargo < max_cargo))
		{
			manifest_quantity++;
			amount--;
			if (unit == UNITS_TONS)  current_cargo++;
		}
		[manifest_commodity replaceObjectAtIndex:MARKET_QUANTITY withObject:[NSNumber numberWithInt:manifest_quantity]];
		[manifest replaceObjectAtIndex:type withObject:[NSArray arrayWithArray:manifest_commodity]];
		[shipCommodityData release];
		shipCommodityData = [[NSArray arrayWithArray:manifest] retain];
	}
	[self calculateCurrentCargo];
}


- (OOGalaxyID) currentGalaxyID
{
	return galaxy_number;
}


- (OOSystemID) currentSystemID
{
	if ([UNIVERSE sun] == nil)  return -1;	// Interstellar space
	return [UNIVERSE currentSystemID];
}


- (void) setMissionChoice:(NSString *)newChoice
{
	[self setMissionChoice:newChoice withEvent:YES];
}


- (void) setMissionChoice:(NSString *)newChoice withEvent:(BOOL)withEvent
{
	BOOL equal = [newChoice isEqualToString:missionChoice] || (newChoice == missionChoice);	// Catch both being nil as well
	if (!equal)
	{
		if (newChoice == nil)
		{
			NSString *oldChoice = missionChoice;
			[missionChoice autorelease];
			missionChoice = nil;
			if (withEvent) [self doScriptEvent:OOJSID("missionChoiceWasReset") withArgument:oldChoice];
		}
		else
		{
			[missionChoice autorelease];
			missionChoice = [newChoice copy];
		}
	}
}


- (NSString *) missionChoice
{
	return missionChoice;
}


- (unsigned) systemPseudoRandom100
{
	seed_RNG_only_for_planet_description(system_seed);
	return (gen_rnd_number() * 256 + gen_rnd_number()) % 100;
}


- (unsigned) systemPseudoRandom256
{
	seed_RNG_only_for_planet_description(system_seed);
	return gen_rnd_number();
}


- (double) systemPseudoRandomFloat
{
	Random_Seed seed = system_seed;
	seed_RNG_only_for_planet_description(system_seed);
	unsigned a = gen_rnd_number();
	unsigned b = gen_rnd_number();
	unsigned c = gen_rnd_number();
	system_seed = seed;
	
	a = (a << 16) | (b << 8) | c;
	return (double)a / (double)0x01000000;
	
}


#ifndef NDEBUG
/*
	dbgDumpSystemInfo
	
	Write JSON file with info about all systems in current galaxy.
	Activate from console with “:: dbgDumpSystemInfo”.
*/
- (void) dbgDumpSystemInfo
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:256];
	
	for (unsigned i = 0; i < 256; i++)
	{
		NSMutableDictionary *info = [[[UNIVERSE generateSystemDataForGalaxy:galaxy_number planet:i] mutableCopy] autorelease];
		
		[info removeObjectsForKeys:$array(@"nebula_count_multiplier", @"star_count_multiplier", @"stations_require_docking_clearance", @"corona_flare")];
		
		Random_Seed seed = [UNIVERSE systemSeedForSystemNumber:i];
		NSPoint coords = [UNIVERSE coordinatesForSystem:seed];
		
		[info setObject:$array($int(seed.a), $int(seed.b), $int(seed.c), $int(seed.d), $int(seed.e), $int(seed.f)) forKey:@"system_seed"];
		[info setObject:$array($float(coords.x), $float(coords.y)) forKey:@"coordinates"];
		
		seed_for_planet_description(seed);
		float h1 = randf();
		float h2 = h1 + 1.0 / (1.0 + (Ranrot() % 5));
		while (h2 > 1.0)  h2 -= 1.0;
		OOColor *col1 = [OOColor colorWithCalibratedHue:h1 saturation:randf() brightness:0.5 + randf()/2.0 alpha:1.0];
		OOColor *col2 = [OOColor colorWithCalibratedHue:h2 saturation:0.5 + randf()/2.0 brightness:0.5 + randf()/2.0 alpha:1.0];
		OOColor *sunColor = [col2 blendedColorWithFraction:0.5 ofColor:col1];
		sunColor = [sunColor blendedColorWithFraction:0.5 ofColor:[OOColor whiteColor]];
		
		[info setObject:[col1 normalizedArray] forKey:@"sky_color_1"];
		[info setObject:[col2 normalizedArray] forKey:@"sky_color_2"];
		[info setObject:[sunColor normalizedArray] forKey:@"sun_color"];
		
		[result addObject:info];
	}
	
	NSData *data = [result ooConfDataWithOptions:kOOConfGenerationJSONCompatible error:NULL];
	[ResourceManager writeDiagnosticData:data toFileNamed:$sprintf(@"galaxy_%u.json", galaxy_number)];
}
#endif

@end


Vector OOGalacticCoordinatesFromInternal(NSPoint internalCoordinates)
{
	return (Vector){ (float)internalCoordinates.x * 0.4f, (float)internalCoordinates.y * 0.2f, 0.0f };
}


NSPoint OOInternalCoordinatesFromGalactic(Vector galacticCoordinates)
{
	return (NSPoint){ (float)galacticCoordinates.x * 2.5f, (float)galacticCoordinates.y * 5.0f };
}
