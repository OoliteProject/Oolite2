//
//  OOEntityDebugInspectorModule.h
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-13.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OODebugInspectorModule.h"
#import "Entity.h"


@interface OOEntityDebugInspectorModule : OODebugInspectorModule
{
	IBOutlet NSTextField		*_scanClassField;
	IBOutlet NSTextField		*_statusField;
	IBOutlet NSTextField		*_retainCountField;
	IBOutlet NSTextField		*_positionField;
	IBOutlet NSTextField		*_velocityField;
	IBOutlet NSTextField		*_orientationField;
	IBOutlet NSTextField		*_energyField;
	IBOutlet NSLevelIndicator	*_energyIndicator;
	IBOutlet NSTextField		*_ownerField;
	IBOutlet NSButton			*_inspectOwnerButton;
}

- (IBAction) inspectOwner:sender;

@end
