//
//  OOEntityDebugInspectorModule.m
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-13.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOEntityDebugInspectorModule.h"
#import "OODebugInspector.h"
#import "OOEntityInspectorExtensions.h"
#import "Entity.h"


@implementation OOEntityDebugInspectorModule

- (IBAction) inspectOwner:sender
{
	[[[self object] owner] inspect];
}


- (void) update
{
	id					object = [self object];
	NSString			*placeholder = InspectorUnknownValueString();
	
	[_scanClassField setStringValue:[object inspScanClassLine] ?: placeholder];
	[_statusField setStringValue:[object inspStatusLine] ?: placeholder];
	[_retainCountField setStringValue:[object inspRetainCountLine] ?: @"0"];
	[_positionField setStringValue:[object inspPositionLine] ?: placeholder];
	[_velocityField setStringValue:[object inspVelocityLine] ?: placeholder];
	[_orientationField setStringValue:[object inspOrientationLine] ?: placeholder];
	[_energyField setStringValue:[object inspEnergyLine] ?: placeholder];
	[_energyIndicator setFloatValue:object ? ([object energy] * 100.0f / [object maxEnergy]) : 0.0f];
	[_ownerField setStringValue:[object inspOwnerLine] ?: @"None"];
}

@end


@implementation Entity (OOEntityDebugInspectorModule)

- (NSArray *) debugInspectorModules
{
	return [[super debugInspectorModules] arrayByAddingInspectorModuleOfClass:[OOEntityDebugInspectorModule class]
																	forObject:(id)self];
}

@end
