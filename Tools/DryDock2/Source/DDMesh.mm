//
//  DDMesh.m
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-11.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDMesh.h"

#import <OoliteGraphics/OoliteGraphics.h>
extern "C" {
#import "MAFuture.h"
}
#import "DDApplicationDelegate.h"


@interface DDMesh ()

- (void) priv_abstractMeshChanged:(NSNotification *)notification;
- (void) priv_noteAbstractMeshSet;
- (void) priv_deferredUpdateRenderMesh;

@end


@implementation DDMesh

@synthesize renderMesh = _renderMesh;
@synthesize materialSpecifications = _materialSpecs;
@synthesize transform = _transform;


- (id) initWithReader:(id<OOMeshReading>)reader issues:(id <OOProblemReporting>)issues
{
	if (reader == nil)  return nil;
	
	if ((self = [super init]))
	{
		BOOL hasNormals;
		
		if (reader.prefersAbstractMesh)
		{
			/*
				If the reader is abstract mesh-oriented, load the abstract mesh
				and let the render mesh be created lazily.
				We can't use a future in this case unless we make a complete
				copy of the abstract mesh, since it's mutable. In any case,
				the render mesh will be generated almost immediately, so there
				wouldn't be much time for it to be generated in the background.
			*/
			OOAbstractMesh *mesh = reader.abstractMesh;
			self.abstractMesh = mesh;
			hasNormals = [mesh.vertexSchema objectForKey:kOONormalAttributeKey] != nil;
		}
		else
		{
			/*
				If the reader is render mesh-oriented, load the render mesh
				and generate the abstract mesh asynchronously. If no extra
				processing is needed before rendering, the abstract mesh won't
				be used until the user edits it in some way.
			*/
			[reader getRenderMesh:&_renderMesh andMaterialSpecs:&_materialSpecs];
			
			if (_renderMesh != nil)
			{
				_abstractMesh = MABackgroundFuture(^{
					OOAbstractMesh *mesh = [self.renderMesh abstractMeshWithMaterialSpecs:self.materialSpecifications];
					mesh.name = self.name;
					mesh.modelDescription = self.modelDescription;
					_abstractMesh = mesh;	// Replace future with real thing. This is necessary for notifications to work.
					
					dispatch_async(dispatch_get_main_queue(), ^{
						// Crucially, it's OK for this stuff to happen even after the mesh has first been used.
						[self priv_noteAbstractMeshSet];
					});
					
					return mesh;
				});
				
				hasNormals = [_renderMesh attributeArrayForKey:kOONormalAttributeKey] != nil;
			}
		}
		
		if (_abstractMesh == nil)
		{
			return nil;
		}
		
		_name = reader.meshName;
		_modelDescription = reader.meshDescription;
		
		if (!hasNormals)
		{
			/*
				If there are no normals, we need to generate some for display.
				This will call in the abstract mesh generation future.
				(N.B.: at some point, we may be able to start with a custom
				material and generate normals on the fly.)
			*/
			
			OOReportInfo(issues, @"The model contains no vertex normals. Temporary normals have been generated for display purposes, but will not be saved with the model. To generate permanent normals, select Generate Normals from the Tools menu.");
			
			_haveTemporaryNormals = YES;
			OOAbstractMesh *mesh = self.abstractMesh;
			[mesh synthesizeNormalsSmoothly:YES replacingExisting:YES];
			OOAbstractFaceGroup *group = nil;
			foreach (group, mesh)
			{
				[group setAttribute:kOONormalAttributeKey temporary:YES];
			}
		}
	}
	
	return self;
}


- (void) priv_noteAbstractMeshSet
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(priv_abstractMeshChanged:)
												 name:kOOAbstractMeshChangedNotification
											   object:_abstractMesh];
	[self priv_deferredUpdateRenderMesh];
}


- (NSString *) descriptionComponents
{
	return [self.abstractMesh descriptionComponents];
}


- (NSString *) name
{
	return _name;
}


- (void) setName:(NSString *)value
{
	_name = [value copy];
	if (_abstractMesh != nil)  self.abstractMesh.value = _name;
}


- (NSString *) modelDescription
{
	return _modelDescription;
}


- (void) setModelDescription:(NSString *)value
{
	_modelDescription = [value copy];
	if (_abstractMesh != nil)  self.abstractMesh.modelDescription = _modelDescription;
}


+ (NSSet *) keyPathsForValuesAffectingName
{
	return [NSSet setWithObject:@"abstractMesh.name"];
}


- (OOAbstractMesh *) abstractMesh
{
	return _abstractMesh;
}


- (void) setAbstractMesh:(OOAbstractMesh *)mesh
{
	if ([mesh isProxy])
	{
		OOLog(@"mesh.proxy", @"Assigned proxy mesy %@", mesh);
	}
	
	_haveTemporaryNormals = NO;
	_name = mesh.name;
	_modelDescription = mesh.modelDescription;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_abstractMesh];
	_abstractMesh = mesh;
	[self priv_noteAbstractMeshSet];
}


- (OORenderMesh *) renderMesh
{
	if (_renderMesh == nil)  [self.abstractMesh getRenderMesh:&_renderMesh andMaterialSpecs:&_materialSpecs];
	return _renderMesh;
}


- (NSArray *) materialSpecifications
{
	if (_renderMesh == nil)  [self.abstractMesh getRenderMesh:&_renderMesh andMaterialSpecs:&_materialSpecs];
	return _materialSpecs;
}


- (NSArray *) renderMaterials
{
	if (_renderMaterials == nil)
	{
		OORenderMesh *mesh = self.renderMesh;
		NSArray *materialSpecs = self.materialSpecifications;
		
		// FIXME: should do this during init and use main problem reporter.
		OOSimpleProblemReportManager *problemReporter = [[OOSimpleProblemReportManager alloc] initWithContextString:$sprintf(@"Loading materials for %@:", self.name) messageClassPrefix:@"material.load.error"];
		
		// FIXME: need to be able to load built-in shaders and shaders relative to mesh file.
		id <OOFileResolving> resolver = [DDApplicationDelegate applicationDelegate].applicationResourceResolver;
		
		NSMutableArray *renderMaterials = [NSMutableArray arrayWithCapacity:materialSpecs.count];
		for (OOMaterialSpecification *spec in materialSpecs)
		{
			OOMaterial *material = [[OOMaterial alloc] initWithSpecification:spec
																		mesh:mesh
																	  macros:nil	// ?
															   bindingTarget:nil
																fileResolver:resolver
															 problemReporter:problemReporter];
			// FIXME: deal with failure.
			[renderMaterials addObject:material];
		}
		_renderMaterials = [renderMaterials copy];
	}
	
	return _renderMaterials;
}


- (NSValue *) boxedTransform
{
	return [NSValue sg_valueWithMatrix4x4:_transform];
}


- (void) setBoxedTransform:(NSValue *)value
{
	SGMatrix4x4 matrix = [value sg_matrix4x4Value];
	// Apple-clang 1.7 raises a nonsense error here if using property syntax. -- Ahruman 2011-03-13
//	self.transform = matrix;
	[self setTransform:matrix];
}


+ (NSSet *) keyPathsForValuesAffectingBoxedTransform
{
	return [NSSet setWithObject:@"transform"];
}


- (void) generateNormalsSmooth:(BOOL)smooth
{
	OOAbstractMesh *mesh = self.abstractMesh;
	
	// As a special case, if we already generated smooth normals but marked them temporary, just un-temp them.
	if (smooth && _haveTemporaryNormals)
	{
		OOAbstractFaceGroup *group = nil;
		foreach (group, mesh)
		{
			[group setAttribute:kOONormalAttributeKey temporary:NO];
		}
		_haveTemporaryNormals = NO;
		return;
	}
	_haveTemporaryNormals = NO;
	
	/*
		If you generate flat normals and then generate smooth vertices, the
		expected result is a smooth model. However, the generation of flat
		normals will have de-uniqued the vertices. By deleting all normals
		and uniquing vertices, we get the expected result.
		We also need to remove tangents so that they don't cause unwanted
		uniqueness.
	*/
	NSMutableDictionary *schema = [NSMutableDictionary dictionaryWithDictionary:mesh.vertexSchema];
	BOOL hadTangents = [schema objectForKey:kOOTangentAttributeKey] != nil;
	
	if (hadTangents || [schema objectForKey:kOONormalAttributeKey] != nil)
	{
		[schema removeObjectForKey:kOONormalAttributeKey];
		[schema removeObjectForKey:kOOTangentAttributeKey];
		[mesh restrictToSchema:schema];
		[mesh uniqueVertices];
	}
	
	[mesh synthesizeNormalsSmoothly:smooth replacingExisting:YES];
	
	// FIXME: if (hadTangents), synthesize new tangents.
	
	OOAbstractFaceGroup *group = nil;
	for (group in mesh)
	{
		[group setAttribute:kOONormalAttributeKey temporary:NO];
	}
}


- (void) flipNormals
{
	[self.abstractMesh flipNormals];
}


- (void) reverseWinding
{
	[self.abstractMesh reverseWinding];
}


- (BOOL) hasSmoothGroups
{
	return [self.abstractMesh.vertexSchema objectForKey:kOOSmoothGroupAttributeKey] != nil;
}


- (void) deleteSmoothGroups
{
	OOAbstractMesh *mesh = self.abstractMesh;
	NSMutableDictionary *schema = [NSMutableDictionary dictionaryWithDictionary:mesh.vertexSchema];
	
	if ([schema objectForKey:kOOSmoothGroupAttributeKey] != nil)
	{
		[schema removeObjectForKey:kOOSmoothGroupAttributeKey];
		[mesh restrictToSchema:schema];
	}
}


- (struct OOBoundingBox) boundingBox
{
	return self.abstractMesh.boundingBox;
}


- (void) priv_abstractMeshChanged:(NSNotification *)notification
{
	if (!_pendingRenderMeshUpdate && [notification.userInfo oo_boolForKey:kOOAbstractMeshChangeAffectsRenderMesh])
	{
		[self priv_deferredUpdateRenderMesh];
	}
}


- (void) priv_deferredUpdateRenderMesh
{
	if (!_pendingRenderMeshUpdate)
	{
		_pendingRenderMeshUpdate = YES;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self willChangeValueForKey:@"renderMesh"];
			[self willChangeValueForKey:@"materialSpecifications"];
			
			_renderMesh = nil;
			_materialSpecs = nil;
			
			[self didChangeValueForKey:@"materialSpecifications"];
			[self didChangeValueForKey:@"renderMesh"];
			
			_pendingRenderMeshUpdate = NO;
		});
	}
}

@end
