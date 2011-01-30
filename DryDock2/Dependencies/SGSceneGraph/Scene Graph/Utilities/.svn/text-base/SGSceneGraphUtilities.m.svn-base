/*
	SGSceneGraphUtilities.m
	
	
	Copyright © 2005-2009 Jens Ayton
	
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

#import "SGSceneGraphUtilities.h"


void SGEnterWireframeMode(SGWFModeContext *outContext)
{
	NSCParameterAssert(outContext != NULL);
	
	glPushAttrib(GL_ENABLE_BIT);
	
	// FIXME: check for GL_ARB_shader_objects extension.
	outContext->program = glGetHandleARB(GL_PROGRAM_OBJECT_ARB);
	
	glDisable(GL_LIGHTING);
	glDisable(GL_TEXTURE_1D);
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_TEXTURE_3D);
	
	glUseProgramObjectARB(0);
}


void SGExitWireframeMode(const SGWFModeContext *context)
{
	NSCParameterAssert(context != NULL);
	
	if (context->program != 0)  glUseProgramObjectARB(context->program);
	
	glPopAttrib();
}


void SGLogOpenGLErrors(NSString *context)
{
	GLenum					error;
	
	if (context == nil)  context = @"unspecified";
	
	for (;;)
	{
		error = glGetError();
		if (GL_NO_ERROR == error) break;
		
#if (!SGLOG_DISABLE)
		SGLog(@"OpenGL error %@ in context: %@.", SGGetOpenGLErrorName(error), context);
#endif
	}
}


NSString *SGGetOpenGLErrorName(GLenum error)
{
	NSString				*result = nil;
	
	switch (error)
	{
		case GL_NO_ERROR:
			result = @"GL_NO_ERROR";
			break;
			
		case GL_INVALID_ENUM:
			result = @"GL_INVALID_ENUM";
			break;
			
		case GL_INVALID_VALUE:
			result = @"GL_INVALID_VALUE";
			break;
			
		case GL_INVALID_OPERATION:
			result = @"GL_INVALID_OPERATION";
			break;
			
		case GL_STACK_OVERFLOW:
			result = @"GL_STACK_OVERFLOW";
			break;
			
		case GL_STACK_UNDERFLOW:
			result = @"GL_STACK_UNDERFLOW";
			break;
			
		case GL_OUT_OF_MEMORY:
			result = @"GL_OUT_OF_MEMORY";
			break;
			
		case GL_TABLE_TOO_LARGE:
			result = @"GL_TABLE_TOO_LARGE";
			break;
			
		default:
			result = $sprintf(@"<unknown error 0x%.4X>", error);
	}
	
	return result;
}
