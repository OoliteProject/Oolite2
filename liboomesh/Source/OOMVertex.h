/*
	OOMVertex.h
	liboomesh
	
	A vertex is a collection of named attributes. Each attribute's value is a
	list of numbers.
	
	For convenience, a number of common vertex attributes are defined.
	
	OOMVertex forms a class cluster with mutable and immutable variants. As
	with other mutable-copiable class clusters, OOMVertex should be copied
	rather than retained when taken as a value.
	
	
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

#import "liboomeshbase.h"


@interface OOMVertex: NSObject <NSCopying, NSMutableCopying>

- (NSDictionary *) allAttributes;

@end


@interface OOMVertex (Creation)

+ (id) vertexWithAttributes:(NSDictionary *)attributes;
- (id) initWithAttributes:(NSDictionary *)attributes;

+ (id) vertexWithPosition:(Vector)position;

@end


@interface OOMVertex (Conveniences)

- (NSArray *) attributeForKey:(NSString *)key;
- (NSArray *) allAttributeKeys;

- (NSEnumerator *) attributeKeyEnumerator;

// Conveniences for attributes of one, two or three elements.
// Undefined elements are zeroed.
- (double) attributeAsDoubleForKey:(NSString *)key;
- (NSPoint) attributeAsPointForKey:(NSString *)key;
- (Vector2D) attributeAsVector2DForKey:(NSString *)key;
- (Vector) attributeAsVectorForKey:(NSString *)key;

// Create a new, immutable vertex by adding/removing attributes.
- (OOMVertex *) vertexByAddingAttributes:(NSDictionary *)attributes;
- (OOMVertex *) vertexByAddingAttribute:(NSArray *)attribute forKey:(NSString *)key;
- (OOMVertex *) vertexByRemovingAttributeForKey:(NSString *)key;


@end


@interface OOMVertex (CommonAttributes)

- (Vector) position;		// kOOMPositionAttributeKey
- (Vector) normal;			// kOOMNormalAttributeKey
- (Vector) tangent;			// kOOMTangentAttributeKey
- (Vector2D) texCoords;		// kOOMTexCoordsAttributeKey
- (Vector) texCoords3D;		// Also kOOMTexCoordsAttributeKey

@end


@interface OOMMutableVertex: OOMVertex

- (void) setAttribute:(NSArray *)attribute forKey:(NSString *)key;

@end


@interface OOMMutableVertex (Conveniences)

- (void) removeAttributeForKey:(NSString *)key;
- (void) removeAllAttributes;

// Conveniences for attributes of one, two or three elements.
- (void) setAttributeAsDouble:(double)value forKey:(NSString *)key;
- (void) setAttributeAsPoint:(NSPoint)value forKey:(NSString *)key;
- (void) setAttributeAsVector2D:(Vector2D)value forKey:(NSString *)key;
- (void) setAttributeAsVector:(Vector)value forKey:(NSString *)key;

@end


@interface OOMMutableVertex (CommonAttributes)

- (void) setPosition:(Vector)value;		// kOOMPositionAttributeKey
- (void) setNormal:(Vector)value;		// kOOMNormalAttributeKey
- (void) setTangent:(Vector)value;		// kOOMTangentAttributeKey
- (void) setTexCoords:(Vector2D)value;	// kOOMTexCoordsAttributeKey
- (void) setTexCoords3D:(Vector)value;	// Also kOOMTexCoordsAttributeKey

@end


extern NSString * const kOOMPositionAttributeKey;	// "aPosition"
extern NSString * const kOOMNormalAttributeKey;		// "aNormal"
extern NSString * const kOOMTangentAttributeKey;	// "aTangent"
extern NSString * const kOOMTexCoordsAttributeKey;	// "aTexCoords"


@interface NSArray (OOMVertex)

- (OOMVertex *) oom_vertexAtIndex:(OOUInteger)i;

@end


// Convert attributes to/from more convenient representations.
NSArray *OOMArrayFromDouble(double value);
NSArray *OOMArrayFromPoint(NSPoint value);
NSArray *OOMArrayFromVector2D(Vector2D value);
NSArray *OOMArrayFromVector(Vector value);

// These will zero-fill if source is too short.
double OOMDoubleFromArray(NSArray *array);
NSPoint OOMPointFromArray(NSArray *array);
Vector2D OOMVector2DFromArray(NSArray *array);
Vector OOMVectorFromArray(NSArray *array);
