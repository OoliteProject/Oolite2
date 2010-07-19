/*
	OOAbstractVertex.h
	
	A vertex is a collection of named attributes. Each attribute's value is a
	list of numbers.
	
	For convenience, a number of common vertex attributes are defined.
	
	OOAbstractVertex forms a class cluster with mutable and immutable variants.
	As with other mutable-copiable class clusters, OOAbstractVertex should be
	copied rather than retained when taken as a value.
	
	
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
#import "OOFloatArray.h"


@interface OOAbstractVertex: NSObject <NSCopying, NSMutableCopying>

- (NSDictionary *) allAttributes;

@end


@interface OOAbstractVertex (Creation)

+ (id) vertexWithAttributes:(NSDictionary *)attributes;
- (id) initWithAttributes:(NSDictionary *)attributes;

+ (id) vertexWithAttribute:(OOFloatArray *)attribute forKey:(NSString *)key;
- (id) initWithAttribute:(OOFloatArray *)attribute forKey:(NSString *)key;

+ (id) vertexWithPosition:(Vector)position;

@end


@interface OOAbstractVertex (Conveniences)

- (OOFloatArray *) attributeForKey:(NSString *)key;
- (NSArray *) allAttributeKeys;

- (NSEnumerator *) attributeKeyEnumerator;

//	Conveniences for attributes of one, two or three elements.
//	Undefined elements are zeroed.
- (double) attributeAsDoubleForKey:(NSString *)key;
- (NSPoint) attributeAsPointForKey:(NSString *)key;
- (Vector2D) attributeAsVector2DForKey:(NSString *)key;
- (Vector) attributeAsVectorForKey:(NSString *)key;

//	Create a new, immutable vertex by adding/removing attributes.
- (OOAbstractVertex *) vertexByAddingAttributes:(NSDictionary *)attributes;
- (OOAbstractVertex *) vertexByAddingAttribute:(OOFloatArray *)attribute forKey:(NSString *)key;
- (OOAbstractVertex *) vertexByRemovingAttributeForKey:(NSString *)key;

//	See comment on vertex schemata in OOAbstractFaceGroup.h.
- (NSDictionary *) schema;

/*	True if the vertex conforms to the specified schema. A vertex conforms if
	it doesn’t have any attributes that fall outside the schema. For instance,
	a vertex with schema { position: 3, texCoords: 2 } conforms to the schema
	{ position: 3, texCoords: 3 }, but a vertex with the schema { position: 3,
	texCoords: 3, normal: 3 } does not.
*/
- (BOOL) conformsToSchema:(NSDictionary *)schema;

//	True only if the vertex strictly matches the specified schema.
- (BOOL) strictlyConformsToSchema:(NSDictionary *)schema;

/*	Extract the attributes of a vertex that conform to the specified schema.
	This doesn’t add anything, only takes away.
*/
- (OOAbstractVertex *) vertexStrictlyConformingToSchema:(NSDictionary *)schema;

@end


@interface OOAbstractVertex (CommonAttributes)

- (Vector) position;		// kOOPositionAttributeKey
- (Vector) normal;			// kOONormalAttributeKey
- (Vector) tangent;			// kOOTangentAttributeKey
- (Vector2D) texCoords;		// kOOTexCoordsAttributeKey
- (Vector) texCoords3D;		// Also kOOTexCoordsAttributeKey

@end


@interface OOMutableAbstractVertex: OOAbstractVertex

- (void) setAttribute:(OOFloatArray *)attribute forKey:(NSString *)key;

@end


@interface OOMutableAbstractVertex (Conveniences)

- (void) removeAttributeForKey:(NSString *)key;
- (void) removeAllAttributes;

//	Conveniences for attributes of one, two or three elements.
- (void) setAttributeAsDouble:(double)value forKey:(NSString *)key;
- (void) setAttributeAsPoint:(NSPoint)value forKey:(NSString *)key;
- (void) setAttributeAsVector2D:(Vector2D)value forKey:(NSString *)key;
- (void) setAttributeAsVector:(Vector)value forKey:(NSString *)key;

@end


@interface OOMutableAbstractVertex (CommonAttributes)

- (void) setPosition:(Vector)value;		// kOOPositionAttributeKey
- (void) setNormal:(Vector)value;		// kOONormalAttributeKey
- (void) setTangent:(Vector)value;		// kOOTangentAttributeKey
- (void) setTexCoords:(Vector2D)value;	// kOOTexCoordsAttributeKey
- (void) setTexCoords3D:(Vector)value;	// Also kOOTexCoordsAttributeKey

@end


extern NSString * const kOOPositionAttributeKey;	// "position"
extern NSString * const kOONormalAttributeKey;		// "normal"
extern NSString * const kOOTangentAttributeKey;		// "tangent"
extern NSString * const kOOTexCoordsAttributeKey;	// "texCoords"


@interface NSArray (OOAbstractVertex)

- (OOAbstractVertex *) oo_abstractVertexAtIndex:(NSUInteger)i;

@end


// Convert attributes to/from more convenient representations.
OOFloatArray *OOFloatArrayFromDouble(double value);
OOFloatArray *OOFloatArrayFromPoint(NSPoint value);
OOFloatArray *OOFloatArrayFromVector2D(Vector2D value);
OOFloatArray *OOFloatArrayFromVector(Vector value);

// These will zero-fill if source is too short.
double OODoubleFromArray(NSArray *array);
NSPoint OOPointFromArray(NSArray *array);
Vector2D OOVector2DFromArray(NSArray *array);
Vector OOVectorFromArray(NSArray *array);


/*	Sort in canonical order for vertex attributes:
	position, normal, tangent, texCoords, anything else by caseInsensitiveCompare.
*/
@interface NSString (OOAbstractVertex)

- (NSComparisonResult) oo_compareByVertexAttributeOrder:(NSString *)other;

@end

#endif	// OOLITE_LEAN
