/*

OOJavaScriptConsoleController.m


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


#import "OOJavaScriptConsoleController.h"
#import "OOMacDebugger.h"
#import "OODebugMonitor.h"
#import "OOJavaScriptEngine.h"

#import "OODebugUtilities.h"
#import "OOTextFieldHistoryManager.h"
#import "RBSplitView.h"


enum
{
	// Size limit for console scrollback
	kConsoleMaxSize			= 100000,
	kConsoleTrimToSize		= 80000,
	
	// Number of lines of console input to remember
	kConsoleMemory			= 100
};


@interface OOJavaScriptConsoleController (Private)

/*	Find a colour specified in the config plist, with the key
	key-foreground-color or key-background-color. A key of nil will be treated
	as "general", the fallback colour.
*/
- (NSColor *)foregroundColorForKey:(NSString *)key;
- (NSColor *)backgroundColorForKey:(NSString *)key;

// Load certain groups of config settings.
- (void)reloadAllSettings;
- (void)setUpFonts;

- (void) saveHistory;

@end


@interface NSLayoutManager (Leopard)
- (void)setAllowsNonContiguousLayout:(BOOL)flag;
@end


@implementation OOJavaScriptConsoleController

- (void)dealloc
{
	[consoleWindow release];
	[inputHistoryManager release];
	
	[_baseFont release];
	[_boldFont release];
	
	[_fgColors release];
	[_bgColors release];
	
	[super dealloc];
}


- (void)awakeFromNib
{
	assert(kConsoleTrimToSize < kConsoleMaxSize);
	
	//	Build RBSplitView programmatically to avoid issues with IB plug-in.
	NSView *contentView = [consoleWindow contentView];
	RBSplitView *splitView = [[RBSplitView alloc] initWithFrame:[contentView frame]];
	
	[contentView addSubview:splitView];
	[splitView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
	
	[splitView setVertical:NO];
	[splitView setDelegate:self];
	
	[splitView addSubview:consoleLogHolderView atPosition:0];
	[[splitView subviewAtPosition:0] setMinDimension:100 andMaxDimension:0];
	
	CGFloat height = [consoleInputHolderView frame].size.height;
	[splitView addSubview:consoleInputHolderView atPosition:1];
	inputSplitSubview = [splitView subviewAtPosition:1];
	[inputSplitSubview setMinDimension:30 andMaxDimension:0];
	
	NSString *thumbPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"SplitViewThumb" ofType:@"png"];
	[splitView setDivider:[[[NSImage alloc] initWithContentsOfFile:thumbPath] autorelease]];
	[inputSplitSubview setDimension:height];
	
	// Free performance boost in Leopard.
	if ([[consoleTextView layoutManager] respondsToSelector:@selector(setAllowsNonContiguousLayout:)])
	{
		[[consoleTextView layoutManager] setAllowsNonContiguousLayout:YES];
	}
	
	// Ensure auto-scrolling will work.
	[verticalScroller setFloatValue:1.0];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[inputHistoryManager setHistory:[defaults arrayForKey:@"debug-js-console-scrollback"]];
	
	[self reloadAllSettings];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
	[self saveHistory];
}


#pragma mark -

- (IBAction) clearConsole:sender
{
	[self clearConsole];
}


- (IBAction)showConsole:sender
{
	[[OODebugMonitor sharedDebugMonitor] showJSConsole];
}


- (IBAction)toggleShowOnWarning:sender
{
	[_debugger performConsoleCommand:@"console.settings[\"show-console-on-warning\"] = !console.settings[\"show-console-on-warning\"]"];
}


- (IBAction)toggleShowOnError:sender
{
	[_debugger performConsoleCommand:@"console.settings[\"show-console-on-error\"] = !console.settings[\"show-console-on-error\"]"];
}


- (IBAction)toggleShowOnLog:sender
{
	[_debugger performConsoleCommand:@"console.settings[\"show-console-on-log\"] = !console.settings[\"show-console-on-log\"]"];
}


- (IBAction)consolePerformCommand:sender
{
	NSString					*command = nil;
	
	// Use consoleInputField rather than sender so we can, e.g., add a button.
	command = [consoleInputField stringValue];
	[consoleInputField setStringValue:@""];
	[consoleWindow makeFirstResponder:consoleInputField];	// Is unset if an empty string is entered otherwise.
	
	[inputHistoryManager addToHistory:command];
	[self saveHistory];
	
	[_debugger performConsoleCommand:command];
}


- (void)appendMessage:(NSString *)string
			 colorKey:(NSString *)colorKey
		emphasisRange:(NSRange)emphasisRange
{
	OOJS_PROFILE_ENTER
	
	NSMutableAttributedString	*mutableStr = nil;
	NSColor						*fgColor = nil,
								*bgColor = nil;
	volatile NSRange			fullRange;
	NSTextStorage				*textStorage = nil;
	BOOL						doScroll;
	unsigned					length;
	
	mutableStr = [NSMutableAttributedString stringWithString:[string stringByAppendingString:@"\n"]
														font:_baseFont];
	
	fullRange = (NSRange){ 0, [mutableStr length] };
	fgColor = [self foregroundColorForKey:colorKey];
	if (fgColor != nil)
	{
		if ([fgColor alphaComponent] == 0.0)  return;
		[mutableStr addAttribute:NSForegroundColorAttributeName
						   value:fgColor
						   range:fullRange];
	}
	
	bgColor = [self backgroundColorForKey:colorKey];
	if (bgColor != nil)
	{
		[mutableStr addAttribute:NSBackgroundColorAttributeName
						   value:bgColor
						   range:fullRange];
	}
	
	if (emphasisRange.length != 0)
	{
		[mutableStr addAttribute:NSFontAttributeName
						   value:_boldFont
						   range:emphasisRange];
	}
	
	doScroll = [verticalScroller floatValue] > 0.980;
	
	textStorage = [consoleTextView textStorage];
	[textStorage appendAttributedString:mutableStr];
	length = [textStorage length];
	if (fullRange.length > kConsoleMaxSize)
	{
		[textStorage deleteCharactersInRange:(NSRange){ length - kConsoleTrimToSize, kConsoleTrimToSize }];
		length = kConsoleTrimToSize;
	}
	
	// Scroll to end of field
	if (doScroll)  [consoleTextView scrollRangeToVisible:(NSRange){ length, 0 }];
	
	OOJS_PROFILE_EXIT_VOID
}


- (void)clearConsole
{
	NSTextStorage				*textStorage = nil;
	
	textStorage = [consoleTextView textStorage];
	[textStorage deleteCharactersInRange:(NSRange){ 0, [textStorage length] }];
}


- (void) doShowConsole
{
	[consoleWindow makeKeyAndOrderFront:nil];
	[consoleWindow makeFirstResponder:consoleInputField];
}


- (void)noteConfigurationChanged:(NSString *)key
{
	if ([key hasSuffix:@"-foreground-color"] || [key hasSuffix:@"-foreground-colour"])
	{
		// Flush foreground colour cache
		[_fgColors removeAllObjects];
	}
	else if ([key hasSuffix:@"-background-color"] || [key hasSuffix:@"-background-colour"])
	{
		// Flush background colour cache
		[_bgColors removeAllObjects];
		[consoleTextView setBackgroundColor:[self backgroundColorForKey:nil]];
	}
	else if ([key hasPrefix:@"font-"])
	{
		[self setUpFonts];
	}
}


- (void)setDebugger:(OOMacDebugger *)debugger
{
	_debugger = debugger;
	[self reloadAllSettings];
}


#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL							action = NULL;
	OODebugMonitor				*monitor = nil;
	
	action = [menuItem action];
	monitor = [OODebugMonitor sharedDebugMonitor];
	
	if (action == @selector(toggleShowOnWarning:))
	{
		[menuItem setState:[_debugger configurationBoolValueForKey:@"show-console-on-warning"]];
		return [monitor debuggerConnected];
	}
	if (action == @selector(toggleShowOnError:))
	{
		[menuItem setState:[_debugger configurationBoolValueForKey:@"show-console-on-error"]];
		return [monitor debuggerConnected];
	}
	if (action == @selector(toggleShowOnLog:))
	{
		[menuItem setState:[_debugger configurationBoolValueForKey:@"show-console-on-log"]];
		return [monitor debuggerConnected];
	}
	if (action == @selector(showConsole:))
	{
		return [monitor debuggerConnected];
	}
	
	return [self respondsToSelector:action];
}


// Split view delegate method to ensure only the console field is resized when resizing window.
- (void)splitView:(RBSplitView*)sender wasResizedFrom:(float)oldDimension to:(float)newDimension
{
	[sender adjustSubviewsExcepting:inputSplitSubview];
}

@end


@implementation OOJavaScriptConsoleController (Private)

- (NSColor *)foregroundColorForKey:(NSString *)key
{
	NSColor						*result = nil;
	NSString					*expandedKey = nil;
	
	if (key == nil)  key = @"general";
	
	result = [_fgColors objectForKey:key];
	if (result == nil)
	{
		// No cached colour; load colour description from config file
		expandedKey = [key stringByAppendingString:@"-foreground-color"];
		result = [NSColor colorWithOOColorDescription:[_debugger configurationValueForKey:expandedKey]];
		if (result == nil)
		{
			expandedKey = [key stringByAppendingString:@"-foreground-colour"];
			result = [NSColor colorWithOOColorDescription:[_debugger configurationValueForKey:expandedKey]];
		}
		if (result == nil && ![key isEqualToString:@"general"])
		{
			result = [self foregroundColorForKey:nil];
		}
		if (result == nil)  result = [NSColor blackColor];
		
		// Store loaded colour in cache
		if (result != nil)
		{
			if (_fgColors == nil)  _fgColors = [[NSMutableDictionary alloc] init];
			[_fgColors setObject:result forKey:key];
		}
	}
	
	return result;
}


- (NSColor *)backgroundColorForKey:(NSString *)key
{
	NSColor						*result = nil;
	NSString					*expandedKey = nil;
	
	if (key == nil)  key = @"general";
	
	result = [_bgColors objectForKey:key];
	if (result == nil)
	{
		// No cached colour; load colour description from config file
		expandedKey = [key stringByAppendingString:@"-background-color"];
		result = [NSColor colorWithOOColorDescription:[_debugger configurationValueForKey:expandedKey]];
		if (result == nil)
		{
			expandedKey = [key stringByAppendingString:@"-background-colour"];
			result = [NSColor colorWithOOColorDescription:[_debugger configurationValueForKey:expandedKey]];
		}
		if (result == nil && ![key isEqualToString:@"general"])
		{
			result = [self backgroundColorForKey:nil];
		}
		if (result == nil)  result = [NSColor whiteColor];
		
		// Store loaded colour in cache
		if (result != nil)
		{
			if (_bgColors == nil)  _bgColors = [[NSMutableDictionary alloc] init];
			[_bgColors setObject:result forKey:key];
		}
	}
	
	return result;
}


- (void)reloadAllSettings
{
	[_fgColors removeAllObjects];
	[_bgColors removeAllObjects];
	[consoleTextView setBackgroundColor:[self backgroundColorForKey:nil]];
	[self setUpFonts];
}


- (void)setUpFonts
{
	NSString					*fontFace = nil;
	int							fontSize;
	
	[_baseFont release];
	_baseFont = nil;
	[_boldFont release];
	_boldFont = nil;
	
	// Set font.
	fontFace = [_debugger configurationValueForKey:@"font-face"
											class:[NSString class]
									 defaultValue:@"Courier"];
	fontSize = [_debugger configurationIntValueForKey:@"font-size"
										defaultValue:12];
	
	_baseFont = [NSFont fontWithName:fontFace size:fontSize];
	if (_baseFont == nil)  _baseFont = [NSFont userFixedPitchFontOfSize:0];
	[_baseFont retain];
	
	// Get bold variant of font.
	_boldFont = [[NSFontManager sharedFontManager] convertFont:_baseFont
												   toHaveTrait:NSBoldFontMask];
	if (_boldFont == nil)  _boldFont = _baseFont;
	[_boldFont retain];
}


- (void) saveHistory
{
	NSArray						*history = nil;
	
	history = [inputHistoryManager history];
	if (history != nil)
	{
		[[NSUserDefaults standardUserDefaults] setObject:history forKey:@"debug-js-console-scrollback"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

@end
