/*
	SGLightManager.m
	
	
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

#import "SGLightManager.h"
#import "SGLight.h"

#if SCENGRAPH_LIGHTING

#define DEBUG_DUMP	0


@implementation SGLightManager

@synthesize context = _context;
@synthesize maxLights = _maxCount;


#if DEBUG_DUMP
static void GLDumpLightState(void);
static void GLDumpOneLightState(unsigned lightIdx);
static NSString *GLColorToString(GLfloat color[4]);
#endif


- (id) initWithContext:(NSOpenGLContext *)context
{
	if (context == nil)
	{
		context = [NSOpenGLContext currentContext];
		if (context == nil)
		{
			[self release];
			return nil;
		}
	}
	
	self = [super init];
	if (self != nil)
	{
		_context = [context retain];
		_lights = [NSMutableSet set];
		
		NSOpenGLContext *saved = [NSOpenGLContext currentContext];
		[_context makeCurrentContext];
		GLint max;
		glGetIntegerv(GL_MAX_LIGHTS, &max);
		_maxCount = max;
		[saved makeCurrentContext];
	}
	
	return self;
}


- (id) initWithCurrentContext
{
	return [self initWithContext:nil];
}


- (id) init
{
	return [self initWithCurrentContext];
}


- (void) dealloc
{
	[_context release];
	[_lights release];
	
	[super dealloc];
}


- (NSEnumerator *) lightEnumerator
{
	return [_lights objectEnumerator];
}


- (void) addLight:(SGLight *)light
{
	if (light != nil)  [_lights addObject:light];
}


- (void) removeLight:(SGLight *)light
{
	if (light != nil)  [_lights removeObject:light];
}


- (void) setUpLights
{
	NSUInteger used = 0;
	
	NSOpenGLContext *saved = [NSOpenGLContext currentContext];
	if (saved != _context)  [_context makeCurrentContext];
	
	GLfloat ambient[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
	
	for (SGLight *light in _lights)
	{
		if (!light.enabled)  continue;
		
		[light applyToLight:GL_LIGHT0 + used];
		[light addAmbientRed:&ambient[0] green:&ambient[1] blue:&ambient[2]];
		if (++used == _maxCount)  break;
	}
	
	// Disable remaining lights
	NSUInteger active = used;
	while (used < _activeCount)
	{
		[SGLight disableAndClearLight:GL_LIGHT0 + used];
		++used;
	}
	_activeCount = active;
	
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, ambient);
	
#if DEBUG_DUMP
	GLDumpLightState();
	NSLog(@"*** Global lighting: ***");
	NSLog(@"Light model ambient: %@", GLColorToString(ambient));
#endif
	
	if (saved != _context)  [saved makeCurrentContext];
}


- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state
								   objects:(id *)stackbuf
									 count:(NSUInteger)len
{
	// Fast enumerate over lights
	return [_lights countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end


@implementation SGLightManager (Conveniences)

- (void) removeAllLights
{
	[_lights removeAllObjects];
}


- (void) enableAllLights
{
	for (SGLight *light in _lights)
	{
		light.enabled = YES;
	}
}


- (void) disableAllLights
{
	for (SGLight *light in _lights)
	{
		light.enabled = NO;
	}
}

@end


#if DEBUG_DUMP
static NSString *GLColorToString(GLfloat color[4])
{
#define COLOR_EQUAL(color, r, g, b, a)  (color[0] == (r) && color[1] == (g) && color[2] == (b) && color[3] == (a))
#define COLOR_CASE(r, g, b, a, str)  do { if (COLOR_EQUAL(color, (r), (g), (b), (a)))  return (str); } while (0)
	
	/*COLOR_CASE(1, 1, 1, 1, @"white");
	COLOR_CASE(0, 0, 0, 1, @"black");
	COLOR_CASE(0, 0, 0, 0, @"clear");
	COLOR_CASE(1, 0, 0, 1, @"red");
	COLOR_CASE(0, 1, 0, 1, @"green");
	COLOR_CASE(0, 0, 1, 1, @"blue");
	COLOR_CASE(0, 1, 1, 1, @"cyan");
	COLOR_CASE(1, 0, 1, 1, @"magenta");
	COLOR_CASE(1, 1, 0, 1, @"yellow");*/
	
	return [NSString stringWithFormat:@"(%.2f, %.2f, %.2f, %.2f)", color[0], color[1], color[2], color[3]];
}


static void GLDumpOneLightState(unsigned lightIdx)
{
	GLenum			lightID = GL_LIGHT0 + lightIdx;
	GLfloat			values[4];
	
	glGetLightfv(lightID, GL_POSITION, values);
	NSLog(@"Position: { %g, %g, %g, %g }", values[0], values[1], values[2], values[3]);
	glGetLightfv(lightID, GL_AMBIENT, values);
	NSLog(@"Ambient: %@", GLColorToString(values));
	glGetLightfv(lightID, GL_DIFFUSE, values);
	NSLog(@"Diffuse: %@", GLColorToString(values));
	glGetLightfv(lightID, GL_SPECULAR, values);
	NSLog(@"Specular: %@", GLColorToString(values));
	
	glGetLightfv(lightID, GL_SPOT_CUTOFF, values);
	if (values[0] != 180)
	{
		NSLog(@"Spot cutoff: %g", values[0]);
		glGetLightfv(lightID, GL_SPOT_DIRECTION, values);
		NSLog(@"Spot direction: { %g, %g, %g, %g }", values[0], values[1], values[2], values[3]);
		glGetLightfv(lightID, GL_SPOT_EXPONENT, values);
		NSLog(@"Spot exponent: %g", values[0]);
	}
	
	glGetLightfv(lightID, GL_CONSTANT_ATTENUATION, values);
	glGetLightfv(lightID, GL_LINEAR_ATTENUATION, values + 1);
	glGetLightfv(lightID, GL_QUADRATIC_ATTENUATION, values + 2);
	if (values[1] || values[2])
	{
		NSLog(@"Attenuation: 1 / (%g + %g * d + %g * d * d)", values[0], values[1], values[2]);
	}
	else if (values[0] == 0.0)
	{
		NSLog(@"Attenuation: NaN");
	}
	else if (values[0] != 1.0)
	{
		NSLog(@"Attenuation: %g", 1.0 / values[0]);
	}
}


static void GLDumpLightState(void)
{
	GLint max;
	glGetIntegerv(GL_MAX_LIGHTS, &max);
	
	for (GLint i = 0; i < max; i++)
	{
		if (glIsEnabled(GL_LIGHT0 + i))
		{
			NSLog(@"*** Light %i: ***", i);
			GLDumpOneLightState(i);
		}
	}
}
#endif	/* DEBUG_DUMP */
#endif	/* SCENGRAPH_LIGHTING */
