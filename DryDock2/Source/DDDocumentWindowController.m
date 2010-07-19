//
//  DDDocumentWindowController.m
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-10.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDDocumentWindowController.h"
#import "DDMainDocumentView.h"
#import "SGSceneGraph.h"

#import <OoliteGraphics/OoliteGraphics.h>
#import "SGDisplayListCacheNode.h"
#import "SGAxisNode.h"
#import "SGPointCloudNode.h"
#import "DDMeshSceneNode.h"


@interface DDDocumentWindowController ()

@property (readwrite, copy) NSArray *meshes;

- (void) priv_buildSceneGraph;
- (void) priv_updateSceneGraph;

@end


@implementation DDDocumentWindowController

@synthesize mainView = _mainView;


+ (BOOL) accessInstanceVariablesDirectly
{
	return NO;
}


- (id) init
{
	return [super initWithWindowNibName:@"DDDocument"];
}


- (void) awakeFromNib
{
	[self priv_buildSceneGraph];
}


- (void) setDocument:(NSDocument *)document
{
	[super setDocument:document];
	if (document != nil)  [self bind:@"meshes" toObject:document withKeyPath:@"meshes" options:nil];
	else  [self unbind:@"meshes"];
}


- (NSArray *) meshes
{
	return _meshes;
}


- (void) setMeshes:(NSArray *)meshes
{
	_meshes = [meshes copy];
	[self priv_updateSceneGraph];
}


- (void) priv_buildSceneGraph
{
	_rootNode = [SGSceneNode new];
	[_rootNode setLocalizedName:@"root"];
	
	[_rootNode addChild:[SGAxisNode new]];
	
	// Add meshes.
	[self priv_updateSceneGraph];
	
	self.mainView.sceneGraph.rootNode = _rootNode;
}


- (void) priv_updateSceneGraph
{
	if (_rootNode == nil)  return;
	
	[_rootNode removeChild:_contentNode];
//	_contentNode = [SGDisplayListCacheNode new];
	_contentNode = [SGSceneNode new];
	[_contentNode setLocalizedName:@"content"];
	[_rootNode addChild:_contentNode];
	
	for (DDMesh *mesh in self.meshes)
	{
		SGSceneNode *node = [[DDMeshSceneNode alloc] initWithMesh:mesh];
		[_contentNode addChild:node];
	}
}


- (IBAction) takeViewFromTag:(NSMenuItem *)sender
{
	self.mainView.cameraType = sender.tag;
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(takeViewFromTag:))
	{
		menuItem.state = ((JASceneGraphViewCameraType)menuItem.tag == self.mainView.cameraType);
	}
	
	return YES;
}

@end
