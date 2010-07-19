/*
	SGPointCloudNode.mm
	
	
	Copyright © 2005 Jens Ayton
	
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

#import "SGPointCloudNode.h"
#import "SGSceneGraphUtilities.h"


@implementation SGPointCloudNode

+ (SGSceneNode *)node
{
	return [[[self alloc] init] autorelease];
}


+ (SGPointCloudNode *)nodeWithSize:(float)inSize divisions:(unsigned)inDivisions
{
	return [[[self alloc] initWithSize:inSize divisions:inDivisions] autorelease];
}


- (id)init
{
	return [self initWithSize:10.0 divisions:11];
}


- (id)initWithSize:(float)inSize divisions:(unsigned)inDivisions
{
	self = [super init];
	if (nil != self)
	{
		_size = inSize;
		_divisions = inDivisions;
		[self setLocalizedName:@"Point cloud"];
	}
	
	return self;
}


- (void)performRenderWithState:(NSDictionary *)inState dirty:(BOOL)inDirty
{
	int					xc, yc, zc;
	float				offset, step;
	float				x, y, z;
	SGWFModeContext		wfmc;
	
	if (_divisions < 2) return;
	
	offset = -0.5 * _size;
	step = _size / (float)(_divisions - 1);
	
	SGEnterWireframeMode(&wfmc);
	
	glColor3f(0.8, 0.8, 0.8);
	glBegin(GL_POINTS);
	
	x = offset;
	xc = _divisions;
	do
	{
		y = offset;
		yc = _divisions;
		do
		{
			z = offset;
			zc = _divisions;
			do
			{
				glVertex3f(x, y, z);
				z += step;
			} while (--zc);
			y += step;
		} while (--yc);
		x += step;
	} while (--xc);
	
	glEnd();
	
	SGExitWireframeMode(&wfmc);
}

@end
