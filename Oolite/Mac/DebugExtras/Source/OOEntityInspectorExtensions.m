//
//  OOEntityInspectorExtensions.m
//  DebugOXP
//
//  Created by Jens Ayton on 2008-03-10.
//  Copyright 2008 Jens Ayton. All rights reserved.
//

#import "OOEntityInspectorExtensions.h"
#import "OOConstToString.h"
#import "PlayerEntity.h"
#import "OODebugInspector.h"


@implementation NSObject (OOInspectorExtensions)

- (NSString *) inspDescription
{
	NSString *desc = [self shortDescriptionComponents];
	if (desc == nil)  return [self className];
	else  return [NSString stringWithFormat:@"%@ %@", [self className], desc];
}


- (NSString *) inspBasicIdentityLine
{
	return [self inspDescription];
}


- (BOOL) inspHasSecondaryIdentityLine
{
	return NO;
}


- (NSString *) inspSecondaryIdentityLine
{
	return nil;
}

- (BOOL) inspCanBecomeTarget
{
	return NO;
}


- (void) inspBecomeTarget
{
	
}


// Callable via JS Entity.inspect()
- (void) inspect
{
	if ([self conformsToProtocol:@protocol(OOWeakReferenceSupport)])
	{
		[[OODebugInspector inspectorForObject:(id <OOWeakReferenceSupport>)self] bringToFront];
	}
}

@end


@implementation Entity (OOEntityInspectorExtensions)

- (NSString *) inspDescription
{
	return [NSString stringWithFormat:@"%@ ID %u", [self class], [self universalID]];
}


- (NSString *) inspBasicIdentityLine
{
	OOUniversalID		myID = [self universalID];
	
	if (myID != NO_TARGET)
	{
		return [NSString stringWithFormat:@"%@ ID %u", [self class], myID];
	}
	else
	{
		return [self className];
	}
}


- (NSString *) inspScanClassLine
{
	return OOStringFromScanClass([self scanClass]);
}


- (NSString *) inspStatusLine
{
	return OOStringFromEntityStatus([self status]);
}


- (NSString *) inspRetainCountLine
{
	return [NSString stringWithFormat:@"%u", [self retainCount]];
}


- (NSString *) inspPositionLine
{
	Vector v = [self position];
	return [NSString stringWithFormat:@"%.0f, %.0f, %.0f", v.x, v.y, v.z];
}


- (NSString *) inspVelocityLine
{
	Vector v = [self velocity];
	return [NSString stringWithFormat:@"%.1f, %.1f, %.1f (%.1f)", v.x, v.y, v.z, magnitude(v)];
}


- (NSString *) inspOrientationLine
{
	Quaternion q = [self orientation];
	return [NSString stringWithFormat:@"%.3f (%.3f, %.3f, %.3f)", q.w, q.x, q.y, q.z];
}


- (NSString *) inspEnergyLine
{
	return [NSString stringWithFormat:@"%i/%i", (int)[self energy], (int)[self maxEnergy]];
}


- (NSString *) inspOwnerLine
{
	if ([self owner] == self)  return @"Self";
	return [[self owner] inspDescription];
}


- (NSString *) inspTargetLine
{
	return nil;
}

@end


@implementation ShipEntity (OOEntityInspectorExtensions)

- (BOOL) inspHasSecondaryIdentityLine
{
	return YES;
}


- (NSString *) inspSecondaryIdentityLine
{
	return [self displayName];
}


- (NSString *) inspDescription
{
	return [NSString stringWithFormat:@"%@ ID %u", [self displayName], [self universalID]];
}


- (NSString *) inspTargetLine
{
	return [[self primaryTarget] inspDescription];
}


- (BOOL) inspCanBecomeTarget
{
	return ![self isSubEntity];
}


- (void) inspBecomeTarget
{
	if ([self inspCanBecomeTarget])  [[PlayerEntity sharedPlayer] addTarget:self];
}

@end


@implementation PlayerEntity (OOEntityInspectorExtensions)

- (NSString *) inspSecondaryIdentityLine
{
	return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"\"%@\", %@", nil, [NSBundle bundleForClass:[self class]], @""), [self captainName], [self displayName]];
}


- (BOOL) inspCanBecomeTarget
{
	return NO;
}


- (NSString *) inspDescription
{
	return @"Player";
}

@end
