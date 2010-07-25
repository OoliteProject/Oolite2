//
//  DDMainDocumentView.m
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-10.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDMainDocumentView.h"
#import <OoliteBase/OoliteBase.h>

#import "SGSceneGraph.h"
#import "SGAxisNode.h"
#import "DDMeshSceneNode.h"
#import "SGSceneGraph+GraphVizGeneration.h"


@interface DDMainDocumentView ()

@property (readonly) SGSceneNode *contentHolderNode;

@end


@implementation DDMainDocumentView

@synthesize showFaces = _showFaces;
@synthesize showWireframe = _showWireframe;
@synthesize showNormals = _showNormals;
@synthesize showTangents = _showTangents;
@synthesize useWhiteShader = _useWhiteShader;


- (unsigned) dragActionForEvent:(NSEvent *)inEvent
{
	switch (inEvent.type)
	{
		case NSLeftMouseDown:
			if (self.cameraType == kViewType3D)  return kDragAction_orbitCamera;
			else  return kDragAction_panCamera;
			
		case NSRightMouseDown:
			return kDragAction_panCamera;
			
		case NSOtherMouseDown:
			switch (inEvent.buttonNumber)
			{
				case 2:
					return kDragAction_zoomCamera;
			}
			
		default:
			return kDragAction_none;
	}
}


- (void) prepareOpenGL
{
	[super prepareOpenGL];
	
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
}


- (void) drawRect:(NSRect)rect
{
	// Ensure lazy set-up has happened.
	(void) self.contentHolderNode;
	
	[super drawRect:rect];
}


- (NSColor *) backgroundColor
{
	return [NSColor darkGrayColor];
}


- (SGSceneNode *) contentNode
{
	return self.contentHolderNode.firstChild;
}


- (void) setContentNode:(SGSceneNode *)node
{
	[self.contentHolderNode removeChild:self.contentNode];
	[self.contentHolderNode addChild:node];
	
	NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:@"scene dump.dot"];
	[self.sceneGraph writeGraphVizToPath:path];
	CSBackupSetItemExcluded((CFURLRef)[NSURL fileURLWithPath:path], YES, NO);
}


- (SGSceneNode *) contentHolderNode
{
	if (_contentHolderNode == nil)
	{
		// Build scene graph.
		SGSceneNode *rootNode = [SGSceneNode new];
		[rootNode setLocalizedName:@"root"];
		
		SGSceneTag *tag = nil;
		tag = [SGSimpleTag tagWithKey: @"show faces" boolValue:NO];
		[tag bind:@"boolValue" toObject:self withKeyPath:@"showFaces" options:nil];
		[rootNode addTag:tag];
		self.showFaces = YES;
		
		tag = [SGSimpleTag tagWithKey: @"show wireframe" boolValue:NO];
		[tag bind:@"boolValue" toObject:self withKeyPath:@"showWireframe" options:nil];
		[rootNode addTag:tag];
		
		tag = [SGSimpleTag tagWithKey: @"show normals" boolValue:NO];
		[tag bind:@"boolValue" toObject:self withKeyPath:@"showNormals" options:nil];
		[rootNode addTag:tag];
		
		tag = [SGSimpleTag tagWithKey: @"show tangents" boolValue:NO];
		[tag bind:@"boolValue" toObject:self withKeyPath:@"showTangents" options:nil];
		[rootNode addTag:tag];
		
		tag = [SGSimpleTag tagWithKey: @"use white shader" boolValue:NO];
		[tag bind:@"boolValue" toObject:self withKeyPath:@"useWhiteShader" options:nil];
		[rootNode addTag:tag];
		
		// Add axis node, visible when wireframe visible.
		SGAxisNode *axisNode = [SGAxisNode new];
		[axisNode addTag:[SGConditionalTag tagWithComparator:$true
												   operation:NSOrderedSame
												conditionKey:@"show wireframe"
												   resultKey:@"visible"]];
		[rootNode addChild:axisNode];
		
		_contentHolderNode = [SGSceneNode new];
		[_contentHolderNode setLocalizedName:@"content holder"];
		[rootNode addChild:_contentHolderNode];
		
		self.sceneGraph.rootNode = rootNode;
	}
	
	return _contentHolderNode;
}


- (IBAction) resetZoom:(id)sender
{
	self.cameraDistance = -50;
	[self displaySettingsChanged];
}


- (BOOL) isCentered
{
	SGVector3 focus = self.focusPoint;
	return focus == SGVector3(0, 0, 0);
}

@end
