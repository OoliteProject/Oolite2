/*
	OOAbstractMesh+Winding.m
	
	
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

#import "OOAbstractMesh+Winding.h"
#import "OOAbstractFaceGroupInternal.h"

#if !OOLITE_LEAN


@implementation OOAbstractMesh (Winding)

- (BOOL) reverseWinding
{
	BOOL OK = YES;
	
	[self beginBatchEdit];
	
	OOAbstractFaceGroup *group = nil;
	
	foreach (group, self)
	{
		if (![group reverseWinding])  OK = NO;
	}
	
	[self endBatchEdit];
	
	return YES;
}

@end


@implementation OOAbstractFaceGroup (Winding)

- (BOOL) reverseWinding
{
	NSMutableArray *newFaces = [[NSMutableArray alloc] initWithCapacity:[self faceCount]];
	OOAbstractFace *face = nil;
	
	foreach (face, self)
	{
		OOAbstractVertex *vertices[3];
		OOAbstractVertex *temp;
		
		[face getVertices:vertices];
		temp = vertices[0];
		vertices[0] = vertices[2];
		vertices[2] = temp;
		
		[newFaces addObject:[OOAbstractFace faceWithVertices:vertices]];
	}
	
	[self internal_replaceAllFaces:newFaces withEffects:kOOChangeInvalidatesRenderMesh];
	[newFaces release];
	
	return YES;
}

@end

#endif	// !OOLITE_LEAN
