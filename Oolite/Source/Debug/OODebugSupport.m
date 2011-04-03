/*

OODebugSupport.m


Copyright (C) 2007-2011 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#ifndef OO_EXCLUDE_DEBUG_SUPPORT


#import "OODebugSupport.h"
#import "ResourceManager.h"
#import "OODebugMonitor.h"
#import "OODebugTCPConsoleClient.h"
#import "GameController.h"
#import "OOJavaScriptEngine.h"


#if OOLITE_MAC_OS_X
static id LoadDebugPlugIn(NSString *path);
#else
#define LoadDebugPlugIn(path) nil
#endif


@interface NSObject (OODebugPlugInController)

- (id<OODebuggerInterface>) setUpDebugger;

@end


void OOInitDebugSupport(void)
{
	// Load debug settings.
	NSDictionary * debugSettings = [ResourceManager dictionaryFromFilesNamed:@"debugConfig.plist"
																	inFolder:@"Config"
																   mergeMode:MERGE_BASIC
																	   cache:NO];
	
	id plugInController = nil;
	id<OODebuggerInterface>	debugger = nil;
	
#if OOLITE_MAC_OS_X
	NSString *debugPlugInPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:@"DebugExtras.bundle"];
	plugInController = LoadDebugPlugIn(debugPlugInPath);
#endif
	
	NSString *consoleHost = [debugSettings oo_stringForKey:@"console-host"];
	uint16_t consolePort = [debugSettings oo_unsignedShortForKey:@"console-port"];
	
	// If consoleHost is nil, and the debug plug-in can set up a debugger, use that.
	if (consoleHost == nil && [plugInController respondsToSelector:@selector(setUpDebugger)])
	{
		debugger = [plugInController setUpDebugger];
	}
	
	// Otherwise, use TCP debugger connection.
	if (debugger == nil)
	{
		debugger = [[OODebugTCPConsoleClient alloc] initWithAddress:consoleHost
															   port:consolePort];
		[debugger autorelease];
	}
	
	// Set up monitor and register debugger, if any.
	[[OODebugMonitor sharedDebugMonitor] setDebugger:debugger];
	[[OOJavaScriptEngine sharedEngine] enableDebuggerStatement];
}


#if OOLITE_MAC_OS_X

// Note: it should in principle be possible to use this code to load a plug-in under GNUstep, too.
static id LoadDebugPlugIn(NSString *path)
{
	OO_DEBUG_PUSH_PROGRESS(@"Loading debug plug-in");
	
	Class					principalClass = Nil;
	NSBundle				*bundle = nil;
	id						debugController = nil;
	
	bundle = [NSBundle bundleWithPath:path];
	if ([bundle load])
	{
		principalClass = [bundle principalClass];
		if (principalClass != Nil)
		{
			// Instantiate principal class of debug bundle, and let it do whatever it wants.
			debugController = [[principalClass alloc] init];
		}
		else
		{
			OOLog(@"debugOXP.load.failed", @"Failed to find principal class of debug bundle.");
		}
	}
	else
	{
		OOLog(@"debugOXP.load.failed", @"Failed to load debug OXP plug-in from %@.", path);
	}
	
	OO_DEBUG_POP_PROGRESS();
	
	return debugController;
}

#endif

#endif	/* OO_EXCLUDE_DEBUG_SUPPORT */
