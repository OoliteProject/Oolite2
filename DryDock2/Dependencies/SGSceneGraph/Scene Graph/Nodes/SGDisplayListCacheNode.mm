/*
	SGDisplayListCacheNode.mm
	
	
	Copyright © 2004-2006 Jens Ayton
	
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

#import "SGDisplayListCacheNode.h"


@implementation SGDisplayListCacheNode

- (id)init
{
	self = [super init];
	if (nil != self)
	{
		[self setLocalizedName:@"Cache"];
	}
	
	return self;
}


- (void)dealloc
{
	if (0 != listName) glDeleteLists(listName, 1);
	
	[super dealloc];
}


- (void)clearDisplayList
{
	// Make display list empty
	if (0 != listName)
	{
		glNewList(listName, GL_COMPILE);
		glEndList();
	}
}


- (void)renderWithState:(NSDictionary *)inState
{
	NSOpenGLContext		*currentContext;
	
	currentContext = [NSOpenGLContext currentContext];
	if (currentContext != context)
	{
		context = currentContext;
		if (0 != listName)
		{
			glDeleteLists(listName, 1);
			listName = 0;
		}
	}
	
	if ([self isDirty] || 0 == listName)
	{
		// Generate list
		if (0 == listName) listName = glGenLists(1);
		glNewList(listName, GL_COMPILE_AND_EXECUTE);
		[super renderWithState:inState];
		if (0 != listName) glEndList();
	}
	else
	{
		// Use cached list
		glCallList(listName);
	}
}

@end
