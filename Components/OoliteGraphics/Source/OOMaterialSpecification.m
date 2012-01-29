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
NSString * const kOOMaterialSpecularColorMapName			= @"specularColorMap";
NSString * const kOOMaterialSpecularExponentName			= @"specularExponent";
NSString * const kOOMaterialSpecularExponentMapName			= @"specularExponentMap";

NSString * const kOOMaterialLightMaps						= @"lightMaps";

NSString * const kOOMaterialNormalMapName					= @"normalMap";
NSString * const kOOMaterialParallaxMapName					= @"parallaxMap";

NSString * const kOOMaterialParallaxScale					= @"parallaxScale";
NSString * const kOOMaterialParallaxBias					= @"parallaxBias";

NSString * const kOOMaterialLightMapColor					= @"color";
NSString * const kOOMaterialLightMapTextureMapName			= @"map";
NSString * const kOOMaterialLightMapType					= @"type";
NSString * const kOOMaterialLightMapTypeValueEmission		= @"emission";
NSString * const kOOMaterialLightMapTypeValueIllumination	= @"illumination";


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


- (id) initWithMaterialKey:(NSString *)materialKey propertyListRepresentation:(NSDictionary *)propertyList issues:(id <OOProblemReporting>)issues
{
	if ((self = [self initWithMaterialKey:materialKey]))
	{
		if (![self loadPropertyListRepresentation:propertyList issues:issues])  DESTROY(self);
	}
	
	return self;
}


+ (id) anonymousMaterial
{
	return [[[[self class] alloc] initWithMaterialKey:@"<unnamed>"] autorelease];
}


- (void) dealloc
{
	DESTROY(_materialKey);
	
	DESTROY(_diffuseColor);
	DESTROY(_ambientColor);
	DESTROY(_diffuseMap);
	
	DESTROY(_specularColor);
	DESTROY(_specularColorMap);
	DESTROY(_specularExponentMap);
	
	DESTROY(_lightMaps);
	
	DESTROY(_normalMap);
	DESTROY(_parallaxMap);
	
	[super dealloc];
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"\"%@\"", self.materialKey);
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


static void GetTexture(NSMutableDictionary *plist, NSString *key, OOTextureSpecification **textureSpec, id <OOProblemReporting> issues)
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


static void GetLightMap(OOMaterialSpecification *self, id plist, id <OOProblemReporting> issues)
{
	OOLightMapSpecification *lightMapSpec = [[OOLightMapSpecification alloc] initWithPropertyListRepresentation:plist
																										 issues:issues];
	if (lightMapSpec != nil)
	{
		[self addLightMap:lightMapSpec];
		[lightMapSpec release];
	}
}


- (BOOL) loadPropertyListRepresentation:(NSDictionary *)propertyList issues:(id <OOProblemReporting>)issues
{
	if (propertyList == nil)  return NO;
	
	NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithDictionary:propertyList];
	
	GetColor(plist, kOOMaterialDiffuseColorName, &_diffuseColor);
	GetColor(plist, kOOMaterialAmbientColorName, &_ambientColor);
	GetTexture(plist, kOOMaterialDiffuseMapName, &_diffuseMap, issues);
	
	GetColor(plist, kOOMaterialSpecularColorName, &_specularColor);
	GetTexture(plist, kOOMaterialSpecularColorMapName, &_specularColorMap, issues);
	if ([plist objectForKey:kOOMaterialSpecularExponentName] != nil)
	{
		_specularExponent = [plist oo_unsignedIntForKey:kOOMaterialSpecularExponentName];
		[plist removeObjectForKey:kOOMaterialSpecularExponentName];
		 if (_specularExponent < 0)  _specularExponent = 0;
	}
	GetTexture(plist, kOOMaterialSpecularExponentMapName, &_specularExponentMap, issues);
	
	id lightMaps = [plist objectForKey:kOOMaterialLightMaps];
	if ([lightMaps isKindOfClass:[NSArray class]])
	{
		id lightMapPList = nil;
		foreach (lightMapPList, lightMaps)
		{
			GetLightMap(self, lightMapPList, issues);
		}
	}
	else if (lightMaps != nil)
	{
		GetLightMap(self, lightMaps, issues);
	}
	
	GetTexture(plist, kOOMaterialNormalMapName, &_normalMap, issues);
	GetTexture(plist, kOOMaterialParallaxMapName, &_parallaxMap, issues);
	if ([plist objectForKey:kOOMaterialParallaxScale] != nil)
	{
		_parallaxScale = [plist oo_floatForKey:kOOMaterialParallaxScale];
		[plist removeObjectForKey:kOOMaterialParallaxScale];
	}
	if ([plist objectForKey:kOOMaterialParallaxBias] != nil)
	{
		_parallaxBias = [plist oo_floatForKey:kOOMaterialParallaxBias];
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


- (OOTextureSpecification *) specularColorMap
{
	return _specularColorMap;
}


- (void) setSpecularColorMap:(OOTextureSpecification *)texture
{
	if (_specularColorMap != texture)
	{
		[_specularColorMap release];
		_specularColorMap = [texture retain];
	}
}


- (unsigned) specularExponent
{
	if (_specularExponent >= 0)  return _specularExponent;
	else  return (_specularExponentMap == nil) ? kDefaultSpecularExponentNoMap : kDefaultSpecularExponentWithMap;
}


- (void) setSpecularExponent:(unsigned)value
{
	_specularExponent = value;
}


- (OOTextureSpecification *) specularExponentMap
{
	return _specularExponentMap;
}


- (void) setSpecularExponentMap:(OOTextureSpecification *)texture
{
	if (_specularExponentMap != texture)
	{
		[_specularExponentMap release];
		_specularExponentMap = [texture retain];
	}
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


- (NSArray *) lightMaps
{
	if (_lightMaps != nil)
	{
		return [[_lightMaps copy] autorelease];
	}
	else
	{
		return [NSArray array];
	}
}


- (void) addLightMap:(OOLightMapSpecification *)lightMap
{
	[self insertLightMap:lightMap atIndex:[[self lightMaps] count]];
}


- (void) insertLightMap:(OOLightMapSpecification *)lightMap atIndex:(NSUInteger)index
{
	if (_lightMaps == nil)  _lightMaps = [[NSMutableArray alloc] initWithCapacity:1];
	
	[_lightMaps insertObject:lightMap atIndex:index];
}


- (void) removeLightMapAtIndex:(NSUInteger)index
{
	[_lightMaps removeObjectAtIndex:index];
}


- (void) replaceLightMapAtIndex:(NSUInteger)index withLightMap:(OOLightMapSpecification *)lightMap
{
	[_lightMaps replaceObjectAtIndex:index withObject:lightMap];
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
	return [self setParallaxScale:[value floatValue]];
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
	return [self setParallaxBias:[value floatValue]];
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
	if ([key isEqualToString:kOOMaterialSpecularColorMapName])  [self setSpecularColorMap:TextureSpec(value)];
	if ([key isEqualToString:kOOMaterialSpecularExponentName])  [self setBoxedSpecularExponent:value];
	if ([key isEqualToString:kOOMaterialSpecularExponentMapName])  [self setSpecularExponentMap:TextureSpec(value)];
	
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
	ADD_TEXTURE(kOOMaterialSpecularColorMapName, _specularColorMap);
	unsigned defaultSpecExp = (_specularExponentMap == nil) ? kDefaultSpecularExponentNoMap : kDefaultSpecularExponentWithMap;
	if ([self specularExponent] != defaultSpecExp)  [result oo_setUnsignedInteger:_specularExponent forKey:kOOMaterialSpecularExponentName];
	ADD_TEXTURE(kOOMaterialSpecularExponentMapName, _specularExponentMap);
	
	NSArray *lightMaps = [self lightMaps];
	if ([lightMaps count] > 0)  [result setObject:[lightMaps ja_propertyListRepresentationWithContext:context] forKey:kOOMaterialLightMaps];
	
	ADD_TEXTURE(kOOMaterialNormalMapName, _normalMap);
	ADD_TEXTURE(kOOMaterialParallaxMapName, _parallaxMap);
	if (_parallaxScale != kDefaultParallaxScale)  [result oo_setFloat:_parallaxScale forKey:kOOMaterialParallaxScale];
	if (_parallaxBias != kDefaultParallaxBias)  [result oo_setFloat:_parallaxBias forKey:kOOMaterialParallaxBias];
	
	return  result;
}

@end


@implementation OOLightMapSpecification


- (id) initWithType:(OOLightMapType)type
			  color:(OOColor *)color
			texture:(OOTextureSpecification *)texture
{
	NSParameterAssert(texture != nil);
	
	if ([OOLightMapSpecification stringFromType:type] == nil)
	{
		// Invalid type.
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_type = type;
		_color = [color retain];
		_textureMap = [texture retain];
	}
	
	return self;
}

- (id) initWithPropertyListRepresentation:(id)plist
								   issues:(id <OOProblemReporting>)issues
{
	NSParameterAssert(plist != nil);
	
	BOOL					OK = YES;
	OOColor					*color = nil;
	id						texturePList;
	OOTextureSpecification	*texture = nil;
	OOLightMapType			type = kOOLightMapTypeDefault;
	
	if ([plist isKindOfClass:[NSString class]])
	{
		// Just a string: treat as texture name.
		texturePList = plist;
	}
	else if ([plist isKindOfClass:[NSDictionary class]])
	{
		texturePList = [plist objectForKey:kOOMaterialLightMapTextureMapName];
		if (texturePList == nil)
		{
			// No "map" key: it may be a texture dictionary.
			texturePList = plist;
		}
		else
		{
			color = [OOColor colorWithDescription:[plist objectForKey:kOOMaterialLightMapColor]];
			NSString *typeString = [plist oo_stringForKey:kOOMaterialLightMapType];
			if (typeString != nil && ![OOLightMapSpecification getType:&type fromString:typeString])
			{
				OOReportWarning(issues, @"Unknown light map type \"%@\", treating as \"%@\".", typeString, [OOLightMapSpecification stringFromType:type]);
			}
		}
	}
	else
	{
		OOReportError(issues, @"Light map specification must be a dictionary or a string, got %@.", [plist class]);
	}
	
	if (OK)
	{
		texture = [OOTextureSpecification textureSpecWithPropertyListRepresentation:texturePList issues:issues];
		OK = (texture != nil);
	}
	
	if (OK)
	{
		return [self initWithType:type
							color:color
						  texture:texture];
	}
	else
	{
		[self release];
		return nil;
	}
}


- (void) dealloc
{
	DESTROY(_color);
	DESTROY(_textureMap);
	
	[self dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
	// Immutable FTW.
	return [self retain];
}


- (NSString *) descriptionComponents
{
	NSString *result = $sprintf(@"%@ -- %@", [OOLightMapSpecification stringFromType:[self type]], [[self textureMap] shortDescription]);
	
	OOColor *color = [self color];
	if (color != nil)
	{
		result = [result stringByAppendingFormat:@" * %@", color];
	}
	
	return result;
}


- (OOLightMapType) type
{
	return _type;
}


- (OOColor *) color
{
	return _color ? [_color autorelease] : [OOColor whiteColor];
}


- (OOTextureSpecification *) textureMap
{
	return [_textureMap autorelease];
}


- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	OOColor			*color = [self color];
	BOOL			isWhite = [color isWhite];
	id				textureSpec = [[self textureMap] ja_propertyListRepresentationWithContext:context];
	OOLightMapType	type = [self type];
	
	// Boil the whole thing down to just texture name if possible.
	if (isWhite && type == kOOLightMapTypeDefault && [textureSpec isKindOfClass:[NSString class]])
	{
		return textureSpec;
	}
	
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:3];
	
	[result setObject:textureSpec forKey:kOOMaterialLightMapTextureMapName];
	if (!isWhite)
	{
		[result setObject:[color normalizedArray] forKey:kOOMaterialLightMapColor];
	}
	if (_type != kOOLightMapTypeDefault)
	{
		[result setObject:[OOLightMapSpecification stringFromType:_type] forKey:kOOMaterialLightMapType];
	}
	
	return result;
}


+ (NSString *) stringFromType:(OOLightMapType)type
{
#define CASE(TYPE) case kOOLightMapType##TYPE: return kOOMaterialLightMapTypeValue##TYPE;
	
	switch (type)
	{
		// When updating, copy cases to +getType:fromString: below.
		CASE(Emission)
		CASE(Illumination)
	}
	
#undef CASE
	
	return nil;
}


+ (BOOL) getType:(OOLightMapType *)type fromString:(NSString *)string
{
	NSParameterAssert(type != NULL);
	
#define CASE(TYPE) if ([string isEqualToString:kOOMaterialLightMapTypeValue##TYPE])  { *type = kOOLightMapType##TYPE; return YES; }
	
	CASE(Emission)
	CASE(Illumination)
	
#undef CASE
	
	*type = kOOLightMapTypeDefault;
	return NO;
}

@end
