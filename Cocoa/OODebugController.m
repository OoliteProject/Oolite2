/*

OODebugController.m


Oolite
Copyright (C) 2004-2007 Giles C Williams and contributors

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


This file may also be distributed under the MIT/X11 license:

Copyright (C) 2007 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#ifndef NDEBUG

#import "OODebugController.h"
#import "ResourceManager.h"

#import "OOGraphicsResetManager.h"
#import "OOTexture.h"
#import "OOLogging.h"
#import "Universe.h"
#import "OOOpenGL.h"
#import "OOCacheManager.h"
#import "PlayerEntity.h"


static OODebugController *sSingleton = nil;


@implementation OODebugController

- (id)init
{
	NSString					*nibPath = nil;
	NSMenuItem					*item = nil;
	NSEnumerator				*itemEnum = nil;
	
	self = [super init];
	if (self != nil)
	{
		nibPath = [ResourceManager pathForFileNamed:@"OODebugController.nib" inFolder:nil];
		if (nibPath == nil)
		{
			[self release];
			self = nil;
		}
		else
		{
			[NSBundle loadNibFile:nibPath externalNameTable:[NSDictionary dictionaryWithObject:self forKey:@"NSOwner"] withZone:nil];
			
			// Insert debug menu in menu bar
			[menu setTitle:@"Debug"];
			item = [[NSMenuItem alloc] initWithTitle:@"Debug" action:nil keyEquivalent:@""];
			[item setSubmenu:menu];
			[[NSApp mainMenu] addItem:item];
			[item release];
			
			// Set up Log Message Classes submenu. Items with no action are mapped to toggleThisLogMessageClassAction:.
			for (itemEnum = [[logMessageClassSubMenu itemArray] objectEnumerator]; (item = [itemEnum nextObject]); )
			{
				if ([item action] == NULL)
				{
					[item setAction:@selector(toggleThisLogMessageClassAction:)];
					[item setTarget:self];
				}
			}
		}
	}
	
	return self;
}


- (void)dealloc
{
	if (sSingleton == self)  sSingleton = nil;
	
	[super dealloc];
}


+ (id)sharedDebugController
{
	// NOTE: assumes single-threaded first access. See header.
	if (sSingleton == nil)  [[self alloc] init];
	return sSingleton;
}


- (void)awakeFromNib
{
	[logPrefsWindow center];
}


#pragma mark -

- (IBAction)graphicsResetAction:sender
{
	[[OOGraphicsResetManager sharedManager] resetGraphicsState];
}


- (IBAction)clearTextureCacheAction:sender
{
	[OOTexture clearCache];
}


- (IBAction)resetAndClearAction:sender
{
	[OOTexture clearCache];
	[[OOGraphicsResetManager sharedManager] resetGraphicsState];
}


- (IBAction)dumpEntityListAction:sender
{
	BOOL						wasEnabled;
	
	wasEnabled = OOLogWillDisplayMessagesInClass(@"universe.objectDump");
	OOLogSetDisplayMessagesInClass(@"universe.objectDump", YES);
	
	[UNIVERSE obj_dump];
	
	OOLogSetDisplayMessagesInClass(@"universe.objectDump", wasEnabled);
}


- (IBAction)dumpPlayerStateAction:sender
{
	[[PlayerEntity sharedPlayer] dumpState];
}


- (IBAction)createShipAction:sender
{
	[NSApp runModalForWindow:createShipPanel];
	[createShipPanel orderOut:self];
}


- (IBAction)clearAllCachesAction:sender
{
	[[OOCacheManager sharedCache] clearAllCaches];
}


- (IBAction)toggleThisLogMessageClassAction:sender
{
	NSString					*msgClass = nil;
	
	if ([sender respondsToSelector:@selector(title)])
	{
		msgClass = [sender title];
		OOLogSetDisplayMessagesInClass(msgClass, !OOLogWillDisplayMessagesInClass(msgClass));
	}
}


- (IBAction)otherLogMessageClassAction:sender
{
	[NSApp runModalForWindow:logMessageClassPanel];
	[logMessageClassPanel orderOut:self];
}


- (IBAction)logMsgClassPanelEnableAction:sender
{
	NSString					*msgClass = nil;
	
	msgClass = [logMsgClassPanelTextField stringValue];
	if ([msgClass length] != 0)  OOLogSetDisplayMessagesInClass(msgClass, YES);
	
	[NSApp stopModal];
}


- (IBAction)logMsgClassPanelDisableAction:sender
{
	NSString					*msgClass = nil;
	
	msgClass = [logMsgClassPanelTextField stringValue];
	if ([msgClass length] != 0)  OOLogSetDisplayMessagesInClass(msgClass, NO);
	
	[NSApp stopModal];
}


- (IBAction)toggleThisDebugFlagAction:sender
{
	debug ^= [sender tag];
}


- (IBAction)showLogPreferencesAction:sender
{
	[logShowAppNameCheckBox setState:OOLogShowApplicationName()];
	[logShowFunctionCheckBox setState:OOLogShowFunction()];
	[logShowFileAndLineCheckBox setState:OOLogShowFileAndLine()];
	[logShowMessageClassCheckBox setState:OOLogShowMessageClass()];
	
	[logPrefsWindow makeKeyAndOrderFront:self];
}


- (IBAction)logSetShowAppNameAction:sender
{
	OOLogSetShowApplicationName([sender state]);
}


- (IBAction)logSetShowFunctionAction:sender
{
	OOLogSetShowFunction([sender state]);
}


- (IBAction)logSetShowFileAndLineAction:sender
{
	OOLogSetShowFileAndLine([sender state]);
}


- (IBAction)logSetShowMessageClassAction:sender
{
	OOLogSetShowMessageClass([sender state]);
}


- (IBAction)insertLogSeparatorAction:sender
{
	OOLogInsertMarker();
}


- (IBAction)createShipPanelOKAction:sender
{
	NSString					*shipRole = nil;
	
	shipRole = [createShipPanelTextField stringValue];
	if ([shipRole length] != 0)  [UNIVERSE addShipWithRole:shipRole nearRouteOneAt:1.0];
	
	[NSApp stopModal];	
}


- (IBAction)modalPanelCancelAction:sender
{
	[NSApp stopModal];
}


#pragma mark -

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	SEL							action = NULL;
	NSString					*msgClass = nil;
	int							tag;
	
	action = [menuItem action];
	
	if (action == @selector(toggleThisLogMessageClassAction:))
	{
		msgClass = [menuItem title];
		[menuItem setState:OOLogWillDisplayMessagesInClass(msgClass)];
		return YES;
	}
	if (action == @selector(toggleThisDebugFlagAction:))
	{
		tag = [menuItem tag];
		[menuItem setState:(debug & tag) == tag];
		return YES;
	}
	
	return [self respondsToSelector:action];
}

@end


@implementation OODebugController (Singleton)

/*	Canonical singleton boilerplate.
	See Cocoa Fundamentals Guide: Creating a Singleton Instance.
	See also +sharedDebugController above.
*/

+ (id)allocWithZone:(NSZone *)inZone
{
	if (sSingleton == nil)
	{
		sSingleton = [super allocWithZone:inZone];
		return sSingleton;
	}
	return nil;
}


- (id)copyWithZone:(NSZone *)inZone
{
	return self;
}


- (id)retain
{
	return self;
}


- (unsigned)retainCount
{
	return UINT_MAX;
}


- (void)release
{}


- (id)autorelease
{
	return self;
}

@end

#endif	// NDEBUG
