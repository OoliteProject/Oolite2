/*
	OOIndexArray.h
	
	Array class intended for handling vertex arrays. The interesting thing
	about these is that the largest value they’ll contain is known in advance,
	which can be used to pack them as tightly as possible.
	
	
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

#import <OoliteBase/OoliteBase.h>
#import "OOOpenGL.h"


@interface OOIndexArray: NSArray

+ (id) newWithArray:(NSArray *)array;
+ (id) arrayWithArray:(NSArray *)array;
- (id) initWithArray:(NSArray *)array;

+ (id) newWithUnsignedInts:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum;
+ (id) arrayWithUnsignedInts:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum;
- (id) initWithUnsignedInts:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum;

/*	In the spirit of NSData, NoCopy is a hint. The implementation may choose
	to copy the data (and immediately free it, if freeWhenDone).
*/
+ (id) newWithUnsignedIntsNoCopy:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum freeWhenDone:(BOOL)freeWhenDone;
+ (id) arrayWithUnsignedIntsNoCopy:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum freeWhenDone:(BOOL)freeWhenDone OO_RETURNS_NOT_RETAINED;
- (id) initWithUnsignedIntsNoCopy:(const GLuint *)values count:(GLuint)count maximum:(GLuint)maximum freeWhenDone:(BOOL)freeWhenDone;

- (GLenum) glType;
- (size_t) elementSize;

/*	NOTE: exposes internal pointer for speed. This does not outlive the
	OOIndexArray, and writing to it would break the array’s mutability.
*/
- (const void *) data;

- (NSUInteger) unsignedIntAtIndex:(GLuint)index;

/*	The default NSArray hash, at least under Mac OS X, is awful. However, a
	subclass can't change the hash because it must be equal to the hash of
	a normal NSArray with the corresponding NSNumbers.
	-betterHash provides a real hash of the array contents.
	Note that this is NOT comparable with -[OOFloatArray betterHash].
*/
- (NSUInteger) betterHash;

@end


@interface OOIndexArray (OpenGL)

- (void) glBufferDataWithUsage:(GLenum)usage;

@end
