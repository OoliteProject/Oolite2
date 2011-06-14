/*

OOJSEntity.m

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

#import "OOJSEntity.h"
#import "OOJSVector.h"
#import "OOJSQuaternion.h"
#import "OOJavaScriptEngine.h"
#import "OOConstToJSString.h"
#import "EntityOOJavaScriptExtensions.h"
#import "OOJSCall.h"

#import "OOJSPlayer.h"
#import "PlayerEntity.h"
#import "OOShipEntity.h"


JSObject		*gOOEntityJSPrototype;


static JSBool EntityGetProperty(JSContext *context, JSObject *this, jsid propID, jsval *value);
static JSBool EntitySetProperty(JSContext *context, JSObject *this, jsid propID, JSBool strict, jsval *value);


JSClass gOOEntityJSClass =
{
	"Entity",
	JSCLASS_HAS_PRIVATE,
	
	JS_PropertyStub,		// addProperty
	JS_PropertyStub,		// delProperty
	EntityGetProperty,		// getProperty
	EntitySetProperty,		// setProperty
	JS_EnumerateStub,		// enumerate
	JS_ResolveStub,			// resolve
	JS_ConvertStub,			// convert
	OOJSObjectWrapperFinalize,// finalize
	JSCLASS_NO_OPTIONAL_MEMBERS
};


enum
{
	// Property IDs
	kEntity_collisionRadius,	// collision radius, double, read-only.
	kEntity_distanceTravelled,	// distance travelled, double, read-only.
	kEntity_energy,				// energy, double, read-write.
	kEntity_energyCapacity,		// energyCapacity, double, read-only.
	kEntity_heading,			// heading, vector, read-only (like orientation but ignoring twist angle)
	kEntity_mass,				// mass, double, read-only
	kEntity_orientation,		// orientation, quaternion, read/write
	kEntity_owner,				// owner, Entity, read-only. (Parent ship for subentities, station for defense ships, launching ship for missiles etc)
	kEntity_position,			// position in system space, Vector, read/write
	kEntity_scanClass,			// scan class, string, read-only
	kEntity_spawnTime,			// spawn time, double, read-only.
	kEntity_status,				// entity status, string, read-only
	kEntity_isPlanet,			// is planet, boolean, read-only.
	kEntity_isPlayer,			// is player, boolean, read-only.
	kEntity_isShip,				// is ship, boolean, read-only.
	kEntity_isStation,			// is station, boolean, read-only.
	kEntity_isSubEntity,		// is subentity, boolean, read-only.
	kEntity_isSun,				// is sun, boolean, read-only.
	kEntity_isValid,			// is not stale, boolean, read-only.
};


static JSPropertySpec sEntityProperties[] =
{
	// JS name					ID							flags
	{ "collisionRadius",		kEntity_collisionRadius,	OOJS_PROP_READONLY_CB },
	{ "distanceTravelled",		kEntity_distanceTravelled,	OOJS_PROP_READONLY_CB },
	{ "energy",					kEntity_energy,				OOJS_PROP_READWRITE_CB },
	{ "energyCapacity",			kEntity_energyCapacity,		OOJS_PROP_READONLY_CB },
	{ "heading",				kEntity_heading,			OOJS_PROP_READONLY_CB },
	{ "mass",					kEntity_mass,				OOJS_PROP_READONLY_CB },
	{ "orientation",			kEntity_orientation,		OOJS_PROP_READWRITE_CB },
	{ "owner",					kEntity_owner,				OOJS_PROP_READONLY_CB },
	{ "position",				kEntity_position,			OOJS_PROP_READWRITE_CB },
	{ "scanClass",				kEntity_scanClass,			OOJS_PROP_READONLY_CB },
	{ "spawnTime",				kEntity_spawnTime,			OOJS_PROP_READONLY_CB },
	{ "status",					kEntity_status,				OOJS_PROP_READONLY_CB },
	{ "isPlanet",				kEntity_isPlanet,			OOJS_PROP_READONLY_CB },
	{ "isPlayer",				kEntity_isPlayer,			OOJS_PROP_READONLY_CB },
	{ "isShip",					kEntity_isShip,				OOJS_PROP_READONLY_CB },
	{ "isStation",				kEntity_isStation,			OOJS_PROP_READONLY_CB },
	{ "isSubEntity",			kEntity_isSubEntity,		OOJS_PROP_READONLY_CB },
	{ "isSun",					kEntity_isSun,				OOJS_PROP_READONLY_CB },
	{ "isValid",				kEntity_isValid,			OOJS_PROP_READONLY_CB },
	{ 0 }
};


static JSFunctionSpec sEntityMethods[] =
{
	// JS name					Function					min args
	{ "toString",				OOJSObjectWrapperToString,	0 },
	{ 0 }
};


void InitOOJSEntity(JSContext *context, JSObject *global)
{
	gOOEntityJSPrototype = JS_InitClass(context, global, NULL, &gOOEntityJSClass, OOJSUnconstructableConstruct, 0, sEntityProperties, sEntityMethods, NULL, NULL);
	OOJSRegisterObjectConverter(&gOOEntityJSClass, OOJSBasicPrivateObjectConverter);
}


BOOL JSValueToEntity(JSContext *context, jsval value, OOEntity **outEntity)
{
	if (JSVAL_IS_OBJECT(value))
	{
		return OOJSEntityGetEntity(context, JSVAL_TO_OBJECT(value), outEntity);
	}
	
	return NO;
}


BOOL EntityFromArgumentList(JSContext *context, NSString *scriptClass, NSString *function, uintN argc, jsval *argv, OOEntity **outEntity, uintN *outConsumed)
{
	OOJS_PROFILE_ENTER
	
	// Sanity checks.
	if (outConsumed != NULL)  *outConsumed = 0;
	if (EXPECT_NOT(argc == 0 || argv == NULL || outEntity == NULL))
	{
		OOLogGenericParameterError();
		return NO;
	}
	
	// Get value, if possible.
	if (EXPECT_NOT(!JSValueToEntity(context, argv[0], outEntity)))
	{
		// Failed; report bad parameters, if given a class and function.
		if (scriptClass != nil && function != nil)
		{
			OOJSReportWarning(context, @"%@.%@(): expected entity, got %@.", scriptClass, function, [NSString stringWithJavaScriptParameters:argv count:1 inContext:context]);
			return NO;
		}
	}
	
	// Success.
	if (outConsumed != NULL)  *outConsumed = 1;
	return YES;
	
	OOJS_PROFILE_EXIT
}


static JSBool EntityGetProperty(JSContext *context, JSObject *this, jsid propID, jsval *value)
{
	if (!JSID_IS_INT(propID))  return YES;
	
	OOJS_NATIVE_ENTER(context)
	
	OOEntity						*entity = nil;
	id							result = nil;
	
	if (EXPECT_NOT(!OOJSEntityGetEntity(context, this, &entity))) return NO;
	if (OOIsStaleEntity(entity))
	{ 
		if (JSID_TO_INT(propID) == kEntity_isValid)  *value = JSVAL_FALSE;
		else  { *value = JSVAL_VOID; }
		return YES;
	}
	
	switch (JSID_TO_INT(propID))
	{
		case kEntity_collisionRadius:
			return JS_NewNumberValue(context, [entity collisionRadius], value);
	
		case kEntity_position:
			return VectorToJSValue(context, [entity position], value);
		
		case kEntity_orientation:
			return QuaternionToJSValue(context, [entity normalOrientation], value);
		
		case kEntity_heading:
			return VectorToJSValue(context, vector_forward_from_quaternion([entity normalOrientation]), value);
		
		case kEntity_status:
			*value = OOJSValueFromEntityStatus(context, [entity status]);
			return YES;
		
		case kEntity_scanClass:
			*value = OOJSValueFromScanClass(context, [entity scanClass]);
			return YES;
		
		case kEntity_mass:
			return JS_NewNumberValue(context, [entity mass], value);
		
		case kEntity_owner:
			result = [entity owner];
			if (result == entity)  result = nil;
			break;
		
		case kEntity_energy:
			return JS_NewNumberValue(context, [entity energy], value);
		
		case kEntity_energyCapacity:
			return JS_NewNumberValue(context, [entity maxEnergy], value);
		
		case kEntity_isValid:
			*value = JSVAL_TRUE;
			return YES;
		
		case kEntity_isShip:
			*value = OOJSValueFromBOOL([entity isShip]);
			return YES;
		
		case kEntity_isStation:
			*value = OOJSValueFromBOOL([entity isStation]);
			return YES;
			
		case kEntity_isSubEntity:
			*value = OOJSValueFromBOOL([entity isSubEntity]);
			return YES;
		
		case kEntity_isPlayer:
			*value = OOJSValueFromBOOL([entity isPlayer]);
			return YES;
			
		case kEntity_isPlanet:
			*value = OOJSValueFromBOOL([entity isPlanet]);
			return YES;
			
		case kEntity_isSun:
			*value = OOJSValueFromBOOL([entity isSun]);
			return YES;
		
		case kEntity_distanceTravelled:
			return JS_NewNumberValue(context, [entity distanceTravelled], value);
		
		case kEntity_spawnTime:
			return JS_NewNumberValue(context, [entity spawnTime], value);
		
		default:
			OOJSReportBadPropertySelector(context, this, propID, sEntityProperties);
	}
	
	*value = OOJSValueFromNativeObject(context, result);
	return YES;
	
	OOJS_NATIVE_EXIT
}


static JSBool EntitySetProperty(JSContext *context, JSObject *this, jsid propID, JSBool strict, jsval *value)
{
	if (!JSID_IS_INT(propID))  return YES;
	
	OOJS_NATIVE_ENTER(context)
	
	OOEntity				*entity = nil;
	double				fValue;
	Vector				vValue;
	Quaternion			qValue;
	
	if (EXPECT_NOT(!OOJSEntityGetEntity(context, this, &entity)))  return NO;
	if (OOIsStaleEntity(entity))  return YES;
	
	switch (JSID_TO_INT(propID))
	{
		case kEntity_position:
			if (JSValueToVector(context, *value, &vValue))
			{
				[entity setPosition:vValue];
				if ([entity isShip]) [(OOShipEntity *)entity resetExhaustPlumes];
				return YES;
			}
			break;
			
		case kEntity_orientation:
			if (JSValueToQuaternion(context, *value, &qValue))
			{
				quaternion_normalize(&qValue);
				[entity setNormalOrientation:qValue];
				return YES;
			}
			break;
			
		case kEntity_energy:
			if (JS_ValueToNumber(context, *value, &fValue))
			{
				fValue = OOClamp_0_max_d(fValue, [entity maxEnergy]);
				[entity setEnergy:fValue];
				return YES;
			}
			break;
		
		default:
			OOJSReportBadPropertySelector(context, this, propID, sEntityProperties);
			return NO;
	}
	
	OOJSReportBadPropertyValue(context, this, propID, sEntityProperties, *value);
	return NO;
	
	OOJS_NATIVE_EXIT
}
