/*
	SGTexture2D.m
	
	
	Copyright © 2005-2006 Jens Ayton
	
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

#import "SGTexture2D.h"
#import <OpenGL/glext.h>
#import "SGSceneGraphUtilities.h"


#if __BIG_ENDIAN__
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8_REV
#else
	#define ARGB_IMAGE_TYPE GL_UNSIGNED_INT_8_8_8_8
#endif


static BOOL AnisotropySupported(void);
static BOOL ValidClampMode(GLenum inMode);
static unsigned GetMaxTextureSize(void);


@implementation SGTexture2D

#pragma mark NSObject

- (id)init
{
	self = [super init];
	if (nil != self)
	{
		minFilter = GL_LINEAR_MIPMAP_LINEAR;
		magFilter = GL_LINEAR;
		wrapModeS = GL_CLAMP_TO_EDGE;
		wrapModeT = GL_CLAMP_TO_EDGE;
		maxAnisotropy = 0.0f;
	}
	
	return self;
}


- (id)description
{
	NSSize size = [self dimensions];
	return [NSString stringWithFormat:@"<%@ %p>{%g x %g px}", [self className], self, size.width, size.height];
}


#pragma mark SGTexture2D

// Configuration to be set up before calling -bind. Doing it afterward will lead to being ignored.
- (GLenum)minFilter
{
	return minFilter;
}


- (void)setMinFilter:(GLenum)inFilter
{
	switch (inFilter)
	{
		case GL_NEAREST:
		case GL_LINEAR:
		case GL_NEAREST_MIPMAP_NEAREST:
		case GL_LINEAR_MIPMAP_NEAREST:
		case GL_NEAREST_MIPMAP_LINEAR:
		case GL_LINEAR_MIPMAP_LINEAR:
			minFilter = inFilter;
			break;
		
		default:
			SGLog(@"Invalid min filter: %u.", inFilter);
	}
}


- (BOOL)mipMap
{
	return minFilter != GL_NEAREST && minFilter != GL_LINEAR;
}


- (GLenum)magFilter
{
	return magFilter;
}


- (void)setMagFilter:(GLenum)inFilter
{
	switch (inFilter)
	{
		case GL_NEAREST:
		case GL_LINEAR:
			magFilter = inFilter;
			break;
		
		default:
			SGLog(@"SGTexture2D: invalid mag filter: %u.", inFilter);
	}
}


- (GLenum)wrapModeS
{
	return wrapModeS;
}


- (void)setWrapModeS:(GLenum)inMode
{
	if (ValidClampMode(inMode)) wrapModeS = inMode;
	else  SGLog(@"SGTexture2D: invalid wrap mode: %u.", inMode);
}


- (GLenum)wrapModeT
{
	return wrapModeT;
}


- (void)setWrapModeT:(GLenum)inMode
{
	if (ValidClampMode(inMode)) wrapModeT = inMode;
	else SGLog(@"SGTexture2D: invalid wrap mode: %u.", inMode);
}


- (void)setWrapMode:(GLenum)inMode
{
	if (ValidClampMode(inMode))
	{
		[self setWrapModeS:inMode];
		[self setWrapModeT:inMode];
	}
	else SGLog(@"SGTexture2D: invalid wrap mode: %u.", inMode);
}


- (GLfloat)maxAnisotropy
{
	if (AnisotropySupported())
	{
		return MIN(maxAnisotropy, [SGTexture2D maxAnistropyLimit]);
	}
	else return 1.0f;
}


- (void)setMaxAnisotropy:(GLfloat)inValue
{
	if (1.0f <= inValue) maxAnisotropy = inValue;
}


- (void)setMaxAnisotropyHighest
{
	[self setMaxAnisotropy:[SGTexture2D maxAnistropyLimit]];
}


+ (GLfloat)maxAnistropyLimit
{
	if (AnisotropySupported())
	{
		GLfloat		result;
		
		glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &result);
		return result;
	}
	else return 1.0f;
}


- (void)bind
{
	[NSException raise:NSGenericException format:@"%s: subclasses must override this method.", __FUNCTION__];
}


- (NSImage *)imageRepresentation
{
	// On the one hand, a default implementation based on glGetTexImage would be handly. On the other hand, it would mean -imageRepresentation would rely on a GL context with the texture bound in it being active.
	return nil;
}


- (NSSize)dimensions
{
	return NSZeroSize;
}


- (void)applySettings
{
	// Assumes TEXTURE_2D, TEXTURE_RECTANGLE_ARB not supported.
	// TODO: support ARB_texture_non_power_of_two. Mip-map generation appears to be the only obstacle to this.
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapModeS);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapModeT);
	if (AnisotropySupported()) glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 4.0);
}

@end


@interface SGNSImageTexture2D (SGPrivate)

- (void)generatePixelData;

@end


@implementation SGNSImageTexture2D

#pragma mark NSObject

- (void)dealloc
{
	[image release];
	[pixelData release];
	
	[super dealloc];
}

#pragma mark SGTexture2D

- (void)bind
{
	size_t					dataSize, expectedDataSize;
	unsigned				max, w, h, level;
	const uint8_t			*bytes = NULL;
	
	if (pixelData == nil) [self generatePixelData];
	if (pixelData == nil)
	{
		return;
	}
	
	dataSize = [pixelData length];
	bytes = [pixelData bytes];
	
	// Extra sanity checking
	expectedDataSize = width * height * 4;
	if (mipMap) expectedDataSize = expectedDataSize * 4 / 3;
	if (dataSize < expectedDataSize)
	{
		SGLog(@"SGTexture2D: expected %zu bytes of data, got %zu.", expectedDataSize, dataSize);
		return;
	}
	
	// GL set-up
	[self applySettings];
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_SHARED_APPLE);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
	glTextureRangeAPPLE(GL_TEXTURE_2D, dataSize, bytes);
	
	// Bind mip levels
	max = GetMaxTextureSize();
	level = 0;
	w = width;
	h = height;
	while (1 <= w && 1 <= h)
	{
		if (w <= max && h <= max)
		{
			// This could be false if the texture is used in more than one context, and the first context is on a device which allows bigger texture sizes than that used by other contexts.
		//	glTexImage2D(GL_TEXTURE_2D, level, GL_RGBA8, w, h, 0, GL_BGRA, ARGB_IMAGE_TYPE, bytes);
			glTexImage2D(GL_TEXTURE_2D, level, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, bytes);
			++level;
		}
		
		bytes += w * h * 4;
		w /= 2;
		h /= 2;
	}
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, level - 1);
}


- (NSImage *)imageRepresentation
{
	// TODO: generate image from bitmap data if image has been released (by -generatePixelData).
	return [[image retain] autorelease];
}


- (NSSize)dimensions
{
	return NSMakeSize(width, height);
}


#pragma mark SGNSImageTexture2D

+ (id)textureWithImage:(NSImage *)inImage
{
	return [[[self alloc] initWithImage:inImage] autorelease];
}


+ (id)textureWithURL:(NSURL *)inURL
{
	return [[[self alloc] initWithURL:inURL] autorelease];
}


+ (id)textureWithPath:(NSString *)inPath
{
	return [[[self alloc] initWithPath:inPath] autorelease];
}


- (id)initWithImage:(NSImage *)inImage
{
	BOOL				OK = YES;
	
	self = [super init];
	if (self == nil) OK = NO;
	
	if (![inImage isValid]) OK = NO;
	
	if (OK)
	{
		[pixelData release];
		pixelData = nil;
		
		image = [inImage retain];
		NSSize size = [inImage sizeInPixels];
		width = SGRoundUpToPowerOf2(2.0f * size.width / 3.0f);
		height = SGRoundUpToPowerOf2(2.0f * size.height / 3.0f);
	}
	
	if (!OK)
	{
		[self release];
		self = nil;
	}
	return self;
}


- (id)initWithURL:(NSURL *)inURL
{
	return [self initWithImage:[[[NSImage alloc] initWithContentsOfURL:inURL] autorelease]];
}


- (id)initWithPath:(NSString *)inPath
{
	return [self initWithImage:[[[NSImage alloc] initWithContentsOfFile:inPath] autorelease]];
}


#pragma mark SGNSImageTexture2D (SGPrivate)

/*	-generatePixelData
	Generates an array of pixel data.
	The pixel data consists of the raw RGBA bytes for each pixel of the
	texture, in sequence from largest to smallest, without padding.
	
	LIMITATION: if the texture is used in a context with a small maximum
	texture size, and then in a context with a large maximum texture size, the
	smaller size will be used in both.
*/
- (void)generatePixelData
{
	GLsizei					w, h, max;
	size_t					dataSize;
	uint8_t					*bytes = NULL, *currBytes;
	NSBitmapImageRep		*bitmap = nil;
	NSGraphicsContext		*context = nil, *savedContext = nil;
	NSRect					bounds = {.origin = {0, 0}};
	BOOL					err = NO;
	BOOL					wasFlipped;
	
	max = GetMaxTextureSize();
	while (max < width || max < height)
	{
		width /= 2;
		height /= 2;
	}
	
	mipMap = [self mipMap];	// This must be cached, otherwise a -setMinFilter: between -binds could cause badness.
	
	dataSize = width * height * 4;
	if (mipMap) dataSize = dataSize * 4 / 3;
	bytes = malloc(dataSize);
	if (bytes == NULL) return;
	
	savedContext = [NSGraphicsContext currentContext];
	
	w = width;
	h = height;
	currBytes = bytes;
	
	while (1 <= w && 1 <= h)
	{
		bitmap = [[NSBitmapImageRep alloc]
					initWithBitmapDataPlanes:&currBytes
								  pixelsWide:w
								  pixelsHigh:h
							   bitsPerSample:8
							 samplesPerPixel:4
									hasAlpha:YES
									isPlanar:NO
							  colorSpaceName:NSDeviceRGBColorSpace
								bitmapFormat:NSAlphaNonpremultipliedBitmapFormat
								 bytesPerRow:w * 4
								bitsPerPixel:0];
		if (bitmap == nil)
		{
			SGLog(@" SGTexture2D: failed to create bitmap image rep.");
			err = YES;
			break;
		}
		
		context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
		[context setImageInterpolation:NSImageInterpolationHigh];
		[NSGraphicsContext setCurrentContext:context];
		
		wasFlipped = [image isFlipped];
		[image setFlipped:!wasFlipped];
		bounds.size.width = w;
		bounds.size.height = h;
		[image drawInRect:bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0f];
		[context flushGraphics];
		[image setFlipped:wasFlipped];
		
		// Pixel data should now be in place. We don’t need the drawing context any longer.
		[bitmap release];
		
	#if 0
		// Dump mipmaps for debugging.
		NSString *dumpPath = [[NSString stringWithFormat:@"~/Desktop/TexDump/%ux%u.raw", w, h] stringByExpandingTildeInPath];
		NSData *tempData = [NSData dataWithBytesNoCopy:currBytes length:w * h * 4 freeWhenDone:NO];
		[tempData writeToFile:dumpPath atomically:NO];
	#endif
		
		// Without mip-mapping, we only want one level.
		if (!mipMap) break;
		
		// Advance
		currBytes += w * h * 4;
		w /= 2;
		h /= 2;
	}
	
	[NSGraphicsContext setCurrentContext:savedContext];
	
	if (err)
	{
		free(bytes);
	}
	else
	{
		pixelData = [[NSData alloc] initWithBytesNoCopy:bytes length:dataSize freeWhenDone:YES];
		[image release];
		image = nil;
	}
}

@end


@implementation SGTexture2D (SGNSImageTexture2DConveniences)

+ (id)textureWithImage:(NSImage *)inImage
{
	return [SGNSImageTexture2D textureWithImage:inImage];
}


+ (id)textureWithURL:(NSURL *)inURL
{
	return [SGNSImageTexture2D textureWithURL:inURL];
}


+ (id)textureWithPath:(NSString *)inPath
{
	return [SGNSImageTexture2D textureWithPath:inPath];
}

@end


@implementation NSImage (SGTexture2DConveniences)

/*	-sizeInPixels
	-[NSImage size] provides a size in points, which is not useful for a
	texture. We want a size in pixels. Strategy:
	* Look for the first bitmap image rep, and ask it.
	* If this fails, look for the first image rep of any sort, and ask it.
	* If this fails, fall back to -[NSImage size].
	  In principle, this should give us {0, 0}.
*/
- (NSSize)sizeInPixels
{
	NSArray				*allReps = nil;
	NSEnumerator		*repEnum = nil;
	NSImageRep			*rep = nil;
	NSSize				size = NSZeroSize;
	
	if (![self isValid]) return NSZeroSize;
	
	// Look for bitmap reps
	allReps = [self representations];
	for (repEnum = [allReps objectEnumerator]; (rep = [repEnum nextObject]); )
	{
		if ([rep isKindOfClass:[NSBitmapImageRep class]])
		{
			size.width = [rep pixelsWide];
			size.height = [rep pixelsHigh];
			if (!NSEqualSizes(size, NSZeroSize)) return size;
		}
	}
	
	// Look for any rep
	rep = [allReps objectAtIndex:0];
	if (nil != rep)
	{
		size.width = [rep pixelsWide];
		size.height = [rep pixelsHigh];
		if (!NSEqualSizes(size, NSZeroSize)) return size;
	}
	
	return [self size];
}

@end


static BOOL AnisotropySupported(void)
{
	return strstr((char*)glGetString(GL_EXTENSIONS), "GL_EXT_texture_filter_anisotropic") != NULL;
}


static BOOL ValidClampMode(GLenum inMode)
{
	switch (inMode)
	{
		case GL_CLAMP:
		case GL_REPEAT:
		case GL_CLAMP_TO_EDGE:
		case GL_CLAMP_TO_BORDER:
	#if GL_ATI_texture_mirror_once
		case GL_MIRROR_CLAMP_ATI:
		case GL_MIRROR_CLAMP_TO_EDGE_ATI:
	#endif
			return YES;
	}
	
	return NO;
}


static unsigned GetMaxTextureSize(void)
{
	GLint				result;
	GLint				preference;
	
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &result);
	
	preference = [[NSUserDefaults standardUserDefaults] integerForKey:@"maxTextureSize"];
	if (64 <= preference) result = preference;
	
	return SGRoundUpToPowerOf2(2 * result / 3);
}
