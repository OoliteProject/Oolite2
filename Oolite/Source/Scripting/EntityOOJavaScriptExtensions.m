/*

EntityOOJavaScriptExtensions.m

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


#import "EntityOOJavaScriptExtensions.h"
#import "OOJSEntity.h"
#import "OOJSShip.h"
#import "OOJSStation.h"
#import "OOStationEntity.h"
#import "OOPlanetEntity.h"


@implementation OOEntity (OOJavaScriptExtensions)

- (BOOL) isVisibleToScripts
{
	return NO;
}


- (NSString *) oo_jsClassName
{
	return @"Entity";
}


- (jsval) oo_jsValueInContext:(JSContext *)context
{
	JSClass					*class = NULL;
	JSObject				*prototype = NULL;
	jsval					result = JSVAL_NULL;
	
	if (_jsSelf == NULL && [self isVisibleToScripts])
	{
		// Create JS object
		[self getJSClass:&class andPrototype:&prototype];
		
		_jsSelf = JS_NewObject(context, class, prototype, NULL);
		if (_jsSelf != NULL)
		{
			if (!JS_SetPrivate(context, _jsSelf, [self weakRetain]))  _jsSelf = NULL;
		}
		
		if (_jsSelf != NULL)
		{
			OOJSAddGCObjectRoot(context, &_jsSelf, "Entity jsSelf");
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(deleteJSSelf)
														 name:kOOJavaScriptEngineWillResetNotification
													   object:[OOJavaScriptEngine sharedEngine]];
		}
	}
	
	if (_jsSelf != NULL)  result = OBJECT_TO_JSVAL(_jsSelf);
	
	return result;
	// Analyzer: object leaked. [Expected, object is retained by JS object.]
}


- (void) getJSClass:(JSClass **)outClass andPrototype:(JSObject **)outPrototype
{
	*outClass = JSEntityClass();
	*outPrototype = JSEntityPrototype();
}


- (void) deleteJSSelf
{
	if (_jsSelf != NULL)
	{
		_jsSelf = NULL;
		JSContext *context = OOJSAcquireContext();
		JS_RemoveObjectRoot(context, &_jsSelf);
		OOJSRelinquishContext(context);
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:kOOJavaScriptEngineWillResetNotification
													  object:[OOJavaScriptEngine sharedEngine]];
	}
}

@end


@implementation OOShipEntity (OOJavaScriptExtensions)

- (BOOL) isVisibleToScripts
{
	return YES;
}


- (void) getJSClass:(JSClass **)outClass andPrototype:(JSObject **)outPrototype
{
	*outClass = JSShipClass();
	*outPrototype = JSShipPrototype();
}


- (NSString *) oo_jsClassName
{
	return @"Ship";
}


- (NSArray *) subEntitiesForScript
{
	return [[self shipSubEntityEnumerator] allObjects];
}


- (void) setTargetForScript:(OOShipEntity *)target
{
	OOShipEntity *me = self;
	
	// Ensure coherence by not fiddling with subentities.
	while ([me isSubEntity])
	{
		if (me == [me owner] || [me owner] == nil)  break;
		me = (OOShipEntity *)[me owner];
	}
	while ([target isSubEntity])
	{
		if (target == [target owner] || [target owner] == nil)  break;
		target = (OOShipEntity *)[target owner];
	}
	if (![me isKindOfClass:[OOShipEntity class]])  return;
	if (target != nil)
	{
		[me addTarget:target];
		// Out of player's scanner range? Lose target - Nikos 20110415
		if ([me isPlayer] && distance2([me position], [target position]) > SCANNER_MAX_RANGE2)
		{
			[UNIVERSE addMessage:DESC(@"target-lost") forCount:3.0];
			[me removeTarget:target];
		}
	}
	else  [me removeTarget:[me primaryTarget]];
}

@end
