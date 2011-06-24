/*

OOJavaScriptConsoleController.h

JavaScript debugging console for Oolite.


Oolite debug support

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

#import <Cocoa/Cocoa.h>
#import <OoliteBase/OoliteBase.h>

@class OOMacDebugger, OOTextFieldHistoryManager, RBSplitSubview;


@interface OOJavaScriptConsoleController: OOWeakRefObject
{
	IBOutlet NSWindow					*consoleWindow;
	
	// Container views for each pane.
	IBOutlet NSView						*consoleLogHolderView;
	IBOutlet NSView						*consoleInputHolderView;
	
	// Content views that actually hold the interesting stuff.
	IBOutlet NSTextView					*consoleTextView;
	IBOutlet NSTextField				*consoleInputField;
	
	IBOutlet OOTextFieldHistoryManager	*inputHistoryManager;
	RBSplitSubview						*inputSplitSubview;
	IBOutlet NSScroller					*verticalScroller;
	
	OOMacDebugger						*_debugger;
	
	NSFont								*_baseFont,
										*_boldFont;
	
	// Caches
	NSMutableDictionary					*_fgColors,
										*_bgColors;
}

- (IBAction) clearConsole:sender;
- (IBAction) showConsole:sender;
- (IBAction) toggleShowOnLog:sender;
- (IBAction) toggleShowOnWarning:sender;
- (IBAction) toggleShowOnError:sender;
- (IBAction) consolePerformCommand:sender;

- (void) appendMessage:(NSString *)string
			  colorKey:(NSString *)colorKey
		 emphasisRange:(NSRange)emphasisRange;

- (void) clearConsole;
- (void) doShowConsole;	// Show the debug console window. -showConsole: dispatches to the active debugger via the debug monitor, -doShowConsole shows the actual Mac console.

- (void) noteConfigurationChanged:(NSString *)key;

- (void) setDebugger:(OOMacDebugger *)debugger;

@end
