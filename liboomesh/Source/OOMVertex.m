/*
	OOMVertex.m
	liboomesh
	
	
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

#import "OOMVertex.h"
#import "OOMFloatArray.h"
#import "OOCollectionExtractors.h"
#import "CollectionUtils.h"


NSString * const kOOMPositionAttributeKey	= @"position";
NSString * const kOOMNormalAttributeKey		= @"normal";
NSString * const kOOMTangentAttributeKey	= @"tangent";
NSString * const kOOMTexCoordsAttributeKey	= @"texCoords";


#ifndef NDEBUG
static BOOL IsValidAttributeDictionary(NSDictionary *dict);
#else
#define IsValidAttributeDictionary(dict) 1
#endif

static id CopyAttributes(NSDictionary *attributes, id self, BOOL mutable, BOOL verify);


@interface OOMVertex (Private)

// Always returns nil.
- (id) priv_subclassResponsibility:(SEL)selector;
+ (BOOL) priv_isMutableType;

@end


@interface OOMConcreteVertex: OOMVertex
{
@private
	NSDictionary			*_attributes;
	OOUInteger				_hash;
}

- (id) priv_initWithAttributes:(NSDictionary *)attributes verify:(BOOL)verify;

@end


@interface OOMPositionOnlyVertex: OOMVertex
{
@private
	Vector					_position;
}

- (id) initWithPosition:(Vector)position;

@end


@interface OOMConcreteMutableVertex: OOMMutableVertex
{
@private
	NSMutableDictionary		*_attributes;
	OOUInteger				_hash;
}

- (id) priv_initWithAttributes:(NSDictionary *)attributes verify:(BOOL)verify;

@end


@interface OOMSingleObjectEnumerator: NSEnumerator
{
@private
	id						_object;
}

- (id) initWithObject:(id)object;

@end


static inline NSDictionary *AttributesDictFromVector(NSString *key, Vector v)
{
	return $dict(key, OOMArrayFromVector(v));
}


@implementation OOMVertex

+ (id) vertexWithAttributes:(NSDictionary *)attributes
{
	if ([attributes count] == 0)  return [[[self alloc] init] autorelease];
	
	if ([attributes count] == 1)
	{
		NSArray *positionAttr = [attributes oo_arrayForKey:kOOMPositionAttributeKey];
		if ([positionAttr count] == 3)
		{
			Vector position =
			{
				[positionAttr oo_floatAtIndex:0], [positionAttr oo_floatAtIndex:1], [positionAttr oo_floatAtIndex:2]
			};
			return [[[OOMPositionOnlyVertex alloc] initWithPosition:position] autorelease];
		}
	}
	
	return [[[OOMConcreteVertex alloc] priv_initWithAttributes:attributes verify:YES] autorelease];
}


+ (id) vertexWithPosition:(Vector)position
{
	if (![self priv_isMutableType])
	{
		return [[OOMPositionOnlyVertex alloc] initWithPosition:position];
	}
	else
	{
		return [self vertexWithAttributes:AttributesDictFromVector(kOOMPositionAttributeKey, position)];
	}

}


// Designated initializer: -init


- (id) initWithAttributes:(NSDictionary *)attributes
{
	if ([attributes count] != 0)
	{
		DESTROY(self);
		return [[[self class] vertexWithAttributes:attributes] retain];
	}
	else
	{
		// Plain OOMVertex is OK for empty, immutable vertex.
		return [self init];
	}
}


- (NSDictionary *) allAttributes
{
	return [NSDictionary dictionary];
}


- (id) copyWithZone:(NSZone *)zone
{
	return [[OOMVertex allocWithZone:zone] priv_initWithAttributes:[self allAttributes] verify:NO];
}


- (id) mutableCopyWithZone:(NSZone *)zone
{
	return [[OOMMutableVertex allocWithZone:zone] priv_initWithAttributes:[self allAttributes] verify:NO];
}


- (BOOL) isEqual:(id)other
{
	if (EXPECT_NOT(![other isKindOfClass:[OOMVertex class]]))  return NO;
	if ([self hash] != [other hash])  return NO;
	return [[self allAttributes] isEqual:[other allAttributes]];
}


- (OOUInteger) hash
{
#if 0
	/*	Under Mac OS X 10.6, -[NSArray hash] returns the array's count. This
		means every pair of vertices for the same mesh will have a hash
		collisions, since they'll have the same properties.
	*/
	OOUInteger hash = [[self allAttributes] hash];
#else
	/*	To avoid the problem mentioned above, manually hash taking the hashes
		of individual components into account. This hash is modified djb2 with
		xor - a string hash that has adequate behaviour in this case.
	*/
	OOUInteger hash = 5381;
	
#define STIR_HASH(x)  do { hash = (hash * 33) ^ (OOUInteger)(x); } while (0)
	
	NSString *key = nil;
	foreach(key, [self allAttributeKeys])
	{
		OOUInteger keyHash = [key hash];
		STIR_HASH(keyHash);
		
#if 0
		NSNumber *value = nil;
		foreach (value, [self attributeForKey:key])
		{
			OOUInteger valHash = [value hash];
			STIR_HASH(valHash);
		}
#else
		STIR_HASH([(OOMFloatArray *)[self attributeForKey:key] betterHash]);
#endif
	}
#endif
	if (hash == 0)  hash = 1;
	return hash;
}

@end


@implementation OOMVertex (Private)

- (id) priv_subclassResponsibility:(SEL)selector
{
	[NSException raise:NSInternalInconsistencyException format:@"%@ does not implement %@ - it is a subclass responsibility.", [self class], NSStringFromSelector(selector)];
	return nil;
}


+ (BOOL) priv_isMutableType
{
	return NO;
}

@end


@implementation OOMVertex (Conveniences)

- (NSArray *) attributeForKey:(NSString *)key
{
	return [[self allAttributes] oo_arrayForKey:key];
}


- (NSArray *) allAttributeKeys
{
	return [[self allAttributes] allKeys];
}


- (NSEnumerator *) attributeKeyEnumerator
{
	return [[self allAttributeKeys] objectEnumerator];
}


- (double) attributeAsDoubleForKey:(NSString *)key
{
	return OOMDoubleFromArray([self attributeForKey:key]);
}


- (NSPoint) attributeAsPointForKey:(NSString *)key
{
	return OOMPointFromArray([self attributeForKey:key]);
}


- (Vector2D) attributeAsVector2DForKey:(NSString *)key
{
	return OOMVector2DFromArray([self attributeForKey:key]);
}


- (Vector) attributeAsVectorForKey:(NSString *)key
{
	return OOMVectorFromArray([self attributeForKey:key]);
}


/*	These methods are relatively costly. I considered changing CopyAttributes
	to merge two dictionaries, which would be faster, but the duplucate
	resolution behaviour of -[NSDictionary initWithObjects:forKeys:count:] is
	not guaranteed.
	-- Ahruman 2010-05-23
*/
- (OOMVertex *) vertexByAddingAttributes:(NSDictionary *)attributes
{
	NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:[self allAttributes]];
	[newAttrs addEntriesFromDictionary:attributes];
	return [OOMVertex vertexWithAttributes:newAttrs];
}


- (OOMVertex *) vertexByAddingAttribute:(OOMFloatArray *)attribute forKey:(NSString *)key
{
	NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:[self allAttributes]];
	[newAttrs setObject:attribute forKey:key];
	return [OOMVertex vertexWithAttributes:newAttrs];
}


- (OOMVertex *) vertexByRemovingAttributeForKey:(NSString *)key
{
	NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:[self allAttributes]];
	[newAttrs removeObjectForKey:key];
	return [OOMVertex vertexWithAttributes:newAttrs];
}

@end


@implementation OOMVertex (CommonAttributes)

- (Vector) position
{
	return [self attributeAsVectorForKey:kOOMPositionAttributeKey];
}


- (Vector) normal
{
	return [self attributeAsVectorForKey:kOOMNormalAttributeKey];
}


- (Vector) tangent
{
	return [self attributeAsVectorForKey:kOOMTangentAttributeKey];
}


- (Vector2D) texCoords
{
	return [self attributeAsVector2DForKey:kOOMTexCoordsAttributeKey];
}


- (Vector) texCoords3D
{
	return [self attributeAsVectorForKey:kOOMTexCoordsAttributeKey];
}

@end


@implementation OOMConcreteVertex

- (id) priv_initWithAttributes:(NSDictionary *)attributes verify:(BOOL)verify
{
	if ((self = [super init]))
	{
		_attributes = CopyAttributes(attributes, self, NO, verify);
		if (_attributes == nil)  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_attributes);
	
	[super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
	// Standard immutable object optimization.
	if (NSShouldRetainWithZone(self, zone))  return [self retain];
	return [super copyWithZone:zone];
}


- (NSDictionary *) allAttributes
{
	return _attributes;
}


- (OOUInteger) hash
{
	if (_hash == 0)  _hash = [super hash];
	return _hash;
}

@end


@implementation OOMMutableVertex

+ (id) vertexWithAttributes:(NSDictionary *)attributes
{
	return [[[OOMConcreteMutableVertex alloc] priv_initWithAttributes:attributes verify:YES] retain];
}


- (id) initWithAttributes:(NSDictionary *)attributes
{
	DESTROY(self);
	return [[[self class] vertexWithAttributes:attributes] retain];
}


- (void) setAttribute:(OOMFloatArray *)attribute forKey:(NSString *)key
{
	[self priv_subclassResponsibility:_cmd];
}


+ (BOOL) priv_isMutableType
{
	return YES;
}

@end


@implementation OOMMutableVertex (Conveniences)

- (void) removeAttributeForKey:(NSString *)key
{
	[self setAttribute:nil forKey:key];
}


- (void) removeAllAttributes
{
	NSString *key = nil;
	foreach(key, [self allAttributeKeys])
	{
		[self removeAttributeForKey:key];
	}
}


- (void) setAttributeAsDouble:(double)value forKey:(NSString *)key
{
	[self setAttribute:OOMArrayFromDouble(value) forKey:key];
}


- (void) setAttributeAsPoint:(NSPoint)value forKey:(NSString *)key
{
	[self setAttribute:OOMArrayFromPoint(value) forKey:key];
}


- (void) setAttributeAsVector2D:(Vector2D)value forKey:(NSString *)key
{
	[self setAttribute:OOMArrayFromVector2D(value) forKey:key];
}


- (void) setAttributeAsVector:(Vector)value forKey:(NSString *)key
{
	[self setAttribute:OOMArrayFromVector(value) forKey:key];
}

@end


@implementation OOMMutableVertex (CommonAttributes)

- (void) setPosition:(Vector)value
{
	[self setAttributeAsVector:value forKey:kOOMPositionAttributeKey];
}


- (void) setNormal:(Vector)value
{
	[self setAttributeAsVector:value forKey:kOOMNormalAttributeKey];
}


- (void) setTangent:(Vector)value
{
	[self setAttributeAsVector:value forKey:kOOMTangentAttributeKey];
}


- (void) setTexCoords:(Vector2D)value
{
	[self setAttributeAsVector2D:value forKey:kOOMTexCoordsAttributeKey];
}


- (void) setTexCoords3D:(Vector)value
{
	[self setAttributeAsVector:value forKey:kOOMTexCoordsAttributeKey];
}

@end


@implementation OOMConcreteMutableVertex

- (id) priv_initWithAttributes:(NSDictionary *)attributes verify:(BOOL)verify
{
	if ((self = [super init]))
	{
		_attributes = CopyAttributes(attributes, self, YES, verify);
		if (_attributes == nil)  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_attributes);
	
	[super dealloc];
}


- (NSDictionary *) allAttributes
{
	return [NSMutableDictionary dictionaryWithDictionary:_attributes];
}


- (void) setAttribute:(OOMFloatArray *)attribute forKey:(NSString *)key
{
	if (EXPECT_NOT(key == nil))  return;
	_hash = 0;
	
	if (attribute != nil)
	{
		[_attributes setObject:attribute forKey:key];
	}
	else
	{
		[_attributes removeObjectForKey:key];
	}

}


- (OOUInteger) hash
{
	if (_hash == 0)  _hash = [super hash];
	return _hash;
}

@end


@implementation OOMPositionOnlyVertex

- (id) initWithPosition:(Vector)position
{
	if ((self = [super init]))
	{
		_position = position;
	}
	return self;
}


- (NSDictionary *) allAttributes
{
	return AttributesDictFromVector(kOOMPositionAttributeKey, _position);
}


- (NSArray *) allAttributeKeys
{
	static NSArray *attributeKeys = nil;
	if (attributeKeys == nil)  attributeKeys = [$array(kOOMPositionAttributeKey) retain];

	return attributeKeys;
}


- (Vector) position
{
	return _position;
}


- (Vector) attributeAsVectorForKey:(NSString *)key
{
	if ([key isEqualToString:kOOMPositionAttributeKey])
	{
		return _position;
	}
	else
	{
		return kZeroVector;
	}

}

@end


@implementation NSArray (OOMVertex)

- (OOMVertex *) oom_vertexAtIndex:(OOUInteger)i
{
	return [self oo_objectOfClass:[OOMVertex class] atIndex:i];
}

@end


@implementation OOMSingleObjectEnumerator

- (id) initWithObject:(id)object
{
	if ((self = [super init]))
	{
		_object = [object retain];
	}
	return self;
}


- (id) nextObject
{
	id result = [_object autorelease];
	_object = nil;
	return result;
}


- (NSArray *) allObjects
{
	if (_object != nil)  return [NSArray arrayWithObject:_object];
	return [NSArray array];
}

@end


static OOUInteger AttributeRank(NSString *string)
{
	if ([string isEqualToString:kOOMPositionAttributeKey])  return 1;
	if ([string isEqualToString:kOOMNormalAttributeKey])  return 2;
	if ([string isEqualToString:kOOMTangentAttributeKey])  return 3;
	if ([string isEqualToString:kOOMTexCoordsAttributeKey])  return 4;
	
	return NSNotFound;
}


@implementation NSString (OOMVertex)

- (NSComparisonResult) oom_compareByVertexAttributeOrder:(NSString *)other
{
	NSParameterAssert([other isKindOfClass:[NSString class]]);
	
	OOUInteger selfRank = AttributeRank(self);
	OOUInteger otherRank = AttributeRank(other);
	
	if (selfRank < otherRank)  return NSOrderedAscending;
	if (selfRank > otherRank)  return NSOrderedDescending;
	if (selfRank == NSNotFound)  return  [self caseInsensitiveCompare:other];
	return NSOrderedSame;
}

@end


#ifndef NDEBUG
static BOOL IsValidAttributeDictionary(NSDictionary *dict)
{
	id key = nil;
	foreach(key, [dict allKeys])
	{
		if (EXPECT_NOT(![key isKindOfClass:[NSString class]]))  return NO;
		if (EXPECT_NOT(![[dict objectForKey:key] isKindOfClass:[NSArray class]]))  return NO;
	}
	return YES;
}
#endif


static id CopyAttributes(NSDictionary *attributes, id self, BOOL mutable, BOOL verify)
{
#ifndef NDEBUG
	if (verify && !IsValidAttributeDictionary(attributes))
	{
		DESTROY(self);
		[NSException raise:NSInvalidArgumentException format:@"OOMVertex attributes must be a dictionary whose keys are strings and whose values are arrays of numbers."];
	}
#endif
	
	/*	Deep copy attributes. The attribute arrays are always immutable, and
		the numbers themselves are inherently immutable. The mutable flag
		determines the mutability of the top-level dictionary.
		
		For small attribute sets, we work on the stack. For bigger ones, we
		need to malloc a buffer.
	*/
	OOUInteger i = 0, count = [attributes count];
	enum
	{
		kStackBufSize = 8
	};
	id stackBuf[kStackBufSize * 2];
	id *keys = stackBuf, *values = stackBuf + kStackBufSize;
	
	if (count <= kStackBufSize) {} else
	{
		keys = malloc(sizeof *keys * count * 2);
		if (EXPECT_NOT(keys == NULL))
		{
			DESTROY(self);
			[NSException raise:NSMallocException format:@"Could not allocate memory for OOMVertex."];
		}
		values = keys + count;
	}
	
	/*	Performance notes:
		This is a relatively expensive function when, e.g., loading large
		files. Most of the time is spent in making floatArrays and dictionaries,
		so there's not much fat to trim.
	*/
	NSString *key;
	i = 0;
	foreach(key, [attributes allKeys])
	{
		keys[i] = key;	// NSDictionary calls copy, no need for us to do anything.
		values[i] = [OOMFloatArray newWithArray:[attributes objectForKey:key]];
		i++;
	}
	
	Class rClass = mutable ? [NSMutableDictionary class] : [NSDictionary class];
	id result = [[rClass alloc] initWithObjects:values forKeys:keys count:count];
	
	for (i = 0; i < count; i++)
	{
		[values[i] release];
	}
	
	if (keys == stackBuf) {} else free(keys);
	
	return result;
}


OOMFloatArray *OOMArrayFromDouble(double value)
{
	return $floatarray(value);
}


OOMFloatArray *OOMArrayFromPoint(NSPoint value)
{
	return $floatarray(value.x, value.y);
}


OOMFloatArray *OOMArrayFromVector2D(Vector2D value)
{
	return $floatarray(value.x, value.y);
}


OOMFloatArray *OOMArrayFromVector(Vector value)
{
	return $floatarray(value.x, value.y, value.z);
}


double OOMDoubleFromArray(NSArray *array)
{
	OOUInteger count = [array count];
	double result = 0;
	if (count > 0)  result = [array oo_doubleAtIndex:0];
	return result;
}


NSPoint OOMPointFromArray(NSArray *array)
{
	OOUInteger count = [array count];
	NSPoint result = NSZeroPoint;
	if (count > 0)  result.x = [array oo_doubleAtIndex:0];
	if (count > 1)  result.y = [array oo_doubleAtIndex:1];
	return result;
}


Vector2D OOMVector2DFromArray(NSArray *array)
{
	OOUInteger count = [array count];
	Vector2D result = kZeroVector2D;
	if (count > 0)  result.x = [array oo_floatAtIndex:0];
	if (count > 1)  result.y = [array oo_floatAtIndex:1];
	return result;
}


Vector OOMVectorFromArray(NSArray *array)
{
	OOUInteger count = [array count];
	Vector result = kZeroVector;
	if (count > 0)  result.x = [array oo_floatAtIndex:0];
	if (count > 1)  result.y = [array oo_floatAtIndex:1];
	if (count > 2)  result.z = [array oo_floatAtIndex:2];
	return result;
}
