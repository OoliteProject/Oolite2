/*

OOMacDebugger.m


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


#import "OOMacDebugger.h"
#import "OODebugMonitor.h"
#import "OOJavaScriptConsoleController.h"


@interface OOMacDebugger (Private) <OODebuggerInterface>

@end


@implementation OOMacDebugger

- (id) initWithController:(OOJavaScriptConsoleController *)controller
{
	self = [super init];
	if (self != nil)
	{
		_jsConsoleController = controller;
		[_jsConsoleController setDebugger:self];
	}
	return self;
}


- (void)dealloc
{
	[_monitor disconnectDebugger:self message:@"Debugger released."];
	// _monitor and _jsConsoleController are not retained.
	
	[_configuration release];
	
	[super dealloc];
}


#pragma mark -

- (void)performConsoleCommand:(NSString *)command
{
	[_monitor performJSConsoleCommand:command];
}


- (id)configurationValueForKey:(NSString *)key
{
	return [self configurationValueForKey:key class:Nil defaultValue:nil];
}


- (id)configurationValueForKey:(NSString *)key class:(Class)class defaultValue:(id)value
{
	id							result = nil;
	
	if (class == Nil)  class = [NSObject class];
	
	result = [_configuration objectForKey:key];
	if (![result isKindOfClass:class] && result != [NSNull null])  result = [[value retain] autorelease];
	if (result == [NSNull null])  result = nil;
	
	return result;
}


- (long long)configurationIntValueForKey:(NSString *)key defaultValue:(long long)value
{
	long long					result;
	id							object = nil;
	
	object = [self configurationValueForKey:key];
	if ([object respondsToSelector:@selector(longLongValue)])  result = [object longLongValue];
	else if ([object respondsToSelector:@selector(intValue)])  result = [object intValue];
	else  result = value;
	
	return result;
}


- (BOOL)configurationBoolValueForKey:(NSString *)key
{
	return OOBooleanFromObject([self configurationValueForKey:key], NO);
}


- (void)setConfigurationValue:(id)value forKey:(NSString *)key
{
	if (key == nil)  return;
	
	[_monitor setConfigurationValue:value forKey:key];
}


- (NSArray *)configurationKeys
{
	return [[_configuration allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

@end


#pragma mark -

@implementation OOMacDebugger (Private)

- (BOOL)connectDebugMonitor:(in OODebugMonitor *)debugMonitor
			   errorMessage:(out NSString **)message
{
	if (debugMonitor == _monitor)
	{
		if (message != NULL)  *message = @"ERROR: attempt to reconnect already-connected debugger!";
		return NO;
	}
	
	if (_monitor != nil)
	{
		// Should never happen.
		[_monitor disconnectDebugger:self message:@"Connected to different monitor."];
	}
	
	// Not retained.
	_monitor = debugMonitor;
	return YES;
}

- (void)disconnectDebugMonitor:(in OODebugMonitor *)debugMonitor
					   message:(in NSString *)message
{
	NSString				*prefix = nil;
	NSRange					emphasisRange;
	
	if (debugMonitor == _monitor)
	{
		prefix = @"Debugger disconnected: ";
		emphasisRange = NSMakeRange(0, [prefix length] - 1);
		[_jsConsoleController appendMessage:[prefix stringByAppendingString:message]
								   colorKey:@"console-internal"
							  emphasisRange:emphasisRange];
		
		_monitor = nil;
	}
	else
	{
		prefix = @"ERROR: ";
		emphasisRange = NSMakeRange(0, [prefix length] - 1);
		message = [NSString stringWithFormat:@"%@attempt to disconnect unconnected debug monitor %@ with message: %@", prefix, debugMonitor, message];
		[_jsConsoleController appendMessage:message
								   colorKey:@"console-internal"
							  emphasisRange:emphasisRange];
	}
}


- (oneway void)debugMonitor:(in OODebugMonitor *)debugMonitor
			jsConsoleOutput:(in NSString *)output
				   colorKey:(in NSString *)colorKey
			  emphasisRange:(in NSRange)emphasisRange
{
	[_jsConsoleController appendMessage:output
							   colorKey:colorKey
						  emphasisRange:emphasisRange];
}

- (oneway void)debugMonitorClearConsole:(in OODebugMonitor *)debugMonitor
{
	[_jsConsoleController clearConsole];
}

- (oneway void)debugMonitorShowConsole:(in OODebugMonitor *)debugMonitor
{
	[_jsConsoleController doShowConsole];
}

- (oneway void)debugMonitor:(in OODebugMonitor *)debugMonitor
		  noteConfiguration:(in NSDictionary *)configuration
{
	[_configuration release];
	_configuration = [configuration mutableCopy];
	
	[_jsConsoleController noteConfigurationChanged:nil];
}


- (oneway void)debugMonitor:(in OODebugMonitor *)debugMonitor
noteChangedConfigrationValue:(in id)newValue
					 forKey:(in NSString *)key
{
	if (_configuration == nil)  _configuration = [[NSMutableDictionary alloc] init];
	if (newValue != nil)  [_configuration setObject:newValue forKey:key];
	else  [_configuration removeObjectForKey:key];
	
	[_jsConsoleController noteConfigurationChanged:key];
}

@end
