/*
	OOAbstractFaceGroup.h
	
	A face group represents a list of faces to be drawn with the same state.
	In rendering terms, it corresponds to an element array, while the state
	is specified by a material.
	
	
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

#import <OOBase/OOBase.h>

@class OOAbstractFace, OOMaterialSpecification, OOIndexArray;


@interface OOAbstractFaceGroup: NSObject <NSFastEnumeration, NSCopying>
{
@private
	NSString					*_name;
	NSMutableArray				*_faces;
	OOMaterialSpecification		*_material;
	NSDictionary				*_vertexSchema;
	BOOL						_homogeneous;
}

- (id) init;

/*
	Fast initializer for data in rendering-optimized format.
	attributeArray: dictionary of NSString->OOFloatArray. Array counts must be
		multiples of vertexCount; the ratio defines the attribute size.
	indexArray: indices into attribute arrays. Values must be less than
		vertexCount. Count must be multiple of three.
*/
- (id) initWithAttributeArrays:(NSDictionary *)attributeArrays
				   vertexCount:(NSUInteger)vertexCount
					indexArray:(OOIndexArray *)indexArray;

- (NSString *) name;
- (void) setName:(NSString *)name;

- (OOMaterialSpecification *) material;
- (void) setMaterial:(OOMaterialSpecification *)material;

- (NSUInteger) faceCount;

- (OOAbstractFace *) faceAtIndex:(NSUInteger)index;

- (void) addFace:(OOAbstractFace *)face;
- (void) insertFace:(OOAbstractFace *)face atIndex:(NSUInteger)index;
- (void) removeLastFace;
- (void) removeFaceAtIndex:(NSUInteger)index;
- (void) replaceFaceAtIndex:(NSUInteger)index withFace:(OOAbstractFace *)face;

- (NSEnumerator *) faceEnumerator;
- (NSEnumerator *) objectEnumerator;	// Same as faceEnumerator, only less descriptive.

/*
	The vertex schema is a dictionary whose keys are attribute names and whose
	values are numbers (sizes). This specifies the maximum size for any
	attribute across all vertices.
	A vertex schema is homogeneous if all vertices fulfill the schema
	completely.
*/
- (NSDictionary *) vertexSchema;
- (BOOL) vertexSchemaIsHomogeneous;

@end


NSDictionary *OOUnionOfSchemata(NSDictionary *a, NSDictionary *b);
