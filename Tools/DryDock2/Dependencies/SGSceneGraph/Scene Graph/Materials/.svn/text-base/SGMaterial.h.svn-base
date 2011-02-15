/*
	SGMaterial.h
	
	Base class for materials in SGSceneGraph.
	
	
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

#import "SGSceneGraphBase.h"

@class SGTexture2D;


typedef struct SGColorRGBA
{
	GLfloat					r,
							g,
							b,
							a;
} SGColorRGBA;


@interface SGMaterial: NSObject

- (void)applyTo:(GLenum)inFace;	// Primitive. Subclasses must override this.
- (void)apply;					// Equivalent to applyTo:GL_FRONT_AND_BACK

/*	removeMaterial
	Removes any material-related resources (textures, shaders, object names)
	from the GL context. This MUST be called explicitly if you stop using the
	material while keeping the context around, or the resources will be
	leaked. The GL context must be active when calling this method.
	
	This does not delete the underlying objects the GL resources represent;
	for instance, for a texture-based material, the SGTexture2D object will
	remain, but the OpenGL texture name will be unbound. It is generally valid
	(but potentially inefficient) to call -removeMaterial and then use the
	material again, at which point any resources associated with the material
	will be regenerated. However, if you have, for example, called
	-dropUnderlyingRepresentation on any textures used by the material, the
	textures will not be regenerated properly.
*/
- (void)removeMaterial;

@end


@interface SGSimpleAttributeMaterial: SGMaterial
{
	SGColorRGBA				diffuse;
	SGColorRGBA				ambient;
	SGColorRGBA				emission;
	SGColorRGBA				specular;
	GLint					shininess;
}

+ (id)materialWithDiffuseColor:(SGColorRGBA)inDiffuse ambientColor:(SGColorRGBA)inAmbient;
+ (id)materialWithDiffuseColor:(SGColorRGBA)inDiffuse
				  ambientColor:(SGColorRGBA)inAmbient
				 specularColor:(SGColorRGBA)inSpecularColor
			  specularExponent:(GLint)inExponent;

- (id)init;	// Designated initializer
- (id)initWithDiffuseColor:(SGColorRGBA)inDiffuse ambientColor:(SGColorRGBA)inAmbient;
- (id)initWithDiffuseColor:(SGColorRGBA)inDiffuse
			  ambientColor:(SGColorRGBA)inAmbient
			 specularColor:(SGColorRGBA)inSpecularColor
		  specularExponent:(GLint)inExponent;

- (SGColorRGBA)diffuseColor;
- (void)setDiffuseColor:(SGColorRGBA)inColor;

- (SGColorRGBA)ambientColor;
- (void)setAmbientColor:(SGColorRGBA)inColor;

- (SGColorRGBA)emissionColor;
- (void)setEmissionColor:(SGColorRGBA)inColor;

- (SGColorRGBA)specularColor;
- (void)setSpecularColor:(SGColorRGBA)inColor;

- (GLint)specularExponent;		// Range: [0,128]. Default: 0.
- (void)setSpecularExponent:(GLint)inExponent;

@end


@interface SGSimpleTexture2DMaterial: SGSimpleAttributeMaterial
{
	SGTexture2D				*texture;
	GLuint					textureName;
	BOOL					textureBound;
}

+ (id)materialWithTexture:(SGTexture2D *)inTexture;
+ (id)materialWithImage:(NSImage *)inImage;

- (id)initWithTexture:(SGTexture2D *)inTexture;
- (id)initWithImage:(NSImage *)inImage;

- (SGTexture2D *)texture;
- (void)setTexture:(SGTexture2D *)inTexture;

@end


@interface SGMaterial (SGSimpleAttributeMaterialConveniences)

// These cover the corresponding SGSimpleAttributeMaterial methods.
+ (id)materialWithDiffuseColor:(SGColorRGBA)inDiffuse ambientColor:(SGColorRGBA)inAmbient;
+ (id)materialWithDiffuseColor:(SGColorRGBA)inDiffuse ambientColor:(SGColorRGBA)inAmbient specularColor:(SGColorRGBA)inSpecularColor specularExponent:(GLint)inExponent;

@end


@interface SGMaterial (SGSimpleTexture2DMaterialConveniences)

// These cover the corresponding SGSimpleTexture2DMaterial methods.
+ (id)materialWithTexture:(SGTexture2D *)inTexture;
+ (id)materialWithImage:(NSImage *)inImage;

@end


static inline SGColorRGBA SGMakeColorRGBA(GLfloat inRed, GLfloat inGreen, GLfloat inBlue, GLfloat inAlpha)
{
	SGColorRGBA result = {inRed, inGreen, inBlue, inAlpha};
	return result;
}


SGColorRGBA SGColorFromNSColor(NSColor *inColor);
NSString *SGColorDescription(SGColorRGBA inColor);
BOOL SGColorsEqual(SGColorRGBA inColorA, SGColorRGBA inColorB);


extern const SGColorRGBA kSGColorDefaultDiffuse;	// {0.8, 0.8, 0.8, 1.0}
extern const SGColorRGBA kSGColorDefaultAmbient;	// {0.2, 0.2, 0.2, 1.0}
#define					 kSGColorDefaultEmission	kSGColorBlack
#define					 kSGColorDefaultSpecular	kSGColorBlack
extern const SGColorRGBA kSGColorWhite;				// {1.0, 1.0, 1.0, 1.0}
extern const SGColorRGBA kSGColorBlack;				// {0.0, 0.0, 0.0, 1.0}
