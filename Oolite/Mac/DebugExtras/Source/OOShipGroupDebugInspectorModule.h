//
//  OOShipGroupDebugInspectorModule.h
//  DebugOXP
//
//  Created by Jens Ayton on 2009-02-06.
//  Copyright 2009 Jens Ayton. All rights reserved.
//

#import "OODebugInspectorModule.h"


@interface OOShipGroupDebugInspectorModule : OODebugInspectorModule
{
@private
	IBOutlet NSTextField		*leaderField;
	IBOutlet NSTableView		*membersList;
	
	NSArray						*_members;
}

- (IBAction) inspectLeader:(id)sender;
- (IBAction) inspectMember:(id)sender;

@end
