/*

OOUniverse.h

Manages a lot of stuff that isn't managed somewhere else.

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

#import <OoliteBase/OoliteBase.h>
#import "OOLegacyOpenGL.h"
#import "OOTypes.h"
#import "OOJSPropID.h"


#if OOLITE_ESPEAK
#include <espeak/speak_lib.h>
#endif

@class	OOGameController, CollisionRegion, MyOpenGLView, GuiDisplayGen,
		OOEntity, OOShipEntity, OOStationEntity, OOPlanetEntity, OOSunEntity,
		OOPlayerShipEntity, OORoleSet, OOColor, OOShipClass;


typedef BOOL (*EntityFilterPredicate)(OOEntity *entity, void *parameter);

#ifndef OO_SCANCLASS_TYPE
#define OO_SCANCLASS_TYPE
typedef enum OOScanClass OOScanClass;
#endif


#define CROSSHAIR_SIZE						32.0

enum
{
	MARKET_NAME								= 0,
	MARKET_QUANTITY							= 1,
	MARKET_PRICE							= 2,
	MARKET_BASE_PRICE						= 3,
	MARKET_ECO_ADJUST_PRICE					= 4,
	MARKET_ECO_ADJUST_QUANTITY  			= 5,
	MARKET_BASE_QUANTITY					= 6,
	MARKET_MASK_PRICE						= 7,
	MARKET_MASK_QUANTITY					= 8,
	MARKET_UNITS							= 9
};


enum
{
	EQUIPMENT_TECH_LEVEL_INDEX				= 0,
	EQUIPMENT_PRICE_INDEX					= 1,
	EQUIPMENT_SHORT_DESC_INDEX				= 2,
	EQUIPMENT_KEY_INDEX						= 3,
	EQUIPMENT_LONG_DESC_INDEX				= 4,
	EQUIPMENT_EXTRA_INFO_INDEX				= 5
};

#define SHADERS_MIN SHADERS_OFF


#define MAX_MESSAGES						5

#define PROXIMITY_WARN_DISTANCE				4 // Eric 2010-10-17: old value was 20.0
#define PROXIMITY_WARN_DISTANCE2			(PROXIMITY_WARN_DISTANCE * PROXIMITY_WARN_DISTANCE)
#define PROXIMITY_AVOID_DISTANCE_FACTOR		10.0
#define SAFE_ADDITION_FACTOR2				800 // Eric 2010-10-17: used to be "2 * PROXIMITY_WARN_DISTANCE2"

#define SUN_SKIM_RADIUS_FACTOR				1.15470053838	// 2 sqrt(3) / 3. Why? I have no idea. -- Ahruman 2009-10-04
#define SUN_SPARKS_RADIUS_FACTOR			2.0

#define KEY_TECHLEVEL						@"techlevel"
#define KEY_ECONOMY							@"economy"
#define KEY_GOVERNMENT						@"government"
#define KEY_POPULATION						@"population"
#define KEY_PRODUCTIVITY					@"productivity"
#define KEY_RADIUS							@"radius"
#define KEY_NAME							@"name"
#define KEY_INHABITANT						@"inhabitant"
#define KEY_INHABITANTS						@"inhabitants"
#define KEY_DESCRIPTION						@"description"
#define KEY_SHORT_DESCRIPTION				@"short_description"

#define KEY_CHANCE							@"chance"
#define KEY_PRICE							@"price"
#define KEY_OPTIONAL_EQUIPMENT				@"optional_equipment"
#define KEY_STANDARD_EQUIPMENT				@"standard_equipment"
#define KEY_EQUIPMENT_MISSILES				@"missiles"
#define KEY_EQUIPMENT_FORWARD_WEAPON		@"forward_weapon_type"
#define KEY_EQUIPMENT_AFT_WEAPON			@"aft_weapon_type"
#define KEY_EQUIPMENT_PORT_WEAPON			@"port_weapon_type"
#define KEY_EQUIPMENT_STARBOARD_WEAPON		@"starboard_weapon_type"
#define KEY_EQUIPMENT_EXTRAS				@"extras"
#define KEY_WEAPON_FACINGS					@"weapon_facings"

#define SHIPYARD_KEY_ID						@"id"
#define SHIPYARD_KEY_SHIPDATA_KEY			@"shipdata_key"
#define SHIPYARD_KEY_SHIP					@"ship"
#define SHIPYARD_KEY_PRICE					@"price"
#define SHIPYARD_KEY_PERSONALITY			@"personality"
#define SHIPYARD_KEY_DESCRIPTION			@"description"

#define PLANETINFO_UNIVERSAL_KEY			@"universal"

// Derived constants (MIN_ENTITY_UID, MAX_ENTITY_UID) are defined in OOTypes.h
#define	UNIVERSE_MAX_ENTITIES				2048

#define OOLITE_EXCEPTION_LOOPING			@"OoliteLoopingException"
#define OOLITE_EXCEPTION_DATA_NOT_FOUND		@"OoliteDataNotFoundException"
#define OOLITE_EXCEPTION_FATAL				@"OoliteFatalException"

#define BILLBOARD_DEPTH						50000.0

#define TIME_ACCELERATION_FACTOR_MIN		0.0625f
#define TIME_ACCELERATION_FACTOR_DEFAULT	1.0f
#define TIME_ACCELERATION_FACTOR_MAX		16.0f

#define DEMO_LIGHT_POSITION 5000.0f, 25000.0f, -10000.0f


#ifndef OO_LOCALIZATION_TOOLS
#define OO_LOCALIZATION_TOOLS				0
#endif

#ifndef MASS_DEPENDENT_FUEL_PRICES
#define MASS_DEPENDENT_FUEL_PRICES			1
#endif

#ifndef REPAIR_DEPENDENT_FUEL_PRICES
#define REPAIR_DEPENDENT_FUEL_PRICES		1
#endif


typedef NSUInteger	OOTechLevelID;		// 0..14, 99 is special. NSNotFound is used, so NSUInteger required.
typedef uint8_t		OOGovernmentID;		// 0..7
typedef uint8_t		OOEconomyID;		// 0..7


@interface OOUniverse: OOWeakRefObject
{
@public
	// use a sorted list for drawing and other activities
	OOEntity				*sortedEntities[UNIVERSE_MAX_ENTITIES];
	unsigned				n_entities;
	
	int						cursor_row;
	
	// collision optimisation sorted lists
	OOEntity				*x_list_start, *y_list_start, *z_list_start;
	
	GLfloat					stars_ambient[4];
	
@private
	NSUInteger				_sessionID;
	
	// colors
	GLfloat					sun_diffuse[4];
	GLfloat					sun_specular[4];

	OOViewID				viewDirection;
	
	OOMatrix				viewMatrix;
	
	GLfloat					airResistanceFactor;
	
	MyOpenGLView			*gameView;
	
	int						next_universal_id;
	OOEntity				*entity_for_uid[MAX_ENTITY_UID];

	NSMutableArray			*entities;
	
	OOWeakReference			*_firstBeacon,
							*_lastBeacon;
	
	GLfloat					skyClearColor[4];
	
	NSString				*currentMessage;
	OOTimeAbsolute			messageRepeatTime;
	OOTimeAbsolute			countdown_messageRepeatTime; 	// Getafix(4/Aug/2010) - Quickfix countdown messages colliding with weapon overheat messages.
									//                       For proper handling of message dispatching, code refactoring is needed.
	GuiDisplayGen			*gui;
	GuiDisplayGen			*message_gui;
	GuiDisplayGen			*comm_log_gui;
	
	BOOL					displayGUI;
	BOOL					wasDisplayGUI;
	BOOL					displayCursor;
	
	BOOL					autoSaveNow;
	BOOL					autoSave;
	BOOL					wireframeGraphics;
	BOOL					reducedDetail;
	OOShaderSetting			shaderEffectsLevel;
	
	BOOL					displayFPS;		
			
	OOTimeAbsolute			universal_time;
	OOTimeDelta				time_delta;
	
	OOTimeAbsolute			demo_stage_time;
	OOTimeAbsolute			demo_start_time;
	GLfloat					demo_start_z;
	int						demo_stage;
	int						demo_ship_index;
	NSArray					*demo_ships;
	
	GLfloat					main_light_position[4];
	
	BOOL					dumpCollisionInfo;
	
	NSDictionary			*commodityLists;		// holds data on commodities for various types of station, loaded at initialisation
	NSArray					*commodityData;			// holds data on commodities extracted from commodityLists
	
	NSDictionary			*illegalGoods;			// holds the legal penalty for illicit commodities, loaded at initialisation
	NSDictionary			*_descriptions;			// holds descriptive text for lots of stuff, loaded at initialisation
	NSDictionary			*customSounds;			// holds descriptive audio for lots of stuff, loaded at initialisation
	NSDictionary			*characters;			// holds descriptons of characters
	NSDictionary			*planetInfo;			// holds overrides for individual planets, keyed by "g# p#" where g# is the galaxy number 0..7 and p# the planet number 0..255
	NSDictionary			*missiontext;			// holds descriptive text for missions, loaded at initialisation
	NSArray					*equipmentData;			// holds data on available equipment, loaded at initialisation
	NSSet					*pirateVictimRoles;		// Roles listed in pirateVictimRoles.plist.
	NSDictionary			*autoAIMap;				// Default AIs for roles from autoAImap.plist.
	NSDictionary			*screenBackgrounds;		// holds filenames for various screens backgrounds, loaded at initialisation
	
	Random_Seed				galaxy_seed;
	Random_Seed				system_seed;
	Random_Seed				target_system_seed;
	
	Random_Seed				systems[256];			// hold pregenerated universe info
	NSString				*system_names[256];		// hold pregenerated universe info
	BOOL					system_found[256];		// holds matches for input strings
	
	int						breakPatternCounter;
	
	OOShipEntity			*demo_ship;
	
	OOStationEntity			*cachedStation;
	OOPlanetEntity			*cachedPlanet;
	OOSunEntity				*cachedSun;
	NSMutableArray			*allPlanets;
	
	NSArray					*closeSystems;
	
	BOOL					no_update;
	
#ifndef NDEBUG
	double					timeAccelerationFactor;
#endif
	
	NSMutableDictionary		*localPlanetInfoOverrides;
	
	NSException				*exception;
	
	NSMutableArray			*activeWormholes;
	
	NSMutableArray			*characterPool;
	
	CollisionRegion			*universeRegion;
	
	// check and maintain linked lists occasionally
	BOOL					doLinkedListMaintenanceThisUpdate;
	
	NSMutableSet			*entitiesDeadThisUpdate;
	int						framesDoneThisUpdate;
	
#if OOLITE_SPEECH_SYNTH
#if OOLITE_MAC_OS_X
	NSSpeechSynthesizer		*speechSynthesizer;		// use this from OS X 10.3 onwards
#elif OOLITE_ESPEAK
	const espeak_VOICE		**espeak_voices;
	unsigned int			espeak_voice_count;
#endif
	NSArray					*speechArray;
#endif
	
#if NEW_PLANETS
	NSMutableArray			*_preloadingPlanetMaterials;
#endif
	BOOL					doProcedurallyTexturedPlanets;
	
	BOOL					_pauseMessage;
	BOOL					_autoCommLog;
	BOOL					_permanentCommLog;
	
	OOTimeAbsolute			_realTime;
}

- (id)initWithGameView:(MyOpenGLView *)gameView;

// SessionID: a value that's incremented when the game is reset.
- (NSUInteger) sessionID;

- (BOOL) doProcedurallyTexturedPlanets;
- (void) setDoProcedurallyTexturedPlanets:(BOOL) value;

- (void) reinitAndShowDemo:(BOOL)showDemo;

- (int) entityCount;
#ifndef NDEBUG
- (void) debugDumpEntities;
- (NSArray *) entityList;
#endif

- (void) pauseGame;
- (BOOL) isGamePaused;

- (void) setUpUniverseFromStation;
- (void) setUpUniverseFromWitchspace;
- (void) setUpUniverseFromMisjump;
- (void) setUpWitchspace;
- (void) setUpSpace;
- (void) setLighting;
- (void) forceLightSwitch;
- (void) setMainLightPosition: (Vector) sunPos;
- (OOPlanetEntity *) setUpPlanet;

- (void) makeSunSkimmer:(OOShipEntity *) ship andSetAI:(BOOL)setAI;
- (void) addShipWithRole:(NSString *) desc nearRouteOneAt:(double) route_fraction;
- (Vector) coordinatesForPosition:(Vector) pos withCoordinateSystem:(NSString *) system returningScalar:(GLfloat*) my_scalar;
- (NSString *) expressPosition:(Vector) pos inCoordinateSystem:(NSString *) system;
- (Vector) legacyPositionFrom:(Vector) pos asCoordinateSystem:(NSString *) system;
- (Vector) coordinatesFromCoordinateSystemString:(NSString *) system_x_y_z;
- (BOOL) addShipWithRole:(NSString *) desc nearPosition:(Vector) pos withCoordinateSystem:(NSString *) system;
- (BOOL) addShips:(int)howMany withRole:(NSString *)desc atPosition:(Vector)pos withCoordinateSystem:(NSString *)system;
- (BOOL) addShips:(int)howMany withRole:(NSString *)desc nearPosition:(Vector)pos withCoordinateSystem:(NSString *)system;
- (BOOL) addShips:(int)howMany withRole:(NSString *)desc nearPosition:(Vector)pos withCoordinateSystem:(NSString *)system withinRadius:(GLfloat)radius;
- (BOOL) addShips:(int)howMany withRole:(NSString *)desc intoBoundingBox:(OOBoundingBox)bbox;
- (BOOL) spawnShip:(NSString *) shipdesc;
- (void) witchspaceShipWithPrimaryRole:(NSString *)role;
- (OOShipEntity *) spawnShipWithRole:(NSString *) desc near:(OOEntity *) entity;

- (OOShipEntity *) addShipAt:(Vector)pos withRole:(NSString *)role withinRadius:(GLfloat)radius;
- (NSArray *) addShipsAt:(Vector)pos withRole:(NSString *)role quantity:(unsigned)count withinRadius:(GLfloat)radius asGroup:(BOOL)isGroup;
- (NSArray *) addShipsToRoute:(NSString *)route withRole:(NSString *)role quantity:(unsigned)count routeFraction:(double)routeFraction asGroup:(BOOL)isGroup;

- (BOOL) roleIsPirateVictim:(NSString *)role;

- (void) addWitchspaceJumpEffectForShip:(OOShipEntity *)ship;

- (void) setUpBreakPattern:(Vector)pos orientation:(Quaternion)q forDocking:(BOOL)forDocking;
- (void) handleGameOver;

- (void) setupIntroFirstGo:(BOOL)justCobra;
- (void) selectIntro2Previous;
- (void) selectIntro2Next;

- (OOStationEntity *) station;
- (OOPlanetEntity *) planet;
- (OOSunEntity *) sun;
- (NSArray *) planets;	// Note: does not include sun.

// Turn main station into just another station, for blowUpStation.
- (void) unMagicMainStation;
// find a valid station in interstellar space
- (OOStationEntity *) stationFriendlyTo:(OOShipEntity *) ship;

- (void) resetBeacons;
- (OOShipEntity *) firstBeacon;
- (OOShipEntity *) lastBeacon;
- (void) setNextBeacon:(OOShipEntity *) beaconShip;

- (GLfloat *) skyClearColor;
// Note: the alpha value is also air resistance!
- (void) setSkyColorRed:(GLfloat)red green:(GLfloat)green blue:(GLfloat)blue alpha:(GLfloat)alpha;

- (BOOL) breakPatternOver;
- (BOOL) breakPatternHide;

- (NSString *) randomShipKeyForRoleRespectingConditions:(NSString *)role;
- (OOShipEntity *) newShipWithRole:(NSString *)role;		// Selects ship using role weights, applies auto_ai, respects conditions
- (OOShipEntity *) newShipWithName:(NSString *)shipKey;	// Does not apply auto_ai or respect conditions
- (OOShipEntity *) newShipWithName:(NSString *)shipKey usePlayerProxy:(BOOL)usePlayerProxy;	// If usePlayerProxy, non-carriers are instantiated as OOProxyPlayerShipEntity.

- (Class) classForShipClass:(OOShipClass *)shipClass usePlayerProxy:(BOOL)usePlayerProxy;

- (NSString *)defaultAIForRole:(NSString *)role;		// autoAImap.plist lookup

- (OOCargoQuantity) maxCargoForShip:(NSString *) desc;

- (OOCreditsQuantity) getEquipmentPriceForKey:(NSString *) eq_key;

- (int) legalStatusOfManifest:(NSArray *)manifest;

- (NSArray *) getContainersOfGoods:(OOCargoQuantity)how_many scarce:(BOOL)scarce;
- (NSArray *) getContainersOfDrugs:(OOCargoQuantity) how_many;
- (NSArray *) getContainersOfCommodity:(NSString *)commodity_name :(OOCargoQuantity)how_many;
- (void) fillCargopodWithRandomCargo:(OOShipEntity *)cargopod;

- (OOCommodityType) getRandomCommodity;
- (OOCargoQuantity) getRandomAmountOfCommodity:(OOCommodityType)co_type;

- (NSArray *) commodityDataForType:(OOCommodityType)type;
- (OOCommodityType) commodityForName:(NSString *)co_name;
- (NSString *) symbolicNameForCommodity:(OOCommodityType)co_type;
- (NSString *) displayNameForCommodity:(OOCommodityType) o_type;
- (OOMassUnit) unitsForCommodity:(OOCommodityType)co_type;
- (NSString *) describeCommodity:(OOCommodityType)co_type amount:(OOCargoQuantity)co_amount;

- (void) setGameView:(MyOpenGLView *)view;
- (MyOpenGLView *) gameView;
- (OOGameController *) gameController;
- (NSDictionary *) gameSettings;

- (void) drawUniverse;
- (void) drawMessage;

// Used to draw subentities. Should be getting this from camera.
- (OOMatrix) viewMatrix;

- (id) entityForUniversalID:(OOUniversalID)u_id DEPRECATED_FUNC;

- (BOOL) addEntity:(OOEntity *) entity;
- (BOOL) removeEntity:(OOEntity *) entity;
- (void) ensureEntityReallyRemoved:(OOEntity *)entity;
- (void) removeAllEntitiesExceptPlayer;
- (void) removeDemoShips;

- (OOShipEntity *) makeDemoShipWithRole:(NSString *)role spinning:(BOOL)spinning;

- (BOOL) isVectorClearFromEntity:(OOEntity *)e1 toDistance:(double)dist fromPoint:(Vector)p2;
- (OOEntity *) hazardOnRouteFromEntity:(OOEntity *)e1 toDistance:(double)dist fromPoint:(Vector)p2;
- (Vector) getSafeVectorFromEntity:(OOEntity *)e1 toDistance:(double)dist fromPoint:(Vector)p2;

- (OOShipEntity *) getFirstShipHitByLaserFromShip:(OOShipEntity *)srcEntity inView:(OOViewID)viewdir offset:(Vector)offset rangeFound:(GLfloat*)range_ptr;
- (OOEntity *) getFirstEntityTargetedByPlayer;

- (NSArray *) getEntitiesWithinRange:(double)range ofEntity:(OOEntity *)entity;
- (unsigned) countShipsWithRole:(NSString *)role inRange:(double)range ofEntity:(OOEntity *)entity;
- (unsigned) countShipsWithRole:(NSString *)role;
- (unsigned) countShipsWithPrimaryRole:(NSString *)role inRange:(double)range ofEntity:(OOEntity *)entity;
- (unsigned) countShipsWithPrimaryRole:(NSString *)role;
- (unsigned) countShipsWithScanClass:(OOScanClass)scanClass inRange:(double)range ofEntity:(OOEntity *)entity;
- (void) sendShipsWithPrimaryRole:(NSString *)role messageToAI:(NSString *)message;


// General count/search methods. Pass range of -1 and entity of nil to search all of system.
- (unsigned) countEntitiesMatchingPredicate:(EntityFilterPredicate)predicate
								  parameter:(void *)parameter
									inRange:(double)range
								   ofEntity:(OOEntity *)entity;
- (unsigned) countShipsMatchingPredicate:(EntityFilterPredicate)predicate
							   parameter:(void *)parameter
								 inRange:(double)range
								ofEntity:(OOEntity *)entity;
- (NSMutableArray *) findEntitiesMatchingPredicate:(EntityFilterPredicate)predicate
										 parameter:(void *)parameter
										   inRange:(double)range
										  ofEntity:(OOEntity *)entity;
- (id) findOneEntityMatchingPredicate:(EntityFilterPredicate)predicate
							parameter:(void *)parameter;
- (NSMutableArray *) findShipsMatchingPredicate:(EntityFilterPredicate)predicate
									  parameter:(void *)parameter
										inRange:(double)range
									   ofEntity:(OOEntity *)entity;
- (id) nearestEntityMatchingPredicate:(EntityFilterPredicate)predicate
							parameter:(void *)parameter
					 relativeToEntity:(OOEntity *)entity;
- (id) nearestShipMatchingPredicate:(EntityFilterPredicate)predicate
						  parameter:(void *)parameter
				   relativeToEntity:(OOEntity *)entity;


- (OOTimeAbsolute) gameTime;	// "Game real time" clock.
- (OOTimeAbsolute) realTime;	// Actual real time clock (for UI).
- (OOTimeDelta) timeDelta;

- (void) findCollisionsAndShadows;
- (NSString*) collisionDescription;
- (void) dumpCollisions;

- (void) setViewDirection:(OOViewID) vd;
- (OOViewID) viewDirection;

- (NSString *) soundNameForCustomSoundKey:(NSString *)key;
- (NSDictionary *) screenTextureDescriptorForKey:(NSString *)key;

- (void) clearPreviousMessage;
- (void) setMessageGuiBackgroundColor:(OOColor *) some_color;
- (void) displayMessage:(NSString *) text forCount:(OOTimeDelta) count;
- (void) displayCountdownMessage:(NSString *) text forCount:(OOTimeDelta) count;
- (void) addDelayedMessage:(NSString *) text forCount:(OOTimeDelta) count afterDelay:(OOTimeDelta) delay;
- (void) addDelayedMessage:(NSDictionary *) textdict;
- (void) addMessage:(NSString *) text forCount:(OOTimeDelta) count;
- (void) addMessage:(NSString *) text forCount:(OOTimeDelta) count forceDisplay:(BOOL) forceDisplay;
- (void) addCommsMessage:(NSString *) text forCount:(OOTimeDelta) count;
- (void) addCommsMessage:(NSString *) text forCount:(OOTimeDelta) count andShowComms:(BOOL)showComms logOnly:(BOOL)logOnly;
- (void) showCommsLog:(OOTimeDelta) how_long;

- (void) update:(OOTimeDelta)delta_t;

// Time Acelleration Factor. In deployment builds, this is always 1.0 and -setTimeAccelerationFactor: does nothing.
- (double) timeAccelerationFactor;
- (void) setTimeAccelerationFactor:(double)newTimeAccelerationFactor;

- (void) filterSortedLists;

///////////////////////////////////////

- (void) setGalaxySeed:(Random_Seed) gal_seed;
- (void) setGalaxySeed:(Random_Seed) gal_seed andReinit:(BOOL) forced;

- (void) setSystemTo:(Random_Seed) s_seed;

- (Random_Seed) systemSeed;
- (Random_Seed) systemSeedForSystemNumber:(OOSystemID) n;
- (Random_Seed) systemSeedForSystemName:(NSString *)sysname;
- (OOSystemID) systemIDForSystemSeed:(Random_Seed)seed;
- (OOSystemID) currentSystemID;

- (NSDictionary *) descriptions;
- (NSDictionary *) characters;
- (NSDictionary *) missiontext;

- (NSString *)descriptionForKey:(NSString *)key;	// String, or random item from array
- (NSString *)descriptionForArrayKey:(NSString *)key index:(unsigned)index;	// Indexed item from array
- (BOOL) descriptionBooleanForKey:(NSString *)key;	// Boolean from descriptions.plist, for configuration.

- (NSString *) keyForPlanetOverridesForSystemSeed:(Random_Seed) s_seed inGalaxySeed:(Random_Seed) g_seed;
- (NSString *) keyForInterstellarOverridesForSystemSeeds:(Random_Seed) s_seed1 :(Random_Seed) s_seed2 inGalaxySeed:(Random_Seed) g_seed;
- (NSDictionary *) generateSystemData:(Random_Seed) system_seed;
- (NSDictionary *) generateSystemData:(Random_Seed) s_seed useCache:(BOOL) useCache;
- (NSDictionary *) currentSystemData;	// Same as generateSystemData:systemSeed unless in interstellar space.
- (BOOL) isInInterstellarSpace;

- (void)setObject:(id)object forKey:(NSString *)key forPlanetKey:(NSString *)planetKey;

- (void) setSystemDataKey:(NSString*) key value:(NSObject*) object;
- (void) setSystemDataForGalaxy:(OOGalaxyID) gnum planet:(OOSystemID) pnum key:(NSString *)key value:(id)object;
- (id) systemDataForGalaxy:(OOGalaxyID) gnum planet:(OOSystemID) pnum key:(NSString *)key;
- (NSArray *) systemDataKeysForGalaxy:(OOGalaxyID)gnum planet:(OOSystemID)pnum;
- (NSString *) getSystemName:(Random_Seed) s_seed;
- (OOGovernmentID) getSystemGovernment:(Random_Seed)s_seed;
- (NSString *) getSystemInhabitants:(Random_Seed) s_seed;
- (NSString *) getSystemInhabitants:(Random_Seed) s_seed plural:(BOOL)plural;
- (NSString *) generateSystemName:(Random_Seed) system_seed;
- (NSString *) generatePhoneticSystemName:(Random_Seed) s_seed;
- (NSString *) generateSystemInhabitants:(Random_Seed) s_seed plural:(BOOL)plural;
- (NSPoint) coordinatesForSystem:(Random_Seed)s_seed;
- (Random_Seed) findSystemAtCoords:(NSPoint) coords withGalaxySeed:(Random_Seed) gal_seed;
- (Random_Seed) findSystemFromName:(NSString *) sysName;

/**
 * Finds systems within range.  If range is greater than 7.0LY then only look within 7.0LY.
 */
- (NSMutableArray *) nearbyDestinationsWithinRange:(double) range;

- (Random_Seed) findNeighbouringSystemToCoords:(NSPoint) coords withGalaxySeed:(Random_Seed) gal_seed;
- (Random_Seed) findConnectedSystemAtCoords:(NSPoint) coords withGalaxySeed:(Random_Seed) gal_seed;
- (int) findSystemNumberAtCoords:(NSPoint) coords withGalaxySeed:(Random_Seed) gal_seed;
- (NSPoint) findSystemCoordinatesWithPrefix:(NSString *) p_fix;
- (NSPoint) findSystemCoordinatesWithPrefix:(NSString *) p_fix exactMatch:(BOOL) exactMatch;
- (BOOL*) systemsFound;
- (NSString*) systemNameIndex:(OOSystemID) index;
- (NSDictionary *) routeFromSystem:(OOSystemID) start toSystem:(OOSystemID) goal optimizedBy:(OORouteType) optimizeBy;
- (NSArray *) neighboursToSystem:(OOSystemID) system_number;
- (NSArray *) neighboursToRandomSeed:(Random_Seed) seed;

- (NSMutableDictionary *) localPlanetInfoOverrides;
- (void) setLocalPlanetInfoOverrides:(NSDictionary*) dict;

- (void) preloadPlanetTexturesForSystem:(Random_Seed)seed;

- (NSDictionary *) planetInfo;

- (NSArray *) equipmentData;
- (NSDictionary *) commodityLists;
- (NSArray *) commodityData;

- (BOOL) generateEconomicDataWithEconomy:(OOEconomyID) economy andRandomFactor:(int) random_factor;
- (NSArray *) commodityDataForEconomy:(OOEconomyID) economy andStation:(OOStationEntity *)some_station andRandomFactor:(int) random_factor;

- (NSString *) timeDescription:(OOTimeDelta) interval;
- (NSString *) shortTimeDescription:(OOTimeDelta) interval;

- (Random_Seed) marketSeed;
- (NSArray *) passengersForLocalSystemAtTime:(OOTimeAbsolute) current_time;
- (NSArray *) contractsForLocalSystemAtTime:(OOTimeAbsolute) current_time;
- (NSArray *) shipsForSaleForSystem:(Random_Seed) s_seed withTL:(OOTechLevelID) specialTL atTime:(OOTimeAbsolute) current_time;

/* Calculate base cost, before depreciation */
- (OOCreditsQuantity) tradeInValueForCommanderDictionary:(NSDictionary*) cmdr_dict;

- (NSString*) brochureDescriptionWithDictionary:(NSDictionary*) dict standardEquipment:(NSArray*) extras optionalEquipment:(NSArray*) options;

- (Vector) getWitchspaceExitPosition;
- (Vector) randomizeFromSeedAndGetWitchspaceExitPosition;
- (Vector) getWitchspaceExitPositionResettingRandomSeed:(BOOL)resetSeed;
- (Quaternion) getWitchspaceExitRotation;

- (Vector) getSunSkimStartPositionForShip:(OOShipEntity*) ship;
- (Vector) getSunSkimEndPositionForShip:(OOShipEntity*) ship;

- (NSArray*) listBeaconsWithCode:(NSString*) code;

- (void) allShipsDoScriptEvent:(jsid)event andReactToAIMessage:(NSString *)message;

///////////////////////////////////////

- (void) clearGUIs;

- (GuiDisplayGen *) gui;
- (GuiDisplayGen *) commLogGUI;
- (GuiDisplayGen *) messageGUI;

- (void) resetCommsLogColor;

- (void) setDisplayCursor:(BOOL) value;
- (BOOL) displayCursor;

- (void) setDisplayText:(BOOL) value;
- (BOOL) displayGUI;

- (void) setDisplayFPS:(BOOL) value;
- (BOOL) displayFPS;

- (void) setAutoSave:(BOOL) value;
- (BOOL) autoSave;

- (void) setWireframeGraphics:(BOOL) value;
- (BOOL) wireframeGraphics;

- (void) setReducedDetail:(BOOL) value;
- (void) setReducedDetail:(BOOL) value transiently:(BOOL)transiently;
- (BOOL) reducedDetail;

- (void) setShaderEffectsLevel:(OOShaderSetting)value;
- (void) setShaderEffectsLevel:(OOShaderSetting)value transiently:(BOOL)transiently;
- (OOShaderSetting) shaderEffectsLevel;
- (BOOL) useShaders;

- (void) handleOoliteException:(NSException*) ooliteException;

- (GLfloat)airResistanceFactor;

// speech routines
//
- (void) startSpeakingString:(NSString *) text;
//
- (void) stopSpeaking;
//
- (BOOL) isSpeaking;
//
#if OOLITE_ESPEAK
- (NSString *) voiceName:(unsigned int) index;
- (unsigned int) voiceNumber:(NSString *) name;
- (unsigned int) nextVoice:(unsigned int) index;
- (unsigned int) prevVoice:(unsigned int) index;
- (unsigned int) setVoice:(unsigned int) index withGenderM:(BOOL) isMale;
#endif
//
////

//autosave 
- (void) setAutoSaveNow:(BOOL) value;
- (BOOL) autoSaveNow;

- (int) framesDoneThisUpdate;
- (void) resetFramesDoneThisUpdate;

// True if textual pause message (as opposed to overlay) is being shown.
- (BOOL) pauseMessageVisible;
- (void) setPauseMessageVisible:(BOOL)value;

- (BOOL) permanentCommLog;
- (void) setPermanentCommLog:(BOOL)value;
- (void) setAutoCommLog:(BOOL)value;

- (BOOL) blockJSPlayerShipProps;
- (void) setBlockJSPlayerShipProps:(BOOL)value;

@end


/*	Use UNIVERSE to refer to the global universe object.
	The purpose of this is that it makes UNIVERSE essentially a read-only
	global with zero overhead.
*/
OOINLINE OOUniverse *GetUniverse(void) INLINE_CONST_FUNC;
OOINLINE OOUniverse *GetUniverse(void)
{
	extern OOUniverse *gSharedUniverse;
	return gSharedUniverse;
}
#define UNIVERSE GetUniverse()


// Only for use with string literals, and only for looking up strings.
NSString *DESC_(NSString *key);
NSString *DESC_PLURAL_(NSString *key, int count);
#define DESC(key)	(DESC_(key ""))
#define DESC_PLURAL(key,count)	(DESC_PLURAL_(key, count))


NSString *OODisplayStringFromGovernmentID(OOGovernmentID government);
NSString *OODisplayStringFromEconomyID(OOEconomyID economy);
