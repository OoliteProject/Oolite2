/*	
	OOAbstractFace.h
	
	A face is simply a collection of three vertices. All other attributes
	depend on context.
	
	An OOAbstractFace is immutable, as are its vertices.
	
	
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

#import <OoliteBase/OoliteBase.h>
#import "OOAbstractVertex.h"


@interface OOAbstractFace: NSObject <NSCopying>
{
@private
	OOAbstractVertex			*_vertices[3];
}

+ (id) faceWithVertex0:(OOAbstractVertex *)vertex0
			   vertex1:(OOAbstractVertex *)vertex1
			   vertex2:(OOAbstractVertex *)vertex2;
+ (id) faceWithVertices:(OOAbstractVertex *[3])vertices;

- (id) initWithVertex0:(OOAbstractVertex *)vertex0
			   vertex1:(OOAbstractVertex *)vertex1
			   vertex2:(OOAbstractVertex *)vertex2;
- (id) initWithVertices:(OOAbstractVertex *[3])vertices;

- (OOAbstractVertex *) vertexAtIndex:(NSUInteger)index;
- (void) getVertices:(OOAbstractVertex *[3])vertices;

- (NSDictionary *) schema;

- (BOOL) conformsToSchema:(NSDictionary *)schema;
- (BOOL) strictlyConformsToSchema:(NSDictionary *)schema;

- (OOAbstractFace *) faceStrictlyConformingToSchema:(NSDictionary *)schema;

@end

#endif	// OOLITE_LEAN
