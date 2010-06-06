/*
	OOMaterialSpecification.m
	
	
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

#import "OOMaterialSpecification.h"
#import "OOTextureSpecification.h"


NSString * const kOOMaterialDiffuseColorName				= @"diffuseColor";
NSString * const kOOMaterialAmbientColorName				= @"ambientColor";
NSString * const kOOMaterialDiffuseMapName					= @"diffuseMap";

NSString * const kOOMaterialSpecularColorName				= @"specularColor";
NSString * const kOOMaterialSpecularModulateColorName		= @"specularModulateColor";
NSString * const kOOMaterialSpecularMapName					= @"specularMap";
NSString * const kOOMaterialSpecularExponentName			= @"specularExponent";

NSString * const kOOMaterialEmissionColorName				= @"emissionColor";
NSString * const kOOMaterialEmissionModulateColorName		= @"emissionModulateColor";
NSString * const kOOMaterialIlluminationModulateColorName	= @"illuminationModulateColor";
NSString * const kOOMaterialEmissionMapName					= @"emissionMap";
NSString * const kOOMaterialIlluminationMapName				= @"illuminationMap";

NSString * const kOOMaterialNormalMapName					= @"normalMap";
NSString * const kOOMaterialParallaxMapName					= @"parallaxMap";

NSString * const kOOMaterialParallaxScale					= @"parallaxScale";
NSString * const kOOMaterialParallaxBias					= @"parallaxBias";


#define kDefaultSpecularIntensity		(0.2f)
#define kDefaultSpecularExponentWithMap	(128)
#define kDefaultSpecularExponentNoMap	(10)
#define kDefaultParallaxScale			(0.01f)
#define kDefaultParallaxBias			(0.0f)


@implementation OOMaterialSpecification

- (id) initWithMaterialKey:(NSString *)materialKey
{
	if (materialKey == nil)
	{
		DESTROY(self);
		return nil;
	}
	
	if ((self = [super init]))
	{
		_materialKey = [materialKey copy];
		
		_specularExponent = -1;	// causes appropriate default value to be used.
		_parallaxScale = kDefaultParallaxScale;
		_parallaxBias = kDefaultParallaxBias;
	}
	
	return self;
}


- (id) initWithMaterialKey:(NSString *)materialKey propertyListRepresentation:(NSDictionary *)propertyList issues:(id <OOProblemReportManager>)issues
{
	if ((self = [self initWithMaterialKey:materialKey]))
	{
		if (![self loadPropertyListRepresentation:propertyList issues:issues])  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_materialKey);
	
	DESTROY(_diffuseColor);
	DESTROY(_ambientColor);
	DESTROY(_diffuseMap);
	
	DESTROY(_specularColor);
	DESTROY(_specularModulateColor);
	DESTROY(_specularMap);
	
	DESTROY(_emissionColor);
	DESTROY(_emissionModulateColor);
	DESTROY(_emissionMap);
	DESTROY(_illuminationModulateColor);
	DESTROY(_illuminationMap);
	
	DESTROY(_normalMap);
	DESTROY(_parallaxMap);
	
	[super dealloc];
}


static void GetColor(NSMutableDictionary *plist, NSString *key, OOColor **color)
{
	NSCParameterAssert(plist != nil && key != nil && color != NULL);
	
	id colorDesc = [plist objectForKey:key];
	if (colorDesc != nil)
	{
		[plist removeObjectForKey:key];
		[*color release];
		*color = [[OOColor colorWithDescription:colorDesc] retain];
	}
}


static void GetTexture(NSMutableDictionary *plist, NSString *key, OOTextureSpecification **textureSpec, id <OOProblemReportManager> issues)
{
	NSCParameterAssert(plist != nil && key != nil && textureSpec != NULL);
	
	id textureDesc = [plist objectForKey:key];
	if (textureDesc != nil)
	{
		[plist removeObjectForKey:key];
		[*textureSpec release];
		*textureSpec = [[OOTextureSpecification textureSpecWithPropertyListRepresentation:textureDesc issues:issues] retain];
	}
}


- (BOOL) loadPropertyListRepresentation:(NSDictionary *)propertyList issues:(id <OOProblemReportManager>)issues
{
	if (propertyList == nil)  return NO;
	
	NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithDictionary:propertyList];
	
	GetColor(plist, kOOMaterialDiffuseColorName, &_diffuseColor);
	GetColor(plist, kOOMaterialAmbientColorName, &_ambientColor);
	GetTexture(plist, kOOMaterialDiffuseMapName, &_diffuseMap, issues);
	
	GetColor(plist, kOOMaterialSpecularColorName, &_specularColor);
	GetColor(plist, kOOMaterialSpecularModulateColorName, &_specularModulateColor);
	GetTexture(plist, kOOMaterialSpecularMapName, &_specularMap, issues);
	if ([plist objectForKey:kOOMaterialSpecularExponentName] != nil)
	{
		_specularExponent = [plist oo_unsignedIntForKey:kOOMaterialSpecularExponentName];
		[plist removeObjectForKey:kOOMaterialSpecularExponentName];
		 if (_specularExponent < 0)  _specularExponent = 0;
	}
	
	GetColor(plist, kOOMaterialEmissionColorName, &_emissionColor);
	GetColor(plist, kOOMaterialEmissionModulateColorName, &_emissionModulateColor);
	GetColor(plist, kOOMaterialIlluminationModulateColorName, &_illuminationModulateColor);
	GetTexture(plist, kOOMaterialEmissionMapName, &_emissionMap, issues);
	GetTexture(plist, kOOMaterialIlluminationMapName, &_illuminationMap, issues);
	
	GetTexture(plist, kOOMaterialNormalMapName, &_normalMap, issues);
	GetTexture(plist, kOOMaterialParallaxMapName, &_parallaxMap, issues);
	if ([plist objectForKey:kOOMaterialParallaxScale] != nil)
	{
		_parallaxScale = [plist oo_unsignedIntForKey:kOOMaterialParallaxScale];
		[plist removeObjectForKey:kOOMaterialParallaxScale];
	}
	if ([plist objectForKey:kOOMaterialParallaxBias] != nil)
	{
		_parallaxBias = [plist oo_unsignedIntForKey:kOOMaterialParallaxBias];
		[plist removeObjectForKey:kOOMaterialParallaxBias];
	}
	
	if ([plist count] != 0)
	{
		if (_extraAttributes == nil)
		{
			_extraAttributes = [plist retain];
		}
		else
		{
			[_extraAttributes addEntriesFromDictionary:plist];
		}

	}
	
	return YES;
}


- (NSString *) materialKey
{
	return _materialKey;
}


- (OOColor *) diffuseColor
{
	if (_diffuseColor == nil)  return [OOColor whiteColor];
	return _diffuseColor;
}


- (void) setDiffuseColor:(OOColor *)color
{
	if ([color isWhite])  color = nil;
	if (color != _diffuseColor)
	{
		[_diffuseColor release];
		_diffuseColor = [color copy];
	}
}


- (OOColor *) ambientColor
{
	if (_ambientColor == nil)  return [OOColor whiteColor];
	return _ambientColor;
}


- (void) setAmbientColor:(OOColor *)color
{
	if ([color isWhite])  color = nil;
	if (color != _ambientColor)
	{
		[_ambientColor release];
		_ambientColor = [color copy];
	}
}


- (OOTextureSpecification *) diffuseMap
{
	return _diffuseMap;
}


- (void) setDiffuseMap:(OOTextureSpecification *)texture
{
	if (_diffuseMap != texture)
	{
		[_diffuseMap release];
		_diffuseMap = [texture retain];
	}
}


- (OOColor *) specularColor
{
	if (_specularColor == nil)  return [OOColor colorWithWhite:kDefaultSpecularIntensity alpha:1.0];
	return _specularColor;
}


- (void) setSpecularColor:(OOColor *)color
{
	if (color != _specularColor)
	{
		[_specularColor release];
		_specularColor = [color copy];
	}
}


- (OOColor *) specularModulateColor
{
	if (_specularModulateColor == nil)  return [OOColor whiteColor];
	return _specularModulateColor;
}


- (void) setSpecularModulateColor:(OOColor *)color
{
	if ([color isWhite])  color = nil;
	if (color != _specularModulateColor)
	{
		[_specularModulateColor release];
		_specularModulateColor = [color copy];
	}
}


- (OOTextureSpecification *) specularMap
{
	return _specularMap;
}


- (void) setSpecularMap:(OOTextureSpecification *)texture
{
	if (_specularMap != texture)
	{
		[_specularMap release];
		_specularMap = [texture retain];
	}
}


- (unsigned) specularExponent
{
	if (_specularExponent >= 0)  _specularExponent;
	else  return (_specularMap == nil) ? kDefaultSpecularExponentNoMap : kDefaultSpecularExponentWithMap;
}


- (void) setSpecularExponent:(unsigned)value
{
	_specularExponent = value;
}


- (NSNumber *) boxed_specularExponent
{
	return $int([self specularExponent]);
}


- (void) setBoxedSpecularExponent:(NSNumber *)value
{
	if (EXPECT_NOT(![value respondsToSelector:@selector(intValue)]))  return;
	return [self setSpecularExponent:[value intValue]];
}


- (OOColor *) emissionColor
{
	if (_emissionColor == nil)  return [OOColor blackColor];
	return _emissionColor;
}


- (void) setEmissionColor:(OOColor *)color
{
	if ([color isBlack])  color = nil;
	if (color != _emissionColor)
	{
		[_emissionColor release];
		_emissionColor = [color copy];
	}
}


- (OOColor *) emissionModulateColor
{
	if (_emissionModulateColor == nil)  return [OOColor whiteColor];
	return _emissionModulateColor;
}


- (void) setEmissionModulateColor:(OOColor *)color
{
	if ([color isWhite])  color = nil;
	if (color != _emissionModulateColor)
	{
		[_emissionModulateColor release];
		_emissionModulateColor = [color copy];
	}
}


- (OOTextureSpecification *) emissionMap
{
	return _emissionMap;
}


- (void) setEmissionMap:(OOTextureSpecification *)texture
{
	if (_emissionMap != texture)
	{
		[_emissionMap release];
		_emissionMap = [texture retain];
	}
}


- (OOColor *) illuminationModulateColor
{
	if (_illuminationModulateColor == nil)  return [OOColor whiteColor];
	return _illuminationModulateColor;
}


- (void) setIlluminationModulateColor:(OOColor *)color
{
	if ([color isWhite])  color = nil;
	if (color != _illuminationModulateColor)
	{
		[_illuminationModulateColor release];
		_illuminationModulateColor = [color copy];
	}
}


- (OOTextureSpecification *) illuminationMap
{
	return _illuminationMap;
}


- (void) setIlluminationMap:(OOTextureSpecification *)texture
{
	if (_illuminationMap != texture)
	{
		[_illuminationMap release];
		_illuminationMap = [texture retain];
	}
}


- (OOTextureSpecification *) normalMap
{
	return _normalMap;
}


- (void) setNormalMap:(OOTextureSpecification *)texture
{
	if (_normalMap != texture)
	{
		[_normalMap release];
		_normalMap = [texture retain];
	}
}


- (OOTextureSpecification *) parallaxMap
{
	return _parallaxMap;
}


- (void) setParallaxMap:(OOTextureSpecification *)texture
{
	if (_parallaxMap != texture)
	{
		[_parallaxMap release];
		_parallaxMap = [texture retain];
	}
}


- (float) parallaxScale
{
	return _parallaxScale;
}


- (void) setParallaxScale:(float)value
{
	_parallaxScale = value;
}


- (NSNumber *) boxed_parallaxScale
{
	return $float([self parallaxScale]);
}


- (void) setBoxedParallaxScale:(NSNumber *)value
{
	if (EXPECT_NOT(![value respondsToSelector:@selector(doubleValue)]))  return;
	return [self setParallaxScale:[value doubleValue]];
}


- (float) parallaxBias
{
	return _parallaxBias;
}


- (void) setParallaxBias:(float)value
{
	_parallaxBias = value;
}


- (NSNumber *) boxed_parallaxBias
{
	return $float([self parallaxBias]);
}


- (void) setBoxedParallaxBias:(NSNumber *)value
{
	if (EXPECT_NOT(![value respondsToSelector:@selector(doubleValue)]))  return;
	return [self setParallaxBias:[value doubleValue]];
}


- (id) valueForKey:(NSString *)key
{
	if ([key rangeOfString:@":"].location == NSNotFound)
	{
		SEL selector = NSSelectorFromString([@"boxed_" stringByAppendingString:key]);
		if ([self respondsToSelector:selector])
		{
			return [self performSelector:selector];
		}
		selector = NSSelectorFromString(key);
		if ([self respondsToSelector:selector])
		{
			return [self performSelector:selector];
		}
	}
	
	return [_extraAttributes objectForKey:key];
}


static OOColor *Color(id value)
{
	if ([value isKindOfClass:[OOColor class]])  return value;
	else  return [OOColor colorWithDescription:value];
}


static OOTextureSpecification *TextureSpec(id value)
{
	if ([value isKindOfClass:[OOTextureSpecification class]])  return value;
	else  return [OOTextureSpecification textureSpecWithPropertyListRepresentation:value issues:nil];
}


- (void) setValue:(id)value forKey:(NSString *)key
{
	if ([key isEqualToString:kOOMaterialDiffuseColorName])  [self setDiffuseColor:Color(value)];
	if ([key isEqualToString:kOOMaterialAmbientColorName])  [self setAmbientColor:Color(value)];
	if ([key isEqualToString:kOOMaterialDiffuseMapName])  [self setDiffuseMap:TextureSpec(value)];
	
	if ([key isEqualToString:kOOMaterialSpecularColorName])  [self setSpecularColor:Color(value)];
	if ([key isEqualToString:kOOMaterialSpecularModulateColorName])  [self setSpecularModulateColor:Color(value)];
	if ([key isEqualToString:kOOMaterialSpecularMapName])  [self setSpecularMap:TextureSpec(value)];
	if ([key isEqualToString:kOOMaterialSpecularExponentName])  [self setBoxedSpecularExponent:value];
	
	if ([key isEqualToString:kOOMaterialEmissionColorName])  [self setEmissionColor:Color(value)];
	if ([key isEqualToString:kOOMaterialEmissionModulateColorName])  [self setEmissionModulateColor:Color(value)];
	if ([key isEqualToString:kOOMaterialIlluminationModulateColorName])  [self setIlluminationModulateColor:Color(value)];
	if ([key isEqualToString:kOOMaterialEmissionMapName])  [self setEmissionMap:TextureSpec(value)];
	if ([key isEqualToString:kOOMaterialIlluminationMapName])  [self setIlluminationMap:TextureSpec(value)];
	
	if ([key isEqualToString:kOOMaterialNormalMapName])  [self setNormalMap:TextureSpec(value)];
	if ([key isEqualToString:kOOMaterialParallaxMapName])  [self setParallaxMap:TextureSpec(value)];
	
	if ([key isEqualToString:kOOMaterialParallaxScale])  [self setBoxedParallaxScale:value];
	if ([key isEqualToString:kOOMaterialParallaxBias])  [self setBoxedParallaxBias:value];
	
	if (_extraAttributes == nil)  _extraAttributes = [[NSMutableDictionary alloc] init];
	[_extraAttributes setObject:value forKey:key];
}


- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:_extraAttributes];
	
#define ADD_COLOR(key, color_, defaultValue) \
	do { \
		OOColor *color = (color_); \
		if (color != nil && ![color isEqual:(defaultValue)]) \
		{ \
			[result setObject:[color normalizedArray] forKey:(key)]; \
		} \
	} while (0)
	
#define ADD_TEXTURE(key, textureSpec) \
	do \
	{ \
		id description = [(textureSpec) ja_propertyListRepresentation]; \
		if (description != nil)  [result setObject:description forKey:(key)]; \
	} while (0)
	
	OOColor *white = [OOColor whiteColor];
	ADD_COLOR(kOOMaterialDiffuseColorName, _diffuseColor, white);
	ADD_COLOR(kOOMaterialAmbientColorName, _ambientColor, white);
	ADD_TEXTURE(kOOMaterialDiffuseMapName, _diffuseMap);
	
	OOColor *defaultSpecular = (_specularExponent > 0.0f) ? [OOColor colorWithWhite:0.2f alpha:1.0f] : [OOColor blackColor];
	ADD_COLOR(kOOMaterialSpecularColorName, _specularColor, defaultSpecular);
	ADD_COLOR(kOOMaterialSpecularModulateColorName, _specularModulateColor, white);
	ADD_TEXTURE(kOOMaterialSpecularMapName, _specularMap);
	unsigned defaultSpecExp = (_specularMap == nil) ? kDefaultSpecularExponentNoMap : kDefaultSpecularExponentWithMap;
	if (_specularExponent != defaultSpecExp)  [result oo_setUnsignedInteger:_specularExponent forKey:kOOMaterialSpecularExponentName];
	
	ADD_COLOR(kOOMaterialEmissionColorName, _emissionColor, [OOColor blackColor]);
	ADD_COLOR(kOOMaterialEmissionModulateColorName, _emissionModulateColor, white);
	ADD_COLOR(kOOMaterialIlluminationModulateColorName, _illuminationModulateColor, white);
	ADD_TEXTURE(kOOMaterialEmissionMapName, _emissionMap);
	ADD_TEXTURE(kOOMaterialIlluminationMapName, _illuminationMap);
	
	ADD_TEXTURE(kOOMaterialNormalMapName, _normalMap);
	ADD_TEXTURE(kOOMaterialParallaxMapName, _parallaxMap);
	if (_parallaxScale != kDefaultParallaxScale)  [result oo_setFloat:_parallaxScale forKey:kOOMaterialParallaxScale];
	if (_parallaxBias != kDefaultParallaxBias)  [result oo_setFloat:_parallaxBias forKey:kOOMaterialParallaxBias];
	
	
#if 0
	// Test data
	[result setObject:$int(42) forKey:@"test-int"];
	[result setObject:$float(42.17) forKey:@"test-float"];
	
	[result setObject:$dict(
							@"empty-.array", [NSArray array],
							@"short_array", $array(@"", @"\""),
							@"longer array", $array(@"a", @"b", @" c ", @"d" , @"e")
						)
			   forKey:@"test-arrays"];
	
	[result setObject:$dict(@"a", @"A", @"b", @"slightly longer string") forKey:@"simple-dict"];
	[result setObject:$dict(@"a", @"A", @"b", @"B", @"c", @"C", @"d", @"D") forKey:@"non-simple-dict"];
	[result setObject:
	 $dict(@"nested",
		   $dict(@"nested",
				 $dict(@"nested", [NSDictionary dictionary]),
				 @"array", $array($int(1), @"string")
			)
	) forKey:@"nested-dict"];
	[result setObject:$array(@"This would be a simple array if it weren't for the fact that this long, rambling string is really rather long and rambling.") forKey:@"non-simple-array"];
#endif
	
	return  result;
}

@end
