/*

JoystickHandlerOSXLeopard.m
By Alex Smith

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

#import "JoystickHandlerOSXLeopard.h"

#define ENUMKEY(x) [NSString stringWithFormat: @"%d", x]


static CFMutableDictionaryRef hu_CreateDeviceMatchingDictionary(UInt32 inUsagePage, UInt32 inUsage)
{
    // create a dictionary to add usage page/usages to
    CFMutableDictionaryRef result = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, 
															  &kCFTypeDictionaryKeyCallBacks, 
															  &kCFTypeDictionaryValueCallBacks);

	CFNumberRef pageCFNumberRef = CFNumberCreate(kCFAllocatorDefault, 
												 kCFNumberIntType, 
												 &inUsagePage);
	CFDictionarySetValue(result, CFSTR(kIOHIDDeviceUsagePageKey), pageCFNumberRef);
	CFRelease(pageCFNumberRef);
				
	CFNumberRef usageCFNumberRef = CFNumberCreate(kCFAllocatorDefault, 
												  kCFNumberIntType, 
												  &inUsage);

	CFDictionarySetValue(result, CFSTR(kIOHIDDeviceUsageKey), usageCFNumberRef);

	CFRelease(usageCFNumberRef);
        
    return result;
}


@interface JoystickHandler ()

- (void) handleInputEvent:(IOHIDValueRef) valueRef;
- (void) handleJoystickAttach:(IOHIDDeviceRef) deviceRef;

@end



@implementation JoystickHandlerOSXLeopard

//Thunking to objective-C
static void handleDeviceMatchingCallback( void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef)
{
	JoystickHandlerOSXLeopard *me = (JoystickHandlerOSXLeopard *) inContext;
//	NSLog(@"%s(context: %p, result: %d, sender: %p, device: %p).\n",
//		  __PRETTY_FUNCTION__, inContext, inResult, inSender, (void*) inIOHIDDeviceRef);
	[me handleJoystickAttach:inIOHIDDeviceRef];  // Callback get called once per device
}



static void handleInputValueCallback( void * inContext, IOReturn inResult, void* inSender, IOHIDValueRef  inIOHIDValueRef)
{
	JoystickHandlerOSXLeopard *me = (JoystickHandlerOSXLeopard *) inContext;
//	NSLog(@"%s(context: %p, result: %d, sender: %p, device: %p).\n",
//		  __PRETTY_FUNCTION__, inContext, inResult, inSender, (void*) inIOHIDValueRef);
	
	[me handleInputEvent:inIOHIDValueRef];
}



static void handleDeviceRemovalCallback( void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef)
{
	JoystickHandlerOSXLeopard *me = (JoystickHandlerOSXLeopard *) inContext;
	//	NSLog(@"%s(context: %p, result: %d, sender: %p, device: %p).\n",
	//		  __PRETTY_FUNCTION__, inContext, inResult, inSender, (void*) inIOHIDDeviceRef);
	me->numSticks --;
}



- (id) init
{
 
	numSticks = 0;
	int i;
	
	// Initialise gamma table 
	for (i=0; i< 256; i++){
		double x = ((double) i - 128.0)/ 128.0;
		double sign = x>=0 ? 1.0 : -1.0;
		double y = sign * floor( 32767.0 * pow (fabs(x), STICK_GAMMA)); 
		gammaTable [i] = (int) y;
	}
	
	/** FIXME - release this reference ??? **/
	ioHIDManagerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);         
	CFDictionaryRef matchingCFDictRef = hu_CreateDeviceMatchingDictionary(kHIDPage_GenericDesktop, kHIDUsage_GD_Joystick);
	IOHIDManagerSetDeviceMatching(ioHIDManagerRef, matchingCFDictRef);
	if (matchingCFDictRef) CFRelease(matchingCFDictRef);
	
	IOHIDManagerRegisterDeviceMatchingCallback(ioHIDManagerRef, handleDeviceMatchingCallback, self);
	IOHIDManagerRegisterDeviceRemovalCallback(ioHIDManagerRef, handleDeviceRemovalCallback, self);
	IOHIDManagerRegisterInputValueCallback(ioHIDManagerRef, handleInputValueCallback, self);
	
	IOHIDManagerScheduleWithRunLoop(ioHIDManagerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	IOReturn iores = IOHIDManagerOpen( ioHIDManagerRef, kIOHIDOptionsTypeNone );
	if (iores != kIOReturnSuccess ){
		NSLog(@"Cannot open IO Manager");
	}

   return [super init];
}



- (void) handleJoystickAttach:(IOHIDDeviceRef) deviceRef
{
#if 0 /* print out elements of new device */
	CFArrayRef tCFArrayRef = IOHIDDeviceCopyMatchingElements( deviceRef, NULL, 0L );
	CFIndex idx, cnt = CFArrayGetCount( tCFArrayRef );
	
	for (idx = 0; idx<cnt; idx++ ){
		IOHIDElementRef elementRef = ( IOHIDElementRef ) CFArrayGetValueAtIndex( tCFArrayRef, idx );
		IOHIDElementType elementType = IOHIDElementGetType( elementRef );
		if ( elementType > kIOHIDElementTypeInput_ScanCodes ) {
			continue;
		}
		IOHIDElementCookie elementCookie = IOHIDElementGetCookie( elementRef );
		uint32_t usagePage = IOHIDElementGetUsagePage( elementRef );
		uint32_t usage = IOHIDElementGetUsage( elementRef );
		uint32_t min = (uint32_t) IOHIDElementGetPhysicalMin(elementRef);
		uint32_t max = (uint32_t) IOHIDElementGetPhysicalMax(elementRef);
		printf ("%d:%d:%d:%d:%d\n", usagePage, usage, (int) elementCookie, min, max);
	}
#endif	
	
	numSticks++;
	
}


- (void) handleInputEvent: (IOHIDValueRef) valueRef
{
	IOHIDElementRef	elementRef = IOHIDValueGetElement(valueRef);
	uint32_t usagePage = IOHIDElementGetUsagePage( elementRef );
	uint32_t usage = IOHIDElementGetUsage( elementRef );
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
	
	if (validEvent){
		if (isAxis){
			JoyAxisEvent evt;
			evt.type = JOYAXISMOTION;
			evt.which = 0;
			evt.axis = axisNum;
			evt.value = gammaTable[IOHIDValueGetIntegerValue(valueRef) % 256];
			[self decodeAxisEvent:&evt ];
		} else {
			JoyButtonEvent evt;
			BOOL buttonState = (IOHIDValueGetIntegerValue(valueRef) != 0);
			evt.type = buttonState ? JOYBUTTONDOWN : JOYBUTTONUP;
			evt.which = 0;
			evt.button = buttonNum;
			evt.state = buttonState ? 1 : 0;	
			[self decodeButtonEvent:&evt];
		}
	}
}


/* not implemented yet, need to find device description file in OSX */
- (char *) getJoystickName:(int)stickNumber
{
	return "OSX JOYSTICK";
}



- (int16_t) getAxisWithStick:(int) stickNum axis:(int) axisNum 
{
	return 0;
}



@end
