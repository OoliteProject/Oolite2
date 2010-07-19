//
//  DDMainDocumentView.m
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-10.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDMainDocumentView.h"


@implementation DDMainDocumentView

- (unsigned) dragActionForEvent:(NSEvent *)inEvent
{
	return kDragAction_orbitCamera;
}


- (void)prepareOpenGL
{
	[super prepareOpenGL];
	
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
}


- (NSColor *) backgroundColor
{
	return [NSColor darkGrayColor];
}


- (void) resetZoom
{
	self.cameraDistance = -500;
	[self displaySettingsChanged];
}

@end
