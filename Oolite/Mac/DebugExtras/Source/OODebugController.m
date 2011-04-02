/*

OODebugController.m


Oolite Debug OXP

Copyright (C) 2007-2010 Jens Ayton

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

#import "OODebugController.h"
#import "OODebugMonitor.h"
#import "OOMacDebugger.h"

#import "ResourceManager.h"

#import "OOGraphicsResetManager.h"
#import "OOTexture.h"
#import "Universe.h"
#import "OOOpenGL.h"
#import "OOCacheManager.h"
#import "PlayerEntity.h"
#import "OOJavaScriptEngine.h"
#import "OODebugInspector.h"
#import "OOEntityInspectorExtensions.h"
#import "OOConstToString.h"
#import "OODebugFlags.h"
#import "OOOpenGLExtensionManager.h"
#import "OoliteLogOutputHandler.h"


static OODebugController *sSingleton = nil;


@interface OODebugController (Private)

- (void)insertDebugMenu;
- (void)setUpLogMessageClassMenu;

@end


@implementation OODebugController

- (id<OODebuggerInterface>) setUpDebugger
{
	return [[[OOMacDebugger alloc] initWithController:jsConsoleController] autorelease];
}


- (id)init
{
	NSString					*nibPath = nil;
	
	self = [super init];
	if (self != nil)
	{
		_bundle = [[NSBundle bundleForClass:[self class]] retain];
		
		nibPath = [self pathForResource:@"OODebugController" ofType:@"nib"];
		if (nibPath == nil)
		{
			OOLog(@"debugOXP.load.failed", @"Could not find OODebugController.nib.");
			[self release];
			self = nil;
		}
		else
		{
			[NSBundle loadNibFile:nibPath externalNameTable:[NSDictionary dictionaryWithObject:self forKey:@"NSOwner"] withZone:NULL];
			
			[self insertDebugMenu];
			[self setUpLogMessageClassMenu];
			OOLog(@"debugOXP.load.success", @"Debug OXP loaded successfully.");
		}
	}
	
	return self;
}


- (void)dealloc
{
	if (sSingleton == self)  sSingleton = nil;
	
	[menu release];
	[logMessageClassPanel release];
	[logPrefsWindow release];
	[createShipPanel release];
	[jsConsoleController release];
	
	[_bundle release];
	
	[super dealloc];
}


+ (id)sharedDebugController
{
	// NOTE: assumes single-threaded first access. See header.
	if (sSingleton == nil)  sSingleton = [[self alloc] init];
	return sSingleton;
}


- (NSBundle *)bundle
{
	return _bundle;
}


- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)type
{
	return [[self bundle] pathForResource:name ofType:type];
}


- (void)awakeFromNib
{
	[logPrefsWindow center];
}


#pragma mark -

- (IBAction)showLogAction:sender
{
	[[NSWorkspace sharedWorkspace] openFile:OOLogHandlerGetLogPath()];
}


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
	
	[UNIVERSE debugDumpEntities];
	
	OOLogSetDisplayMessagesInClass(@"universe.objectDump", wasEnabled);
}


- (IBAction)dumpPlayerStateAction:sender
{
	[[PlayerEntity sharedPlayer] dumpState];
}


- (IBAction)createShipAction:sender
{
	NSString					*role = nil;
	
	role = [[NSUserDefaults standardUserDefaults] stringForKey:@"debug-create-ship-panel-last-role"];
	if (role != nil)
	{
		[createShipPanelTextField setStringValue:role];
	}
	
	[NSApp runModalForWindow:createShipPanel];
	[createShipPanel orderOut:self];
}


- (IBAction)clearAllCachesAction:sender
{
	[[OOCacheManager sharedCache] clearAllCaches];
}


- (IBAction)toggleWireframeModeAction:sender
{
	[UNIVERSE setWireframeGraphics:![UNIVERSE wireframeGraphics]];
}


- (IBAction) hideShowHUD:sender
{
	BOOL hidden = [[[PlayerEntity sharedPlayer] hud] isHidden];
	NSString *command = [NSString stringWithFormat:@"player.ship.hudHidden = %@", hidden ? @"false" : @"true"];
	[[OODebugMonitor sharedDebugMonitor] performJSConsoleCommand:command];
}


- (IBAction) inspectPlayer:sender
{
	//	[[PlayerEntity sharedPlayer] inspect];
	[[OODebugMonitor sharedDebugMonitor] performJSConsoleCommand:@"player.ship.inspect()"];
}


- (IBAction) inspectTarget:sender
{
	//	[[[PlayerEntity sharedPlayer] primaryTarget] inspect];
	[[OODebugMonitor sharedDebugMonitor] performJSConsoleCommand:@"player.ship.target.inspect()"];
}


- (IBAction) cleanUpInspectors:sender
{
	[OODebugInspector cleanUpInspectors];
}


static void SetDisplayLogMessagesInClassThroughJS(NSString *msgClass, BOOL display)
{
	NSString *command = [NSString stringWithFormat:@"console.setDisplayMessagesInClass(\"%@\", %@)", [msgClass escapedForJavaScriptLiteral], display ? @"true" : @"false"];
	[[OODebugMonitor sharedDebugMonitor] performJSConsoleCommand:command];
}


- (IBAction)toggleThisLogMessageClassAction:sender
{
	NSString					*msgClass = nil;
	
	if ([sender respondsToSelector:@selector(representedObject)])
	{
		msgClass = [sender representedObject];
		SetDisplayLogMessagesInClassThroughJS(msgClass, !OOLogWillDisplayMessagesInClass(msgClass));
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
	if ([msgClass length] != 0)  SetDisplayLogMessagesInClassThroughJS(msgClass, YES);
	
	[NSApp stopModal];
}


- (IBAction)logMsgClassPanelDisableAction:sender
{
	NSString					*msgClass = nil;
	
	msgClass = [logMsgClassPanelTextField stringValue];
	if ([msgClass length] != 0)  SetDisplayLogMessagesInClassThroughJS(msgClass, NO);
	
	[NSApp stopModal];
}


- (IBAction)toggleThisDebugFlagAction:sender
{
	uint32_t					tag, bits;
	NSString					*command = nil;
	
	tag = [sender tag];
	bits = gDebugFlags & tag;
	
	if (bits != tag)
	{
		// Flags are off or mixed.
		command = [NSString stringWithFormat:@"console.debugFlags |= 0x%.X", tag];
	}
	else
	{
		// Flags are all on.
		command = [NSString stringWithFormat:@"console.debugFlags &= ~0x%.X", tag];
	}
	
	[[OODebugMonitor sharedDebugMonitor] performJSConsoleCommand:command];
}


- (IBAction) setShaderModeToTag:sender
{
	OOShaderSetting setting = [sender tag];
	NSString *settingString = [OOStringFromShaderSetting(setting) escapedForJavaScriptLiteral];
	NSString *command = [NSString stringWithFormat:@"console.shaderMode = \"%@\"", settingString];
	
	[[OODebugMonitor sharedDebugMonitor] performJSConsoleCommand:command];
}


- (IBAction)showLogPreferencesAction:sender
{
	[logShowFunctionCheckBox setState:OOLogShowFunction()];
	[logShowFileAndLineCheckBox setState:OOLogShowFileAndLine()];
	[logShowMessageClassCheckBox setState:OOLogShowMessageClass()];
	[logShowTimeStampCheckBox setState:OOLogShowTime()];
	
	[logPrefsWindow makeKeyAndOrderFront:self];
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


- (IBAction) logSetShowTimeStampAction:sender
{
	OOLogSetShowTime([sender state]);
}


- (IBAction)insertLogSeparatorAction:sender
{
	[[OODebugMonitor sharedDebugMonitor] performJSConsoleCommand:@"console.writeLogMarker()"];
}


- (IBAction)createShipPanelOKAction:sender
{
	NSString					*shipRole = nil;
	
	shipRole = [createShipPanelTextField stringValue];
	if ([shipRole length] != 0)
	{
		[self performSelector:@selector(spawnShip:) withObject:shipRole afterDelay:0.1f];
		[[NSUserDefaults standardUserDefaults] setObject:shipRole forKey:@"debug-create-ship-panel-last-role"];
	}
	
	[NSApp stopModal];	
}


- (void)spawnShip:(NSString *)shipRole
{
	NSString					*command = nil;
	
	if (shipRole == nil)  return;
	
	if ([[OODebugMonitor sharedDebugMonitor] debuggerConnected])
	{
		command = [NSString stringWithFormat:@"this.T = system.addShips('%@', 1, player.ship.position, 10000); if (this.T) this.T = this.T[0]; else consoleMessage('command-error', 'Could not spawn \"%@\".');", [shipRole escapedForJavaScriptLiteral], [shipRole escapedForJavaScriptLiteral]];
		[[OODebugMonitor sharedDebugMonitor] performJSConsoleCommand:command];
	}
	else
	{
		[UNIVERSE addShipWithRole:shipRole nearRouteOneAt:1.0];
	}
}


- (IBAction)modalPanelCancelAction:sender
{
	[NSApp stopModal];
}


#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL							action = NULL;
	NSString					*msgClass = nil;
	uint32_t					tag, bits;
	int							state;
	
	action = [menuItem action];
	
	if (action == @selector(toggleThisLogMessageClassAction:))
	{
		msgClass = [menuItem representedObject];
		[menuItem setState:OOLogWillDisplayMessagesInClass(msgClass)];
		return YES;
	}
	if (action == @selector(toggleThisDebugFlagAction:))
	{
		tag = [menuItem tag];
		bits = gDebugFlags & tag;
		if (bits == 0)  state = NSOffState;
		else if (bits == tag)  state = NSOnState;
		else state = NSMixedState;
		
		[menuItem setState:state];
		return YES;
	}
	if (action == @selector(toggleWireframeModeAction:))
	{
		[menuItem setState:!![UNIVERSE wireframeGraphics]];		
		return YES;
	}
	if (action == @selector(inspectTarget:))
	{
		return [[PlayerEntity sharedPlayer] primaryTarget] != nil;
	}
	if (action == @selector(hideShowHUD:))
	{
		BOOL hidden = [[[PlayerEntity sharedPlayer] hud] isHidden];
		[menuItem setTitle:hidden ? @"Show HUD" : @"Hide HUD"];
		return YES;
	}
	if (action == @selector(setShaderModeToTag:))
	{
		OOShaderSetting itemLevel = [menuItem tag];
		
		[menuItem setState:[UNIVERSE shaderEffectsLevel] == itemLevel];
		return itemLevel <= [[OOOpenGLExtensionManager sharedManager] maximumShaderSetting];
	}
	
	return [self respondsToSelector:action];
}

@end


@implementation OODebugController (Private)

- (void)insertDebugMenu
{
	NSMenuItem					*item = nil;
	int							index;
	
	[menu setTitle:@"Debug"];
	item = [[NSMenuItem alloc] initWithTitle:@"Debug" action:NULL keyEquivalent:@""];
	[item setSubmenu:menu];
	[[NSApp mainMenu] addItem:item];
	[item release];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"debug-show-extra-menu-items"])
	{
		while (index = [menu indexOfItemWithTag:-42], index != -1)
		{
			[menu removeItemAtIndex:index];
		}
	}
}


- (void)setUpLogMessageClassMenu
{
	NSArray						*definitions = nil;
	unsigned					i, count, inserted = 0;
	NSString					*title = nil, *key = nil;
	NSMenuItem					*item = nil;
	
	definitions = [ResourceManager arrayFromFilesNamed:@"debugLogMessageClassesMenu.plist" inFolder:@"Config" andMerge:YES];
	count = [definitions count] / 2;
	
	for (i = 0; i != count; ++i)
	{
		title = [definitions oo_stringAtIndex:i * 2];
		key = [definitions oo_stringAtIndex:i * 2 + 1];
		if (title == nil || key == nil)  continue;
		
		item = [[NSMenuItem alloc] initWithTitle:title
										  action:@selector(toggleThisLogMessageClassAction:)
								   keyEquivalent:@""];
		[item setTarget:self];
		[item setRepresentedObject:key];
		
		[logMessageClassSubMenu insertItem:item atIndex:inserted++];
		[item release];
	}
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


- (OOUInteger)retainCount
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
