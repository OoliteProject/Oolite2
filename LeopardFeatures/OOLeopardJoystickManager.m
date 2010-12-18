/*

OOLeopardJoystickManager.m
By Alex Smith and Jens Ayton

Oolite
Copyright (C) 2004-2010 Giles C Williams and contributors

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

#import "OOLeopardJoystickManager.h"
#import "OOLogging.h"


static NSMutableDictionary *DeviceMatchingDictionary(UInt32 inUsagePage, UInt32 inUsage)
{
	// create a dictionary to add usage page/usages to
    return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:inUsagePage], @kIOHIDDeviceUsagePageKey,
			[NSNumber numberWithUnsignedInt:inUsage], @kIOHIDDeviceUsageKey,
			nil];
}


@interface OOLeopardJoystickManager ()

- (void) handleInputEvent:(IOHIDValueRef)value;
- (void) handleJoystickAttach:(IOHIDDeviceRef)device;
- (void) handleDeviceRemoval:(IOHIDDeviceRef)device;

@end


static void HandleDeviceMatchingCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef);
static void HandleInputValueCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDValueRef  inIOHIDValueRef);
static void HandleDeviceRemovalCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef);


@implementation OOLeopardJoystickManager

- (id) init
{
	if ((self = [super init]))
	{
		// Initialise gamma table
		int i;
		for (i = 0; i< kJoystickGammaTableSize; i++)
		{
			double x = ((double) i - 128.0) / 128.0;
			double sign = x>=0 ? 1.0 : -1.0;
			double y = sign * floor(32767.0 * pow (fabs(x), STICK_GAMMA)); 
			gammaTable[i] = (int) y;
		}
		
		hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);         
		NSDictionary *matchingCFDictRef = DeviceMatchingDictionary(kHIDPage_GenericDesktop, kHIDUsage_GD_Joystick);
		IOHIDManagerSetDeviceMatching(hidManager, (CFDictionaryRef)matchingCFDictRef);
		
		IOHIDManagerRegisterDeviceMatchingCallback(hidManager, HandleDeviceMatchingCallback, self);
		IOHIDManagerRegisterDeviceRemovalCallback(hidManager, HandleDeviceRemovalCallback, self);
		IOHIDManagerRegisterInputValueCallback(hidManager, HandleInputValueCallback, self);
		
		IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		IOReturn iores = IOHIDManagerOpen( hidManager, kIOHIDOptionsTypeNone );
		if (iores != kIOReturnSuccess)
		{
			OOLog(@"joystick.error.init", @"Cannot open HID manager; joystick support will not function.");
		}
		
		devices = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	}
	return self;
}


- (void) dealloc
{
	if (hidManager != NULL)  CFRelease(hidManager);
	if (devices != NULL)  CFRelease(devices);
	
	[super dealloc];
}


- (OOUInteger) joystickCount
{
	return CFArrayGetCount(devices);
}


- (void) handleJoystickAttach:(IOHIDDeviceRef)device
{
	OOLog(@"joystick.connect", @"Joystick connected: %@", IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey)));
	
	CFArrayAppendValue(devices, device);
	
	if (OOLogWillDisplayMessagesInClass(@"joystick.connect.element"))
	{
		OOLogIndent();
		
		// Print out elements of new device
		CFArrayRef elementList = IOHIDDeviceCopyMatchingElements( device, NULL, 0L );
		CFIndex idx, count = CFArrayGetCount(elementList);
		
		for (idx = 0; idx < count; idx++)
		{
			IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(elementList, idx);
			IOHIDElementType elementType = IOHIDElementGetType(element);
			if (elementType > kIOHIDElementTypeInput_ScanCodes)
			{
				continue;
			}
			IOHIDElementCookie elementCookie = IOHIDElementGetCookie(element);
			uint32_t usagePage = IOHIDElementGetUsagePage(element);
			uint32_t usage = IOHIDElementGetUsage(element);
			uint32_t min = (uint32_t)IOHIDElementGetPhysicalMin(element);
			uint32_t max = (uint32_t)IOHIDElementGetPhysicalMax(element);
			NSString *name = (NSString *)IOHIDElementGetProperty(element, CFSTR(kIOHIDElementNameKey)) ?: @"unnamed";
			OOLog(@"joystick.connect.element", @"%@ - usage %d:%d, cookie %d, range %d-%d", name, usagePage, usage, (int) elementCookie, min, max);
		}
		
		OOLogOutdent();
	}
}


- (void) handleDeviceRemoval:(IOHIDDeviceRef)device
{
	OOLog(@"joystick.remove", @"Joystick removed: %@", IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey)));
	
	CFIndex index = CFArrayGetFirstIndexOfValue(devices, CFRangeMake(0, CFArrayGetCount(devices)), device);
	if (index != kCFNotFound)  CFArrayRemoveValueAtIndex(devices, index);
}


- (void) handleInputEvent:(IOHIDValueRef)value
{
	IOHIDElementRef	element = IOHIDValueGetElement(value);
	uint32_t usagePage = IOHIDElementGetUsagePage(element);
	uint32_t usage = IOHIDElementGetUsage(element);
	BOOL isAxis = NO;
	BOOL validEvent = NO;
	int buttonNum = 0;
	int axisNum = 0;
	
	if (usagePage == 0x01)
	{
			// Axis Event
		if( (usage >= 0x30) && (usage < 0x30 + MAX_AXES))
		{
			// Axis in range 
			axisNum = usage - 0x30;
			isAxis = YES;
			validEvent = YES;
		}
		// Code to handle PS3 button forces/accelerometer goes here ...
	}
	
	if (usagePage == 0x09)
	{
		// Button Event
		isAxis = NO;
		validEvent = YES;
		buttonNum = usage;
	}
	
	if (validEvent)
	{
		if (isAxis)
		{
			JoyAxisEvent evt;
			evt.type = JOYAXISMOTION;
			evt.which = 0;
			evt.axis = axisNum;
			// FIXME: assumption that axes range from 0-255 is invalid.
			evt.value = gammaTable[IOHIDValueGetIntegerValue(value) % kJoystickGammaTableSize];
			[self decodeAxisEvent:&evt];
		}
		else
		{
			JoyButtonEvent evt;
			BOOL buttonState = (IOHIDValueGetIntegerValue(value) != 0);
			evt.type = buttonState ? JOYBUTTONDOWN : JOYBUTTONUP;
			evt.which = 0;
			evt.button = buttonNum;
			evt.state = buttonState ? 1 : 0;	
			[self decodeButtonEvent:&evt];
		}
	}
}


- (NSString *) nameOfJoystick:(int)stickNumber
{
	IOHIDDeviceRef device = (IOHIDDeviceRef)CFArrayGetValueAtIndex(devices, stickNumber);
	return (NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
}



- (int16_t) getAxisWithStick:(int) stickNum axis:(int) axisNum 
{
	return 0;
}



@end


//Thunking to Objective-C
static void HandleDeviceMatchingCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef)
{
	[(OOLeopardJoystickManager *)inContext handleJoystickAttach:inIOHIDDeviceRef];
}



static void HandleInputValueCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDValueRef  inIOHIDValueRef)
{
	[(OOLeopardJoystickManager *)inContext handleInputEvent:inIOHIDValueRef];
}



static void HandleDeviceRemovalCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef)
{
	[(OOLeopardJoystickManager *)inContext handleDeviceRemoval:inIOHIDDeviceRef];
}
