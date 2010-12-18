//
//  OOLeopardFeaturesLoader.m
//  LeopardFeatures
//
//  Created by Jens Ayton on 2010-04-02.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "OOLeopardFeaturesLoader.h"
#import "OOLogging.h"
#import "JoystickHandlerOSXLeopard.h"


@implementation OOLeopardFeaturesLoader

- (id) init
{
	if ([JoystickHandler setStickHandlerClass:[JoystickHandlerOSXLeopard class]])
	{
		OOLog(@"temp.joystick", @"Successfully installed joystick handler.");
	}
	else
	{
		OOLog(@"temp.joystick", @"Failed to install joystick handler.");
	}

	
	return [super init];
}

@end
