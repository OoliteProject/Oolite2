//
//  OOEntityInspectorExtensions.h
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-10.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "Entity.h"


@interface NSObject (OOInspectorExtensions)

- (NSString *) inspDescription;
- (NSString *) inspBasicIdentityLine;

- (BOOL) inspHasSecondaryIdentityLine;
- (NSString *) inspSecondaryIdentityLine;

- (BOOL) inspCanBecomeTarget;
- (void) inspBecomeTarget;

- (void) inspect;

@end


@interface Entity (OOEntityInspectorExtensions)

- (NSString *) inspScanClassLine;
- (NSString *) inspStatusLine;
- (NSString *) inspRetainCountLine;
- (NSString *) inspPositionLine;
- (NSString *) inspVelocityLine;
- (NSString *) inspOrientationLine;
- (NSString *) inspEnergyLine;
- (NSString *) inspOwnerLine;
- (NSString *) inspTargetLine;

@end
