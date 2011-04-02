//
//  OODebugInspectorModule.h
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-13.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OoliteBase/OoliteBase.h>


@interface OODebugInspectorModule: NSObject
{
@private
	OOWeakReference				*_object;
	IBOutlet NSView				*_rootView;
	
}

- (id) initWithObject:(id <OOWeakReferenceSupport>)object;
- (BOOL) loadUserInterface;		// Called to load UI; subclasses should generally override -awakeFromNib and optionally -nibName instead.

- (NSString *) nibName;	// Default: class name
- (NSView *) rootView;

- (id) object;
- (void) update;

@end


@interface NSObject (OODebugInspectorSupport)

- (NSArray *) debugInspectorModules;		// Array of OODebugInspectorModule subclasses.

@end


@interface NSArray (OODebugInspectorSupportUtilities)

// Utility for implementing -debugInspectorModules.
- (NSArray *) arrayByAddingInspectorModuleOfClass:(Class)theClass
										forObject:(id <OOWeakReferenceSupport>)object;

@end


// Em dash
NSString *InspectorUnknownValueString(void);
