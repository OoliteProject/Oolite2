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
#import "OOCollectionExtractors.h"
#import "CollectionUtils.h"


NSString * const kOOMPositionAttributeKey	= @"aPosition";
NSString * const kOOMNormalAttributeKey		= @"aNormal";
NSString * const kOOMTangentAttributeKey	= @"aTangent";
NSString * const kOOMTexCoordsAttributeKey	= @"aTexCoords";


static BOOL IsValidAttribute(NSArray *attr);
static BOOL IsValidAttributeDictionary(NSDictionary *dict);
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


static NSDictionary *AttributesDictFromVector(NSString *key, Vector v)
{
	return $dict(key, OOMArrayFromVector(v));
}


@implementation OOMVertex

+ (id) vertexWithAttributes:(NSDictionary *)attributes
{
	if ([attributes count] == 0)  return [[[self alloc] init] autorelease];
	
	if ([attributes count] == 1)
	{
		NSArray *positionAttr = [attributes objectForKey:kOOMPositionAttributeKey];
		if ([positionAttr count] == 3 && IsValidAttribute(positionAttr))
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


OOUInteger gHashCollisions = 0;

- (BOOL) isEqual:(id)other
{
	if (EXPECT_NOT(![other isKindOfClass:[OOMVertex class]]))  return NO;
	if ([self hash] != [other hash])  return NO;
	BOOL result = [[self allAttributes] isEqual:[other allAttributes]];
	if (!result)  gHashCollisions++;
	return result;
}


- (OOUInteger) hash
{
#if 0
	OOUInteger hash = [[self allAttributes] hash];
#else
	OOUInteger hash = 5381;
	
#define HASH_BITS (sizeof hash * CHAR_BIT)
#define STIR_HASH(x)  do { hash = (hash * 33) ^ (OOUInteger)(x); } while (0)
	
	NSString *key = nil;
	foreach(key, [self allAttributeKeys])
	{
		OOUInteger keyHash = [key hash];
		STIR_HASH(keyHash);
#if 0
		OOUInteger valHash = [[self attributeForKey:key] hash];
		STIR_HASH(valHash);
#else
		NSNumber *value = nil;
		foreach (value, [self attributeForKey:key])
		{
			OOUInteger valHash = [value hash];
			STIR_HASH(valHash);
		}
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


- (OOMVertex *) vertexByAddingAttributes:(NSDictionary *)attributes
{
	NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:[self allAttributes]];
	[newAttrs addEntriesFromDictionary:attributes];
	return [OOMVertex vertexWithAttributes:newAttrs];
}


- (OOMVertex *) vertexByAddingAttribute:(NSArray *)attribute forKey:(NSString *)key
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


- (void) setAttribute:(NSArray *)attribute forKey:(NSString *)key
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


- (void) setAttribute:(NSArray *)attribute forKey:(NSString *)key
{
	if (EXPECT_NOT(key == nil))  return;
	_hash = 0;
	
	if (attribute != nil)
	{
		if (IsValidAttribute(attribute))
		{
			[_attributes setObject:attribute forKey:key];
		}
		else
		{
			[NSException raise:NSInvalidArgumentException format:@"OOMVertex attributes must be a dictionary whose keys are strings and whose values are arrays of numbers."];
		}

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


static BOOL IsValidAttribute(NSArray *attr)
{
	if (attr == nil)  return NO;
	
	id value = nil;
	foreach(value, attr)
	{
		if (EXPECT_NOT(![value isKindOfClass:[NSNumber class]]))  return NO;
	}
	
	return YES;
}


static BOOL IsValidAttributeDictionary(NSDictionary *dict)
{
	id key = nil;
	foreach(key, [dict allKeys])
	{
		if (EXPECT_NOT(![key isKindOfClass:[NSString class]]))  return NO;
		if (EXPECT_NOT(!IsValidAttribute([dict oo_arrayForKey:key])))  return NO;
	}
	return YES;
}


static id CopyAttributes(NSDictionary *attributes, id self, BOOL mutable, BOOL verify)
{
	if (verify && !IsValidAttributeDictionary(attributes))
	{
		DESTROY(self);
		[NSException raise:NSInvalidArgumentException format:@"OOMVertex attributes must be a dictionary whose keys are strings and whose values are arrays of numbers."];
	}
	
	/*	Deep copy attributes. The attribute arrays are always immutable, and
		the numbers themselves are inherently immutable. The mutable flag
		determines the mutability of the top-level dictionary.
	*/
	OOUInteger i = 0, count = [attributes count];
	id *keys = malloc(sizeof *keys * count);
	id *values = malloc(sizeof *values * count);
	if (keys == NULL || values == NULL)
	{
		DESTROY(self);
		free(keys);
		free(values);
		[NSException raise:NSMallocException format:@"Could not allocate memory for OOMVertex."];
	}
	
	NSString *key = nil;
	i = 0;
	foreach(key, [attributes allKeys])
	{
		keys[i] = [key copy];
		values[i] = [NSArray arrayWithArray:[attributes objectForKey:key]];
		i++;
	}
	
	id result = [[(mutable ? [NSMutableDictionary class] : [NSDictionary class]) alloc] initWithObjects:values forKeys:keys count:count];
	
	for (i = 0; i < count; i++)
	{
		[keys[i] release];
	}
	free(keys);
	free(values);
	
	return result;
}


NSArray *OOMArrayFromDouble(double value)
{
	return $array($float(value));
}


NSArray *OOMArrayFromPoint(NSPoint value)
{
	return $array($float(value.x), $float(value.y));
}


NSArray *OOMArrayFromVector2D(Vector2D value)
{
	return $array($float(value.x), $float(value.y));
}


NSArray *OOMArrayFromVector(Vector value)
{
	return $array($float(value.x), $float(value.y), $float(value.z));
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
