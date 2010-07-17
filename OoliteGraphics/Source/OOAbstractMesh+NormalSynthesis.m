/*
	OOAbstractMesh+NormalSynthesis.m	
	
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

#import "OOAbstractMesh+NormalSynthesis.h"
#import "OOAbstractFaceGroupInternal.h"


@interface OOAbstractFaceGroup (NormalSynthesisPrivate)

- (BOOL) priv_performNormalSynthesisSmoothly:(BOOL)smooth replacingExisting:(BOOL)replace;

@end


@implementation OOAbstractMesh (NormalSynthesis)

- (BOOL) synthesizeNormalsSmoothly:(BOOL)smooth replacingExisting:(BOOL)replace
{
	OOAbstractFaceGroup *group = nil;
	foreach (group, self)
	{
		if (![group synthesizeNormalsSmoothly:smooth replacingExisting:replace])  return NO;
	}
	
	return YES;
}

@end


@implementation OOAbstractFaceGroup (NormalSynthesis)

- (BOOL) synthesizeNormalsSmoothly:(BOOL)smooth replacingExisting:(BOOL)replace
{
	/*
		If we aren’t replacing, and normals are in the current schema, and the
		current schema is homogeneous, there’s no need to do anything.
	*/
	if (!replace && [self vertexSchemaIsHomogeneous] && [[self vertexSchema] objectForKey:kOONormalAttributeKey] != nil)
	{
		return YES;
	}
	
	/*
		If there’s an existing schema, and it’s homogeneous, normal synthesis
		will extend the schema with the normal attribute (if not present)
		while maintaining homogenity.
		If the existing schema is not homogeneous and does not contain
		normals, the new schema will add normals and still be inhomogeneous.
		If the existing schema contains normals and is not homogeneous, we
		can’t predict whether the new schema will be homogeneous, so a new
		schema will need to be built on-demand.
	*/
	BOOL manipulateSchema = NO;
	BOOL homogeneous = _homogeneous;
	if (_vertexSchema != nil)
	{
		if (homogeneous)
		{
			NSAssert(replace || [_vertexSchema objectForKey:kOONormalAttributeKey] == nil, @"Internal inconsistency in normal synthesis");
			/*
				If replace was NO, and we get here, we’re generating a new
				normal for every vertex, so the value of replace has no effect.
				In this case, YES is marginally more efficient.
			*/
			replace = YES;
			
			manipulateSchema = YES;
		}
		else if ([_vertexSchema objectForKey:kOONormalAttributeKey] == nil)
		{
			manipulateSchema = YES;
		}
	}
	NSDictionary *newSchema = nil;
	if (manipulateSchema)
	{
		NSMutableDictionary *mutableSchema = [NSMutableDictionary dictionaryWithDictionary:_vertexSchema];
		[mutableSchema setObject:[NSNumber numberWithUnsignedChar:3] forKey:kOONormalAttributeKey];
		newSchema = [mutableSchema copy];
		[newSchema autorelease];
	}
	
	if (![self priv_performNormalSynthesisSmoothly:smooth replacingExisting:replace])  return NO;
	
	// Apply schema manipulation if appropriate.
	DESTROY(_vertexSchema);
	if (manipulateSchema)
	{
		_vertexSchema = [newSchema retain];
		_homogeneous = homogeneous;
	}
	else
	{
		_homogeneous = NO;
	}
	
	return YES;
}

@end


OOINLINE void CalculateFaceNormals(NSArray *faces, Vector *faceNormals, NSMapTable *vertexMap)
{
	NSCParameterAssert(faces != nil && faceNormals != NULL);
	
	NSUInteger fIter, vIter, fCount = [faces count];
	
	/*
		Calculate area-weighted normal of each triangle, and map each vertex
		to the faces it adjoins (if smoothing).
	*/
	for (fIter = 0; fIter < fCount; fIter++)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		OOAbstractFace *face = [faces objectAtIndex:fIter];
		OOAbstractVertex *vertices[3];
		[face getVertices:vertices];
		
		Vector positions[3];
		NSNumber *faceIndex = nil;
		if (vertexMap != nil)  faceIndex = [NSNumber numberWithUnsignedInteger:fIter];
		
		for (vIter = 0; vIter < 3; vIter++)
		{
			positions[vIter] = [vertices[vIter] position];
			
			if (vertexMap != nil)
			{
				NSMutableArray *faceList = NSMapGet(vertexMap, vertices[vIter]);
				if (faceList == nil)
				{
					faceList = [[NSMutableArray alloc] init];
					NSMapInsertKnownAbsent(vertexMap, vertices[vIter], faceList);
					[faceList release];
				}
				[faceList addObject:faceIndex];
			}
		}
		
		/*
			The cross product of two vectors is normal to both of them and has
			the area of the parallelogram they span. Hence, the cross product
			of two sides of the triangle is a normal whose magnitude is twice
			the area of the triangle. Since we only use the area as a weight,
			the factor 2 can be ignored.
		*/
		Vector AB = vector_subtract(positions[1], positions[0]);
		Vector AC = vector_subtract(positions[2], positions[0]);
		faceNormals[fIter] = true_cross_product(AB, AC);
		
		[pool drain];
	}
}


OOINLINE NSMutableArray *ApplySmoothNormals(NSArray *faces, Vector *faceNormals, NSMapTable *vertexMap, BOOL replace)
{
	NSUInteger fIter, fCount, vIter, vCount = NSCountMapTable(vertexMap);
	
	/*
		Convert vertexMap from vertex->face mapping to vertex->new vertex mapping.
	*/
	NSArray *vertices = NSAllMapTableKeys(vertexMap);
	for (vIter = 0; vIter < vCount; vIter++)
	{
		OOAbstractVertex *oldVertex = [vertices objectAtIndex:vIter];
		if (!replace && [oldVertex attributeForKey:kOONormalAttributeKey] != nil)  continue;
		
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		Vector normal = kZeroVector;
		NSArray *faces = NSMapGet(vertexMap, oldVertex);
		
		fCount = [faces count];
		for (fIter = 0; fIter < fCount; fIter++)
		{
			NSUInteger fIndex = [[faces objectAtIndex:fIter] unsignedIntegerValue];
			normal = vector_add(normal, faceNormals[fIndex]);
		}
		
		normal = vector_normal(normal);
		
		OOMutableAbstractVertex *newVertex = [oldVertex mutableCopy];
		[newVertex setNormal:normal];
		NSMapInsert(vertexMap, oldVertex, [[newVertex copy] autorelease]);
		[newVertex release];
		
		[pool drain];
	}
	
	/*
		Replace all faces using the new vertices.
	*/
	fCount = [faces count];
	NSMutableArray *newFaces = [NSMutableArray arrayWithCapacity:fCount];
	for (fIter = 0; fIter < fCount; fIter++)
	{
		OOAbstractFace *face = [faces objectAtIndex:fIter];
		OOAbstractVertex *vertices[3];
		[face getVertices:vertices];
		
		for (vIter = 0; vIter < 3; vIter++)
		{
			vertices[vIter] = NSMapGet(vertexMap, vertices[vIter]);
		}
		
		[newFaces addObject:[OOAbstractFace faceWithVertices:vertices]];
	}
	
	return newFaces;
}


OOINLINE NSMutableArray *ApplyFlatNormals(NSArray *faces, Vector *faceNormals, BOOL replace)
{
	NSUInteger fIter, fCount = [faces count], vIter;
	NSMutableArray *newFaces = [NSMutableArray arrayWithCapacity:fCount];
	for (fIter = 0; fIter < fCount; fIter++)
	{
		OOAbstractFace *face = [faces objectAtIndex:fIter];
		OOAbstractVertex *vertices[3];
		[face getVertices:vertices];
		BOOL changedAny = NO;
		Vector normal = vector_normal(faceNormals[fIter]);
		
		for (vIter = 0; vIter < 3; vIter++)
		{
			if (replace || [vertices[vIter] attributeForKey:kOONormalAttributeKey] == nil)
			{
				OOMutableAbstractVertex *mv = [vertices[vIter] mutableCopy];
				[mv setNormal:normal];
				vertices[vIter] = [[mv copy] autorelease];
				[mv release];
				changedAny = YES;
			}
		}
		
		if (changedAny)
		{
			[newFaces addObject:[OOAbstractFace faceWithVertices:vertices]];
		}
		else
		{
			[newFaces addObject:face];
		}
	}
	
	return newFaces;
}


@implementation OOAbstractFaceGroup (NormalSynthesisPrivate)

- (BOOL) priv_performNormalSynthesisSmoothly:(BOOL)smooth replacingExisting:(BOOL)replace
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	BOOL success = NO;
	NSUInteger fCount = [_faces count];
	
	Vector *faceNormals = malloc(sizeof (Vector) * fCount);
	if (faceNormals != NULL)
	{
		NSMapTable *vertexMap = nil;
		if (smooth)
		{
			// NOTE: uses a map table rather than a dictionary to avoid copying, which could mess with results.
			vertexMap = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, fCount * 3);
		}
		
		if (!smooth || vertexMap != NULL)
		{
			CalculateFaceNormals(_faces, faceNormals, vertexMap);
			
			NSMutableArray *newFaces = nil;
			if (smooth)
			{
				newFaces = ApplySmoothNormals(_faces, faceNormals, vertexMap, replace);
			}
			else
			{
				newFaces = ApplyFlatNormals(_faces, faceNormals, replace);
			}
			[_faces release];
			_faces = [newFaces retain];
			
			[self internal_becomeDirtyWithAdditions:!smooth];
			
			success = YES;
		}
		if (vertexMap != NULL)  NSFreeMapTable(vertexMap);
	}
	free(faceNormals);
	
	[pool drain];
	return success;
}

@end
