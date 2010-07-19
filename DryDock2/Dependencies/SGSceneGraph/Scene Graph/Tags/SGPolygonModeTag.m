/*
	SGPolygonModeTag.m
	
	
	Copyright © 2009 Jens Ayton
	
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

#import "SGPolygonModeTag.h"


@implementation SGPolygonModeTag

- (id) init
{
	if ((self = [super init]))
	{
		_mode = kSGPolygonModeFilled;
		_face = GL_FRONT_AND_BACK;
	}
	return self;
}


- (NSString *) name
{
	return @"polygon mode";
}


- (SGPolygonMode) mode
{
	return _mode;
}


- (void) setMode:(SGPolygonMode)mode
{
	switch (mode)
	{
		case kSGPolygonModePoints:
		case kSGPolygonModeWireframe:
		case kSGPolygonModeFilled:
			if (mode != _mode)
			{
				_mode = mode;
				[self becomeDirty];
			}
	}
}


- (BOOL) applyToFrontFace
{
	return _face == GL_FRONT || _face == GL_FRONT_AND_BACK;
}


- (void) setApplyToFrontFace:(BOOL)flag
{
	GLenum newValue = _face;
	
	switch (_face)
	{
		case 0:
		case GL_FRONT:
			newValue = flag ? GL_FRONT : 0;
			break;
		
		case GL_FRONT_AND_BACK:
		case GL_BACK:
			newValue = flag ? GL_FRONT_AND_BACK : GL_BACK;
			break;
	}
	
	if (newValue != _face)
	{
		_face = newValue;
		[self becomeDirty];
	}
}


- (BOOL) applyToBackFace
{
	return _face == GL_BACK || _face == GL_FRONT_AND_BACK;
}


- (void) setApplyToBackFace:(BOOL)flag
{
	GLenum newValue = _face;
	
	switch (_face)
	{
		case 0:
		case GL_BACK:
			newValue = flag ? GL_BACK : 0;
			break;
			
		case GL_FRONT_AND_BACK:
		case GL_FRONT:
			newValue = flag ? GL_FRONT_AND_BACK : GL_FRONT;
			break;
	}
	
	if (newValue != _face)
	{
		_face = newValue;
		[self becomeDirty];
	}
}


- (void) apply:(NSMutableDictionary *)ioState
{
	/*	Note: we push state even if face is 0, so that changing the face while
		the tag is applied won't break the attribute stack.
	*/
	glPushAttrib(GL_POLYGON_BIT);
	
	if (_face != 0)
	{
		glPolygonMode(_face, _mode);
	}
}


- (void) unapply
{
	glPopAttrib();
}

@end


@implementation SGPolygonModeTag (GraphVizGeneration)

- (NSString *) graphVizLabel
{
	NSString			*mode = @"[unknown mode]";
	NSString			*face = nil;
	
	switch (self.mode)
	{
		case kSGPolygonModePoints:
			mode = @"points";
			break;
			
		case kSGPolygonModeWireframe:
			mode = @"wireframe";
			break;
			
		case kSGPolygonModeFilled:
			mode = @"filled";
			break;
	}
	
	if (self.applyToFrontFace)
	{
		face = self.applyToBackFace ? @"both faces" : @"front face";
	}
	else
	{
		face = self.applyToBackFace ? @"back face" : @"no face";
	}
	
	return $sprintf(@"%@ mode for %@", mode, face);
}

@end
