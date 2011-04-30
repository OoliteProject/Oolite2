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
#if 0
	_rootNode = [SGSceneNode new];
	[_rootNode setLocalizedName:@"root"];
	
	[_rootNode addChild:[SGAxisNode new]];
	
	// Add meshes.
	[self priv_updateSceneGraph];
	
	self.mainView.sceneGraph.rootNode = _rootNode;
#else
	[self priv_updateSceneGraph];
#endif
}


- (void) priv_updateSceneGraph
{
#if 0
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
#else
	SGSceneNode *contentGroup = [SGSceneNode new];
	[contentGroup setLocalizedName:@"content group"];
	
	for (DDMesh *mesh in self.meshes)
	{
		SGSceneNode *node = [[DDMeshSceneNode alloc] initWithMesh:mesh];
		[contentGroup addChild:node];
	}
	
	self.mainView.contentNode = contentGroup;
#endif
}


- (IBAction) takeViewFromTag:(NSMenuItem *)sender
{
	self.mainView.cameraType = sender.tag;
}


- (IBAction) toggleShowFaces:(id)sender
{
	BOOL showFaces = !self.mainView.showFaces;
	self.mainView.showFaces = showFaces;
	
	// At least one of faces and wireframe must be visible.
	if (!showFaces)  self.mainView.showWireframe = YES;
}


- (IBAction) toggleShowWireframe:(id)sender
{
	BOOL showWireframe = !self.mainView.showWireframe;
	self.mainView.showWireframe = showWireframe;
	
	// At least one of faces and wireframe must be visible.
	if (!showWireframe)  self.mainView.showFaces = YES;
}


- (IBAction) toggleShowNormals:(id)sender
{
	self.mainView.showNormals = !self.mainView.showNormals;
}


- (IBAction) toggleShowTangents:(id)sender
{
	self.mainView.showTangents = !self.mainView.showTangents;
}


- (IBAction) switchToWhiteShader:(id)sender
{
	self.mainView.useWhiteShader = YES;
}


- (IBAction) switchToMaterialShader:(id)sender
{
	self.mainView.useWhiteShader = NO;
}


- (IBAction) resetCamera:(id)sender
{
	[self.mainView resetCamera:sender];
}


- (IBAction) recenterCamera:(id)sender
{
	[self.mainView resetPan:sender];
}


- (IBAction) zoomIn:(id)sender
{
	[self.mainView zoomIn:sender];
}


- (IBAction) zoomOut:(id)sender
{
	[self.mainView zoomOut:sender];
}


- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
//- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	id item = anItem;
	SEL action = [item action];
	BOOL initialState, state = NO;
	BOOL hasState = [item respondsToSelector:@selector(setState:)];
	if (hasState)  state = initialState = [(id)item state];
	BOOL enabled = YES;
	
	if (action == @selector(takeViewFromTag:) && [item respondsToSelector:@selector(tag)])
	{
		state = ((JASceneGraphViewCameraType)[item tag] == self.mainView.cameraType);
	}
	else if (action == @selector(toggleShowFaces:))
	{
		state = self.mainView.showFaces;
	}
	else if (action == @selector(toggleShowWireframe:))
	{
		state = self.mainView.showWireframe;
	}
	else if (action == @selector(toggleShowNormals:))
	{
		state = self.mainView.showNormals;
	}
	else if (action == @selector(toggleShowTangents:))
	{
		state = self.mainView.showTangents;
	}
	else if (action == @selector(switchToWhiteShader:))
	{
		state = self.mainView.useWhiteShader;
		enabled = self.mainView.showFaces;
	}
	else if (action == @selector(switchToMaterialShader:))
	{
		state = !self.mainView.useWhiteShader;
		enabled = self.mainView.showFaces;
	}
	else if (action == @selector(recenterCamera:))
	{
		enabled = !self.mainView.centered;
	}
	
	if (hasState && state != initialState)
	{
		[item setState:state];
	}
	
	return enabled;
}

@end
