//
//  OOObjectDebugInspectorModule.h
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-13.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OODebugInspectorModule.h"


@interface OOObjectDebugInspectorModule: OODebugInspectorModule
{
	IBOutlet NSTextField		*_basicIdentityField;
	IBOutlet NSTextField		*_secondaryIdentityField;
	IBOutlet NSButton			*_targetSelfButton;
}

- (IBAction) targetSelf:sender;

@end
