/*
	SGTexture2D.h
	
	Abstract base class for textures, and standard implementation based on
	NSImage.
	
	
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

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>


@interface SGTexture2D: NSObject
{
	GLenum					minFilter,
							magFilter,
							wrapModeS,
							wrapModeT;
	GLfloat					maxAnisotropy;
};

- (id)init;	// Designated initializer

// Configuration to be set up before calling -bind. Doing it afterward will lead to being ignored.
- (GLenum)minFilter;	// Default: GL_LINEAR_MIPMAP_LINEAR. Note that this isn’t the OpenGL default.
- (void)setMinFilter:(GLenum)inFilter;
- (BOOL)mipMap;			// False if minFilter is a GL_NEAREST or GL_LINEAR, true otherwise.
- (GLenum)magFilter;	// Default: GL_LINEAR.
- (void)setMagFilter:(GLenum)inFilter;
- (GLenum)wrapModeS;	// Default: GL_CLAMP_TO_EDGE. Note that this isn’t the OpenGL default.
- (void)setWrapModeS:(GLenum)inMode;
- (GLenum)wrapModeT;	// Default: GL_CLAMP_TO_EDGE. Note that this isn’t the OpenGL default.
- (void)setWrapModeT:(GLenum)inMode;
- (void)setWrapMode:(GLenum)inMode;	// Sets both S and T wrap modes.
- (GLfloat)maxAnisotropy;	// Default: 1.0. May not be set to less than 1.0.
- (void)setMaxAnisotropy:(GLfloat)inValue;
- (void)setMaxAnisotropyHighest;	// Equvialent to -setMaxAnisotropy:[SGTexture2D maxAnistropyLimit].
+ (GLfloat)maxAnistropyLimit;	// Highest value for maxAnisotropy supported by current GL context. 1.0 if anisotropy is not supported, at least 2.0 otherwise.

- (void)bind;	// Binds to current active texture (glActiveTextureARB) and current texture name (glBindTexture)
// IMPORTANT NOTE: subclasses may (and SGNSImageTexture2D will) use GL_UNPACK_CLIENT_STORAGE_APPLE. This means, in a nutshell, that you must keep the SGTexture2D around as long as the texture is being used. Failure to do so will lead to corruption or crashing if the texture needs to be re-uploaded.

- (NSImage *)imageRepresentation;

- (NSSize)dimensions;

// Intended for subclasses implementing -bind. Currently supports TEXTURE_2D only, not TEXTURE_RECTANGLE_ARB.
- (void)applySettings;

@end


@interface SGNSImageTexture2D: SGTexture2D
{
	NSImage					*image;
	NSData					*pixelData;
	GLsizei					width, height;
	BOOL					mipMap;
}

+ (id)textureWithImage:(NSImage *)inImage;
+ (id)textureWithURL:(NSURL *)inURL;
+ (id)textureWithPath:(NSString *)inPath;

- (id)initWithImage:(NSImage *)inImage;
- (id)initWithURL:(NSURL *)inURL;
- (id)initWithPath:(NSString *)inPath;

@end


@interface SGTexture2D (SGNSImageTexture2DConveniences)

// These cover the corresponding SGNSImageTexture2D methods.
+ (id)textureWithImage:(NSImage *)inImage;
+ (id)textureWithURL:(NSURL *)inURL;
+ (id)textureWithPath:(NSString *)inPath;

@end


@interface NSImage (SGTexture2DConveniences)

- (NSSize)sizeInPixels;

@end
