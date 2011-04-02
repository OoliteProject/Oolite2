/*

OOJSPlayer.h

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

#import "OOJSPlayer.h"
#import "OOJSEntity.h"
#import "OOJSShip.h"
#import "OOJSVector.h"
#import "OOJavaScriptEngine.h"
#import "EntityOOJavaScriptExtensions.h"

#import "PlayerEntity.h"
#import "PlayerEntityContracts.h"
#import "PlayerEntityScriptMethods.h"
#import "PlayerEntityLegacyScriptEngine.h"

#import "OOConstToString.h"
#import "OOStringParsing.h"


static JSObject		*sPlayerPrototype;
static JSObject		*sPlayerObject;


static JSBool PlayerGetProperty(JSContext *context, JSObject *this, jsid propID, jsval *value);
static JSBool PlayerSetProperty(JSContext *context, JSObject *this, jsid propID, JSBool strict, jsval *value);

static JSBool PlayerCommsMessage(JSContext *context, uintN argc, jsval *vp);
static JSBool PlayerConsoleMessage(JSContext *context, uintN argc, jsval *vp);
static JSBool PlayerIncreaseContractReputation(JSContext *context, uintN argc, jsval *vp);
static JSBool PlayerDecreaseContractReputation(JSContext *context, uintN argc, jsval *vp);
static JSBool PlayerIncreasePassengerReputation(JSContext *context, uintN argc, jsval *vp);
static JSBool PlayerDecreasePassengerReputation(JSContext *context, uintN argc, jsval *vp);
static JSBool PlayerAddMessageToArrivalReport(JSContext *context, uintN argc, jsval *vp);
static JSBool PlayerSetEscapePodDestination(JSContext *context, uintN argc, jsval *vp);


static JSClass sPlayerClass =
{
	"Player",
	JSCLASS_HAS_PRIVATE,
	
	JS_PropertyStub,		// addProperty
	JS_PropertyStub,		// delProperty
	PlayerGetProperty,		// getProperty
	PlayerSetProperty,		// setProperty
	JS_EnumerateStub,		// enumerate
	JS_ResolveStub,			// resolve
	JS_ConvertStub,			// convert
	OOJSObjectWrapperFinalize,// finalize
	JSCLASS_NO_OPTIONAL_MEMBERS
};


enum
{
	// Property IDs
	kPlayer_alertAltitude,			// low altitude alert flag, boolean, read-only
	kPlayer_alertCondition,			// alert level, integer, read-only
	kPlayer_alertEnergy,			// low energy alert flag, boolean, read-only
	kPlayer_alertHostiles,			// hostiles present alert flag, boolean, read-only
	kPlayer_alertMassLocked,		// mass lock alert flag, boolean, read-only
	kPlayer_alertTemperature,		// cabin temperature alert flag, boolean, read-only
	kPlayer_bounty,					// bounty, unsigned int, read/write
	kPlayer_contractReputation,		// reputation for cargo contracts, integer, read only
	kPlayer_credits,				// credit balance, float, read/write
	kPlayer_dockingClearanceStatus,	// docking clearance status, string, read only
	kPlayer_legalStatus,			// legalStatus, string, read-only
	kPlayer_name,					// Player name, string, read-only
	kPlayer_passengerReputation,	// reputation for passenger contracts, integer, read-only
	kPlayer_rank,					// rank, string, read-only
	kPlayer_score,					// kill count, integer, read/write
	kPlayer_trumbleCount,			// number of trumbles, integer, read-only
};


static JSPropertySpec sPlayerProperties[] =
{
	// JS name					ID							flags
	{ "alertAltitude",			kPlayer_alertAltitude,		OOJS_PROP_READONLY_CB },
	{ "alertCondition",			kPlayer_alertCondition,		OOJS_PROP_READONLY_CB },
	{ "alertEnergy",			kPlayer_alertEnergy,		OOJS_PROP_READONLY_CB },
	{ "alertHostiles",			kPlayer_alertHostiles,		OOJS_PROP_READONLY_CB },
	{ "alertMassLocked",		kPlayer_alertMassLocked,	OOJS_PROP_READONLY_CB },
	{ "alertTemperature",		kPlayer_alertTemperature,	OOJS_PROP_READONLY_CB },
	{ "bounty",					kPlayer_bounty,				OOJS_PROP_READWRITE_CB },
	{ "contractReputation",		kPlayer_contractReputation,	OOJS_PROP_READONLY_CB },
	{ "credits",				kPlayer_credits,			OOJS_PROP_READWRITE_CB },
	{ "dockingClearanceStatus",	kPlayer_dockingClearanceStatus,	OOJS_PROP_READONLY_CB },
	{ "legalStatus",			kPlayer_legalStatus,		OOJS_PROP_READONLY_CB },
	{ "name",					kPlayer_name,				OOJS_PROP_READONLY_CB },
	{ "passengerReputation",	kPlayer_passengerReputation,	OOJS_PROP_READONLY_CB },
	{ "rank",					kPlayer_rank,				OOJS_PROP_READONLY_CB },
	{ "score",					kPlayer_score,				OOJS_PROP_READWRITE_CB },
	{ "trumbleCount",			kPlayer_trumbleCount,		OOJS_PROP_READONLY_CB },
	{ 0 }
};


static JSFunctionSpec sPlayerMethods[] =
{
	// JS name							Function							min args
	{ "addMessageToArrivalReport",		PlayerAddMessageToArrivalReport,	1 },
	{ "commsMessage",					PlayerCommsMessage,					1 },
	{ "consoleMessage",					PlayerConsoleMessage,				1 },
	{ "decreaseContractReputation",		PlayerDecreaseContractReputation,	0 },
	{ "decreasePassengerReputation",	PlayerDecreasePassengerReputation,	0 },
	{ "increaseContractReputation",		PlayerIncreaseContractReputation,	0 },
	{ "increasePassengerReputation",	PlayerIncreasePassengerReputation,	0 },
	{ "setEscapePodDestination",		PlayerSetEscapePodDestination,		1 },	// null destination must be set explicitly
	{ 0 }
};


void InitOOJSPlayer(JSContext *context, JSObject *global)
{
	sPlayerPrototype = JS_InitClass(context, global, NULL, &sPlayerClass, OOJSUnconstructableConstruct, 0, sPlayerProperties, sPlayerMethods, NULL, NULL);
	OOJSRegisterObjectConverter(&sPlayerClass, OOJSBasicPrivateObjectConverter);
	
	// Create PLAYER object as a property of the global object.
	sPlayerObject = JS_DefineObject(context, global, "PLAYER", &sPlayerClass, sPlayerPrototype, OOJS_PROP_READONLY);
}


JSClass *JSPlayerClass(void)
{
	return &sPlayerClass;
}


JSObject *JSPlayerPrototype(void)
{
	return sPlayerPrototype;
}


JSObject *JSPlayerObject(void)
{
	return sPlayerObject;
}


static JSBool PlayerGetProperty(JSContext *context, JSObject *this, jsid propID, jsval *value)
{
	if (!JSID_IS_INT(propID))  return YES;
	
	OOJS_NATIVE_ENTER(context)
	
	id							result = nil;
	
	switch (JSID_TO_INT(propID))
	{
		case kPlayer_name:
			result = [PLAYER playerName];
			break;
			
		case kPlayer_score:
			*value = INT_TO_JSVAL([PLAYER score]);
			return YES;
			
		case kPlayer_credits:
			return JS_NewNumberValue(context, [PLAYER creditBalance], value);
			
		case kPlayer_rank:
			*value = OOJSValueFromNativeObject(context, OODisplayRatingStringFromKillCount([PLAYER score]));
			return YES;
			
		case kPlayer_legalStatus:
			*value = OOJSValueFromNativeObject(context, OODisplayStringFromLegalStatus([PLAYER bounty]));
			return YES;
			
		case kPlayer_alertCondition:
			*value = INT_TO_JSVAL([PLAYER alertCondition]);
			return YES;
			
		case kPlayer_alertTemperature:
			*value = OOJSValueFromBOOL([PLAYER alertFlags] & ALERT_FLAG_TEMP);
			return YES;
			
		case kPlayer_alertMassLocked:
			*value = OOJSValueFromBOOL([PLAYER alertFlags] & ALERT_FLAG_MASS_LOCK);
			return YES;
			
		case kPlayer_alertAltitude:
			*value = OOJSValueFromBOOL([PLAYER alertFlags] & ALERT_FLAG_ALT);
			return YES;
			
		case kPlayer_alertEnergy:
			*value = OOJSValueFromBOOL([PLAYER alertFlags] & ALERT_FLAG_ENERGY);
			return YES;
			
		case kPlayer_alertHostiles:
			*value = OOJSValueFromBOOL([PLAYER alertFlags] & ALERT_FLAG_HOSTILES);
			return YES;
			
		case kPlayer_trumbleCount:
			return JS_NewNumberValue(context, [PLAYER trumbleCount], value);
			
		case kPlayer_contractReputation:
			*value = INT_TO_JSVAL([PLAYER contractReputation]);
			return YES;
			
		case kPlayer_passengerReputation:
			*value = INT_TO_JSVAL([PLAYER passengerReputation]);
			return YES;
			
		case kPlayer_dockingClearanceStatus:
			// EMMSTRAN: OOConstToJSString-ify this.
			*value = OOJSValueFromNativeObject(context, DockingClearanceStatusToString([PLAYER getDockingClearanceStatus]));
			return YES;
			
		case kPlayer_bounty:
			*value = INT_TO_JSVAL([PLAYER legalStatus]);
			return YES;
		
		default:
			OOJSReportBadPropertySelector(context, this, propID, sPlayerProperties);
			return NO;
	}
	
	*value = OOJSValueFromNativeObject(context, result);
	return YES;
	
	OOJS_NATIVE_EXIT
}


static JSBool PlayerSetProperty(JSContext *context, JSObject *this, jsid propID, JSBool strict, jsval *value)
{
	if (!JSID_IS_INT(propID))  return YES;
	
	OOJS_NATIVE_ENTER(context)
	
	jsdouble					fValue;
	int32						iValue;
	
	switch (JSID_TO_INT(propID))
	{
		case kPlayer_score:
			if (JS_ValueToInt32(context, *value, &iValue))
			{
				iValue = MAX(iValue, 0);
				[PLAYER setScore:iValue];
				return YES;
			}
			break;
			
		case kPlayer_credits:
			if (JS_ValueToNumber(context, *value, &fValue))
			{
				[PLAYER setCreditBalance:fValue];
				return YES;
			}
			break;
			
		case kPlayer_bounty:
			if (JS_ValueToInt32(context, *value, &iValue))
			{
				if (iValue < 0)  iValue = 0;
				[PLAYER setBounty:iValue];
				return YES;
			}
			break;
		
		default:
			OOJSReportBadPropertySelector(context, this, propID, sPlayerProperties);
			return NO;
	}
	
	OOJSReportBadPropertyValue(context, this, propID, sPlayerProperties, *value);
	return NO;
	
	OOJS_NATIVE_EXIT
}


// *** Methods ***

// commsMessage(message : String [, duration : Number])
static JSBool PlayerCommsMessage(JSContext *context, uintN argc, jsval *vp)
{
	OOJS_NATIVE_ENTER(context)
	
	NSString				*message = nil;
	double					time = 4.5;
	BOOL					gotTime = YES;
	
	if (argc > 0)  message = OOStringFromJSValue(context, OOJS_ARGV[0]);
	if (argc > 1)  gotTime = JS_ValueToNumber(context, OOJS_ARGV[1], &time);
	if (message == nil || !gotTime)
	{
		OOJSReportBadArguments(context, @"Player", @"commsMessage", argc, OOJS_ARGV, nil, @"message and optional duration");
		return NO;
	}
	
	[UNIVERSE addCommsMessage:message forCount:time];
	OOJS_RETURN_VOID;
	
	OOJS_NATIVE_EXIT
}


// consoleMessage(message : String [, duration : Number])
static JSBool PlayerConsoleMessage(JSContext *context, uintN argc, jsval *vp)
{
	OOJS_NATIVE_ENTER(context)
	
	NSString				*message = nil;
	double					time = 3.0;
	BOOL					gotTime = YES;
	
	if (argc > 0)  message = OOStringFromJSValue(context, OOJS_ARGV[0]);
	if (argc > 1)  gotTime = JS_ValueToNumber(context, OOJS_ARGV[1], &time);
	if (message == nil || !gotTime)
	{
		OOJSReportBadArguments(context, @"Player", @"consoleMessage", argc, OOJS_ARGV, nil, @"message and optional duration");
		return NO;
	}
	
	[UNIVERSE addMessage:message forCount:time];
	OOJS_RETURN_VOID;
	
	OOJS_NATIVE_EXIT
}


// increaseContractReputation()
static JSBool PlayerIncreaseContractReputation(JSContext *context, uintN argc, jsval *vp)
{
	OOJS_NATIVE_ENTER(context)
	
	[PLAYER increaseContractReputation];
	OOJS_RETURN_VOID;
	
	OOJS_NATIVE_EXIT
}


// decreaseContractReputation()
static JSBool PlayerDecreaseContractReputation(JSContext *context, uintN argc, jsval *vp)
{
	OOJS_NATIVE_ENTER(context)
	
	[PLAYER decreaseContractReputation];
	OOJS_RETURN_VOID;
	
	OOJS_NATIVE_EXIT
}


// increasePassengerReputation()
static JSBool PlayerIncreasePassengerReputation(JSContext *context, uintN argc, jsval *vp)
{
	OOJS_NATIVE_ENTER(context)
	
	[PLAYER increasePassengerReputation];
	OOJS_RETURN_VOID;
	
	OOJS_NATIVE_EXIT
}


// decreasePassengerReputation()
static JSBool PlayerDecreasePassengerReputation(JSContext *context, uintN argc, jsval *vp)
{
	OOJS_NATIVE_ENTER(context)
	
	[PLAYER decreasePassengerReputation];
	OOJS_RETURN_VOID;
	
	OOJS_NATIVE_EXIT
}

// addMessageToArrivalReport(message : String)
static JSBool PlayerAddMessageToArrivalReport(JSContext *context, uintN argc, jsval *vp)
{
	OOJS_NATIVE_ENTER(context)
	
	NSString				*report = nil;
	
	if (argc > 0)  report = OOStringFromJSValue(context, OOJS_ARGV[0]);
	if (report == nil)
	{
		OOJSReportBadArguments(context, @"Player", @"addMessageToArrivalReport", MIN(argc, 1U), OOJS_ARGV, nil, @"string (arrival message)");
		return NO;
	}
	
	[PLAYER addMessageToReport:report];
	OOJS_RETURN_VOID;
	
	OOJS_NATIVE_EXIT
}


// setEscapePodDestination(Entity | 'NEARBY_SYSTEM')
static JSBool PlayerSetEscapePodDestination(JSContext *context, uintN argc, jsval *vp)
{
	OOJS_NATIVE_ENTER(context)
	
	if (EXPECT_NOT(!OOIsPlayerStale()))
	{
		OOJSReportError(context, @"Player.setEscapePodDestination() only works while the escape pod is in flight.");
		return NO;
	}
	
	BOOL			OK = NO;
	id				destValue = nil;
	
	if (argc == 1)
	{
		destValue = OOJSNativeObjectFromJSValue(context, OOJS_ARGV[0]);
		
		if (destValue == nil)
		{
			[PLAYER setDockTarget:NULL];
			OK = YES;
		}
		else if ([destValue isKindOfClass:[ShipEntity class]] && [destValue isStation])
		{
			[PLAYER setDockTarget:destValue];
			OK = YES;
		}
		else if ([destValue isKindOfClass:[NSString class]])
		{
			if ([destValue isEqualToString:@"NEARBY_SYSTEM"])
			{
				// find the nearest system with a main station, or die in the attempt!
				[PLAYER setDockTarget:NULL];
				
				double rescueRange = 7.0;	// reach at least 1 other system!
				if ([UNIVERSE inInterstellarSpace])
				{
					// Set 3.5 ly as the limit, enough to reach at least 2 systems!
					rescueRange = 3.5;
				}
				NSMutableArray	*sDests = [UNIVERSE nearbyDestinationsWithinRange:rescueRange];
				int 			i = 0, nDests = [sDests count];
				
				if (nDests > 0)	for (i = --nDests; i > 0; i--)
				{
					if ([[sDests oo_dictionaryAtIndex:i] oo_boolForKey:@"nova"])
					{
						[sDests removeObjectAtIndex:i];
					}
				}
				
				// i is back to 0, nDests could have changed...
				nDests = [sDests count];
				if (nDests > 0)	// we have a system with a main station!
				{
					if (nDests > 1)  i = ranrot_rand() % nDests;	// any nearby system will do.
					NSDictionary *dest = [sDests objectAtIndex:i];
					
					// add more time until rescue, with overheads for entering witchspace in case of overlapping systems.
					double dist = [dest oo_doubleForKey:@"distance"];
					[PLAYER advanceClockBy:OOHOURS(.2 + dist * dist + 1.5 * (ranrot_rand() & 127))];
					
					// at the end of the docking sequence we'll check if the target system is the same as the system we're in...
					[PLAYER setTargetSystemSeed:RandomSeedFromString([dest oo_stringForKey:@"system_seed"])];
				}
				OK = YES;
			}
		}
		else
		{
			JSBool bValue;
			if (JS_ValueToBoolean(context, OOJS_ARGV[0], &bValue) && bValue == NO)
			{
				[PLAYER setDockTarget:NULL];
				OK = YES;
			}
		}
	}
	
	if (OK == NO)
	{
		OOJSReportBadArguments(context, @"Player", @"setEscapePodDestination", argc, OOJS_ARGV, nil, @"a valid station, null, or 'NEARBY_SYSTEM'");
	}
	return OK;
	
	OOJS_NATIVE_EXIT
}
