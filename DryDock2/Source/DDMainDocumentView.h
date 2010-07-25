//
//  DDMainDocumentView.h
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-10.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDSceneView.h"

@class SGSceneNode;


@interface DDMainDocumentView: DDSceneView
{
@private
	SGSceneNode				*_contentHolderNode;
	
#if !__OBJC2__
	BOOL					_showFaces;
	BOOL					_showWireframe;
	BOOL					_showNormals;
	BOOL					_showTangents;
	BOOL					_useWhiteShader;
#endif
}

@property BOOL showFaces;
@property BOOL showWireframe;
@property BOOL showNormals;
@property BOOL showTangents;

@property BOOL useWhiteShader;

@property (readonly, getter=isCentered) BOOL centered;

@property SGSceneNode *contentNode;

@end
