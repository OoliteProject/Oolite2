/*
	OOFloatArray.m
	
	
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
#import "OOCollectionExtractors.h"
#import "CollectionUtils.h"


typedef uint32_t FloatSizedInt;


@interface OOFloatArray (Private)

- (BOOL) priv_isEqualToOOMFloatArray:(OOFloatArray *)other;

//	Subclass responsibility:
- (float *) priv_floatArray;

@end


enum
{
	/*
		Largest count for which we will use OOMInlineFloatArray.
		This should be quite low when using garbage collection, because the
		entire object is scanned for pointers.
		Without GC, there's no particular reason to limit it (except that on
		64-bit systems, the use of FloatSizedInt as _count is a concern).
		Since there's no feature macro for garbage collection mode
		(thanks, Apple!) I'm going the conservative route.
		-- Ahruman 2010-05-26
	*/
	kMaxInlineCount				= 30,
	
	// Smallest count for which we will use OOMExternFloatArray.
	kMinExternCount				= 8
};


/*	
	OOMInlineFloatArray
	Concrete OOFloatArray which uses object_getIndexedIvars() as storage.
*/
@interface OOMInlineFloatArray: OOFloatArray
{
@private
	FloatSizedInt				_count;
}

// Create a new array with allocated space and count but no values filled in.
+ (id) priv_newWithCapacity:(NSUInteger)count;
+ (id) priv_newWithFloats:(float *)values count:(NSUInteger)count;

@end


@interface OOMExternFloatArray: OOFloatArray
{
	NSUInteger					_freeWhenDone: 1,
								_count: ((sizeof (NSUInteger) * CHAR_BIT) - 1);
	float						*_floats;
}

// Create a new array with allocated space and count but no values filled in.
+ (id) priv_newWithCapacity:(NSUInteger)count;
- (id) priv_initWithFloatsNoCopy:(float *)values count:(NSUInteger)count freeWhenDone:(BOOL)freeWhenDone;

@end


@implementation OOFloatArray

#ifndef NS_BLOCK_ASSERTIONS
+ (void) initialize
{
	NSAssert(sizeof(FloatSizedInt) == sizeof(uint32_t), @"OOFloatArray: FloatSizedInt is not defined appropriately.");
}
#endif


// Choose a class for arrays that aren't NoCopy.
static inline Class ClassForNormalArrayOfSize(OOUInteger size)
{
	return (size <= kMaxInlineCount) ? [OOMInlineFloatArray class] : [OOMExternFloatArray class];
}


+ (id) newWithArray:(NSArray *)array
{
	if (array == nil)  return [OOMInlineFloatArray priv_newWithFloats:nil count:0];
	if ([array isKindOfClass:[OOFloatArray class]])  return [array copy];
	
	NSUInteger i, count = [array count];
	Class rClass = ClassForNormalArrayOfSize(count);
	OOFloatArray *result = [rClass priv_newWithCapacity:count];
	
	if (result != nil)
	{
		float *next = [result priv_floatArray];
		for (i = 0; i < count; i++)
		{
			*next++ = [array oo_floatAtIndex:i];
		}
	}
	
	return result;
}


+ (id) array
{
	return [self newWithFloats:NULL count:0];
}


+ (id) arrayWithArray:(NSArray *)array
{
	OOFloatArray *result = [OOFloatArray newWithArray:array];
	[result autorelease];
	return result;
}


- (id) initWithArray:(NSArray *)array
{
	[self release];
	return [OOFloatArray newWithArray:array];
}


+ (id) newWithFloats:(float *)values count:(NSUInteger)count
{
	NSParameterAssert(values != NULL || count == 0);
	
	Class rClass = ClassForNormalArrayOfSize(count);
	return [rClass priv_newWithFloats:values count:count];
}


+ (id) arrayWithFloats:(float *)values count:(NSUInteger)count
{
	return [[OOMInlineFloatArray priv_newWithFloats:values count:count] autorelease];
}


- (id) initWithFloats:(float *)values count:(NSUInteger)count
{
	[self release];
	return [[self class] priv_newWithFloats:(float *)values count:count];
}


+ (id) newWithFloatsNoCopy:(float *)values count:(NSUInteger)count freeWhenDone:(BOOL)freeWhenDone
{
	NSParameterAssert(values != NULL || count == 0);
	
	OOFloatArray *result = nil;
	
	if (count > kMinExternCount)
	{
		result = [[OOMExternFloatArray alloc] priv_initWithFloatsNoCopy:values count:count freeWhenDone:freeWhenDone];
	}
	else
	{
		result = [self newWithFloats:values count:count];
		if (freeWhenDone)  free(values);
	}
	return result;
}


+ (id) arrayWithFloatsNoCopy:(float *)values count:(NSUInteger)count freeWhenDone:(BOOL)freeWhenDone
{
	return [[self newWithFloatsNoCopy:values count:count freeWhenDone:freeWhenDone] autorelease];
}


- (id) initWithFloatsNoCopy:(float *)values count:(NSUInteger)count freeWhenDone:(BOOL)freeWhenDone
{
	[self release];
	return [[self class] newWithFloatsNoCopy:values count:count freeWhenDone:freeWhenDone];
}


- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}


- (float) floatAtIndex:(NSUInteger)index
{
	if (index < [self count])  return [self priv_floatArray][index];
	return  NAN;
}


- (NSUInteger) betterHash
{
	NSUInteger hash = 5381;
	
	float *array = [self priv_floatArray];
	NSUInteger count = [self count];
	for (NSUInteger i = 0; i < count; i++)
	{
		NSUInteger bits = *(FloatSizedInt *)array;
		array++;
		
		hash = (hash * 33) ^ bits;
	}
	
	return hash;
}


- (id) objectAtIndex:(NSUInteger)index
{
	return [NSNumber numberWithFloat:[self floatAtIndex:index]];
}


- (BOOL) isEqualToArray:(NSArray *)other
{
	if ([other isKindOfClass:[OOFloatArray class]])  return [self priv_isEqualToOOMFloatArray:(OOFloatArray *)other];
	return [super isEqualToArray:other];
}


- (BOOL) isEqual:(id)other
{
	if ([other isKindOfClass:[OOFloatArray class]])  return [self priv_isEqualToOOMFloatArray:other];
	return [super isEqual:other];
}

@end


@implementation OOFloatArray (Private)

- (BOOL) priv_isEqualToOOMFloatArray:(OOFloatArray *)other
{
	NSParameterAssert(other != nil);
	
	NSUInteger count = [self count];
	if (count != [other count])  return NO;
	
	float *mine = [self priv_floatArray];
	float *theirs = [self priv_floatArray];
	for (NSUInteger i = 0; i < count; i++)
	{
		if (*mine++ != *theirs++)  return NO;
	}
	
	return YES;
}


- (float *) priv_floatArray
{
	[NSException raise:NSInternalInconsistencyException format:@"%s is a subclass responsibility.", __PRETTY_FUNCTION__];
	return NULL;
}

@end


@implementation OOMInlineFloatArray

+ (id) priv_newWithCapacity:(NSUInteger)count
{
	OOMInlineFloatArray *result = [NSAllocateObject(self, count * sizeof (float), NULL) init];
	if (result != nil)  result->_count = count;
	return result;
}


+ (id) priv_newWithFloats:(float *)values count:(NSUInteger)count
{
	if (count != 0 && values == NULL)  return nil;
	size_t size = sizeof *values * count;
	
	OOFloatArray *result = [self priv_newWithCapacity:count];
	if (result != nil)
	{
		memcpy([result priv_floatArray], values, size);
	}
	
	return result;
}


- (float *) priv_floatArray
{
	return object_getIndexedIvars(self);
}


- (NSUInteger) count
{
	return _count;
}


- (float) floatAtIndex:(NSUInteger)index
{
	if (index < _count)  return ((float *)object_getIndexedIvars(self))[index];
	return  NAN;
}


- (float) oo_floatAtIndex:(NSUInteger)index
{
	if (index < _count)  return ((float *)object_getIndexedIvars(self))[index];
	return  0.0f;
}

@end


@implementation OOMExternFloatArray
#if 0
{
	NSUInteger					_freeWhenDone: 1,
								_count: ((sizeof (NSUInteger) * CHAR_BIT) - 1);
	float						*_floats;
}
#endif


+ (id) priv_newWithCapacity:(NSUInteger)count
{
	float *buffer = malloc(sizeof(float) * count);
	if (EXPECT_NOT(buffer == NULL))  return nil;
	
	return [[OOMExternFloatArray alloc] priv_initWithFloatsNoCopy:buffer count:count freeWhenDone:YES];
}


- (id) priv_initWithFloatsNoCopy:(float *)values count:(NSUInteger)count freeWhenDone:(BOOL)freeWhenDone
{
	NSParameterAssert(values != NULL || count == 0);
	
	if ((self = [super init]))
	{
		_count = count;
		if (EXPECT_NOT(_count != count))
		{
			[self release];
			return nil;
		}
		
		_freeWhenDone = !!freeWhenDone;
		_floats = values;
	}
	return self;
}


- (void) dealloc
{
	if (_freeWhenDone)
	{
		free(_floats);
		_floats = NULL;
	}
	
	[super dealloc];
}


- (void) finalize
{
	if (_freeWhenDone)
	{
		free(_floats);
		_floats = NULL;
	}
	
	[super finalize];
}


- (float *) priv_floatArray
{
	return _floats;
}


- (NSUInteger) count
{
	return _count;
}

@end


@implementation OOFloatArray (OOCollectionExtractors)

- (float) oo_floatAtIndex:(NSUInteger)index defaultValue:(float)value
{
	if (index < [self count])  return [self floatAtIndex:index];
	return  value;
}


- (double) oo_doubleAtIndex:(NSUInteger)index defaultValue:(double)value
{
	return [self oo_floatAtIndex:index defaultValue:value];
}


- (char) oo_charAtIndex:(NSUInteger)index defaultValue:(char)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], CHAR_MIN, CHAR_MAX);
}


- (short) oo_shortAtIndex:(NSUInteger)index defaultValue:(short)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], SHRT_MIN, SHRT_MAX);
}


- (int) oo_intAtIndex:(NSUInteger)index defaultValue:(int)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], INT_MIN, INT_MAX);
}


- (long) oo_longAtIndex:(NSUInteger)index defaultValue:(long)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], LONG_MIN, LONG_MAX);
}


- (long long) oo_longLongAtIndex:(NSUInteger)index defaultValue:(long long)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], LLONG_MIN, LLONG_MAX);
}


- (NSInteger) oo_integerAtIndex:(NSUInteger)index defaultValue:(NSInteger)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], NSIntegerMin, NSIntegerMax);
}



- (unsigned char) oo_unsignedCharAtIndex:(NSUInteger)index defaultValue:(unsigned char)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, UCHAR_MAX);
}


- (unsigned short) oo_unsignedShortAtIndex:(NSUInteger)index defaultValue:(unsigned short)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, USHRT_MAX);
}


- (unsigned int) oo_unsignedIntAtIndex:(NSUInteger)index defaultValue:(unsigned int)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, UINT_MAX);
}


- (unsigned long) oo_unsignedLongAtIndex:(NSUInteger)index defaultValue:(unsigned long)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, ULONG_MAX);
}


- (unsigned long long) oo_unsignedLongLongAtIndex:(NSUInteger)index defaultValue:(unsigned long long)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, ULLONG_MAX);
}


- (NSUInteger) oo_unsignedIntegerAtIndex:(NSUInteger)index defaultValue:(NSUInteger)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, NSIntegerMax);
}



- (BOOL) oo_boolAtIndex:(NSUInteger)index defaultValue:(BOOL)value
{
	return [self oo_floatAtIndex:index defaultValue:value] != 0;
}

@end
