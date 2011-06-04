//
//  OOShipGroupDebugInspectorModule.m
//  DebugOXP
//
//  Created by Jens Ayton on 2009-02-06.
//  Copyright 2009 Jens Ayton. All rights reserved.
//

#import "OOShipGroupDebugInspectorModule.h"
#import "OOEntityInspectorExtensions.h"
#import "OOShipGroup.h"


@implementation OOShipGroupDebugInspectorModule

- (void) awakeFromNib
{
	[membersList setDoubleAction:[membersList action]];
	[membersList setAction:NULL];
}


- (void) update
{
	OOShipGroup			*object = [self object];
	NSString			*placeholder = InspectorUnknownValueString();
	NSEnumerator		*memberEnum = nil;
	ShipEntity			*member = nil;
	NSMutableArray		*members = nil;
	
	[leaderField setStringValue:[[object leader] inspDescription] ?: placeholder];
	
	// Make array of weakRefs to group members.
	members = [NSMutableArray array];
	for (memberEnum = [object objectEnumerator]; (member = [memberEnum nextObject]); )
	{
		id memberRef = [member weakRetain];
		[members addObject:memberRef];
		[memberRef release];
	}
	
	// Sort array.
	[members sortUsingSelector:@selector(ooCompareByPointerValue:)];
	if (![_members isEqualToArray:members])
	{
		[_members release];
		_members = [members copy];
		[membersList reloadData];
	}
}


- (IBAction) inspectLeader:(id)sender
{
	[[[self object] leader] inspect];
}


- (IBAction) inspectMember:(id)sender
{
	NSInteger clickedRow = [sender clickedRow];
	if (clickedRow < 0)  return;
	
	[[_members objectAtIndex:clickedRow] inspect];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_members count];
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [[_members objectAtIndex:row] inspDescription];
}

@end


@implementation OOShipGroup (OOInspectorExtensions)

- (NSString *) inspDescription
{
	NSString *name = [self name];
	if (name != nil)  name = [NSString stringWithFormat:@"\"%@\"", name];
	else  name = @"anonymous";
	
	return [NSString stringWithFormat:@"%@, %lu ships", name, [self count]];
}


- (NSString *) inspBasicIdentityLine
{
	NSString *name = [self name];
	if (name != nil)  return [NSString stringWithFormat:@"Group \"%@\"", name];
	else  return @"Anonymous group";
}


- (NSArray *) debugInspectorModules
{
	return [[super debugInspectorModules] arrayByAddingInspectorModuleOfClass:[OOShipGroupDebugInspectorModule class]
																	forObject:(id)self];
}

@end


@implementation NSObject (OOCompareByPointerValue)

- (NSComparisonResult) ooCompareByPointerValue:(id)other
{
	if ((uintptr_t)self < (uintptr_t)other)  return NSOrderedAscending;
	if ((uintptr_t)self > (uintptr_t)other)  return NSOrderedDescending;
	return NSOrderedSame;
}

@end
