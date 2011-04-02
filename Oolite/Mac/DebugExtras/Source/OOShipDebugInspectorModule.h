//
//  OOShipDebugInspectorModule.h
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-13.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OODebugInspectorModule.h"


@interface OOShipDebugInspectorModule: OODebugInspectorModule
{
	IBOutlet NSTextField		*_primaryRoleField;
	IBOutlet NSTextField		*_otherRolesField;
	IBOutlet NSTextField		*_targetField;
	IBOutlet NSTextField		*_AIField;
	IBOutlet NSButton			*_reportAIMessagesCheckBox;
	IBOutlet NSTextField		*_scriptField;
	IBOutlet NSTextField		*_groupField;
	IBOutlet NSTextField		*_escortGroupField;
	IBOutlet NSTextField		*_laserTempField;
	IBOutlet NSLevelIndicator	*_laserTempIndicator;
	IBOutlet NSTextField		*_cabinTempField;
	IBOutlet NSLevelIndicator	*_cabinTempIndicator;
	IBOutlet NSTextField		*_fuelField;
	IBOutlet NSLevelIndicator	*_fuelIndicator;
}

- (IBAction) inspectPlayer:sender;
- (IBAction) inspectTarget:sender;
- (IBAction) inspectAI:sender;
- (IBAction) inspectGroup:sender;
- (IBAction) inspectEscortGroup:sender;
- (IBAction) takeReportAIMessagesFrom:sender;

@end
