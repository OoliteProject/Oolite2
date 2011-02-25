/*

OOTextureInternal.h

Subclass interface for OOTexture.


Copyright (C) 2007-2011 Jens Ayton and contributors

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

#import "OOTexture.h"
#import "OOOpenGLExtensionManager.h"


@interface OOTexture (SubclassInterface)

- (void) addToCaches;
- (void) removeFromCaches;	// Must be called on -dealloc (while -cacheKey is still valid) for cacheable textures.

+ (OOTexture *) existingTextureForKey:(NSString *)key;

@end


@interface OOTexture (SubclassResponsibilities)

- (void)apply;
- (NSSize)dimensions;


- (void) forceRebind;

@end


@interface OOTexture (SubclassOptional)

- (void)ensureFinishedLoading;					// Default: does nothing
- (BOOL) isFinishedLoading;						// Default: YES
- (NSString *) cacheKey;						// Default: nil
- (BOOL) isRectangleTexture;					// Default: NO
- (BOOL) isCubeMap;								// Default: NO
- (NSSize)texCoordsScale;						// Default: 1,1
- (struct OOPixMap) copyPixMapRepresentation;	// Default: kOONullPixMap

@end


typedef struct OOTextureInfo
{
	GLfloat					anisotropyScale;
	unsigned				anisotropyAvailable: 1,
							clientStorageAvailable: 1,
							rectangleTextureAvailable: 1;
} OOTextureInfo;

extern OOTextureInfo gOOTextureInfo;


#ifndef GL_EXT_texture_filter_anisotropic
#warning GL_EXT_texture_filter_anisotropic unavailble -- are you using an up-to-date glext.h?
#endif

#if defined(GL_APPLE_client_storage) && !OOTEXTURE_RELOADABLE
#define OO_GL_CLIENT_STORAGE	(1)
#define EnableClientStorage()	OOGL(glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE))
#else
#define OO_GL_CLIENT_STORAGE	(0)
#define EnableClientStorage()	do {} while (0)
#endif
