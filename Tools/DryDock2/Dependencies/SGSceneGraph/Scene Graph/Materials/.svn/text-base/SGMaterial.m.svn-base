/*
	SGMaterial.m
	
	
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

#import "SGMaterial.h"
#import "SGTexture2D.h"


const SGColorRGBA kSGColorDefaultDiffuse	= {0.8f, 0.8f, 0.8f, 1.0f};
const SGColorRGBA kSGColorDefaultAmbient	= {0.2f, 0.2f, 0.2f, 1.0f};
const SGColorRGBA kSGColorWhite				= {1.0f, 1.0f, 1.0f, 1.0f};
const SGColorRGBA kSGColorBlack				= {0.0f, 0.0f, 0.0f, 1.0f};


@implementation SGMaterial

- (void)applyTo:(GLenum)inFace
{
	[NSException raise:NSGenericException format:@"%s: subclasses must override this method.", __FUNCTION__];
}


- (void)apply
{
	[self applyTo:GL_FRONT_AND_BACK];
}


- (void)removeMaterial
{
	
}

@end


@implementation SGSimpleAttributeMaterial

#pragma mark NSObject

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{diffuse:%@ ambient:%@, emission:%@, specular:%@, shininess:%i}",
									  [self className],
									  self,
									  SGColorDescription([self diffuseColor]),
									  SGColorDescription([self ambientColor]),
									  SGColorDescription([self emissionColor]),
									  SGColorDescription([self specularColor]),
									  [self specularExponent]];
}


#pragma mark SGMaterial

static inline void SGApplyColor(GLenum inFace, GLenum inProperty, SGColorRGBA *inColor)
{
	float color[4];
	
	assert(inColor != NULL);
	color[0] = inColor->r;
	color[1] = inColor->g;
	color[2] = inColor->b;
	color[3] = inColor->a;
	
	glMaterialfv(inFace, inProperty, color);
}


- (void)applyTo:(GLenum)inFace
{
	SGApplyColor(inFace, GL_DIFFUSE, &diffuse);
	SGApplyColor(inFace, GL_AMBIENT, &ambient);
	SGApplyColor(inFace, GL_EMISSION, &emission);
	SGApplyColor(inFace, GL_SPECULAR, &specular);
	glMateriali(inFace, GL_SHININESS, shininess);
}


#pragma mark SGSimpleAttributeMaterial

+ (id)materialWithDiffuseColor:(SGColorRGBA)inDiffuse ambientColor:(SGColorRGBA)inAmbient
{
	return [[[self alloc] initWithDiffuseColor:inDiffuse ambientColor:inAmbient] autorelease];
}


+ (id)materialWithDiffuseColor:(SGColorRGBA)inDiffuse
				  ambientColor:(SGColorRGBA)inAmbient
				 specularColor:(SGColorRGBA)inSpecularColor
			  specularExponent:(GLint)inExponent
{
	return [[[self alloc] initWithDiffuseColor:inDiffuse
								  ambientColor:inAmbient
								 specularColor:inSpecularColor
							  specularExponent:inExponent] autorelease];
}

- (id)init	// Designated initializer
{
	self = [super init];
	if (self != nil)
	{
		diffuse = kSGColorDefaultDiffuse;
		ambient = kSGColorDefaultAmbient;
		emission = kSGColorDefaultEmission;
		specular = kSGColorDefaultSpecular;
	}
	
	return self;
}


- (id)initWithDiffuseColor:(SGColorRGBA)inDiffuse ambientColor:(SGColorRGBA)inAmbient
{
	self = [self init];
	if (self != nil)
	{
		[self setDiffuseColor:inDiffuse];
		[self setAmbientColor:inAmbient];
	}
	return self;
}


- (id)initWithDiffuseColor:(SGColorRGBA)inDiffuse
			  ambientColor:(SGColorRGBA)inAmbient
			 specularColor:(SGColorRGBA)inSpecularColor
		  specularExponent:(GLint)inExponent
{
	self = [self initWithDiffuseColor:inDiffuse ambientColor:inAmbient];
	if (self != nil)
	{
		[self setSpecularColor:inSpecularColor];
		[self setSpecularExponent:inExponent];
	}
	return self;
}


- (SGColorRGBA)diffuseColor
{
	return diffuse;
}


- (void)setDiffuseColor:(SGColorRGBA)inColor
{
	diffuse = inColor;
}


- (SGColorRGBA)ambientColor
{
	return ambient;
}


- (void)setAmbientColor:(SGColorRGBA)inColor
{
	ambient = inColor;
}


- (SGColorRGBA)emissionColor
{
	return emission;
}


- (void)setEmissionColor:(SGColorRGBA)inColor
{
	emission = inColor;
}


- (SGColorRGBA)specularColor
{
	return specular;
}


- (void)setSpecularColor:(SGColorRGBA)inColor
{
	specular = inColor;
}


- (GLint)specularExponent
{
	return shininess;
}


- (void)setSpecularExponent:(GLint)inExponent
{
	// Clamp to permissible range: [0,128]
	if (inExponent < 0) shininess = 0;
	else if (128 < inExponent) shininess = 128;
	else shininess = inExponent;
}

@end


@implementation SGSimpleTexture2DMaterial

#pragma mark NSObject

- (void)dealloc
{
	[texture release];
	
	[super dealloc];
}


#pragma mark SGMaterial

- (void)applyTo:(GLenum)inFace
{
	[super applyTo:inFace];
	
	if (texture != nil)
	{
		if (textureName == 0)
		{
			glGenTextures(1, &textureName);
			if (textureName == 0) return;
			
			assert(textureBound == 0);
		}
		
		glBindTexture(GL_TEXTURE_2D, textureName);
		if (!textureBound)
		{
			[texture bind];
			textureBound = YES;
		}
	}
}


- (void)removeMaterial
{
	if (textureBound)
	{
		glDeleteTextures(1, &textureName);
		textureName = 0;
		textureBound = NO;
	}
	[super removeMaterial];
}


#pragma mark SGSimpleTexture2DMaterial

+ (id)materialWithTexture:(SGTexture2D *)inTexture
{
	return [[[self alloc] initWithTexture:inTexture] autorelease];
}


+ (id)materialWithImage:(NSImage *)inImage
{
	return [[[self alloc] initWithImage:inImage] autorelease];
}


- (id)init
{
	self = [super init];
	if (self != nil)
	{
		[self setDiffuseColor:kSGColorWhite];
	}
	return self;
}


- (id)initWithTexture:(SGTexture2D *)inTexture
{
	self = [self init];
	if (self != nil)
	{
		texture = [inTexture retain];
	}
	return self;
}


- (id)initWithImage:(NSImage *)inImage
{
	return [self initWithTexture:[SGTexture2D textureWithImage:inImage]];
}


- (SGTexture2D *)texture
{
	return [[texture retain] autorelease];
}


- (void)setTexture:(SGTexture2D *)inTexture
{
	if (inTexture != texture)
	{
		textureBound = NO;
		[texture release];
		texture = [inTexture retain];
	}
}

@end


@implementation SGMaterial (SGSimpleAttributeMaterialConveniences)

// These cover the corresponding SGSimpleAttributeMaterial methods.
+ (id)materialWithDiffuseColor:(SGColorRGBA)inDiffuse ambientColor:(SGColorRGBA)inAmbient
{
	return [SGSimpleAttributeMaterial materialWithDiffuseColor:inDiffuse ambientColor:inAmbient];
}


+ (id)materialWithDiffuseColor:(SGColorRGBA)inDiffuse ambientColor:(SGColorRGBA)inAmbient specularColor:(SGColorRGBA)inSpecularColor specularExponent:(GLint)inExponent
{
	return [SGSimpleAttributeMaterial materialWithDiffuseColor:inDiffuse
												  ambientColor:inAmbient
												 specularColor:inSpecularColor
											  specularExponent:inExponent];
}

@end


@implementation SGMaterial (SGSimpleTexture2DMaterialConveniences)

// These cover the corresponding SGSimpleTexture2DMaterial methods.
+ (id)materialWithTexture:(SGTexture2D *)inTexture
{
	return [SGSimpleTexture2DMaterial materialWithTexture:inTexture];
}


+ (id)materialWithImage:(NSImage *)inImage
{
	return [SGSimpleTexture2DMaterial materialWithImage:inImage];
}

@end


SGColorRGBA SGColorFromNSColor(NSColor *inColor)
{
	NSColor			*rgb;
	SGColorRGBA		result;
	
	rgb = [inColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	result.r = [rgb redComponent];
	result.g = [rgb greenComponent];
	result.b = [rgb blueComponent];
	result.a = [rgb alphaComponent];
	
	return result;
}


NSString *SGColorDescription(SGColorRGBA inColor)
{
	return [NSString stringWithFormat:@"{%g, %g, %g, %g}", inColor.r, inColor.g, inColor.b, inColor.a];
}
