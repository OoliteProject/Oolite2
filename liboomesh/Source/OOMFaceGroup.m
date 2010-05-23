/*
	OOMFaceGroup.m
	liboomesh
	
	A face group represents a list of faces to be drawn with the same state.
	In rendering terms, it corresponds to an element array.
	
	
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

#import "OOMFaceGroup.h"
#import "OOMFace.h"


@implementation OOMFaceGroup

- (id) init
{
	if ((self = [super init]))
	{
		_faces = [[NSMutableArray alloc] init];
		if (_faces == nil)  DESTROY(self);
	}
	return self;
}


- (void) dealloc
{
	[_faces release];
	
	[super dealloc];
}


- (NSString *) name
{
	return _name;
}


- (void) setName:(NSString *)name
{
	[_name autorelease];
	_name = [name copy];
}


- (OOMMaterialSpecification *) material
{
	return _material;
}


- (void) setMaterial:(OOMMaterialSpecification *)material
{
	[_material autorelease];
	_material = [material retain];
}


- (OOUInteger) faceCount
{
	return [_faces count];
}


- (OOMFace *) faceAtIndex:(OOUInteger)index
{
	return [_faces objectAtIndex:index];
}


- (void) addFace:(OOMFace *)face
{
	[_faces addObject:face];
}


- (void) insertFace:(OOMFace *)face atIndex:(OOUInteger)index
{
	[_faces insertObject:face atIndex:index];
}


- (void) removeLastFace
{
	[_faces removeLastObject];
}


- (void) removeFaceAtIndex:(OOUInteger)index
{
	[_faces removeObjectAtIndex:index];
}


- (void) replaceFaceAtIndex:(OOUInteger)index withFace:(OOMFace *)face
{
	[_faces replaceObjectAtIndex:index withObject:face];
}


- (NSEnumerator *) faceEnumerator
{
	return [_faces objectEnumerator];
}


- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
	return [_faces countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
