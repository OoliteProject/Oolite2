//
//  OOShipDebugInspectorModule.m
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-13.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOShipDebugInspectorModule.h"
#import "OOEntityDebugInspectorModule.h"
#import "OOShipGroupDebugInspectorModule.h"
#import "OOEntityInspectorExtensions.h"
#import "ShipEntity.h"
#import "OODebugInspector.h"
#import "AI.h"
#import "OORoleSet.h"
#import "OOShipGroup.h"
#import "OOConstToString.h"


@interface ShipEntity (DebugRawAccess)

- (OOShipGroup *) rawEscortGroup;

@end


@implementation OOShipDebugInspectorModule

- (void) update
{
	ShipEntity			*object = [self object];
	NSString			*primaryRole = [object primaryRole];
	NSMutableSet		*roles = nil;
	NSString			*placeholder = InspectorUnknownValueString();
	AI					*objAI = nil;
	NSString			*desc = nil;
	float				level;
	int					fuel;
	
	roles = [[[[object roleSet] roles] mutableCopy] autorelease];
	[roles removeObject:primaryRole];
	
	[_primaryRoleField setStringValue:primaryRole ?: placeholder];
	if ([roles count] != 0)
	{
		desc = [[[roles allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] componentsJoinedByString:@", "];
		[_otherRolesField setStringValue:desc];
	}
	else
	{
		[_otherRolesField setStringValue:placeholder];
	}
	[_targetField setStringValue:[object inspTargetLine] ?: placeholder];
	objAI = [object getAI];
	if (objAI != nil)
	{
		desc = [objAI name];
		if ([desc hasSuffix:@".plist"])  desc = [desc stringByDeletingPathExtension];
		desc = [NSString stringWithFormat:@"%@: %@", desc, [objAI state]];
		[_AIField setStringValue:desc];
	}
	else
	{
		[_AIField setStringValue:placeholder];
	}
	[_reportAIMessagesCheckBox setState:[object reportAIMessages]];
	[_scriptField setStringValue:[[object script] name] ?: placeholder];
	
	[_groupField setStringValue:[[object group] inspDescription] ?: placeholder];
	[_escortGroupField setStringValue:[[object rawEscortGroup] inspDescription] ?: placeholder];
	
	if (object != nil)
	{
		level = [object laserHeatLevel];
		[_laserTempField setStringValue:[NSString stringWithFormat:@"%.2f", level]];
		[_laserTempIndicator setFloatValue:level * 100.0];
		level = [object hullHeatLevel];
		[_cabinTempField setStringValue:[NSString stringWithFormat:@"%.2f", level]];
		[_cabinTempIndicator setFloatValue:level * 100.0];
		fuel = [object fuel];
		[_fuelField setStringValue:[NSString stringWithFormat:@"%.1f", (float)fuel / 10.0f]];
		[_fuelIndicator setIntValue:fuel];
	}
	else
	{
		[_laserTempField setStringValue:placeholder];
		[_laserTempIndicator setFloatValue:0];
		[_cabinTempField setStringValue:placeholder];
		[_cabinTempIndicator setFloatValue:0];
		[_fuelField setStringValue:placeholder];
		[_fuelIndicator setFloatValue:0];
	}
}


- (IBAction) inspectPlayer:sender 
{ 
   [[self object] inspect]; 
} 


- (IBAction) inspectTarget:sender 
{ 
   [[[self object] primaryTarget] inspect]; 
}


- (IBAction) inspectAI:sender
{
	[[[self object] getAI] inspect];
}


- (IBAction) inspectGroup:sender
{
	[[[self object] group] inspect];
}


- (IBAction) inspectEscortGroup:sender
{
	[[[self object] rawEscortGroup] inspect];
}


- (IBAction) takeReportAIMessagesFrom:sender
{
	[[self object] setReportAIMessages:[sender state]];
}

@end


@implementation ShipEntity (OOShipDebugInspectorModule)

- (NSArray *) debugInspectorModules
{
	return [[super debugInspectorModules] arrayByAddingInspectorModuleOfClass:[OOShipDebugInspectorModule class]
																	forObject:(id)self];
}

@end
