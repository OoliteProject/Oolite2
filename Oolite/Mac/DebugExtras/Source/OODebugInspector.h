//
//  OODebugInspector.h
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-10.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OoliteBase/OoliteBase.h>


@interface OODebugInspector: NSObject
{
	OOWeakReference				*_object;
	IBOutlet NSPanel			*_panel;
	NSTimer						*_timer;
	NSValue						*_key;
	
	NSArray						*_modules;
}

+ (id) inspectorForObject:(id <OOWeakReferenceSupport>)object;
- (void) bringToFront;

- (id <OOWeakReferenceSupport>) object;

+ (void) cleanUpInspectors;

@end
