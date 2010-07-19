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

- (void) priv_renderImmediateMode;
- (void) priv_renderNormalsWithScale:(float)scale;

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


- (void) renderWithState:(NSDictionary *)inState
{
//	OOLogOpenGLState();
//	[self priv_renderNormalsWithScale:0.01f];
	
	OOGL(glEnable(GL_CULL_FACE));
	
#if 1
	OORenderMesh *renderMesh = self.renderMesh;
	if (renderMesh == nil)  return;
	
	if (_shader == nil)
	{
		NSURL *url = [[NSBundle mainBundle] URLForResource:@"PreviewShader" withExtension:@"vs"];
		NSString *vertexShader = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
		url = [[NSBundle mainBundle] URLForResource:@"PreviewShader" withExtension:@"fs"];
		NSString *fragmentShader = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
		
		_shader = [OOShaderProgram shaderProgramWithVertexShader:vertexShader
												  fragmentShader:fragmentShader
												vertexShaderName:@"PreviewShader.vs"
												vertexShaderName:@"PreviewShader.fs"
														  prefix:nil
											   attributeBindings:renderMesh.prefixedAttributeIndices];
	}
	
	// TODO: reify materials.
	[_shader apply];
	
	[renderMesh renderWithMaterials:nil];
	
	[OOShaderProgram applyNone];
#else
	[self priv_renderImmediateMode];
#endif
	OOGL(glDisable(GL_CULL_FACE));
	
	OOCheckOpenGLErrors(@"After rendering DDMeshSceneNode");
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
	
	SGWFModeContext wfmc;
	SGEnterWireframeMode(&wfmc);
	
	OOGL(glColor3f(0.0f, 1.0f, 1.0f));
	OOGL(glEnableClientState(GL_VERTEX_ARRAY));
	OOGL(glVertexPointer(3, GL_FLOAT, 0, buffer));
	OOGL(glDrawArrays(GL_LINES, 0, vCount * 2));
	OOGL(glDisableClientState(GL_VERTEX_ARRAY));
	
	SGExitWireframeMode(&wfmc);
	
	free(buffer);
}

@end
