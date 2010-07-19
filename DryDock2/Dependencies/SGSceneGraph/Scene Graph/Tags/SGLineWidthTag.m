/*
	SGSceneTag.mm
	
	
	Copyright © 2008 Jens Ayton
	
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

#import "SGLineWidthTag.h"


@implementation SGLineWidthTag

@synthesize width = _width;


+ (id) tagWithWidth:(GLfloat)width
{
	return [[(SGLineWidthTag *)[self alloc] initWithWidth:width] autorelease];
}


- (id) init
{
	return [self initWithWidth:1.0f];
}


- (id) initWithWidth:(GLfloat)width
{
	self = [super init];
	if (self != nil)
	{
		self.width = width;
	}
	return self;
}


- (NSString *) name
{
	return @"line width";
}


- (void) apply:(NSMutableDictionary *)ioState
{
	glPushAttrib(GL_LINE_BIT);
	glLineWidth(fmaxf(self.width, 0.0f));
}

- (void) unapply
{
	glPopAttrib();
}


- (NSString *) graphVizLabel
{
	return $sprintf(@"%g", self.width);
}

@end
