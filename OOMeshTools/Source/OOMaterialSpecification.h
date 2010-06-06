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

#import <OOBase/OOBase.h>
#import "JAPropertyListRepresentation.h"
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
	OOColor						*_specularModulateColor;
	OOTextureSpecification		*_specularMap;
	int							_specularExponent;
	
	OOColor						*_emissionColor;
	OOColor						*_emissionModulateColor;
	OOTextureSpecification		*_emissionMap;
	OOColor						*_illuminationModulateColor;
	OOTextureSpecification		*_illuminationMap;
	
	OOTextureSpecification		*_normalMap;
	OOTextureSpecification		*_parallaxMap;
	float						_parallaxScale;
	float						_parallaxBias;
	
	NSMutableDictionary			*_extraAttributes;
}

//	Material key: a string identifying the material. Must be unique per file.
- (id) initWithMaterialKey:(NSString *)materialKey;
- (id) initWithMaterialKey:(NSString *)materialKey propertyListRepresentation:(NSDictionary *)propertyList issues:(id <OOProblemReportManager>)issues;

- (BOOL) loadPropertyListRepresentation:(NSDictionary *)propertyList issues:(id <OOProblemReportManager>)issues;

- (NSString *) materialKey;

- (OOColor *) diffuseColor;
- (void) setDiffuseColor:(OOColor *)color;
- (OOColor *) ambientColor;
- (void) setAmbientColor:(OOColor *)color;
- (OOTextureSpecification *) diffuseMap;
- (void) setDiffuseMap:(OOTextureSpecification *)texture;

- (OOColor *) specularColor;
- (void) setSpecularColor:(OOColor *)color;
- (OOColor *) specularModulateColor;
- (void) setSpecularModulateColor:(OOColor *)color;
- (OOTextureSpecification *) specularMap;
- (void) setSpecularMap:(OOTextureSpecification *)texture;
- (unsigned) specularExponent;
- (void) setSpecularExponent:(unsigned)value;

- (OOColor *) emissionColor;
- (void) setEmissionColor:(OOColor *)color;
- (OOColor *) emissionModulateColor;
- (void) setEmissionModulateColor:(OOColor *)color;
- (OOTextureSpecification *) emissionMap;
- (void) setEmissionMap:(OOTextureSpecification *)texture;
- (OOColor *) illuminationModulateColor;
- (void) setIlluminationModulateColor:(OOColor *)color;
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


NSString * const kOOMaterialDiffuseColorName;
NSString * const kOOMaterialAmbientColorName;
NSString * const kOOMaterialDiffuseMapName;

NSString * const kOOMaterialSpecularColorName;
NSString * const kOOMaterialSpecularModulateColorName;
NSString * const kOOMaterialSpecularMapName;
NSString * const kOOMaterialSpecularExponentName;

NSString * const kOOMaterialEmissionColorName;
NSString * const kOOMaterialEmissionModulateColorName;
NSString * const kOOMaterialIlluminationModulateColorName;
NSString * const kOOMaterialEmissionMapName;
NSString * const kOOMaterialIlluminationMapName;

NSString * const kOOMaterialNormalMapName;
NSString * const kOOMaterialParallaxMapName;

NSString * const kOOMaterialParallaxScale;
NSString * const kOOMaterialParallaxBias;
