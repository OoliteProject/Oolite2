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

#import "OOAbstractFace.h"
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


- (OOAbstractVertex *) vertexAtIndex:(NSUInteger)index
{
	if (EXPECT_NOT(index >= 3))  return nil;
	
	return _vertices[index];
}

@end
