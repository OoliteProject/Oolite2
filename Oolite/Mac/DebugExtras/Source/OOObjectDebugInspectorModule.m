//
//  OOObjectDebugInspectorModule.m
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-13.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOObjectDebugInspectorModule.h"
#import "PlayerEntity.h"
#import "OOEntityInspectorExtensions.h"


@implementation OOObjectDebugInspectorModule

- (void) awakeFromNib
{
	NSRect				basicIDFrame, secondaryIDFrame, targetSelfFrame, rootFrame;
	NSView				*rootView = [self rootView];
	float				delta;
	
	id object = [self object];
	
	basicIDFrame = [_basicIdentityField frame];
	secondaryIDFrame = [_secondaryIdentityField frame];
	targetSelfFrame = [_targetSelfButton frame];
	rootFrame = [rootView frame];
	
	if (![object inspCanBecomeTarget])
	{
		// Remove targetSelfButton.
		[_targetSelfButton removeFromSuperview];
		_targetSelfButton = nil;
		basicIDFrame.size.width = secondaryIDFrame.size.width;
	}
	
	if (![object inspHasSecondaryIdentityLine])
	{
		// No secondary identity line, remove secondary identity field.
		delta = basicIDFrame.origin.y - secondaryIDFrame.origin.y;
		[_secondaryIdentityField removeFromSuperview];
		_secondaryIdentityField = nil;
		
		rootFrame.size.height -= delta;
		basicIDFrame.origin.y -= delta,
		targetSelfFrame.origin.y -= delta;
	}
	
	// Put bits in the right place.
	[rootView setFrame:rootFrame];
	[_basicIdentityField setFrame:basicIDFrame];
	[_secondaryIdentityField setFrame:secondaryIDFrame];
	[_targetSelfButton setFrame:targetSelfFrame];
}


- (void) update
{
	id object = [self object];
	
	if (object != nil)  [_basicIdentityField setStringValue:[object inspBasicIdentityLine]];
	if (_secondaryIdentityField != nil)
	{
		if (object != nil)
		{
			[_secondaryIdentityField setStringValue:[object inspSecondaryIdentityLine] ?: InspectorUnknownValueString()];
		}
		else
		{
			[_secondaryIdentityField setStringValue:@"Dead"];
		}
	}
}


- (IBAction) targetSelf:sender
{
	[[self object] inspBecomeTarget];
}

@end


@implementation NSObject (OOObjectDebugInspectorModule)

- (NSArray *) debugInspectorModules
{
	return [[NSArray array] arrayByAddingInspectorModuleOfClass:[OOObjectDebugInspectorModule class]
													  forObject:(id)self];
}

@end
