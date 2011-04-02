/*

OODebugController.h

Add debug utility GUI to debug builds of Oolite.

 
Oolite Debug OXP

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


/*

Note on the Log Message Classes submenu: for ease of editing, items in this
submenu with no action specified are used to toggle (and display) the log
message class specified in their title. Display titles (optional) are set in
the Attributed Title property. Thus, to add a menu item to control the foo.bar
message class, simply add an item titled foo.bar in the nib.

Note on extra menu items: some esoteric commands are hidden by default. To
show them, set the preference debug-show-extra-menu-items:

	defaults write org.aegidian.oolite debug-show-extra-menu-items -bool YES

*/


#import <Cocoa/Cocoa.h>

@class OOJavaScriptConsoleController;


@interface OODebugController: NSObject
{
	IBOutlet NSMenu							*menu;
	IBOutlet NSMenu							*logMessageClassSubMenu;
	
	IBOutlet NSPanel						*logMessageClassPanel;
	IBOutlet NSTextField					*logMsgClassPanelTextField;
	
	IBOutlet NSWindow						*logPrefsWindow;
	IBOutlet NSButton						*logShowFunctionCheckBox;
	IBOutlet NSButton						*logShowFileAndLineCheckBox;
	IBOutlet NSButton						*logShowMessageClassCheckBox;
	IBOutlet NSButton						*logShowTimeStampCheckBox;
	
	IBOutlet NSPanel						*createShipPanel;
	IBOutlet NSTextField					*createShipPanelTextField;
	
	IBOutlet OOJavaScriptConsoleController	*jsConsoleController;
	
	NSBundle								*_bundle;
	
}

+ (id) sharedDebugController;

- (NSBundle *) bundle;
- (NSString *) pathForResource:(NSString *)name ofType:(NSString *)type;

// Debug menu commands
- (IBAction) showLogAction:sender;
- (IBAction) graphicsResetAction:sender;
- (IBAction) clearTextureCacheAction:sender;
- (IBAction) resetAndClearAction:sender;
- (IBAction) dumpEntityListAction:sender;
- (IBAction) dumpPlayerStateAction:sender;
- (IBAction) createShipAction:sender;
- (IBAction) clearAllCachesAction:sender;
- (IBAction) toggleWireframeModeAction:sender;
- (IBAction) hideShowHUD:sender;
- (IBAction) inspectPlayer:sender;
- (IBAction) inspectTarget:sender;
- (IBAction) cleanUpInspectors:sender;

// Log Message Classes submenu
- (IBAction) toggleThisLogMessageClassAction:sender;
- (IBAction) otherLogMessageClassAction:sender;

// Log Message Classes -> Other... alert
- (IBAction) logMsgClassPanelEnableAction:sender;
- (IBAction) logMsgClassPanelDisableAction:sender;

// Debug Flags submenu
- (IBAction) toggleThisDebugFlagAction:sender;

// Shader Mode submenu
- (IBAction) setShaderModeToTag:sender;

// Log Preferences window
- (IBAction) showLogPreferencesAction:sender;
- (IBAction) logSetShowFunctionAction:sender;
- (IBAction) logSetShowFileAndLineAction:sender;
- (IBAction) logSetShowMessageClassAction:sender;
- (IBAction) logSetShowTimeStampAction:sender;

- (IBAction) insertLogSeparatorAction:sender;

// Create Ship... alert
- (IBAction) createShipPanelOKAction:sender;

- (IBAction) modalPanelCancelAction:sender;

@end
