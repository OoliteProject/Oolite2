/*
	OOTextureSpecification.m
	
	
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

#import "OOTextureSpecification.h"


NSString * const kOOTextureNameKey				= @"name";

NSString * const kOOTextureMinFilterKey			= @"minFilter";
NSString * const kOOTextureMagFilterKey			= @"magFilter";
NSString * const kOOTextureDefaultFilterName	= @"default";
NSString * const kOOTextureNearestFilterName	= @"nearest";
NSString * const kOOTextureLinearFilterName		= @"linear";
NSString * const kOOTextureMipMapFilterName		= @"mipmap";

NSString * const kOOTextureNoShrinkKey			= @"noShrink";
NSString * const kOOTextureRepeatSKey			= @"repeatS";
NSString * const kOOTextureRepeatTKey			= @"repeatT";
NSString * const kOOTextureCubeMapKey			= @"cubeMap";

NSString * const kOOTextureAnisotropyKey		= @"anisotropy";
NSString * const kOOTextureLODBiasKey			= @"lodBias";

NSString * const kOOTextureExtractChannelKey	= @"extract";
NSString * const kOOTextureRedChannelName		= @"r";
NSString * const kOOTextureGreenChannelName		= @"g";
NSString * const kOOTextureBlueChannelName		= @"b";
NSString * const kOOTextureAlphaChannelName		= @"a";


@implementation OOTextureSpecification

+ (id) textureSpecWithName:(NSString *)name
{
	OOTextureSpecification *result = [[self alloc] init];
	[result setTextureMapName:name];
	return [result autorelease];
}


+ (id) textureSpecWithPropertyListRepresentation:(id)rep issues:(id <OOProblemReporting>)issues
{
	OOTextureSpecification *result = [[[self alloc] init] autorelease];
	
	if ([rep isKindOfClass:[NSString class]])
	{
		[result setTextureMapName:rep];
	}
	else if ([rep isKindOfClass:[NSDictionary class]])
	{
		NSString *name = [rep oo_stringForKey:kOOTextureNameKey];
		if (name == nil)
		{
			OOReportError(issues, @"Texture specifier does not include name, ignoring.");
			return nil;
		}
		
		[result setTextureMapName:name];
		
		OOTextureOptionFlags options = kOOTextureDefaultOptions;
		NSString *stringValue = [rep oo_stringForKey:kOOTextureMinFilterKey];
		if (stringValue != nil)
		{
			if ([stringValue isEqualToString:kOOTextureNearestFilterName])  options |= kOOTextureMinFilterNearest;
			else if ([stringValue isEqualToString:kOOTextureLinearFilterName])  options |= kOOTextureMinFilterLinear;
			else if ([stringValue isEqualToString:kOOTextureMipMapFilterName])  options |= kOOTextureMinFilterMipMap;
			else if (![stringValue isEqualToString:kOOTextureDefaultFilterName])
			{
				OOReportWarning(issues, @"Unknown texture minification mode key \"%@\" for texture \"%@\", ignoring.", stringValue, name);
			}
		}
		
		stringValue = [rep oo_stringForKey:kOOTextureMagFilterKey];
		if (stringValue != nil)
		{
			if ([stringValue isEqualToString:kOOTextureNearestFilterName])  options |= kOOTextureMagFilterNearest;
			else
			{
				if (![stringValue isEqualToString:kOOTextureLinearFilterName] && ![stringValue isEqualToString:kOOTextureDefaultFilterName])
				{
					OOReportWarning(issues, @"Unknown texture magnification mode key \"%@\" for texture \"%@\", ignoring.", stringValue, name);
				}
				
				options |= kOOTextureMagFilterLinear;
			}
		}
		
		stringValue = [rep oo_stringForKey:kOOTextureExtractChannelKey];
		if (stringValue != nil)
		{
			if ([stringValue isEqualToString:kOOTextureRedChannelName])  options |= kOOTextureExtractChannelR;
			else if ([stringValue isEqualToString:kOOTextureGreenChannelName])  options |= kOOTextureExtractChannelG;
			else if ([stringValue isEqualToString:kOOTextureBlueChannelName])  options |= kOOTextureExtractChannelB;
			else if ([stringValue isEqualToString:kOOTextureAlphaChannelName])  options |= kOOTextureExtractChannelA;
			else
			{
				OOReportWarning(issues, @"Unknown texture channel extract key \"%@\" for texture \"%@\", ignoring.", stringValue, name);
			}
		}
		
		if ([rep oo_boolForKey:kOOTextureNoShrinkKey])  options |= kOOTextureNoShrink;
		if ([rep oo_boolForKey:kOOTextureRepeatSKey])  options |= kOOTextureRepeatS;
		if ([rep oo_boolForKey:kOOTextureRepeatTKey])  options |= kOOTextureRepeatT;
		if ([rep oo_boolForKey:kOOTextureCubeMapKey])  options |= kOOTextureCubeMap;
		
		[result setOptionFlags:options];
		
		result->_anisotropy = [rep oo_floatForKey:kOOTextureAnisotropyKey defaultValue:kOOTextureDefaultAnisotropy];
		result->_lodBias = [rep oo_floatForKey:kOOTextureLODBiasKey defaultValue:kOOTextureDefaultLODBias];
	}
	else
	{
		OOReportError(issues, @"Texture specifier is not string or dictionary, ignoring.");
		return nil;
	}

	return result;
}


- (id) init
{
	if ((self = [super init]))
	{
		_optionFlags = kOOTextureDefaultOptions;
		_anisotropy = kOOTextureDefaultAnisotropy;
		_lodBias = kOOTextureDefaultLODBias;
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_name);
	
	[super dealloc];
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"\"%@\"", [self textureMapName]);
}


- (NSString *) textureMapName
{
	return _name;
}


- (void) setTextureMapName:(NSString *)value
{
	[_name autorelease];
	_name = [value copy];
}


#define SET_BITS(mask, value)  do { OOTextureOptionFlags mask_ = (mask); _optionFlags = (_optionFlags & ~mask_) | ((value) & mask_); } while (0)
#define SET_FLAG(mask, value) do { OOTextureOptionFlags mask__ = (mask); SET_BITS(mask__, (value) ? mask__ : 0); } while (0)



- (OOTextureMinFilter) minFilter
{
	return _optionFlags & kOOTextureMinFilterMask;
}


- (void) setMinFilter:(OOTextureMinFilter)value
{
	SET_BITS(kOOTextureMinFilterMask, value);
}


- (OOTextureMagFilter) magFilter
{
	return _optionFlags & kOOTextureMagFilterMask;
}


- (void) setMagFilter:(OOTextureMagFilter)value
{
	SET_BITS(kOOTextureMagFilterMask, value);
}


- (OOTextureChannelExtractMode) extractChannelMode
{
	return _optionFlags & kOOTextureExtractChannelMask;
}


- (void) setExtractChannelMode:(OOTextureChannelExtractMode)value
{
	SET_BITS(kOOTextureExtractChannelMask, value);
}


- (BOOL) allowShrink
{
	return !(_optionFlags & kOOTextureNoShrink);
}


- (void) setAllowShrink:(BOOL)value
{
	SET_FLAG(kOOTextureNoShrink, !value);
}


- (BOOL) allowResizing
{
	return !(_optionFlags & kOOTextureNeverScale);
}


- (void) setAllowResizing:(BOOL)value
{
	SET_FLAG(kOOTextureNeverScale, !value);
}


- (BOOL) repeatS
{
	return !!(_optionFlags & kOOTextureRepeatS);
}


- (void) setAllowRepeatS:(BOOL)value
{
	SET_FLAG(kOOTextureRepeatS, value);
}


- (BOOL) repeatT
{
	return !!(_optionFlags & kOOTextureRepeatT);
}


- (void) setAllowRepeatT:(BOOL)value
{
	SET_FLAG(kOOTextureRepeatT, value);
}


- (BOOL) suppressFileNotFoundMessage
{
	return !!(_optionFlags & kOOTextureNoFNFMessage);
}


- (void) setSuppressFileNotFoundMessage:(BOOL)value
{
	SET_FLAG(kOOTextureNoFNFMessage, value);
}


- (BOOL) isAlphaMask
{
	return !!(_optionFlags & kOOTextureAlphaMask);
}


- (void) setAlphaMask:(BOOL)value
{
	SET_FLAG(kOOTextureAlphaMask, value);
}


- (BOOL) isCubeMap
{
	return !!(_optionFlags & kOOTextureCubeMap);
}


- (void) setCubeMap:(BOOL)value
{
	SET_FLAG(kOOTextureCubeMap, value);
}


- (OOTextureOptionFlags) optionFlags
{
	return _optionFlags;
}


- (void) setOptionFlags:(OOTextureOptionFlags)optionFlags
{
	_optionFlags = optionFlags;
}


- (float) anisotropy
{
	return _anisotropy;
}


- (void) setAnisotropy:(float)value
{
	_anisotropy = OOClamp_0_1_f(value);
}


- (float) lodBias
{
	return _lodBias;
}


- (void) setLODBias:(float)value
{
	_lodBias = value;
}


- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	if (_optionFlags == kOOTextureDefaultOptions && _anisotropy == kOOTextureDefaultAnisotropy && _lodBias == kOOTextureDefaultLODBias)
	{
		return [[_name retain] autorelease];
	}
	else
	{
		if (_name == nil)  return nil;	// A texture specifier without a name is meaningless.
		
		NSMutableDictionary *result = [NSMutableDictionary dictionary];
		
		[result setObject:_name forKey:kOOTextureNameKey];
		NSString *stringValue = nil;
		if ((_optionFlags & kOOTextureMinFilterMask) != kOOTextureMinFilterDefault)
		{
			switch (_optionFlags & kOOTextureMinFilterMask)
			{
				case kOOTextureMinFilterNearest:
					stringValue = kOOTextureNearestFilterName;
					break;
					
				case kOOTextureMinFilterLinear:
					stringValue = kOOTextureLinearFilterName;
					break;
					
				case kOOTextureMinFilterMipMap:
					stringValue = kOOTextureMipMapFilterName;
					break;
			}
			if (stringValue != nil)  [result setObject:stringValue forKey:kOOTextureMinFilterKey];
		}
		
		if ((_optionFlags & kOOTextureMagFilterMask) == kOOTextureMagFilterNearest)
		{
			[result setObject:kOOTextureNearestFilterName forKey:kOOTextureMagFilterKey];
		}
		
		if (_optionFlags & kOOTextureNoShrink)  [result oo_setBool:YES forKey:kOOTextureNoShrinkKey];
		if (_optionFlags & kOOTextureRepeatS)  [result oo_setBool:YES forKey:kOOTextureRepeatSKey];
		if (_optionFlags & kOOTextureRepeatT)  [result oo_setBool:YES forKey:kOOTextureRepeatTKey];
		if (_optionFlags & kOOTextureCubeMap)  [result oo_setBool:YES forKey:kOOTextureCubeMapKey];
		
		if (_anisotropy != kOOTextureDefaultAnisotropy)  [result oo_setFloat:_anisotropy forKey:kOOTextureAnisotropyKey];
		if (_lodBias != kOOTextureDefaultLODBias)  [result oo_setFloat:_lodBias forKey:kOOTextureLODBiasKey];
		
		if ((_optionFlags & kOOTextureExtractChannelMask) != kOOTextureExtractChannelNone)
		{
			switch (_optionFlags & kOOTextureExtractChannelMask)
			{
				case kOOTextureExtractChannelR:
					stringValue = kOOTextureRedChannelName;
					break;
					
				case kOOTextureExtractChannelG:
					stringValue = kOOTextureGreenChannelName;
					break;
					
				case kOOTextureExtractChannelB:
					stringValue = kOOTextureBlueChannelName;
					break;
					
				case kOOTextureExtractChannelA:
					stringValue = kOOTextureAlphaChannelName;
					break;
			}
			if (stringValue != nil)  [result setObject:stringValue forKey:kOOTextureExtractChannelKey];
		}
		
		return result;
	}
}

@end
