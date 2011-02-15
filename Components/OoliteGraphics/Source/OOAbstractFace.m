/*
	OOAbstractFace.m
	
	A face is simply a collection of three vertices. All other attributes
	depend on context.
	
	
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

#import "OOAbstractFace.h"
#import "OOAbstractFaceGroup.h"
#import "OOAbstractVertex.h"


@implementation OOAbstractFace

+ (id) faceWithVertex0:(OOAbstractVertex *)vertex0 vertex1:(OOAbstractVertex *)vertex1 vertex2:(OOAbstractVertex *)vertex2
{
	return [[[self alloc] initWithVertex0:vertex0 vertex1:vertex1 vertex2:vertex2] autorelease];
}


+ (id) faceWithVertices:(OOAbstractVertex *[3])vertices
{
	return [[[self alloc] initWithVertices:vertices] autorelease];
}

- (id) initWithVertex0:(OOAbstractVertex *)vertex0 vertex1:(OOAbstractVertex *)vertex1 vertex2:(OOAbstractVertex *)vertex2
{
	if ((self = [super init]))
	{
		_vertices[0] = vertex0 ? [vertex0 copy] : [OOAbstractVertex new];
		_vertices[1] = vertex1 ? [vertex1 copy] : [OOAbstractVertex new];
		_vertices[2] = vertex2 ? [vertex2 copy] : [OOAbstractVertex new];
	}
	return self;
}


- (id) initWithVertices:(OOAbstractVertex *[3])vertices
{
	NSParameterAssert(vertices != NULL);
	return [self initWithVertex0:vertices[0] vertex1:vertices[1] vertex2:vertices[2]];
}


- (void) dealloc
{
	DESTROY(_vertices[0]);
	DESTROY(_vertices[1]);
	DESTROY(_vertices[2]);
	
	[super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
	// Immutable.
	return [self retain];
}


- (OOAbstractVertex *) vertexAtIndex:(NSUInteger)index
{
	NSParameterAssert(index < 3);
	
	return _vertices[index];
}


- (void) getVertices:(OOAbstractVertex *[3])vertices
{
	NSParameterAssert(&vertices[0] != NULL);
	
	vertices[0] = _vertices[0];
	vertices[1] = _vertices[1];
	vertices[2] = _vertices[2];
}

- (NSDictionary *) schema
{
	return OOUnionOfSchemata([_vertices[0] schema], OOUnionOfSchemata([_vertices[1] schema], [_vertices[2] schema]));
}


- (BOOL) conformsToSchema:(NSDictionary *)schema
{
	return [_vertices[0] conformsToSchema:schema] && [_vertices[1] conformsToSchema:schema] && [_vertices[2] conformsToSchema:schema];
}


- (BOOL) strictlyConformsToSchema:(NSDictionary *)schema
{
	return [_vertices[0] strictlyConformsToSchema:schema] && [_vertices[1] strictlyConformsToSchema:schema] && [_vertices[2] strictlyConformsToSchema:schema];
}


- (OOAbstractFace *) faceStrictlyConformingToSchema:(NSDictionary *)schema
{
	OOAbstractVertex *vertices[3];
	vertices[0] = [_vertices[0] vertexStrictlyConformingToSchema:schema];
	vertices[1] = [_vertices[1] vertexStrictlyConformingToSchema:schema];
	vertices[2] = [_vertices[2] vertexStrictlyConformingToSchema:schema];
	
	if (vertices[0] != _vertices[0] ||
		vertices[1] != _vertices[1] ||
		vertices[2] != _vertices[2])
	{
		return [OOAbstractFace faceWithVertices:vertices];
	}
	else
	{
		return self;
	}
}

@end

#endif	// OOLITE_LEAN
