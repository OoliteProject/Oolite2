//
//  OOAIDebugInspectorModule.h
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-14.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OODebugInspectorModule.h"


@interface OOAIDebugInspectorModule: OODebugInspectorModule
{
	IBOutlet NSTextField		*_stateMachineNameField;
	IBOutlet NSTextField		*_stateField;
	IBOutlet NSTextField		*_stackDepthField;
	IBOutlet NSTextField		*_pendingMessagesField;
	IBOutlet NSTextField		*_timeToThinkField;
	IBOutlet NSTextField		*_behaviourField;
	IBOutlet NSTextField		*_frustrationField;
}

- (IBAction) dumpPendingMessages:sender;
- (IBAction) thinkNow:sender;

@end
