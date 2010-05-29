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

- (id) priv_initWithUnsignedInts:(GLuint *)values count:(GLuint)count;

@end


@interface OOUShortIndexArray: OOIndexArray
{
@private
	GLuint					_count;
	GLushort				*_values;
}

- (id) priv_initWithUnsignedInts:(GLuint *)values count:(GLuint)count;

@end


@interface OOUIntIndexArray: OOIndexArray
{
@private
	GLuint					_count;
	GLuint					*_values;
	BOOL					_freeWhenDone;
}

- (id) priv_initWithUnsignedInts:(GLuint *)values count:(GLuint)count;
- (id) priv_initWithUnsignedIntsNoCopy:(GLuint *)values count:(GLuint)count freeWhenDone:(BOOL)freeWhenDone;

@end


@interface OOIndexArray (Private)

// Designated initializer.
- (id) priv_init;

@end


@implementation OOIndexArray

+ (id) newWithUnsignedInts:(GLuint *)values count:(GLuint)count maximum:(GLuint)maximum
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


+ (id) arrayWithUnsignedInts:(GLuint *)values count:(GLuint)count maximum:(GLuint)maximum
{
	return [[self newWithUnsignedInts:values count:count maximum:maximum] autorelease];
}


- (id) initWithUnsignedInts:(GLuint *)values count:(GLuint)count maximum:(GLuint)maximum
{
	[self release];
	return [OOIndexArray newWithUnsignedInts:values count:count maximum:maximum];
}


+ (id) newWithUnsignedIntsNoCopy:(GLuint *)values count:(GLuint)count maximum:(GLuint)maximum freeWhenDone:(BOOL)freeWhenDone
{
	NSParameterAssert(values != NULL || count == 0);
	
	id result = nil;
	if (maximum <= 0xFFFF || count == 0)
	{
		result = [self newWithUnsignedInts:values count:count maximum:maximum];
		if (freeWhenDone)  free(values);
	}
	else
	{
		result = [[OOUIntIndexArray alloc] priv_initWithUnsignedIntsNoCopy:values count:count freeWhenDone:freeWhenDone];
	}
	return result;
}


+ (id) arrayWithUnsignedIntsNoCopy:(GLuint *)values count:(GLuint)count maximum:(GLuint)maximum freeWhenDone:(BOOL)freeWhenDone
{
	return [[self newWithUnsignedIntsNoCopy:values count:count maximum:maximum freeWhenDone:freeWhenDone] autorelease];
}


- (id) initWithUnsignedIntsNoCopy:(GLuint *)values count:(GLuint)count maximum:(GLuint)maximum freeWhenDone:(BOOL)freeWhenDone
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

@end


@implementation OOUByteIndexArray

- (id) priv_initWithUnsignedInts:(GLuint *)values count:(GLuint)count
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


- (const void *) data
{
	return _values;
}


- (NSUInteger) unsignedIntAtIndex:(GLuint)index
{
	return _values[index];
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

- (id) priv_initWithUnsignedInts:(GLuint *)values count:(GLuint)count
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


- (const void *) data
{
	return _values;
}


- (NSUInteger) unsignedIntAtIndex:(GLuint)index
{
	return _values[index];
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

- (id) priv_initWithUnsignedInts:(GLuint *)values count:(GLuint)count
{
	_values = malloc(count * sizeof (GLuint));
	NSUInteger i;
	for (i = 0; i < count; i++)
	{
		_values[i] = values[i];
	}
	return [self priv_initWithUnsignedIntsNoCopy:_values count:count freeWhenDone:YES];
}


- (id) priv_initWithUnsignedIntsNoCopy:(GLuint *)values count:(GLuint)count freeWhenDone:(BOOL)freeWhenDone
{
	if ((self = [super priv_init]))
	{
		_values = values;
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


- (const void *) data
{
	return _values;
}


- (NSUInteger) unsignedIntAtIndex:(GLuint)index
{
	return _values[index];
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
