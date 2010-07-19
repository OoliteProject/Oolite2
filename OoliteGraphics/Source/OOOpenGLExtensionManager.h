/*

OOOpenGLExtensionManager.h

Handles checking for and using OpenGL extensions and related information.

This is thread safe, except for initialization; that is, +sharedManager should
be called from the main thread at an early point. The OpenGL context must be
set up by then.


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


#ifndef OO_SHADERS
#ifdef NO_SHADERS
#define	OO_SHADERS		0
#else
#define	OO_SHADERS		1
#endif
#endif


#define OOOPENGLEXTMGR_LOCK_SET_ACCESS		(!OOLITE_MAC_OS_X)


@interface OOOpenGLExtensionManager: NSObject
{
@private
#if OOOPENGLEXTMGR_LOCK_SET_ACCESS
	NSLock					*_lock;
#endif
	NSSet					*_extensions;
	
	NSString				*_vendor;
	NSString				*_renderer;
	
	unsigned				_major, _minor, _release;
	
	BOOL					_usePointSmoothing;
	BOOL					_useLineSmoothing;
	
	BOOL					_complexShadersPermitted;
	BOOL					_complexShadersByDefault;
	GLint					_textureImageUnitCount;
}

+ (id) sharedManager;

- (void) reset;

- (BOOL) haveExtension:(NSString *)extension;

- (BOOL) complexShadersPermitted;
- (BOOL) complexShadersByDefault;

- (OOUInteger)textureImageUnitCount;	// Fragment shader sampler count limit. Does not apply to fixed function multitexturing. (GL_MAX_TEXTURE_IMAGE_UNITS_ARB)

- (OOUInteger) majorVersionNumber;
- (OOUInteger) minorVersionNumber;
- (OOUInteger) releaseVersionNumber;
- (void) getVersionMajor:(unsigned *)outMajor minor:(unsigned *)outMinor release:(unsigned *)outRelease;
- (BOOL) versionIsAtLeastMajor:(unsigned)maj minor:(unsigned)min;

- (NSString *) vendorString;
- (NSString *) rendererString;

//	GL_POINT_SMOOTH is slow or non-functional on some GPUs.
- (BOOL) usePointSmoothing;
- (BOOL) useLineSmoothing;

@end
