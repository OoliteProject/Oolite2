//
//  DDMeshSceneNode.h
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-11.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "SGSceneNode.h"

@class DDMesh, OORenderMesh, OOShaderProgram, OOTexture;


@interface DDMeshSceneNode: SGSceneNode
{
@private
#if !__OBJC2__
	DDMesh						*_mesh;
	NSArray						*_materialSpecs;
	NSArray						*_renderMaterials;
#endif
	OORenderMesh				*_renderMesh;
	NSArray						*_materials;
	
	// TEMP
	OOShaderProgram				*_whiteShader;
	OOShaderProgram				*_shadedWireframeShader;
	OOShaderProgram				*_solidWireframeShader;
	GLint						_shadedWireframeColorUniform;
	GLint						_solidWireframeColorUniform;
	
	GLuint						_normalVectorVBO;
	GLuint						_normalVBO;
	
	// TEMP
	OOTexture					*_testTexture;
}

- (id) initWithMesh:(DDMesh *)mesh;

@property (readonly) DDMesh *mesh;

@end
