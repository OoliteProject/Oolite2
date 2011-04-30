//
//  DDApplicationDelegate.m
//  DryDock2
//
//  Created by Jens Ayton on 2010-08-29.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDApplicationDelegate.h"
#include <asl.h>


@implementation DDApplicationDelegate

+ (DDApplicationDelegate *) applicationDelegate
{
	return [NSApp delegate];
}


- (void) awakeFromNib
{
	OOLoggingInit(self);
}


- (BOOL) shouldShowMessageInClass:(NSString *)messageClass
{
	static NSSet *excluded = nil;
	if (EXPECT_NOT(excluded == nil))
	{
		excluded =
		$set(
			 @"rendering.opengl",
			 @"materials.synthesize.dump",
			 @"texture.load.asyncLoad",
			 @"texture.load.rescale",
			 @"texture.upload"
		);
	}
	
	if ([excluded containsObject:messageClass])  return NO;
	
	for (NSString *prefix in excluded)
	{
		if ([messageClass hasPrefix:prefix])  return NO;
	}
	
	return YES;
}


- (BOOL) showMessageClass
{
	return NO;
}


- (id <OOFileResolving>) applicationResourceResolver
{
	if (_resourceResolver == nil)
	{
		_resourceResolver = [[OOSimpleFileResolver alloc] initWithBasePath:[[NSBundle mainBundle] resourcePath]];
	}
	
	return _resourceResolver;
}

@end
