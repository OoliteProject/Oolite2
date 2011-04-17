//
//  DDSceneView.m
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-10.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDSceneView.h"
#import <OoliteGraphics/OoliteGraphics.h>


@implementation DDSceneView

- (OOGraphicsContext *) graphicsContext
{
	if (_context == nil)  _context = [[OOGraphicsContext alloc] initWithOpenGLContext:self.openGLContext];
	return _context;
}


- (void) prepareOpenGL
{
	[self.graphicsContext makeCurrent];
	[super prepareOpenGL];
}


- (void) drawRect:(NSRect)dirtyRect
{
	[self.graphicsContext makeCurrent];
	[super drawRect:dirtyRect];
}

@end
