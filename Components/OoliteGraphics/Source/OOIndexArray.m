/*
	OOIndexArray.m
	
	
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

#import "OOIndexArray.h"


@interface OOUByteIndexArray: OOIndexArray
{
@private
	GLuint					_count;
	GLubyte					*_values;
}

- (id) priv_initWithUnsignedInts:(const GLuint *)values count:(GLuint)count;

@end


@interface OOUShortIndexArray: OOIndexArray
{
@private
	GLuint					_count;
	GLushort				*_values;
}

- (id) priv_initWithUnsignedInts:(const GLuint *)values count:(GLuint)count;

@end


@interface OOUIntIndexArray: OOIndexArray
{
@private
	GLuint					_count;
	GLuint					*_values;
	BOOL					_freeWhenDone;
}

- (id) priv_initWithUnsignedInts:(const GLuint *)values count:(GLuint)count;
- (id) priv_initWithUnsignedIntsNoCopy:(const GLuint *)values count:(GLuint)count freeWhenDone:(BOOL)freeWhenDone;

@end


@interface OOIndexArray (Private)

// Designated initializer.
- (id) priv_init;

@end


@implementation OOIndexArray

+ (id) newWithArray:(NSArray *)array
{
	if (EXPECT_NOT(array == nil))  return [[self alloc] init];
	if ([array isKindOfClass:[OOIndexArray class]])  return [array copy];
	
	OOUInteger i, count = [array count], maximum = 0;
	GLuint *values = malloc(count * sizeof (GLuint));
	if (EXPECT_NOT(values == NULL))  return nil;
	
	//	Convert to numbers and find maximum.
	for (i = 0; i < count; i++)
	{
		values[i] = [array oo_unsignedIntAtIndex:i];
		maximum = MAX(maximum, values[i]);
	}
	
	return [self newWithUnsignedIntsNoCopy:values count:count maximum:maximum freeWhenDone:YES];
}


+ (id) arrayWithArray:(NSArray *)array
{
	return [[self newWithArray:array] autorelease];
}


- (id) initWithArray:(NSArray *)array
{
	[self release];
	return [OOIndexArray newWithArray:array];
}


+ (id) newWithUnsignedInts:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum
{
	NSParameterAssert(values != NULL || count == 0);
	
	Class aClass = Nil;
	if (maximum <= 0xFF || count == 0)
	{
		aClass = [OOUByteIndexArray class];
	}
	else if (maximum <= 0xFFFF)
	{
		aClass = [OOUShortIndexArray class];
	}
	else
	{
		aClass = [OOUIntIndexArray class];
	}
	return [[aClass alloc] priv_initWithUnsignedInts:values count:count];
}


+ (id) arrayWithUnsignedInts:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum
{
	return [[self newWithUnsignedInts:values count:count maximum:maximum] autorelease];
}


- (id) initWithUnsignedInts:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum
{
	[self release];
	return [OOIndexArray newWithUnsignedInts:values count:count maximum:maximum];
}


+ (id) newWithUnsignedIntsNoCopy:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum freeWhenDone:(BOOL)freeWhenDone
{
	NSParameterAssert(values != NULL || count == 0);
	
	id result = nil;
	if (maximum <= 0xFFFF || count == 0)
	{
		result = [self newWithUnsignedInts:values count:count maximum:maximum];
		if (freeWhenDone)  free((void *)values);
	}
	else
	{
		result = [[OOUIntIndexArray alloc] priv_initWithUnsignedIntsNoCopy:values count:count freeWhenDone:freeWhenDone];
	}
	return result;
}


+ (id) arrayWithUnsignedIntsNoCopy:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum freeWhenDone:(BOOL)freeWhenDone
{
	/*	Static analyzer reports a retain count problem here. This is a false
		positive: the method name includes “copy”, but not in the relevant
		sense.
		Mainline clang has an annotation for this, but it is’t available in
		OS X at the time of writing. It should be picked up automatically
		when it is.
	*/
	return [[self newWithUnsignedIntsNoCopy:values count:count maximum:maximum freeWhenDone:freeWhenDone] autorelease];
}


- (id) initWithUnsignedIntsNoCopy:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum freeWhenDone:(BOOL)freeWhenDone
{
	[self release];
	return [OOIndexArray newWithUnsignedIntsNoCopy:values count:count maximum:maximum freeWhenDone:freeWhenDone];
}


+ (id) array
{
	return [self arrayWithUnsignedInts:NULL count:0 maximum:0];
}


- (id) init
{
	return [self initWithUnsignedInts:NULL count:0 maximum:0];
}


- (id) priv_init
{
	return [super init];
}


- (GLenum) glType
{
	[NSException raise:NSInternalInconsistencyException format:@"%s is a subclass responsibility.", __PRETTY_FUNCTION__];
	return 0;
}


- (size_t) elementSize
{
	[NSException raise:NSInternalInconsistencyException format:@"%s is a subclass responsibility.", __PRETTY_FUNCTION__];
	return 0;
}


- (const void *) data
{
	[NSException raise:NSInternalInconsistencyException format:@"%s is a subclass responsibility.", __PRETTY_FUNCTION__];
	return NULL;
}


- (NSUInteger) unsignedIntAtIndex:(GLuint)index
{
	[NSException raise:NSInternalInconsistencyException format:@"%s is a subclass responsibility.", __PRETTY_FUNCTION__];
	return 0;
}


- (NSUInteger) betterHash
{
	[NSException raise:NSInternalInconsistencyException format:@"%s is a subclass responsibility.", __PRETTY_FUNCTION__];
	return 0;
}


- (id) objectAtIndex:(NSUInteger)index
{
	return [NSNumber numberWithUnsignedInt:[self unsignedIntAtIndex:index]];
}


- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}


- (BOOL) priv_isEqualToOOIndexArray:(OOIndexArray *)other
{
	NSUInteger selfCount = [self count], otherCount = [other count], iter;
	if (selfCount != otherCount)  return NO;
	
	for (iter = 0; iter < selfCount; iter++)
	{
		if ([self unsignedIntAtIndex:iter] != [other unsignedIntAtIndex:iter])  return NO;
	}
	
	return YES;
}


- (BOOL) isEqualToArray:(NSArray *)other
{
	if ([other isKindOfClass:[OOIndexArray class]])  return [self priv_isEqualToOOIndexArray:(OOIndexArray *)other];
	return [super isEqualToArray:other];
}


- (BOOL) isEqual:(id)other
{
	if ([other isKindOfClass:[OOIndexArray class]])  return [self priv_isEqualToOOIndexArray:other];
	return [super isEqual:other];
}

@end


@implementation OOUByteIndexArray

- (id) priv_initWithUnsignedInts:(const GLuint *)values count:(GLuint)count
{
	if ((self = [super priv_init]))
	{
		_values = malloc(count * sizeof (GLubyte));
		if (EXPECT_NOT(_values == NULL))
		{
			[self release];
			return nil;
		}
		_count = count;
		
		NSUInteger i;
		for (i = 0; i < count; i++)
		{
			_values[i] = values[i];
		}
	}
	
	return self;
}


- (void) dealloc
{
	free(_values);
	
	[super dealloc];
}


- (void) finalize
{
	free(_values);
	
	[super finalize];
}


- (NSUInteger) count
{
	return _count;
}


- (GLenum) glType
{
	return GL_UNSIGNED_BYTE;
}


- (size_t) elementSize
{
	return sizeof *_values;
}


- (const void *) data
{
	return _values;
}


- (NSUInteger) unsignedIntAtIndex:(GLuint)index
{
	return (index < _count) ? _values[index] : 0;
}


- (NSUInteger) betterHash
{
	NSUInteger hash = 5381;
	
	for (NSUInteger i = 0; i < _count; i++)
	{
		hash = (hash * 33) ^ _values[i];
	}
	
	return hash;
}

@end


@implementation OOUShortIndexArray

- (id) priv_initWithUnsignedInts:(const GLuint *)values count:(GLuint)count
{
	if ((self = [super priv_init]))
	{
		_values = malloc(count * sizeof (GLushort));
		if (EXPECT_NOT(_values == NULL))
		{
			[self release];
			return nil;
		}
		_count = count;
		
		NSUInteger i;
		for (i = 0; i < count; i++)
		{
			_values[i] = values[i];
		}
	}
	
	return self;
}


- (void) dealloc
{
	free(_values);
	
	[super dealloc];
}


- (void) finalize
{
	free(_values);
	
	[super finalize];
}


- (NSUInteger) count
{
	return _count;
}


- (GLenum) glType
{
	return GL_UNSIGNED_SHORT;
}


- (size_t) elementSize
{
	return sizeof *_values;
}


- (const void *) data
{
	return _values;
}


- (NSUInteger) unsignedIntAtIndex:(GLuint)index
{
	return (index < _count) ? _values[index] : 0;
}


- (NSUInteger) betterHash
{
	NSUInteger hash = 5381;
	
	for (NSUInteger i = 0; i < _count; i++)
	{
		hash = (hash * 33) ^ _values[i];
	}
	
	return hash;
}

@end


@implementation OOUIntIndexArray

- (id) priv_initWithUnsignedInts:(const GLuint *)values count:(GLuint)count
{
	_values = malloc(count * sizeof (GLuint));
	NSUInteger i;
	for (i = 0; i < count; i++)
	{
		_values[i] = values[i];
	}
	return [self priv_initWithUnsignedIntsNoCopy:_values count:count freeWhenDone:YES];
}


- (id) priv_initWithUnsignedIntsNoCopy:(const GLuint *)values count:(GLuint)count freeWhenDone:(BOOL)freeWhenDone
{
	if ((self = [super priv_init]))
	{
		_values = (GLuint *)values;
		_count = count;
		_freeWhenDone = freeWhenDone;
	}
	
	return self;
}


- (void) dealloc
{
	if (_freeWhenDone)  free(_values);
	
	[super dealloc];
}


- (void) finalize
{
	if (_freeWhenDone)  free(_values);
	
	[super finalize];
}


- (NSUInteger) count
{
	return _count;
}


- (GLenum) glType
{
	return GL_UNSIGNED_INT;
}


- (size_t) elementSize
{
	return sizeof *_values;
}


- (const void *) data
{
	return _values;
}


- (NSUInteger) unsignedIntAtIndex:(GLuint)index
{
	return (index < _count) ? _values[index] : 0;
}


- (NSUInteger) betterHash
{
	NSUInteger hash = 5381;
	
	for (NSUInteger i = 0; i < _count; i++)
	{
		hash = (hash * 33) ^ _values[i];
	}
	
	return hash;
}

@end


@implementation OOIndexArray (OOCollectionExtractors)

- (float) oo_floatAtIndex:(NSUInteger)index defaultValue:(float)value
{
	return [self oo_doubleAtIndex:index defaultValue:value];
}


- (double) oo_doubleAtIndex:(NSUInteger)index defaultValue:(double)value
{
	if (index < [self count])  return [self unsignedIntAtIndex:index];
	return value;
}


- (NSUInteger) oo_unsignedIntegerAtIndex:(NSUInteger)index defaultValue:(NSUInteger)value
{
	if (index < [self count])  return [self unsignedIntAtIndex:index];
	return value;
}


- (char) oo_charAtIndex:(NSUInteger)index defaultValue:(char)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], CHAR_MIN, CHAR_MAX);
}


- (short) oo_shortAtIndex:(NSUInteger)index defaultValue:(short)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], SHRT_MIN, SHRT_MAX);
}


- (int) oo_intAtIndex:(NSUInteger)index defaultValue:(int)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], INT_MIN, INT_MAX);
}


- (long) oo_longAtIndex:(NSUInteger)index defaultValue:(long)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], LONG_MIN, LONG_MAX);
}


- (long long) oo_longLongAtIndex:(NSUInteger)index defaultValue:(long long)value
{
	return [self oo_unsignedIntegerAtIndex:index defaultValue:value];
}


- (NSInteger) oo_integerAtIndex:(NSUInteger)index defaultValue:(NSInteger)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], NSIntegerMin, NSIntegerMax);
}



- (unsigned char) oo_unsignedCharAtIndex:(NSUInteger)index defaultValue:(unsigned char)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], 0, UCHAR_MAX);
}


- (unsigned short) oo_unsignedShortAtIndex:(NSUInteger)index defaultValue:(unsigned short)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], 0, USHRT_MAX);
}


- (unsigned int) oo_unsignedIntAtIndex:(NSUInteger)index defaultValue:(unsigned int)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], 0, UINT_MAX);
}


- (unsigned long) oo_unsignedLongAtIndex:(NSUInteger)index defaultValue:(unsigned long)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], 0, ULONG_MAX);
}


- (unsigned long long) oo_unsignedLongLongAtIndex:(NSUInteger)index defaultValue:(unsigned long long)value
{
	return OOClampInteger([self oo_unsignedIntegerAtIndex:index defaultValue:value], 0, ULLONG_MAX);
}



- (BOOL) oo_boolAtIndex:(NSUInteger)index defaultValue:(BOOL)value
{
	return [self oo_unsignedIntegerAtIndex:index defaultValue:value] != 0;
}

@end


#import "OOOpenGLUtilities.h"

@implementation OOIndexArray (OpenGL)

- (void) glBufferDataWithUsage:(unsigned int /* GLenum */)usage
{
	OOGL(glBufferData(GL_ELEMENT_ARRAY_BUFFER, [self count] * [self elementSize], [self data], usage));
}

@end
