//
//  DDMesh.h
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-11.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OoliteGraphics/OoliteGraphics.h>
#import "SGSceneGraph.h"

@class OOAbstractMesh, OORenderMesh;
@protocol OOMeshReading, OOProblemReporting;


@interface DDMesh: NSObject
{
@private
	SGMatrix4x4					_transform;
	OOAbstractMesh				*_abstractMesh;
	OORenderMesh				*_renderMesh;
	NSArray						*_materialSpecs;
	NSString					*_name;
	NSString					*_modelDescription;
	
	BOOL						_haveTemporaryNormals;
	
	BOOL						_pendingRenderMeshUpdate;
}

- (id) initWithReader:(id<OOMeshReading>)reader issues:(id <OOProblemReporting>)issues;

@property (readwrite, assign) OOAbstractMesh *abstractMesh;
@property (readonly) OORenderMesh *renderMesh;
@property (readonly) NSArray *materialSpecifications;

@property (copy) NSString *name;
@property (copy) NSString *modelDescription;

@property (readonly) struct OOBoundingBox boundingBox;

@property SGMatrix4x4 transform;

@property (copy) NSValue *boxedTransform;	// Matrix wrapped in NSValue for bindings.

- (void) generateNormalsSmooth:(BOOL)smooth;
- (void) flipNormals;
- (void) reverseWinding;

@property (readonly) BOOL hasSmoothGroups;
- (void) deleteSmoothGroups;

@end
