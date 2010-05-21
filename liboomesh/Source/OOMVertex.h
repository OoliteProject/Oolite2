/*	OOMVertex.h
	liboomesh
	
	A vertex is a collection of named attributes. Each attribute's value is a
	list of numbers.
	
	For convenience, a number of common vertex attributes are defined.
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

// Conveniences for attributes of one, two or three elements.
// Undefined elements are zeroed.
- (double) attributeAsDoubleForKey:(NSString *)key;
- (NSPoint) attributeAsPointForKey:(NSString *)key;
- (Vector2D) attributeAsVector2DForKey:(NSString *)key;
- (Vector) attributeAsVectorForKey:(NSString *)key;

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

