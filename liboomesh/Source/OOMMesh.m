/*
	OOMMesh.h
	
	
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

#import "OOMMesh.h"
#import "OOMFaceGroup.h"


@implementation OOMMesh

- (id) init
{
	if ((self = [super init]))
	{
		_faceGroups = [[NSMutableArray alloc] init];
		if (_faceGroups == nil)  DESTROY(self);
	}
	return self;
}


- (void) dealloc
{
	[_faceGroups release];
	
	[super dealloc];
}


- (NSUInteger) faceGroupCount
{
	return [_faceGroups count];
}


- (OOMFaceGroup *) faceGroupAtIndex:(NSUInteger)index
{
	return [_faceGroups objectAtIndex:index];
}


- (void) addFaceGroup:(OOMFaceGroup *)faceGroup
{
	[_faceGroups addObject:faceGroup];
}


- (void) insertFaceGroup:(OOMFaceGroup *)faceGroup atIndex:(NSUInteger)index
{
	[_faceGroups insertObject:faceGroup atIndex:index];
}


- (void) removeLastFaceGroup
{
	[_faceGroups removeLastObject];
}


- (void) removeFaceGroupAtIndex:(NSUInteger)index
{
	[_faceGroups removeObjectAtIndex:index];
}


- (void) replaceFaceGroupAtIndex:(NSUInteger)index withFaceGroup:(OOMFaceGroup *)faceGroup
{
	[_faceGroups replaceObjectAtIndex:index withObject:faceGroup];
}


- (NSEnumerator *) faceGroupEnumerator
{
	return [_faceGroups objectEnumerator];
}


- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
	return [_faceGroups countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
