/*
	SGImageNode.m
	
	
	Copyright © 2007 Jens Ayton
	
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

#import "SGImageNode.h"
#import "SGMaterial.h"
#import "SGTexture2D.h"

#ifndef DEBUG
	#define CGL_MACRO_CACHE_RENDERER
	#include <OpenGL/CGLCurrent.h>
	#import <OpenGL/CGLMacro.h>
#else
	// Don’t use CGLMacro, to make stepping less messy.
	#define CGL_MACRO_DECLARE_VARIABLES() do {} while (0)
#endif

@implementation SGImageNode

#pragma mark NSObject

- (void)dealloc
{
	[material release];
	
	[super dealloc];
}

#pragma mark SGSceneNode

- (void)performRenderWithState:(NSDictionary *)inState dirty:(BOOL)inDirty
{
	CGL_MACRO_DECLARE_VARIABLES();
	
	glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT);
	glDisable(GL_LIGHTING);
	glEnable(GL_TEXTURE_2D);
	[material apply];
	
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glBegin(GL_QUADS);
	
	glTexCoord3f(0.0f, 0.0f, 0.0f);
	glVertex2f(-halfWidth, -halfHeight);
	glTexCoord3f(0.0f, 1.0f, 0.0f);
	glVertex2f(-halfWidth, halfHeight);
	glTexCoord3f(1.0f, 1.0f, 0.0f);
	glVertex2f(halfWidth, halfHeight);
	glTexCoord3f(1.0f, 0.0f, 0.0f);
	glVertex2f(halfWidth, -halfHeight);
	
	glEnd();
	
	glPopAttrib();
}


- (NSString *)itemDescription
{
	return [NSString stringWithFormat:@"size=(%g, %g)", halfWidth * 2.0f, halfHeight * 2.0f];
}


#pragma mark SGImageNode

+ (id)nodeWithTexture:(SGTexture2D *)inTexture
{
	return [[[self alloc] initWithTexture:inTexture] autorelease];
}


+ (id)nodeWithImage:(NSImage *)inImage
{
	return [[[self alloc] initWithImage:inImage] autorelease];
}


- (id)init
{
	self = [super init];
	if (self != nil)
	{
		halfWidth = 0.5;
		halfHeight = 0.5;
		
		material = [[SGSimpleTexture2DMaterial alloc] init];
	}
	
	return self;
}

- (id)initWithTexture:(SGTexture2D *)inTexture
{
	self = [self init];
	if (self != nil)
	{
		[self setTexture:inTexture];
	}
	return self;
}


- (id)initWithImage:(NSImage *)inImage
{
	self = [self init];
	if (self != nil)
	{
		[self setImage:inImage];
	}
	return self;
}


- (SGTexture2D *)texture
{
	return [material texture];
}


- (void)setTexture:(SGTexture2D *)inTexture
{
	if (inTexture != [material texture])
	{
		[material setTexture:inTexture];
		[self becomeDirty];
	}
}


- (void)setImage:(NSImage *)inImage
{
	SGTexture2D *texture = [SGTexture2D textureWithImage:inImage];
	[texture setMaxAnisotropyHighest];
	[material setTexture:texture];
}


- (NSSize)dimensions
{
	return NSMakeSize(halfWidth * 2.0f, halfHeight * 2.0f);
}


- (void)setDimensions:(NSSize)inDimensions
{
	NSSize halfSize = {inDimensions.width * 0.5f, inDimensions.height * 0.5f};
	if (halfSize.width != halfWidth || halfSize.height != halfHeight)
	{
		halfWidth = inDimensions.width * 0.5f;
		halfHeight = inDimensions.height * 0.5f;
		[self becomeDirty];
	}
}

@end
