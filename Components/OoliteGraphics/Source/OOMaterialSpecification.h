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

@class OOLightMapSpecification;	// Declared below


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
	
	NSMutableArray				*_lightMaps;
	
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

- (NSArray *) lightMaps;
- (void) addLightMap:(OOLightMapSpecification *)lightMap;
- (void) insertLightMap:(OOLightMapSpecification *)lightMap atIndex:(NSUInteger)index;
- (void) removeLightMapAtIndex:(NSUInteger)index;
- (void) replaceLightMapAtIndex:(NSUInteger)index withLightMap:(OOLightMapSpecification *)lightMap;

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


typedef enum OOLightMapType
{
	kOOLightMapTypeEmission,
	kOOLightMapTypeIllumination,
	
	kOOLightMapTypeDefault = kOOLightMapTypeEmission
} OOLightMapType;

/*
	OOLightMapSpecification
	Immutable specification for a single light map.
*/
@interface OOLightMapSpecification: NSObject <JAPropertyListRepresentation, NSCopying>
{
@private
	OOLightMapType				_type;
	OOColor						*_color;
	OOTextureSpecification		*_textureMap;
}

- (id) initWithType:(OOLightMapType)type
			  color:(OOColor *)color
			texture:(OOTextureSpecification *)texture;	// May not be nil.

- (id) initWithPropertyListRepresentation:(id)propertyList
								   issues:(id <OOProblemReporting>)issues;

- (OOLightMapType) type;
- (OOColor *) color;
- (OOTextureSpecification *) textureMap;

+ (NSString *) stringFromType:(OOLightMapType)type;
+ (BOOL) getType:(OOLightMapType *)type fromString:(NSString *)string;	// For invalid strings, sets *type to kOOLightMapTypeDefault and returns NO.

@end


// OOMaterialSpecification property list keys.
extern NSString * const kOOMaterialDiffuseColorName;
extern NSString * const kOOMaterialAmbientColorName;
extern NSString * const kOOMaterialDiffuseMapName;

extern NSString * const kOOMaterialSpecularColorName;
extern NSString * const kOOMaterialSpecularColorMapName;
extern NSString * const kOOMaterialSpecularExponentName;
extern NSString * const kOOMaterialSpecularExponentMapName;

extern NSString * const kOOMaterialLightMaps;

extern NSString * const kOOMaterialNormalMapName;
extern NSString * const kOOMaterialParallaxMapName;

extern NSString * const kOOMaterialParallaxScale;
extern NSString * const kOOMaterialParallaxBias;


// OOLightMapSpecification keys.
extern NSString * const kOOMaterialLightMapColor;
extern NSString * const kOOMaterialLightMapTextureMapName;
extern NSString * const kOOMaterialLightMapType;
extern NSString * const kOOMaterialLightMapTypeValueEmission;
extern NSString * const kOOMaterialLightMapTypeValueIllumination;
