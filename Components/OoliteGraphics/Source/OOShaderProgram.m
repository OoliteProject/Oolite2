/*

OOShaderProgram.m


Copyright (C) 2007-2010 Jens Ayton

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

#import "OOShaderProgram.h"
#import "OOMacroOpenGL.h"
#import "OOOpenGLUtilities.h"


static OOShaderProgram			*sActiveProgram = nil;


static NSString *GetGLSLInfoLog(GLuint shaderObject);
static BOOL ValidateShaderObject(GLuint object, NSString *name);


@interface OOShaderProgram (OOPrivate)

- (id)initWithVertexShaderSource:(NSString *)vertexSource
			fragmentShaderSource:(NSString *)fragmentSource
					prefixString:(NSString *)prefixString
					  vertexName:(NSString *)vertexName
					fragmentName:(NSString *)fragmentName
			   attributeBindings:(NSDictionary *)attributeBindings;

- (void) bindAttributes:(NSDictionary *)attributeBindings;

@end


@implementation OOShaderProgram

+ (id) shaderProgramWithVertexShader:(NSString *)vertexShaderSource
					  fragmentShader:(NSString *)fragmentShaderSource
					vertexShaderName:(NSString *)vertexShaderName
					vertexShaderName:(NSString *)fragmentShaderName
							  prefix:(NSString *)prefixString			// String prepended to program source (both vs and fs)
				   attributeBindings:(NSDictionary *)attributeBindings
{
	if ([prefixString length] == 0)  prefixString = nil;
	return  [[[OOShaderProgram alloc] initWithVertexShaderSource:vertexShaderSource
											fragmentShaderSource:fragmentShaderSource
													prefixString:prefixString
													  vertexName:vertexShaderName
													fragmentName:fragmentShaderName
											   attributeBindings:attributeBindings] autorelease];
}


- (void)dealloc
{
	OO_ENTER_OPENGL();
	
#ifndef NDEBUG
	if (EXPECT_NOT(sActiveProgram == self))
	{
		OOLog(@"shader.dealloc.imbalance", @"***** OOShaderProgram deallocated while active, indicating a retain/release imbalance. Expect imminent crash.");
		[OOShaderProgram applyNone];
	}
#endif
	
	OOGL(glDeleteProgram(program));
	
	[super dealloc];
}


- (void)apply
{
	OO_ENTER_OPENGL();
	
	if (sActiveProgram != self)
	{
		[sActiveProgram release];
		sActiveProgram = [self retain];
		OOGL(glUseProgram(program));
	}
}


+ (void)applyNone
{
	OO_ENTER_OPENGL();
	
	if (sActiveProgram != nil)
	{
		[sActiveProgram release];
		sActiveProgram = nil;
		OOGL(glUseProgram(0));
	}
}


- (GLuint) program
{
	return program;
}


- (id)initWithVertexShaderSource:(NSString *)vertexSource
			fragmentShaderSource:(NSString *)fragmentSource
					prefixString:(NSString *)prefixString
					  vertexName:(NSString *)vertexName
					fragmentName:(NSString *)fragmentName
			   attributeBindings:(NSDictionary *)attributeBindings
{
	BOOL					OK = YES;
	const GLchar			*sourceStrings[2] = { "", NULL };
	GLuint					vertexShader = 0;
	GLuint					fragmentShader = 0;
	
	OO_ENTER_OPENGL();
	
	self = [super init];
	if (self == nil)  OK = NO;
	
	if (OK && vertexSource == nil && fragmentSource == nil)  OK = NO;	// Must have at least one shader!
	
	if (OK && prefixString != nil)
	{
		sourceStrings[0] = [prefixString UTF8String];
	}
	
	if (OK && vertexSource != nil)
	{
		// Compile vertex shader.
		OOGL(vertexShader = glCreateShader(GL_VERTEX_SHADER));
		if (vertexShader != 0)
		{
			sourceStrings[1] = [vertexSource UTF8String];
			OOGL(glShaderSource(vertexShader, 2, sourceStrings, NULL));
			OOGL(glCompileShader(vertexShader));
			
			OK = ValidateShaderObject(vertexShader, vertexName);
		}
		else  OK = NO;
	}
	
	if (OK && fragmentSource != nil)
	{
		// Compile fragment shader.
		OOGL(fragmentShader = glCreateShader(GL_FRAGMENT_SHADER));
		if (fragmentShader != 0)
		{
			sourceStrings[1] = [fragmentSource UTF8String];
			OOGL(glShaderSource(fragmentShader, 2, sourceStrings, NULL));
			OOGL(glCompileShader(fragmentShader));
			
			OK = ValidateShaderObject(fragmentShader, fragmentName);
		}
		else  OK = NO;
	}
	
	if (OK)
	{
		// Link shader.
		OOGL(program = glCreateProgram());
		if (program != 0)
		{
			if (vertexShader != 0)  OOGL(glAttachShader(program, vertexShader));
			if (fragmentShader != 0)  OOGL(glAttachShader(program, fragmentShader));
			[self bindAttributes:attributeBindings];
			OOGL(glLinkProgram(program));
			
			OK = ValidateShaderObject(program, [NSString stringWithFormat:@"%@/%@", vertexName, fragmentName]);
		}
		else  OK = NO;
	}
	
	if (vertexShader != 0)  OOGL(glDeleteShader(vertexShader));
	if (fragmentShader != 0)  OOGL(glDeleteShader(fragmentShader));
	
	if (!OK)
	{
		if (program != 0)
		{
			OOGL(glDeleteShader(program));
			program = 0;
		}
		
		[self release];
		self = nil;
	}
	return self;
}


- (void) bindAttributes:(NSDictionary *)attributeBindings
{
	OO_ENTER_OPENGL();
	
	NSString				*attrKey = nil;
	NSEnumerator			*keyEnum = nil;
	
	for (keyEnum = [attributeBindings keyEnumerator]; (attrKey = [keyEnum nextObject]); )
	{
		OOGL(glBindAttribLocation(program, [attributeBindings oo_unsignedIntForKey:attrKey], [attrKey UTF8String]));	
	}
}

@end


static NSString *GetGLSLInfoLog(GLuint shaderObject)
{
	GLint					length;
	GLchar					*log = NULL;
	
	OO_ENTER_OPENGL();
	
	if (EXPECT_NOT(shaderObject == 0))  return nil;
	
	BOOL isProgram = glIsProgram(shaderObject);
	if (isProgram)
	{
		OOGL(glGetProgramiv(shaderObject, GL_INFO_LOG_LENGTH, &length));
	}
	else
	{
		OOGL(glGetShaderiv(shaderObject, GL_INFO_LOG_LENGTH, &length));
	}
	
	log = malloc(length);
	if (log == NULL)
	{
		length = 1024;
		log = malloc(length);
		if (log == NULL)  return @"<out of memory>";
	}
	
	if (isProgram)
	{
		OOGL(glGetProgramInfoLog(shaderObject, length, NULL, log));
	}
	else
	{
		OOGL(glGetShaderInfoLog(shaderObject, length, NULL, log));
	}
	
	NSString *result = [NSString stringWithUTF8String:log];
	if (result == nil)  result = [[[NSString alloc] initWithBytes:log length:length - 1 encoding:NSISOLatin1StringEncoding] autorelease];
	return result;
}


static BOOL ValidateShaderObject(GLuint object, NSString *name)
{
	GLint		shaderType, status;
	NSString	*shaderTypeString = nil;
	NSString	*actionString = nil;
	
	OO_ENTER_OPENGL();
	
	BOOL linking;
	OOGL(linking = glIsProgram(object));
	
	if (linking)
	{
		shaderTypeString = @"shader program";
		actionString = @"linking";
		OOGL(glGetProgramiv(object, GL_LINK_STATUS, &status));
	}
	else
	{
		// FIXME
		OOGL(glGetShaderiv(object, GL_SHADER_TYPE, &shaderType));
		switch (shaderType)
		{
			case GL_VERTEX_SHADER:
				shaderTypeString = @"vertex shader";
				break;
				
			case GL_FRAGMENT_SHADER:
				shaderTypeString = @"fragment shader";
				break;
				
#if GL_EXT_geometry_shader4
			case GL_GEOMETRY_SHADER_EXT:
				shaderTypeString = @"geometry shader";
				break;
#endif
				
			default:
				shaderTypeString = [NSString stringWithFormat:@"<unknown shader type 0x%.4X>", shaderType];
		}
		actionString = @"compilation";
		OOGL(glGetShaderiv(object, GL_COMPILE_STATUS, &status));
	}
	
	if (status == GL_FALSE)
	{
		NSString *msgClass = [NSString stringWithFormat:@"shader.%@.failure", linking ? @"link" : @"compile"];
		OOLogERR(msgClass, @"GLSL %@ %@ failed for %@:\n>>>>> GLSL log:\n%@\n", shaderTypeString, actionString, name, GetGLSLInfoLog(object));
		return NO;
	}
	
	return YES;
}
