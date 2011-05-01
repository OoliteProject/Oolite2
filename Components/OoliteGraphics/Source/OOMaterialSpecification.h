/*
	OOMaterialSpecification.h
	
	Definition of a material for oomesh.
	
	
	Copyright © 2010 Jens Ayton.
	
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

#import <OoliteBase/OoliteBase.h>
#import "OOTextureSpecification.h"
#import "OOColor.h"


@interface OOMaterialSpecification: NSObject <JAPropertyListRepresentation>
{
@private
	NSString					*_materialKey;
	
	OOColor						*_diffuseColor;
	OOColor						*_ambientColor;
	OOTextureSpecification		*_diffuseMap;
	
	OOColor						*_specularColor;
	OOTextureSpecification		*_specularColorMap;
	OOTextureSpecification		*_specularExponentMap;
	int							_specularExponent;
	
	OOColor						*_emissionColor;
	OOTextureSpecification		*_emissionMap;
	
	OOColor						*_illuminationColor;
	OOTextureSpecification		*_illuminationMap;
	
	OOTextureSpecification		*_normalMap;
	OOTextureSpecification		*_parallaxMap;
	float						_parallaxScale;
	float						_parallaxBias;
	
	NSMutableDictionary			*_extraAttributes;
}

//	Material key: a string identifying the material. Must be unique per file.
- (id) initWithMaterialKey:(NSString *)materialKey;
- (id) initWithMaterialKey:(NSString *)materialKey propertyListRepresentation:(NSDictionary *)propertyList issues:(id <OOProblemReporting>)issues;

+ (id) anonymousMaterial;

- (BOOL) loadPropertyListRepresentation:(NSDictionary *)propertyList issues:(id <OOProblemReporting>)issues;

- (NSString *) materialKey;

- (OOColor *) diffuseColor;
- (void) setDiffuseColor:(OOColor *)color;
- (OOColor *) ambientColor;
- (void) setAmbientColor:(OOColor *)color;
- (OOTextureSpecification *) diffuseMap;
- (void) setDiffuseMap:(OOTextureSpecification *)texture;

- (OOColor *) specularColor;
- (void) setSpecularColor:(OOColor *)color;
- (OOTextureSpecification *) specularColorMap;
- (void) setSpecularColorMap:(OOTextureSpecification *)texture;
- (unsigned) specularExponent;
- (void) setSpecularExponent:(unsigned)value;
- (OOTextureSpecification *) specularExponentMap;
- (void) setSpecularExponentMap:(OOTextureSpecification *)texture;

- (OOColor *) emissionColor;
- (void) setEmissionColor:(OOColor *)color;
- (OOTextureSpecification *) emissionMap;
- (void) setEmissionMap:(OOTextureSpecification *)texture;

- (OOColor *) illuminationColor;
- (void) setIlluminationColor:(OOColor *)color;
- (OOTextureSpecification *) illuminationMap;
- (void) setIlluminationMap:(OOTextureSpecification *)texture;

- (OOTextureSpecification *) normalMap;
- (void) setNormalMap:(OOTextureSpecification *)texture;
- (OOTextureSpecification *) parallaxMap;
- (void) setParallaxMap:(OOTextureSpecification *)texture;
- (float) parallaxScale;
- (void) setParallaxScale:(float)value;
- (float) parallaxBias;
- (void) setParallaxBias:(float)value;

- (id) valueForKey:(NSString *)key;
- (void) setValue:(id)value forKey:(NSString *)key;

@end


extern NSString * const kOOMaterialDiffuseColorName;
extern NSString * const kOOMaterialAmbientColorName;
extern NSString * const kOOMaterialDiffuseMapName;

extern NSString * const kOOMaterialSpecularColorName;
extern NSString * const kOOMaterialSpecularColorMapName;
extern NSString * const kOOMaterialSpecularExponentName;
extern NSString * const kOOMaterialSpecularExponentMapName;

extern NSString * const kOOMaterialEmissionColorName;
extern NSString * const kOOMaterialEmissionMapName;
extern NSString * const kOOMaterialIlluminationColorName;
extern NSString * const kOOMaterialIlluminationMapName;

extern NSString * const kOOMaterialNormalMapName;
extern NSString * const kOOMaterialParallaxMapName;

extern NSString * const kOOMaterialParallaxScale;
extern NSString * const kOOMaterialParallaxBias;
