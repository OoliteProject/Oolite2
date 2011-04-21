/*

OOGraphicsContextInternal.h

Internal interfaces for graphics contexts.


Copyright (C) 2011 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/


#import "OOGraphicsContext.h"


OOINLINE OOGraphicsContext *OOCurrentGraphicsContext(void)
{
	extern OOGraphicsContext *gOOCurrentGraphicsContext;
	return gOOCurrentGraphicsContext;
}


@interface OOGraphicsContext (OOPrivate)

// Accessors for current material. NOTE: old material is released immediately when setting a new one.
- (OOMaterial *) currentMaterial;
- (void) setCurrentMaterial:(OOMaterial *)material;

// Accessors for current shader program. NOTE: old shader program is released immediately when setting a new one.
- (OOShaderProgram *) currentShaderProgram;
- (void) setCurrentShaderProgram:(OOShaderProgram *)shaderProgram;

@end

/*
	OOAssertGraphicsContext(expectedContext)
	Assert that the current graphics context is non-nil and is shared with
	expectedContext.
	See comment at -isSharingWithContext: in OOGraphicsContext.h.
*/
#ifndef NDEBUG
#define OOAssertGraphicsContext(expectedContext)  do { \
	OOGraphicsContext *currentContext = OOCurrentGraphicsContext(); \
	NSCAssert(currentContext != nil && [currentContext isSharingWithContext:expectedContext], @"Incompatible graphics context."); \
} while (0)
#else
#define OOAssertGraphicsContext(expectedContext)  do {} while (0)
#endif

