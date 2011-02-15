/*
	SGLight.m
	
	
	Copyright © 2008-2009 Jens Ayton
	
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

#import "SGLight.h"

#if SCENGRAPH_LIGHTING

#import <Cocoa/Cocoa.h>	// For NSColor


static NSString *ColorDesc(GLfloat color[4]);


@implementation SGLight

@synthesize name = _name;
@synthesize enabled = _enabled;
@synthesize constantAttenuation = _constantAttenuation;
@synthesize linearAttenuation = _linearAttenuation;
@synthesize quadraticAttenuation = _quadraticAttenuation;
@synthesize spotDirection = _spotDirection;
@synthesize spotExponent = _spotExponent;
@synthesize spotCutoff = _spotCutoff;


- (id) init
{
	self = [super init];
	if (self != nil)
	{
		// Set defaults as per header
		_position[2] = 1.0f;
		_enabled = YES;
		_diffuse[3] = 1.0f;
		_specular[3] = 1.0f;
		_ambient[3] = 1.0f;
		_constantAttenuation = 1.0f;
		_spotDirection.z = -1.0f;
		_spotCutoff = 180.0f;
		// Everything else 0
	}
	return self;
}


- (void) dealloc
{
	[_name release];
	
	[super dealloc];
}


- (NSString *) description
{
	NSString *desc = nil;
	
	if (self.enabled)
	{
		NSString *type = nil;
		if (self.spotCutoff == 180.0f)
		{
			if (self.positional)  type = @"positional";
			else  type = @"directional";
		}
		else
		{
			type = @"spot";
		}
		
		desc = $sprintf(@"%@ (%@), %@", self.position.Description(), type, ColorDesc(_diffuse));
		if (self.spotCutoff != 180.0f)
		{
			desc = $sprintf(@"%@, spot direction: %@, cutoff: %.1g", desc, self.spotDirection.Description(), self.spotCutoff);
		}
	}
	else  desc = @"disabled";
	
	if (self.name != nil)
	{
		desc = $sprintf(@"\"%@\" - %@", self.name);
	}
	
	return $sprintf(@"<%@ %p>{%@}", self.className, self, desc);
}


- (id) copyWithZone:(NSZone *)zone
{
	return NSCopyObject(self, 0, zone);
	[_name retain];
}


- (SGVector3) position
{
	return SGVector3(_position[0], _position[1], _position[2]);
}


- (void) setPosition:(SGVector3)position
{
	_position[0] = position.x;
	_position[1] = position.y;
	_position[2] = position.z;
}


- (BOOL) isPositional
{
	return _position[3] != 0.0;
}


- (void) setPositional:(BOOL)positional
{
	_position[3] = positional ? 1.0 : 0.0;
}


- (NSColor *) diffuse
{
	return [NSColor colorWithDeviceRed:_diffuse[0] green:_diffuse[1] blue:_diffuse[2] alpha:_diffuse[3]];
}


- (void) setDiffuse:(NSColor *)color
{
	color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	_diffuse[0] = color.redComponent;
	_diffuse[1] = color.greenComponent;
	_diffuse[2] = color.blueComponent;
	_diffuse[3] = color.alphaComponent;
}


- (NSColor *) specular
{
	return [NSColor colorWithDeviceRed:_specular[0] green:_specular[1] blue:_specular[2] alpha:_specular[3]];
}


- (void) setSpecular:(NSColor *)color
{
	color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	_specular[0] = color.redComponent;
	_specular[1] = color.greenComponent;
	_specular[2] = color.blueComponent;
	_specular[3] = color.alphaComponent;
}


- (NSColor *) ambient
{
	return [NSColor colorWithDeviceRed:_ambient[0] green:_ambient[1] blue:_ambient[2] alpha:_ambient[3]];
}


- (void) setAmbient:(NSColor *)color
{
	color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	_ambient[0] = color.redComponent;
	_ambient[1] = color.greenComponent;
	_ambient[2] = color.blueComponent;
	_ambient[3] = color.alphaComponent;
}


- (void) applyToLight:(GLenum)light
{
	NSParameterAssert(light >= GL_LIGHT0 && light < 0x5000);
	
	if (_enabled)
	{
		glEnable(light);
		glLightfv(light, GL_DIFFUSE, _diffuse);
		glLightfv(light, GL_SPECULAR, _specular);
		glLightfv(light, GL_POSITION, _position);
		glLightfv(light, GL_SPOT_DIRECTION, _spotDirection.v);
		glLightf(light, GL_SPOT_EXPONENT, _spotExponent);
		glLightf(light, GL_SPOT_CUTOFF, _spotCutoff);
		glLightf(light, GL_CONSTANT_ATTENUATION, _constantAttenuation);
		glLightf(light, GL_LINEAR_ATTENUATION, _linearAttenuation);
		glLightf(light, GL_QUADRATIC_ATTENUATION, _quadraticAttenuation);
		const GLfloat zero[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
		glLightfv(light, GL_AMBIENT, zero);
	}
	else
	{
		[SGLight disableAndClearLight:light];
	}
}


+ (void) disableAndClearLight:(GLenum)light
{
	NSParameterAssert(light >= GL_LIGHT0 && light < 0x5000);
	
	const GLfloat zero[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
	
	glDisable(light);
	glLightfv(light, GL_DIFFUSE, zero);
	glLightfv(light, GL_SPECULAR, zero);
	glLightfv(light, GL_AMBIENT, zero);
}


- (void) getDiffuseRed:(GLfloat *)r green:(GLfloat *)g blue:(GLfloat *)b alpha:(GLfloat *)a
{
	NSParameterAssert(r != NULL && g != NULL && b != NULL && a != NULL);
	
	*r = _diffuse[0];
	*g = _diffuse[1];
	*b = _diffuse[2];
	*a = _diffuse[3];
}


- (void) getSpecularRed:(GLfloat *)r green:(GLfloat *)g blue:(GLfloat *)b alpha:(GLfloat *)a
{
	NSParameterAssert(r != NULL && g != NULL && b != NULL && a != NULL);
	
	*r = _specular[0];
	*g = _specular[1];
	*b = _specular[2];
	*a = _specular[3];
}


- (void) getAmbientRed:(GLfloat *)r green:(GLfloat *)g blue:(GLfloat *)b alpha:(GLfloat *)a
{
	NSParameterAssert(r != NULL && g != NULL && b != NULL && a != NULL);
	
	*r = _ambient[0];
	*g = _ambient[1];
	*b = _ambient[2];
	*a = _ambient[3];
}


- (void) addAmbientRed:(GLfloat *)r green:(GLfloat *)g blue:(GLfloat *)b
{
	NSParameterAssert(r != NULL && g != NULL && b != NULL);
	
	*r += _ambient[0] * _ambient[3];
	*g += _ambient[1] * _ambient[3];
	*b += _ambient[2] * _ambient[3];
}

@end


static NSString *ColorDesc(GLfloat color[4])
{
	return $sprintf(@"{%.2f %.2f %.2f %.2f}", color[0], color[1], color[2], color[3]);
}

#endif	// SCENGRAPH_LIGHTING
