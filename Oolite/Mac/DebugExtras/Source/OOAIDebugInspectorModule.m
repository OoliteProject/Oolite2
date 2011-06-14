//
//  OOAIDebugInspectorModule.m
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-14.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOAIDebugInspectorModule.h"
#import "AI.h"
#import "OOShipEntity.h"
#import "Universe.h"
#import "OOEntityInspectorExtensions.h"
#import "OOConstToString.h"


@implementation OOAIDebugInspectorModule

- (void) update
{
	AI					*object = [self object];
	NSString			*placeholder = InspectorUnknownValueString();
	NSSet				*pending = nil;
	NSString			*pendingDesc = nil;
	
	[_stateMachineNameField setStringValue:[object name] ?: placeholder];
	[_stateField setStringValue:[object state] ?: placeholder];
	if (object != nil)
	{
		[_stackDepthField setIntValue:[object stackDepth]];
		[_timeToThinkField setStringValue:[NSString stringWithFormat:@"%.1f", [object nextThinkTime] - [UNIVERSE gameTime]]];
		[_behaviourField setStringValue:OOStringFromBehaviour([[object owner] behaviour])];
		[_frustrationField setDoubleValue:[[object owner] frustration]];
	}
	else
	{
		[_stackDepthField setStringValue:placeholder];
		[_timeToThinkField setStringValue:placeholder];
		[_behaviourField setStringValue:placeholder];
		[_frustrationField setStringValue:placeholder];
	}
	
	pending = [object pendingMessages];
	if ([pending count] == 0)
	{
		pendingDesc = @"none";
	}
	else
	{
		pendingDesc = [[[pending allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] componentsJoinedByString:@", "];
		pendingDesc = [NSString stringWithFormat:@"%u: %@", [pending count], pendingDesc];
	}
	
	[_pendingMessagesField setStringValue:pendingDesc];
}


- (IBAction) thinkNow:sender
{
	[[self object] setNextThinkTime:[UNIVERSE gameTime]];
}


- (IBAction) dumpPendingMessages:sender
{
	[[self object] debugDumpPendingMessages];
}

@end


@implementation AI (OOAIDebugInspectorModule)

- (NSString *) inspBasicIdentityLine
{
	if ([self owner] != nil)  return [NSString stringWithFormat:@"AI for %@", [[self owner] inspBasicIdentityLine]];
	return  [super inspBasicIdentityLine];
}


- (NSArray *) debugInspectorModules
{
	return [[super debugInspectorModules] arrayByAddingInspectorModuleOfClass:[OOAIDebugInspectorModule class]
																	forObject:(id)self];
}

@end
