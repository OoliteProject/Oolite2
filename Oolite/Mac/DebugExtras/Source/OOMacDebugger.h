/*

OOMacDebugger.h

Mac OS X/Appkit based implementation of Oolite debugging interface.

This mostly acts as a dispatcher. Currently it dispatches everything to
OOJavaScriptConsoleController, but that could changed as non-JavaScript
debugging facilities are added.


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

#import <Cocoa/Cocoa.h>

@class OODebugMonitor, OOJavaScriptConsoleController;


@interface OOMacDebugger: NSObject
{
	OODebugMonitor						*_monitor;
	
	OOJavaScriptConsoleController		*_jsConsoleController;
	
	// "Local" copy of configuration. This distinction is of little importance in the current implementation, but will be useful if moving to a separate process.
	NSMutableDictionary					*_configuration;
}

- (id) initWithController:(OOJavaScriptConsoleController *)controller;

- (void)performConsoleCommand:(NSString *)command;

// *** Configuration management.
- (id)configurationValueForKey:(NSString *)key;
- (id)configurationValueForKey:(NSString *)key class:(Class)class defaultValue:(id)value;
- (long long)configurationIntValueForKey:(NSString *)key defaultValue:(long long)value;
- (BOOL)configurationBoolValueForKey:(NSString *)key;

- (void)setConfigurationValue:(id)value forKey:(NSString *)key;

- (NSArray *)configurationKeys;

@end
