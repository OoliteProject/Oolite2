/*
	OOAbstractVertex.m
	
	
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

#import "OOAbstractVertex.h"
#import "OOFloatArray.h"


NSString * const kOOPositionAttributeKey	= @"position";
NSString * const kOONormalAttributeKey		= @"normal";
NSString * const kOOTangentAttributeKey		= @"tangent";
NSString * const kOOTexCoordsAttributeKey	= @"texCoords";


#ifndef NDEBUG
static BOOL IsValidAttributeDictionary(NSDictionary *dict);
#else
#define IsValidAttributeDictionary(dict) 1
#endif

static id CopyAttributes(NSDictionary *attributes, id self, BOOL mutable, BOOL verify);


@interface OOAbstractVertex (Private)

// Always returns nil.
- (id) priv_subclassResponsibility:(SEL)selector;
+ (BOOL) priv_isMutableType;

@end


@interface OOConcreteVertex: OOAbstractVertex
{
@private
	NSDictionary			*_attributes;
	NSUInteger				_hash;
}

- (id) priv_initWithAttributes:(NSDictionary *)attributes verify:(BOOL)verify;

@end


@interface OOPositionOnlyVertex: OOAbstractVertex
{
@private
	Vector					_position;
}

- (id) initWithPosition:(Vector)position;

@end


@interface OOConcreteMutableVertex: OOMutableAbstractVertex
{
@private
	NSMutableDictionary		*_attributes;
	NSUInteger				_hash;
}

- (id) priv_initWithAttributes:(NSDictionary *)attributes verify:(BOOL)verify;

@end


@interface OOSingleObjectEnumerator: NSEnumerator
{
@private
	id						_object;
}

- (id) initWithObject:(id)object;

@end


static inline NSDictionary *AttributesDictFromVector(NSString *key, Vector v)
{
	return $dict(key, OOFloatArrayFromVector(v));
}


@implementation OOAbstractVertex

+ (id) vertexWithAttributes:(NSDictionary *)attributes
{
	if ([attributes count] == 0)  return [[[self alloc] init] autorelease];
	
	if ([attributes count] == 1)
	{
		NSArray *positionAttr = [attributes oo_arrayForKey:kOOPositionAttributeKey];
		if ([positionAttr count] == 3)
		{
			Vector position =
			{
				[positionAttr oo_floatAtIndex:0], [positionAttr oo_floatAtIndex:1], [positionAttr oo_floatAtIndex:2]
			};
			return [[[OOPositionOnlyVertex alloc] initWithPosition:position] autorelease];
		}
	}
	
	return [[[OOConcreteVertex alloc] priv_initWithAttributes:attributes verify:YES] autorelease];
}


+ (id) vertexWithAttribute:(OOFloatArray *)attribute forKey:(NSString *)key
{
	NSParameterAssert((attribute == nil) == (key == nil));
	if (key == nil)  return [[[self alloc] init] autorelease];
	
	if ([attribute count] == 3 && [key isEqualToString:kOOPositionAttributeKey])
	{
		Vector position =
		{
			[attribute oo_floatAtIndex:0], [attribute oo_floatAtIndex:1], [attribute oo_floatAtIndex:2]
		};
		return [[[OOPositionOnlyVertex alloc] initWithPosition:position] autorelease];
	}
	
	return [[[OOConcreteVertex alloc] priv_initWithAttributes:[NSDictionary dictionaryWithObject:attribute forKey:key] verify:NO] autorelease];
}


+ (id) vertexWithPosition:(Vector)position
{
	if (![self priv_isMutableType])
	{
		return [[[OOPositionOnlyVertex alloc] initWithPosition:position] autorelease];
	}
	else
	{
		return [self vertexWithAttributes:AttributesDictFromVector(kOOPositionAttributeKey, position)];
	}
}


// Designated initializer: -init


- (id) initWithAttributes:(NSDictionary *)attributes
{
	if ([attributes count] != 0)
	{
		DESTROY(self);
		return [[OOAbstractVertex vertexWithAttributes:attributes] retain];
	}
	else
	{
		// Plain OOAbstractVertex is OK for empty, immutable vertex.
		return [self init];
	}
}


- (id) initWithAttribute:(OOFloatArray *)attribute forKey:(NSString *)key
{
	NSParameterAssert((attribute == nil) == (key == nil));
	
	if (attribute != nil)
	{
		DESTROY(self);
		return [[OOAbstractVertex vertexWithAttribute:attribute forKey:key] retain];
	}
	else
	{
		// Plain OOAbstractVertex is OK for empty, immutable vertex.
		return [self init];
	}

}


- (NSDictionary *) allAttributes
{
	return [NSDictionary dictionary];
}


- (id) copyWithZone:(NSZone *)zone
{
	return [[OOConcreteVertex allocWithZone:zone] priv_initWithAttributes:[self allAttributes] verify:NO];
}


- (id) mutableCopyWithZone:(NSZone *)zone
{
	return [[OOConcreteMutableVertex allocWithZone:zone] priv_initWithAttributes:[self allAttributes] verify:NO];
}


- (BOOL) isEqual:(id)other
{
	if (EXPECT_NOT(![other isKindOfClass:[OOAbstractVertex class]]))  return NO;
	if ([self hash] != [other hash])  return NO;
	return [[self allAttributes] isEqual:[other allAttributes]];
}


- (NSUInteger) hash
{
	NSUInteger hash = 5381;
	
#define STIR_HASH(x)  do { hash = (hash * 33) ^ (NSUInteger)(x); } while (0)
	
	NSString *key = nil;
	foreach(key, [self allAttributeKeys])
	{
		NSUInteger keyHash = [key hash];
		STIR_HASH(keyHash);
		STIR_HASH([[self attributeForKey:key] betterHash]);
	}
	
	if (EXPECT_NOT(hash == 0))  hash = 1;
	return hash;
}

@end


@implementation OOAbstractVertex (Private)

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


@implementation OOAbstractVertex (Conveniences)

- (OOFloatArray *) attributeForKey:(NSString *)key
{
	return [[self allAttributes] objectForKey:key];
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
	return OODoubleFromArray([self attributeForKey:key]);
}


- (NSPoint) attributeAsPointForKey:(NSString *)key
{
	return OOPointFromArray([self attributeForKey:key]);
}


- (Vector2D) attributeAsVector2DForKey:(NSString *)key
{
	return OOVector2DFromArray([self attributeForKey:key]);
}


- (Vector) attributeAsVectorForKey:(NSString *)key
{
	return OOVectorFromArray([self attributeForKey:key]);
}


/*	These methods are relatively costly. I considered changing CopyAttributes
	to merge two dictionaries, which would be faster, but the duplicate
	resolution behaviour of -[NSDictionary initWithObjects:forKeys:count:] is
	not guaranteed.
	-- Ahruman 2010-05-23
*/
- (OOAbstractVertex *) vertexByAddingAttributes:(NSDictionary *)attributes
{
	NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:[self allAttributes]];
	[newAttrs addEntriesFromDictionary:attributes];
	return [OOAbstractVertex vertexWithAttributes:newAttrs];
}


- (OOAbstractVertex *) vertexByAddingAttribute:(OOFloatArray *)attribute forKey:(NSString *)key
{
	NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:[self allAttributes]];
	[newAttrs setObject:attribute forKey:key];
	return [OOAbstractVertex vertexWithAttributes:newAttrs];
}


- (OOAbstractVertex *) vertexByRemovingAttributeForKey:(NSString *)key
{
	NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:[self allAttributes]];
	[newAttrs removeObjectForKey:key];
	return [OOAbstractVertex vertexWithAttributes:newAttrs];
}


- (NSDictionary *) schema
{
	NSDictionary *attrs = [self allAttributes];
	NSMutableDictionary *schema = [NSMutableDictionary dictionaryWithCapacity:[attrs count]];
	NSString *key = nil;
	foreachkey (key, attrs)
	{
		[schema setObject:[NSNumber numberWithUnsignedInteger:[[attrs objectForKey:key] count]] forKey:key];
	}
	return schema;
}


- (BOOL) conformsToSchema:(NSDictionary *)schema
{
	NSDictionary *selfSchema = [self schema];
	NSString *attrKey = nil;
	foreachkey(attrKey, selfSchema)
	{
		if ([selfSchema oo_unsignedIntForKey:attrKey] > [schema oo_unsignedIntForKey:attrKey])  return NO;
	}
	/*	NOTE: keys in schema but not in selfSchema don’t matter, since our
		count is 0 and therefore definitely conformant.
	*/
	
	return YES;
}


- (BOOL) strictlyConformsToSchema:(NSDictionary *)schema
{
	NSDictionary *selfSchema = [self schema];
	NSString *attrKey = nil;
	foreachkey(attrKey, selfSchema)
	{
		if ([selfSchema oo_unsignedIntForKey:attrKey] != [schema oo_unsignedIntForKey:attrKey])  return NO;
	}
	
	/*	In this case, we need to check both ways. Conceptually, it might be
		cleaner to merge the sets of keys, but I don’t think it would be more
		efficient.
		-- Ahruman 2010-05-30
	*/
	foreachkey(attrKey, schema)
	{
		if ([selfSchema oo_unsignedIntForKey:attrKey] != [schema oo_unsignedIntForKey:attrKey])  return NO;
	}
	
	return YES;
}


- (OOAbstractVertex *) vertexStrictlyConformingToSchema:(NSDictionary *)schema
{
	if ([self conformsToSchema:schema])
	{
		return [[self retain] autorelease];
	}
	
	OOMutableAbstractVertex *result = [[[OOMutableAbstractVertex alloc] init] autorelease];
	NSString *attrKey = nil;
	foreachkey(attrKey, schema)
	{
		OOFloatArray *value = [self attributeForKey:attrKey];
		NSUInteger limit = [schema oo_unsignedIntegerForKey:attrKey];
		if ([value count] > limit)
		{
			value = (OOFloatArray *)[value subarrayWithRange:(NSRange){ 0, limit }];
		}
		
		[result setAttribute:value forKey:attrKey];
	}
	
	return [[result copy] autorelease];
}

@end


@implementation OOAbstractVertex (CommonAttributes)

- (Vector) position
{
	return [self attributeAsVectorForKey:kOOPositionAttributeKey];
}


- (Vector) normal
{
	return [self attributeAsVectorForKey:kOONormalAttributeKey];
}


- (Vector) tangent
{
	return [self attributeAsVectorForKey:kOOTangentAttributeKey];
}


- (Vector2D) texCoords
{
	return [self attributeAsVector2DForKey:kOOTexCoordsAttributeKey];
}


- (Vector) texCoords3D
{
	return [self attributeAsVectorForKey:kOOTexCoordsAttributeKey];
}

@end


@implementation OOConcreteVertex

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


- (NSUInteger) hash
{
	if (_hash == 0)  _hash = [super hash];
	return _hash;
}

@end


@implementation OOMutableAbstractVertex

+ (id) vertexWithAttributes:(NSDictionary *)attributes
{
	return [[[OOConcreteMutableVertex alloc] priv_initWithAttributes:attributes verify:YES] autorelease];
}


+ (id) vertexWithAttribute:(OOFloatArray *)attribute forKey:(NSString *)key
{
	NSParameterAssert((attribute == nil) == (key == nil));
	
	NSDictionary *dict = nil;
	if (key != nil)  dict = [NSDictionary dictionaryWithObject:attribute forKey:key];
	
	return [[[OOConcreteMutableVertex alloc] priv_initWithAttributes:dict verify:NO] autorelease];
}


- (id) initWithAttributes:(NSDictionary *)attributes
{
	DESTROY(self);
	return [[OOMutableAbstractVertex vertexWithAttributes:attributes] retain];
}


- (id) initWithAttribute:(OOFloatArray *)attribute forKey:(NSString *)key
{
	DESTROY(self);
	return [[OOMutableAbstractVertex vertexWithAttribute:attribute forKey:key] retain];
}


- (void) setAttribute:(OOFloatArray *)attribute forKey:(NSString *)key
{
	[self priv_subclassResponsibility:_cmd];
}


- (id) init
{
	return [self initWithAttributes:nil];
}


- (id) priv_init
{
	return [super init];
}


+ (BOOL) priv_isMutableType
{
	return YES;
}

@end


@implementation OOMutableAbstractVertex (Conveniences)

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
	[self setAttribute:OOFloatArrayFromDouble(value) forKey:key];
}


- (void) setAttributeAsPoint:(NSPoint)value forKey:(NSString *)key
{
	[self setAttribute:OOFloatArrayFromPoint(value) forKey:key];
}


- (void) setAttributeAsVector2D:(Vector2D)value forKey:(NSString *)key
{
	[self setAttribute:OOFloatArrayFromVector2D(value) forKey:key];
}


- (void) setAttributeAsVector:(Vector)value forKey:(NSString *)key
{
	[self setAttribute:OOFloatArrayFromVector(value) forKey:key];
}

@end


@implementation OOMutableAbstractVertex (CommonAttributes)

- (void) setPosition:(Vector)value
{
	[self setAttributeAsVector:value forKey:kOOPositionAttributeKey];
}


- (void) setNormal:(Vector)value
{
	[self setAttributeAsVector:value forKey:kOONormalAttributeKey];
}


- (void) setTangent:(Vector)value
{
	[self setAttributeAsVector:value forKey:kOOTangentAttributeKey];
}


- (void) setTexCoords:(Vector2D)value
{
	[self setAttributeAsVector2D:value forKey:kOOTexCoordsAttributeKey];
}


- (void) setTexCoords3D:(Vector)value
{
	[self setAttributeAsVector:value forKey:kOOTexCoordsAttributeKey];
}

@end


@implementation OOConcreteMutableVertex

- (id) priv_initWithAttributes:(NSDictionary *)attributes verify:(BOOL)verify
{
	if ((self = [super priv_init]))
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


- (void) setAttribute:(OOFloatArray *)attribute forKey:(NSString *)key
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


- (NSUInteger) hash
{
	if (_hash == 0)  _hash = [super hash];
	return _hash;
}

@end


@implementation OOPositionOnlyVertex

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
	return AttributesDictFromVector(kOOPositionAttributeKey, _position);
}


- (NSArray *) allAttributeKeys
{
	static NSArray *attributeKeys = nil;
	if (attributeKeys == nil)  attributeKeys = [$array(kOOPositionAttributeKey) retain];

	return attributeKeys;
}


- (Vector) position
{
	return _position;
}


- (Vector) attributeAsVectorForKey:(NSString *)key
{
	if ([key isEqualToString:kOOPositionAttributeKey])
	{
		return _position;
	}
	else
	{
		return kZeroVector;
	}

}


- (BOOL) conformsToSchema:(NSDictionary *)schema
{
	return [schema oo_unsignedIntForKey:kOOPositionAttributeKey] >= 3;
}


- (BOOL) strictlyConformsToSchema:(NSDictionary *)schema
{
	return [schema count] == 1 && [schema oo_unsignedIntForKey:kOOPositionAttributeKey] == 3;
}

@end


@implementation NSArray (OOAbstractVertex)

- (OOAbstractVertex *) oo_abstractVertexAtIndex:(NSUInteger)i
{
	return [self oo_objectOfClass:[OOAbstractVertex class] atIndex:i];
}

@end


@implementation OOSingleObjectEnumerator

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


static NSUInteger AttributeRank(NSString *string)
{
	if ([string isEqualToString:kOOPositionAttributeKey])  return 1;
	if ([string isEqualToString:kOONormalAttributeKey])  return 2;
	if ([string isEqualToString:kOOTangentAttributeKey])  return 3;
	if ([string isEqualToString:kOOTexCoordsAttributeKey])  return 4;
	
	return NSNotFound;
}


@implementation NSString (OOAbstractVertex)

- (NSComparisonResult) oo_compareByVertexAttributeOrder:(NSString *)other
{
	NSParameterAssert([other isKindOfClass:[NSString class]]);
	
	NSUInteger selfRank = AttributeRank(self);
	NSUInteger otherRank = AttributeRank(other);
	
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
		[NSException raise:NSInvalidArgumentException format:@"OOAbstractVertex attributes must be a dictionary whose keys are strings and whose values are arrays of numbers."];
	}
#endif
	
	/*	Deep copy attributes. The attribute arrays are always immutable, and
		the numbers themselves are inherently immutable. The mutable flag
		determines the mutability of the top-level dictionary.
		
		For small attribute sets, we work on the stack. For bigger ones, we
		need to malloc a buffer.
	*/
	NSUInteger i = 0, count = [attributes count];
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
			[NSException raise:NSMallocException format:@"Could not allocate memory for OOAbstractVertex."];
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
		values[i] = [OOFloatArray newWithArray:[attributes objectForKey:key]];
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


OOFloatArray *OOFloatArrayFromDouble(double value)
{
	return $floatarray(value);
}


OOFloatArray *OOFloatArrayFromPoint(NSPoint value)
{
	return $floatarray(value.x, value.y);
}


OOFloatArray *OOFloatArrayFromVector2D(Vector2D value)
{
	return $floatarray(value.x, value.y);
}


OOFloatArray *OOFloatArrayFromVector(Vector value)
{
	return $floatarray(value.x, value.y, value.z);
}


double OODoubleFromArray(NSArray *array)
{
	NSUInteger count = [array count];
	double result = 0;
	if (count > 0)  result = [array oo_doubleAtIndex:0];
	return result;
}


NSPoint OOPointFromArray(NSArray *array)
{
	NSUInteger count = [array count];
	NSPoint result = NSZeroPoint;
	if (count > 0)  result.x = [array oo_doubleAtIndex:0];
	if (count > 1)  result.y = [array oo_doubleAtIndex:1];
	return result;
}


Vector2D OOVector2DFromArray(NSArray *array)
{
	NSUInteger count = [array count];
	Vector2D result = kZeroVector2D;
	if (count > 0)  result.x = [array oo_floatAtIndex:0];
	if (count > 1)  result.y = [array oo_floatAtIndex:1];
	return result;
}


Vector OOVectorFromArray(NSArray *array)
{
	NSUInteger count = [array count];
	Vector result = kZeroVector;
	if (count > 0)  result.x = [array oo_floatAtIndex:0];
	if (count > 1)  result.y = [array oo_floatAtIndex:1];
	if (count > 2)  result.z = [array oo_floatAtIndex:2];
	return result;
}

#endif	// OOLITE_LEAN
