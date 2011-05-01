/*
	OOTextureSpecification.h
	
	Description of a texture map for oomesh.
	
	
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

@protocol OOProblemReporting;


/*	Note that these enumeration values are assigned such that they can be
	merged into a single bitfield together with the option flags.
*/
typedef enum
{
	kOOTextureMinFilterDefault		= 0x00000000UL,
	kOOTextureMinFilterNearest		= 0x00000001UL,
	kOOTextureMinFilterLinear		= 0x00000002UL,
	kOOTextureMinFilterMipMap		= 0x00000003UL
} OOTextureMinFilter;


typedef enum
{
	kOOTextureMagFilterNearest		= 0x00000000UL,
	kOOTextureMagFilterLinear		= 0x00000004UL
} OOTextureMagFilter;


enum
{
	kOOTextureShrinkIfLarge			= 0x00000010UL,
	kOOTextureNoShrink				= 0x00000020UL,
	kOOTextureNeverScale			= 0x00000040UL,	// Don't rescale texture, even if result is not usable as texture. This *must not* be used for regular textures, but may be passed to OOTextureLoader when being used for other purposes.
	
	kOOTextureRepeatS				= 0x00000080UL,
	kOOTextureRepeatT				= 0x00000100UL,
	kOOTextureNoFNFMessage			= 0x00000200UL,	// Don't log file not found error
	kOOTextureAlphaMask				= 0x00000200UL,	// Single-channel texture should be GL_ALPHA, not GL_LUMINANCE. No effect for multi-channel textures.
	kOOTextureCubeMap				= 0x00000400UL,
	
	kOOTextureMinFilterMask			= 0x00000003UL,
	kOOTextureMagFilterMask			= 0x00000004UL,
	
	kOOTextureDefaultOptions		= kOOTextureMinFilterDefault | kOOTextureMagFilterLinear
};

typedef uint32_t OOTextureOptionFlags;


#define kOOTextureDefaultAnisotropy		0.5f
#define kOOTextureDefaultLODBias		-0.1f


@interface OOTextureSpecification: NSObject <JAPropertyListRepresentation>
{
@private
	NSString						*_name;
	
	float							_anisotropy;
	float							_lodBias;
	
	OOTextureOptionFlags			_optionFlags;
	NSString						*_extractMode;
}

+ (id) textureSpecWithName:(NSString *)name;
+ (id) textureSpecWithPropertyListRepresentation:(id)rep issues:(id <OOProblemReporting>)issues;

- (NSString *) textureMapName;
- (void) setTextureMapName:(NSString *)value;

- (OOTextureMinFilter) minFilter;
- (void) setMinFilter:(OOTextureMinFilter)value;

- (OOTextureMagFilter) magFilter;
- (void) setMagFilter:(OOTextureMagFilter)value;

/*
	extractMode: a string of one to four characters in the set {r, g, b, a}
	(lowercase) specifying which channels of the texture image to use, or nil
	indicating that the default (which depends on context) should be used.
	
	-setExtractMode: fails if its parameter does not match this format, and
	-extractMode will never return an invalid value.
	
	NOTE: extraction is actually handled by the default material synthesizer
	(and can’t be used with custom shaders). It’s attached to the texture
	specifier to simplify manangement both in code and in material specs.
*/
- (NSString *) extractMode;
- (BOOL) setExtractMode:(NSString *)value;

- (BOOL) allowShrink;
- (void) setAllowShrink:(BOOL)value;

- (BOOL) allowResizing;
- (void) setAllowResizing:(BOOL)value;

- (BOOL) repeatS;
- (void) setAllowRepeatS:(BOOL)value;

- (BOOL) repeatT;
- (void) setAllowRepeatT:(BOOL)value;

- (BOOL) suppressFileNotFoundMessage;
- (void) setSuppressFileNotFoundMessage:(BOOL)value;

- (BOOL) isAlphaMask;
- (void) setAlphaMask:(BOOL)value;

- (BOOL) isCubeMap;
- (void) setCubeMap:(BOOL)value;

- (OOTextureOptionFlags) optionFlags;
- (void) setOptionFlags:(OOTextureOptionFlags)optionFlags;

- (float) anisotropy;
- (void) setAnisotropy:(float)value;

- (float) lodBias;
- (void) setLODBias:(float)value;

@end


extern NSString * const kOOTextureNameKey;

extern NSString * const kOOTextureMinFilterKey;
extern NSString * const kOOTextureMagFilterKey;
extern NSString * const kOOTextureDefaultFilterName;
extern NSString * const kOOTextureNearestFilterName;
extern NSString * const kOOTextureLinearFilterName;
extern NSString * const kOOTextureMipMapFilterName;

extern NSString * const kOOTextureNoShrinkKey;
extern NSString * const kOOTextureRepeatSKey;
extern NSString * const kOOTextureRepeatTKey;
extern NSString * const kOOTextureCubeMapKey;

extern NSString * const kOOTextureAnisotropyKey;
extern NSString * const kOOTextureLODBiasKey;

extern NSString * const kOOTextureExtractChannelKey;
extern NSString * const kOOTextureExtractChannelIdentity;	// "rgba"
