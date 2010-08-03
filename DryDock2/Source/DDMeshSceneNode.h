//
//  DDMeshSceneNode.h
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-11.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "SGSceneNode.h"

@class DDMesh, OORenderMesh, OOShaderProgram;


@interface DDMeshSceneNode: SGSceneNode
{
@private
#if !__OBJC2__
	DDMesh						*_mesh;
	NSArray						*_materialSpecs;
#endif
	OORenderMesh				*_renderMesh;
	NSArray						*_materials;
	
	// TEMP
	OOShaderProgram				*_whiteShader;
	OOShaderProgram				*_wireframeShader;
	OOShaderProgram				*_boundingBoxShader;
	GLint						_wireframeColorUniform;
	
	GLuint						_normalVectorVBO;
	GLuint						_normalVBO;
}

- (id) initWithMesh:(DDMesh *)mesh;

@property (readonly) DDMesh *mesh;

@end
