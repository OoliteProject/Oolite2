//
//  DDMeshSceneNode.mm
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-11.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDMeshSceneNode.h"
#import "DDMesh.h"
#import "SGSceneGraphUtilities.h"

#import <OoliteGraphics/OoliteGraphics.h>


@interface DDMeshSceneNode ()

@property (readwrite) DDMesh *mesh;

@property (readwrite) OORenderMesh *renderMesh;
@property (readwrite, assign) NSArray *materialSpecifications;

- (void) priv_renderFilledNormal;
- (void) priv_renderFilledWhite;
- (void) priv_renderWireframe;
- (void) priv_renderBoundingBox;
- (void) priv_renderNormalsWithScale:(float)scale;

- (void) priv_renderImmediateMode;

- (OOShaderProgram *) priv_whiteShader;
- (OOShaderProgram *) priv_wireframeShader;
- (OOShaderProgram *) priv_boundingBoxShader;
- (OOShaderProgram *) priv_loadShaderNamed:(NSString *)name attributeMap:(NSDictionary *)attributeMap;

@end


@implementation DDMeshSceneNode

@synthesize mesh = _mesh;
@synthesize renderMesh = _renderMesh;
@synthesize materialSpecifications = _materialSpecs;


- (id) initWithMesh:(DDMesh *)mesh
{
	if (mesh == nil)  return nil;
	
	if ((self = [super init]))
	{
		self.mesh = mesh;
		self.name = mesh.name;
		
		[self bind:@"boxedTransform" toObject:mesh withKeyPath:@"boxedTransform" options:nil];
		[self bind:@"renderMesh" toObject:mesh withKeyPath:@"renderMesh" options:nil];
		[self bind:@"materialSpecifications" toObject:mesh withKeyPath:@"materialSpecifications" options:nil];
	}
	
	return self;
}


- (NSString *) descriptionComponents
{
	return [self.mesh descriptionComponents];
}


- (void) setRenderMesh:(OORenderMesh *)mesh
{
	[self becomeDirty];
	
	// Shader attribute indices may need rebinding. This is wasteful, but gets the job done:
	_whiteShader = nil;
	_wireframeShader = nil;
	_boundingBoxShader = nil;
	
	_renderMesh = mesh;
}


- (void) setMaterialSpecifications:(NSArray *)specs
{
	if (![specs isEqualToArray:self.materialSpecifications])
	{
		_materialSpecs = specs;
		_materials = nil;
	}
}


- (void) renderWithState:(NSDictionary *)state
{
	if ([state oo_boolForKey:@"show normals"])  [self priv_renderNormalsWithScale:0.1f];
	if ([state oo_boolForKey:@"show wireframe"])
	{
		[self priv_renderBoundingBox];
		[self priv_renderWireframe];
	}
	if ([state oo_boolForKey:@"show faces"])
	{
		if ([state oo_boolForKey:@"use white shader"])  [self priv_renderFilledWhite];
		else  [self priv_renderFilledNormal];
	}
	
	[OOShaderProgram applyNone];
	OOCheckOpenGLErrors(@"After rendering DDMeshSceneNode");
}


- (void) priv_renderFilledNormal
{
	// TODO: use materials.
	[self priv_renderFilledWhite];
}


- (void) priv_renderFilledWhite
{
	[[self priv_whiteShader] apply];
	
	OOGL(glEnable(GL_CULL_FACE));
	[self.renderMesh renderWithMaterials:nil];
	OOGL(glDisable(GL_CULL_FACE));
}


- (void) priv_renderWireframe
{
	OOGL(glPolygonMode(GL_FRONT_AND_BACK, GL_LINE));
	
	[[self priv_wireframeShader] apply];
	OOGL(glUniform4f(_wireframeColorUniform, 0.7f, 0.7f, 0.0f, 1.0f));
	
	[self.renderMesh renderWithMaterials:nil];
	
	OOGL(glPolygonMode(GL_FRONT_AND_BACK, GL_FILL));
}


- (void) priv_renderBoundingBox
{
	OOBoundingBox bbox = self.mesh.boundingBox;
	
	float vertices[8 * 3];
	float *next = vertices;
	unsigned i;
	for (i = 0; i < 8; i++)
	{
#define COMPONENT(mask) ((mask) ? bbox.max : bbox.min)
		*next++ = COMPONENT(i & 1).x;
		*next++ = COMPONENT(i & 2).y;
		*next++ = COMPONENT(i & 4).z;
	}
	
	GLuint indices[] =
	{
		0, 1, 1, 3, 3, 2, 2, 0,
		4, 5, 5, 7, 7, 6, 6, 4,
		0, 4, 1, 5, 2, 6, 3, 7
	};
	
	[[self priv_boundingBoxShader] apply];
	
	OOGL(glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, vertices));
	OOGL(glEnableVertexAttribArray(0));
	OOGL(glDrawElements(GL_LINES, sizeof indices / sizeof *indices, GL_UNSIGNED_INT, indices));
	OOGL(glDisableVertexAttribArray(0));
}


- (void) priv_renderImmediateMode
{
	// Immediate-mode rendering from abstract mesh, for debugging.
	
	glColor4f(1, 1, 1, 1);
	glEnable(GL_LIGHT0);
	
	glBegin(GL_TRIANGLES);
	for (OOAbstractFaceGroup *group in self.mesh.abstractMesh)
	{
		for (OOAbstractFace *face in group)
		{
			for (unsigned i = 0; i < 3; i++)
			{
				OOAbstractVertex *vertex = [face vertexAtIndex:i];
				Vector v = vertex.normal;
				glNormal3f(v.x, v.y, v.z);
				v = vertex.position;
				glVertex3f(v.x, v.y, v.z);
			}
		}
	}
	glEnd();
}


- (void) priv_renderNormalsWithScale:(float)scale
{
	// FIXME: use VBO & VAO.
	
	OORenderMesh *rMesh = self.renderMesh;
	NSUInteger pSize = [rMesh attributeSizeForKey:kOOPositionAttributeKey];
	NSUInteger nSize = [rMesh attributeSizeForKey:kOONormalAttributeKey];
	if (pSize < 3 || nSize < 3)  return;
	
	NSUInteger vIter, vCount = rMesh.vertexCount;
	
	GLfloat *buffer = (GLfloat *)malloc(vCount * 6 * sizeof (GLfloat));
	if (buffer == NULL)  return;
	
	OOFloatArray *pArray = [rMesh attributeArrayForKey:kOOPositionAttributeKey];
	OOFloatArray *nArray = [rMesh attributeArrayForKey:kOONormalAttributeKey];
	
	GLfloat *next = buffer;
	for (vIter = 0; vIter < vCount; vIter++)
	{
		for (unsigned cIter = 0; cIter < 3; cIter++)
		{
			next[cIter] = [pArray floatAtIndex:pSize * vIter + cIter];
			next[cIter + 3] = next[cIter] + [nArray floatAtIndex:nSize * vIter + cIter] * scale;
		}
		
		next += 6;
	}
	
	[[self priv_wireframeShader] apply];
	OOGL(glUniform4f(_wireframeColorUniform, 0.7f, 0.0f, 0.0f, 0.0f));
	
	OOGL(glEnable(GL_POLYGON_OFFSET_LINE));
	OOGL(glPolygonOffset(1, 1));
	
	OOGL(glPolygonMode(GL_FRONT_AND_BACK, GL_LINE));
	OOGL(glEnableClientState(GL_VERTEX_ARRAY));
	OOGL(glVertexPointer(3, GL_FLOAT, 0, buffer));
	OOGL(glDrawArrays(GL_LINES, 0, vCount * 2));
	OOGL(glDisableClientState(GL_VERTEX_ARRAY));
	
	OOGL(glPolygonMode(GL_FRONT_AND_BACK, GL_FILL));
	OOGL(glDisable(GL_POLYGON_OFFSET_LINE));
	
	free(buffer);
}


- (OOShaderProgram *) priv_whiteShader
{
	if (_whiteShader == nil)
	{
		_whiteShader = [self priv_loadShaderNamed:@"PreviewShader" attributeMap:nil];
	}
	return _whiteShader;
}


- (OOShaderProgram *) priv_wireframeShader
{
	if (_wireframeShader == nil)
	{
		_wireframeShader = [self priv_loadShaderNamed:@"WireframeShader" attributeMap:nil];
		if (_wireframeShader != nil)
		{
			OOGL(_wireframeColorUniform = glGetUniformLocation(_wireframeShader.program, "uColor"));
		}
	}
	return _wireframeShader;
}


- (OOShaderProgram *) priv_boundingBoxShader
{
	if (_boundingBoxShader == nil)
	{
		_boundingBoxShader = [self priv_loadShaderNamed:@"BoundingBoxShader" attributeMap:$dict(@"aPosition", $int(0))];
	}
	return _boundingBoxShader;
}


- (OOShaderProgram *) priv_loadShaderNamed:(NSString *)name attributeMap:(NSDictionary *)attributeMap
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:name withExtension:@"vs"];
	NSString *vertexShader = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
	url = [[NSBundle mainBundle] URLForResource:name withExtension:@"fs"];
	NSString *fragmentShader = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
	
	if (attributeMap == nil)  attributeMap = self.renderMesh.prefixedAttributeIndices;
	
	return [OOShaderProgram shaderProgramWithVertexShader:vertexShader
										   fragmentShader:fragmentShader
										 vertexShaderName:[name stringByAppendingPathExtension:@"vs"]
										 vertexShaderName:[name stringByAppendingPathExtension:@"fs"]
												   prefix:nil
										attributeBindings:attributeMap];
}

@end
