/*
	OOAbstractMesh.h
	
	
	Copyright © 2010 Jens Ayton.
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#if !OOLITE_LEAN

#import "OOAbstractMesh.h"
#import "OOAbstractFaceGroup.h"


@interface OOAbstractMesh (Private)

// Must be called whenever mesh is mutated.
- (void) priv_becomeDirtyWithAdditions:(BOOL)additions;
- (void) priv_observeFaceGroup:(OOAbstractFaceGroup *)faceGroup;
- (void) priv_stopObservingFaceGroup:(OOAbstractFaceGroup *)faceGroup;

- (void) priv_buildRenderMesh;

- (void) priv_uniqueVerticesGettingResults:(NSArray **)outVertices
								   indices:(NSDictionary **)outIndices
								 useCounts:(NSArray **)outUseCounts
							 updatingFaces:(BOOL)updatingFaces;

@end


@implementation OOAbstractMesh

- (id) init
{
	if ((self = [super init]))
	{
		_faceGroups = [[NSMutableArray alloc] init];
		if (_faceGroups == nil)  DESTROY(self);
	}
	return self;
}


- (void) dealloc
{
	DESTROY(_faceGroups);
	DESTROY(_name);
	
	DESTROY(_renderMesh);
	DESTROY(_materialSpecs);
	
	[super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
	OOAbstractMesh *result = [[self class] allocWithZone:zone];
	if (result != nil)
	{
		OOAbstractFaceGroup *group = nil;
		foreach(group, self)
		{
			[result addFaceGroup:[group copy]];
		}
		
		[result setName:[self name]];
		
		result->_renderMesh = [_renderMesh copy];
		result->_materialSpecs = [_materialSpecs copy];
	}
	
	return result;
}


- (NSString *) descriptionComponents
{
	return [NSString stringWithFormat:@"\"%@\"", [self name]];
}


- (NSString *) name
{
	return _name;
}


- (void) setName:(NSString *)name
{
#ifndef NDEBUG
	// render mesh doesn't have a name if NDEBUG is defined.
	if ([name isEqualToString:_name])  return;
	[self priv_becomeDirtyWithAdditions:NO];
#endif
	
	[_name autorelease];
	_name = [name copy];
}


- (NSString *) modelDescription
{
	return _modelDescription;
}


- (void) setModelDescription:(NSString *)value
{
	[_modelDescription autorelease];
	_modelDescription = [value copy];
}


- (NSUInteger) faceGroupCount
{
	return [_faceGroups count];
}


- (OOAbstractFaceGroup *) faceGroupAtIndex:(NSUInteger)index
{
	return [_faceGroups objectAtIndex:index];
}


- (void) addFaceGroup:(OOAbstractFaceGroup *)faceGroup
{
	if (EXPECT_NOT(faceGroup == nil || [_faceGroups indexOfObject:faceGroup] != NSNotFound))  return;
	
	[self priv_becomeDirtyWithAdditions:YES];
	[self priv_observeFaceGroup:faceGroup];
	
	[_faceGroups addObject:faceGroup];
}


- (void) insertFaceGroup:(OOAbstractFaceGroup *)faceGroup atIndex:(NSUInteger)idx
{
	if (EXPECT_NOT(faceGroup == nil || [_faceGroups indexOfObject:faceGroup] != NSNotFound))  return;
	
	[self priv_becomeDirtyWithAdditions:YES];
	[self priv_observeFaceGroup:faceGroup];
	
	[_faceGroups insertObject:faceGroup atIndex:idx];
}


- (void) removeLastFaceGroup
{
	if (EXPECT_NOT([_faceGroups count] == 0))  return;
	
	[self priv_becomeDirtyWithAdditions:NO];
	[self priv_stopObservingFaceGroup:[_faceGroups lastObject]];
	
	[_faceGroups removeLastObject];
}


- (void) removeFaceGroupAtIndex:(NSUInteger)idx
{
	if (EXPECT_NOT(idx >= [_faceGroups count]))  return;
	
	[self priv_becomeDirtyWithAdditions:NO];
	[self priv_stopObservingFaceGroup:[_faceGroups objectAtIndex:idx]];
	
	[_faceGroups removeObjectAtIndex:idx];
}


- (void) replaceFaceGroupAtIndex:(NSUInteger)idx withFaceGroup:(OOAbstractFaceGroup *)faceGroup
{
	if (EXPECT_NOT(idx >= [_faceGroups count]))  return;
	
	[self priv_becomeDirtyWithAdditions:YES];
	[self priv_stopObservingFaceGroup:[_faceGroups objectAtIndex:idx]];
	[self priv_observeFaceGroup:faceGroup];
	
	[_faceGroups replaceObjectAtIndex:idx withObject:faceGroup];
}


- (NSEnumerator *) faceGroupEnumerator
{
	return [_faceGroups objectEnumerator];
}


- (NSEnumerator *) objectEnumerator
{
	return [_faceGroups objectEnumerator];
}


- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
	return [_faceGroups countByEnumeratingWithState:state objects:stackbuf count:len];
}


- (void) getVertexSchema:(NSDictionary **)outSchema homogeneous:(BOOL *)outIsHomogeneous ignoringTemporary:(BOOL)ignoringTemporary
{
	NSDictionary *mergedSchema = nil, *groupSchema = nil;
	BOOL homogeneous = YES;
	
	OOAbstractFaceGroup *group = nil;
	foreach (group, _faceGroups)
	{
		groupSchema = ignoringTemporary ? [group vertexSchemaIgnoringTemporary] : [group vertexSchema];
		homogeneous = homogeneous && [group vertexSchemaIsHomogeneous];
		if (mergedSchema == nil)  mergedSchema = groupSchema;
		else if (![groupSchema isEqualToDictionary:mergedSchema])
		{
			homogeneous = NO;
			mergedSchema = OOUnionOfSchemata(mergedSchema, groupSchema);
		}
	}
	
	if (outSchema != NULL)  *outSchema = [NSDictionary dictionaryWithDictionary:mergedSchema];
	if (outIsHomogeneous != NULL)  *outIsHomogeneous = homogeneous;
}


- (NSDictionary *) vertexSchema
{
	NSDictionary *result;
	[self getVertexSchema:&result homogeneous:NULL ignoringTemporary:NO];
	return result;
}


- (NSDictionary *) vertexSchemaIgnoringTemporary
{
	NSDictionary *result;
	[self getVertexSchema:&result homogeneous:NULL ignoringTemporary:YES];
	return result;
}


- (void) mergeMesh:(OOAbstractMesh *)other
{
	OOAbstractFaceGroup *group = nil;
	foreach (group, other)
	{
		[self addFaceGroup:group];
	}
}


- (void) uniqueVertices
{
	[self priv_uniqueVerticesGettingResults:NULL indices:NULL useCounts:NULL updatingFaces:YES];
}


- (void) getRenderMesh:(OORenderMesh **)renderMesh andMaterialSpecs:(NSArray **)materialSpecifications
{
	if (_renderMesh == nil)  [self priv_buildRenderMesh];
	
	if (renderMesh != NULL)  *renderMesh = _renderMesh;
	if (materialSpecifications != NULL)  *materialSpecifications = _materialSpecs;
}


- (void) priv_becomeDirtyWithAdditions:(BOOL)additions
{
	DESTROY(_renderMesh);
	DESTROY(_materialSpecs);
	
	// Vertices can't be de-uniqued by removing faces.
	if (additions)  _verticesAreUnique = NO;
}


- (void) priv_observeFaceGroup:(OOAbstractFaceGroup *)faceGroup
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(priv_faceGroupChanged:)
												 name:kOOAbstractFaceGroupChangedNotification
											   object:faceGroup];
}


- (void) priv_stopObservingFaceGroup:(OOAbstractFaceGroup *)faceGroup
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:kOOAbstractFaceGroupChangedNotification
												  object:faceGroup];
}


- (void) priv_faceGroupChanged:(NSNotification *)notification
{
	[self priv_becomeDirtyWithAdditions:[[notification userInfo] oo_boolForKey:kOOAbstractFaceGroupChangeIsAdditive]];
}


- (void) priv_uniqueVerticesGettingResults:(NSArray **)outVertices
								   indices:(NSDictionary **)outIndices
								 useCounts:(NSArray **)outUseCounts
							 updatingFaces:(BOOL)updatingFaces
{
	NSAutoreleasePool		*pool = [NSAutoreleasePool new];
	
	NSMutableArray			*vertices = [NSMutableArray array];
	NSMutableDictionary		*indices = [NSMutableDictionary dictionary];
	NSMutableArray			*useCounts = nil;
	NSUInteger				vertexCount = 0;
	OOAbstractFaceGroup		*faceGroup = nil;
	OOAbstractFace			*face = nil;
	
	if (_verticesAreUnique)
	{
		// updatingFaces should have no effect if _verticesAreUnique is legitimately true.
		updatingFaces = NO;
	}
	
	if (outVertices == NULL && outIndices == NULL && outUseCounts == NULL && !updatingFaces)
	{
		// Nothing to do.
		[pool drain];
		return;
	}
	
	if (outUseCounts != NULL)  useCounts = [NSMutableArray array];
	
	foreach (faceGroup, self)
	{
		NSUInteger faceIndex = 0;
		
		foreach (face, faceGroup)
		{
			NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
			
			OOAbstractVertex *faceVerts[3];
			BOOL changedVert = NO;
			[face getVertices:faceVerts];
			
			for (uint_fast8_t vIter = 0; vIter < 3; vIter++)
			{
				NSNumber *index = [indices objectForKey:faceVerts[vIter]];
				if (index == nil)
				{
					// Previously unseen vertex.
					index = [NSNumber numberWithUnsignedInteger:vertexCount++];
					[indices setObject:index forKey:faceVerts[vIter]];
					[vertices addObject:faceVerts[vIter]];
					
					if (useCounts != nil)
					{
						[useCounts addObject:[NSNumber numberWithUnsignedInteger:1]];
					}
				}
				else
				{
					// Reuse existing vertex.
					if (updatingFaces)
					{
						changedVert = YES;
						faceVerts[vIter] = [vertices objectAtIndex:[index unsignedIntegerValue]];
					}
					
					if (useCounts != nil)
					{
						NSUInteger indexVal = [index unsignedIntegerValue];
						NSUInteger useCount = [[useCounts objectAtIndex:indexVal] unsignedIntegerValue];
						useCount++;
						[useCounts replaceObjectAtIndex:indexVal withObject:[NSNumber numberWithUnsignedInteger:useCount]];
					}
				}
				
				if (changedVert)
				{
					// Apply uniqued face.
					face = [OOAbstractFace faceWithVertices:faceVerts];
					[faceGroup replaceFaceAtIndex:faceIndex withFace:face];
				}
			}
			
			[innerPool drain];
			faceIndex++;
		}
	}
	
	if (outVertices != NULL)  *outVertices = [vertices retain];
	if (outIndices != NULL)  *outIndices = [indices retain];
	if (outUseCounts != NULL)  *outUseCounts = [useCounts retain];
	
	if (updatingFaces)  _verticesAreUnique = YES;
	
	[pool drain];
	
	if (outVertices != NULL)  [*outVertices autorelease];
	if (outIndices != NULL)  [*outIndices autorelease];
	if (outUseCounts != NULL)  [*outUseCounts autorelease];
}


- (void) priv_buildRenderMesh
{
	NSArray					*vertices = nil;
	NSDictionary			*indices = nil;
	NSMutableArray			*materials = nil;
	
	DESTROY(_renderMesh);
	DESTROY(_materialSpecs);
	
	// Get uniqued vertices.
	[self priv_uniqueVerticesGettingResults:&vertices indices:&indices useCounts:NULL updatingFaces:NO];
	
	
	
	// Build material array.
	OOAbstractFaceGroup		*faceGroup = nil;
	OOMaterialSpecification	*anonMaterial = nil;
	
	materials = [NSMutableArray arrayWithCapacity:[self faceGroupCount]];
	foreach (faceGroup, self)
	{
		OOMaterialSpecification *material = [faceGroup material];
		if (material == nil)
		{
			if (anonMaterial == nil)
			{
				anonMaterial = [OOMaterialSpecification anonymousMaterial];
			}
			material = anonMaterial;
		}
		
		[materials addObject:material];
	}
	_materialSpecs = [[NSArray alloc] initWithArray:materials];
}

@end


@implementation OORenderMesh (OOAbstractMeshSupport)

- (OOAbstractMesh *) abstractMesh
{
	NSDictionary		*attributeArrays = [self attributeArrays];
	NSArray				*indexArrays = [self indexArrays];
	NSUInteger			vertexCount = [self vertexCount];
	OOAbstractMesh		*mesh = [[[OOAbstractMesh alloc] init] autorelease];
	
#ifndef NDEBUG
	[mesh setName:[self name]];
#endif
	
	OOIndexArray *indexArray = nil;
	foreach (indexArray, indexArrays)
	{
		OOAbstractFaceGroup *faceGroup = [[OOAbstractFaceGroup alloc] initWithAttributeArrays:attributeArrays
																				  vertexCount:vertexCount
																				   indexArray:indexArray];
		
		if (EXPECT_NOT(faceGroup == nil))  return nil;
		
		[mesh addFaceGroup:faceGroup];
	}
	
	return mesh;
}

@end

#endif	// OOLITE_LEAN
