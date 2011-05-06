//
//  DDDocument.h
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-10.
//  Copyright 2010 Jens Ayton. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class DDMesh, DDSceneView;


@interface DDDocument: NSDocument
{
@private
	NSMutableArray						*_meshes;
	NSURL								*_realTargetURL;
	
#if !__OBJC2__
	float								_loadingProgress;
#endif
}

- (IBAction) generateNormalsSmooth:(id)sender;
- (IBAction) generateNormalsFlat:(id)sender;
- (IBAction) flipNormals:(id)sender;
- (IBAction) reverseWinding:(id)sender;

- (IBAction) deleteSmoothGroups:(id)sender;

// Meshes: an array of DDMesh.
- (NSArray *) meshes;
- (void) addMesh:(DDMesh *)mesh;
- (void) removeMesh:(DDMesh *)mesh;

@end
