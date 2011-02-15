/*
	OORenderMesh.h
	
	A render mesh is a mesh representation optimized for rendering.
	
	A render mesh can contain arbitrary attribute arrays and any number of
	groups. Each group is an index array which is rendered with a specific
	material.
	
	The materials for each group are specified at render time, so the data can
	be shared between entities using different materials. Materials’ shaders
	must have attributes bound in accordance with the render mesh’s wishes.
	
	Since the attribute arrays are shared, all groups must have the same
	vertex schema.
	
	
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

#import "OOFloatArray.h"
#import "OOIndexArray.h"
#import "OOOpenGL.h"


@interface OORenderMesh: NSObject
{
@private
#ifndef NDEBUG
	NSString					*_name;
#endif
	
	GLuint						_attributeCount;
	GLuint						_groupCount;
	
	OOFloatArray				**_attributeArrays;
	GLuint						*_attributeSizes;
	NSArray						*_attributeNames;
	NSDictionary				*_attributeIndices; // String->integer
	GLuint						*_attributeVBOs;
	GLuint						*_elementVBOs;
	
	OOIndexArray				**_groups;
	
	GLuint						_vertexArrayObject;
}

- (id) initWithName:(NSString *)name vertexCount:(NSUInteger)vertexCount attributes:(NSDictionary *)attributes groups:(NSArray *)groups;

- (NSUInteger) attributeIndexForKey:(NSString *)key;
- (OOFloatArray *) attributeArrayForKey:(NSString *)key;
- (NSUInteger) attributeSizeForKey:(NSString *)key;

- (void) renderWithMaterials:(NSArray *)materials;

- (NSDictionary *) attributeArrays;
- (NSArray *) indexArrays;
- (NSDictionary *) attributeIndices;
- (NSDictionary *) prefixedAttributeIndices;	// Converts "attribute" to "aAttribute".
- (NSUInteger) vertexCount;

#ifndef NDEBUG
- (NSString *) name;
#endif

@end
