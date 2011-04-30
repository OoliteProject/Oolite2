/*

OOTexture.h

Load, track and manage textures. In general, this should be used through an
OOMaterial.

Note: OOTexture is abstract. The factory methods return instances of
OOConcreteTexture, but special-case implementations are possible.


Copyright (C) 2007-2010 Jens Ayton and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import <OoliteBase/OoliteBase.h>

#import "OOOpenGL.h"
#import "OOPixMap.h"
#import "OOTextureSpecification.h"

@class OOTextureLoader, OOTextureGenerator;


enum
{
	
	kOOTextureDefinedFlags			= kOOTextureMinFilterMask | kOOTextureMagFilterMask
									| kOOTextureShrinkIfLarge
									| kOOTextureNoShrink
									| kOOTextureNeverScale
									| kOOTextureCubeMap
									| kOOTextureRepeatS
									| kOOTextureRepeatT
									| kOOTextureNoFNFMessage
									| kOOTextureAlphaMask,
	
	kOOTextureFlagsAllowedForCubeMap =
									kOOTextureDefinedFlags & ~(kOOTextureRepeatS | kOOTextureRepeatT)
};


typedef enum
{
	kOOTextureDataInvalid			= kOOPixMapInvalidFormat,
	
	kOOTextureDataRGBA				= kOOPixMapRGBA,			// GL_RGBA
	kOOTextureDataGrayscale			= kOOPixMapGrayscale,		// GL_LUMINANCE (or GL_ALPHA with kOOTextureAlphaMask)
	kOOTextureDataGrayscaleAlpha	= kOOPixMapGrayscaleAlpha	// GL_LUMINANCE_ALPHA
} OOTextureDataFormat;


@interface OOTexture: OOWeakRefObject
{
@protected
#ifndef NDEBUG
	BOOL						_trace;
#endif
}

//	Load a texture.
+ (id) textureWithSpecification:(OOTextureSpecification *)spec
				   fileResolver:(id <OOFileResolving>)resolver
				problemReporter:(id <OOProblemReporting>)problemReporter;

/*	Return the "null texture", a texture object representing an empty texture.
	Applying the null texture is equivalent to calling [OOTexture applyNone].
*/
+ (id) nullTexture;

/*	Load a texture from a generator.
*/
+ (id) textureWithGenerator:(OOTextureGenerator *)generator;


/*	Bind the texture to the current texture unit.
	This will block until loading is completed.
*/
- (void) apply;

+ (void) applyNone;

/*	Ensure texture is loaded. This is required because setting up textures
	inside display lists isn't allowed.
*/
- (void) ensureFinishedLoading;

/*	Check whether a texture has loaded. NOTE: this does not do the setup that
	-ensureFinishedLoading does, so -ensureFinishedLoading is still required
	before using the texture in a display list.
*/
- (BOOL) isFinishedLoading;

- (NSString *) cacheKey;

/*	Dimensions in pixels.
	This will block until loading is completed.
*/
- (NSSize) dimensions;

/*	Check whether texture is mip-mapped.
	This will block until loading is completed.
*/
- (BOOL) isMipMapped;

/*	Create a new pixmap with a copy of the texture data. The caller is
	responsible for free()ing the resulting buffer.
*/
- (OOPixMap) copyPixMapRepresentation;

/*	Identify special texture types.
*/
- (BOOL) isCubeMap;

#ifndef NDEBUG
- (void) setTrace:(BOOL)trace;

- (size_t) dataSize;

- (NSString *) name;
#endif

@end


uint8_t OOTextureComponentsForFormat(OOTextureDataFormat format);
