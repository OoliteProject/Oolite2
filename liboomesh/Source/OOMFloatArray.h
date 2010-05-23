/*
	OOMFloatArray.h
	liboomesh
	
	An immutable array of floats.
	
	For interoperability, this is a subclass of NSArray. Using normal NSArray
	methods, it will return NSNumber objects created on the fly. Using
	-floatAtIndex: is obviously more efficient.
	
	OOMFloatArray also implements optimized versions of the
	OOCollectionExtractors methods.
	
	
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

#import <Foundation/Foundation.h>


@interface OOMFloatArray: NSArray
{
@private
	OOUInteger					_count;
}

+ (id) arrayWithArray:(NSArray *)array;
- (id) initWithArray:(NSArray *)array;

+ (id) arrayWithFloats:(float *)values count:(OOUInteger)count;
- (id) initWithFloats:(float *)values count:(OOUInteger)count;

//	Returns NaN if index is out of range.
- (float) floatAtIndex:(OOUInteger)index;

/*	The default NSArray hash, at least under Mac OS X, is awful. However, a
	subclass can't change the hash because it must be equal to the hash of
	a normal NSArray with the corresponding NSNumbers.
	-betterHash provides a real hash of the array contents.
*/
- (OOUInteger) betterHash;

@end
