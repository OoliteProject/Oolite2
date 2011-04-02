//
//  OODebugInspectorModule.m
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-13.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OODebugInspectorModule.h"


@implementation OODebugInspectorModule

- (id) initWithObject:(id <OOWeakReferenceSupport>)object
{
	if ((self = [super init]))
	{
		_object = [object weakRetain];
		
		if (![self loadUserInterface])
		{
			[self release];
			self = nil;
		}
	}
	
	return self;
}


- (void) dealloc
{
	[_rootView release];
	[_object release];
	
	[super dealloc];
}


- (BOOL) loadUserInterface
{
	NSString				*nibName = nil;
	
	nibName = [self nibName];
	if (nibName == nil)  return NO;
	
	return [NSBundle loadNibNamed:nibName owner:self];
}


- (NSString *) nibName
{
	return [self className];
}


- (NSView *) rootView
{
	return _rootView;
}


- (id) object
{
	return [_object weakRefUnderlyingObject];
}


- (void) update
{
	
}

@end


@implementation NSArray (OODebugInspectorSupportUtilities)

- (NSArray *) arrayByAddingInspectorModuleOfClass:(Class)theClass
										forObject:(id <OOWeakReferenceSupport>)object
{
	id				module = nil;
	NSArray			*result = self;
	
	if ([theClass isSubclassOfClass:[OODebugInspectorModule class]])
	{
		module = [[[theClass alloc] initWithObject:object] autorelease];
		if (module != nil)
		{
			result = [result arrayByAddingObject:module];
		}
	}
	
	return result;
}

@end


NSString *InspectorUnknownValueString(void)
{
	static NSString *string = nil;
	if (string == nil)
	{
		string = [NSLocalizedStringFromTableInBundle(@"--", NULL, [NSBundle bundleForClass:[OODebugInspectorModule class]], @"") retain];
		if (string == nil)  string = @"-";
	}
	
	return string;
}
