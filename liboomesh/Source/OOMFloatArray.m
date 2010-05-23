/*
	OOMFloatArray.m
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

#import "OOMFloatArray.h"
#import "OOCollectionExtractors.h"
#import "CollectionUtils.h"


typedef uint32_t FloatSizedInt;


@interface OOMFloatArray (Private)

// Create a new array with allocated space and count but no values filled in.
+ (id) priv_newWithCapacity:(OOUInteger)count zone:(NSZone *)zone;

+ (id) priv_newWithFloats:(float *)values count:(OOUInteger)count zone:(NSZone *)zone;
+ (id) priv_newOrRetainedArrayWithArray:(NSArray *)array;

- (BOOL) priv_isEqualToOOMFloatArray:(OOMFloatArray *)other;

@end


@implementation OOMFloatArray

#ifndef NS_BLOCK_ASSERTIONS
+ (void) initialize
{
	NSAssert(sizeof(FloatSizedInt) == sizeof(uint32_t), @"OOMFloatArray: FloatSizedInt is not defined appropriately.");
}
#endif


static inline float *GetFloatArray(OOMFloatArray *self)
{
	return object_getIndexedIvars(self);
}


+ (id) arrayWithArray:(NSArray *)array
{
	OOMFloatArray *result = [self priv_newOrRetainedArrayWithArray:array];
	[result autorelease];
	return result;
}


- (id) initWithArray:(NSArray *)array
{
	[self release];
	return [[self class] priv_newOrRetainedArrayWithArray:array];
}


+ (id) arrayWithFloats:(float *)values count:(OOUInteger)count
{
	return [[self priv_newWithFloats:values count:count zone:nil] autorelease];
}


- (id) initWithFloats:(float *)values count:(OOUInteger)count
{
	NSZone *zone = [self zone];
	[self release];
	return [[self class] priv_newWithFloats:(float *)values count:count zone:zone];
}


- (id) copyWithZone:(NSZone *)zone
{
	if (NSShouldRetainWithZone(self, zone))
	{
		return [self retain];
	}
	else
	{
		return [[self class] priv_newWithFloats:GetFloatArray(self) count:_count zone:zone];
	}
}


- (float) floatAtIndex:(OOUInteger)index
{
	if (index < _count)  return GetFloatArray(self)[index];
	return  NAN;
}


- (OOUInteger) betterHash
{
	OOUInteger hash = 5381;
	
	float *array = GetFloatArray(self);
	for (OOUInteger i = 0; i < _count; i++)
	{
		OOUInteger bits = *(FloatSizedInt *)array;
		array++;
		
		hash = (hash * 33) ^ bits;
	}
	
	return hash;
}


- (OOUInteger) count
{
	return _count;
}


- (id) objectAtIndex:(NSUInteger)index
{
	return [NSNumber numberWithFloat:[self floatAtIndex:index]];
}


- (BOOL) isEqualToArray:(NSArray *)other
{
	if ([other isKindOfClass:[OOMFloatArray class]])  return [self priv_isEqualToOOMFloatArray:(OOMFloatArray *)other];
	return [super isEqualToArray:other];
}


- (BOOL) isEqual:(id)other
{
	if ([other isKindOfClass:[OOMFloatArray class]])  return [self priv_isEqualToOOMFloatArray:other];
	return [super isEqual:other];
}

@end


@implementation OOMFloatArray (Private)

+ (id) priv_newWithCapacity:(OOUInteger)count zone:(NSZone *)zone
{
	/*	To avoid an extra allocation (and extra allocation padding, cache
	 innefficency and all that jazz) we store the array contiguously with
	 the object.
	 */
	OOMFloatArray *result = NSAllocateObject(self, count * sizeof (float), zone);
	if (result != nil)  result->_count = count;
	return result;
}


+ (id) priv_newWithFloats:(float *)values count:(OOUInteger)count zone:(NSZone *)zone
{
	if (count != 0 && values == NULL)  return nil;
	size_t size = sizeof *values * count;
	
	OOMFloatArray *result = [self priv_newWithCapacity:count zone:zone];
	if (result != nil)
	{
		memcpy(GetFloatArray(result), values, size);
	}
	
	return result;
}


+ (id) priv_newOrRetainedArrayWithArray:(NSArray *)array
{
	if (array == nil)  return [self priv_newWithFloats:nil count:0 zone:nil];
	if ([array isKindOfClass:[OOMFloatArray class]])  return [array copy];
	
	OOUInteger i, count = [array count];
	OOMFloatArray *result = [self priv_newWithCapacity:count zone:[array zone]];
	
	if (result != nil)
	{
		float *next = GetFloatArray(result);
		for (i = 0; i < count; i++)
		{
			*next++ = [array oo_floatAtIndex:i];
		}
	}
	
	return result;
}


- (BOOL) priv_isEqualToOOMFloatArray:(OOMFloatArray *)other
{
	NSParameterAssert(other != nil);
	
	if (_count != other->_count)  return NO;
	
	float *mine = GetFloatArray(self);
	float *theirs = GetFloatArray(self);
	for (OOUInteger i = 0; i < _count; i++)
	{
		if (*mine++ != *theirs++)  return NO;
	}
	
	return YES;
}

@end


@implementation OOMFloatArray (OOCollectionExtractors)

- (float) oo_floatAtIndex:(OOUInteger)index defaultValue:(float)value
{
	if (index < _count)  return [self floatAtIndex:index];
	return  value;
}


- (double) oo_doubleAtIndex:(OOUInteger)index defaultValue:(double)value
{
	return [self oo_floatAtIndex:index defaultValue:value];
}


- (char) oo_charAtIndex:(OOUInteger)index defaultValue:(char)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], CHAR_MIN, CHAR_MAX);
}


- (short) oo_shortAtIndex:(OOUInteger)index defaultValue:(short)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], SHRT_MIN, SHRT_MAX);
}


- (int) oo_intAtIndex:(OOUInteger)index defaultValue:(int)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], INT_MIN, INT_MAX);
}


- (long) oo_longAtIndex:(OOUInteger)index defaultValue:(long)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], LONG_MIN, LONG_MAX);
}


- (long long) oo_longLongAtIndex:(OOUInteger)index defaultValue:(long long)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], LLONG_MIN, LLONG_MAX);
}


- (OOInteger) oo_integerAtIndex:(OOUInteger)index defaultValue:(OOInteger)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], OOIntegerMin, OOIntegerMax);
}



- (unsigned char) oo_unsignedCharAtIndex:(OOUInteger)index defaultValue:(unsigned char)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, UCHAR_MAX);
}


- (unsigned short) oo_unsignedShortAtIndex:(OOUInteger)index defaultValue:(unsigned short)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, USHRT_MAX);
}


- (unsigned int) oo_unsignedIntAtIndex:(OOUInteger)index defaultValue:(unsigned int)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, UINT_MAX);
}


- (unsigned long) oo_unsignedLongAtIndex:(OOUInteger)index defaultValue:(unsigned long)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, ULONG_MAX);
}


- (unsigned long long) oo_unsignedLongLongAtIndex:(OOUInteger)index defaultValue:(unsigned long long)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, ULLONG_MAX);
}


- (OOUInteger) oo_unsignedIntegerAtIndex:(OOUInteger)index defaultValue:(OOUInteger)value
{
	return OOClampInteger([self oo_floatAtIndex:index defaultValue:value], 0, OOIntegerMax);
}



- (BOOL) oo_boolAtIndex:(OOUInteger)index defaultValue:(BOOL)value
{
	return [self oo_floatAtIndex:index defaultValue:value] != 0;
}

@end
