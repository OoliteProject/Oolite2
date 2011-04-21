/*

OOGraphicsContext.h

Object representing an OpenGL context and associated render state. There is
only one graphics context in Oolite, but multiple ones in Dry Dock. To support
this, OOGraphicsContexts can be associated with NSOpenGLContexts under Mac OS X.

OOGraphicsContext takes over the duties of OOOpenGLExtensionManager and
OOOpenGLResetManager in Oolite 1.x. Unlike OOOpenGLExtensionManager, it doesn’t
have an opinion on what OpenGL version is required; that’s up to the client.
It’s done this way to keep error handling out of shared code.


Copyright (C) 2011 Jens Ayton

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

@class OOMaterial, OOShaderProgram;


@interface OOGraphicsContext: NSObject
{
@private
#if OOLITE_MAC_OS_X
	NSOpenGLContext			*_nsContext;
#endif
	
	NSString				*_vendor;
	NSString				*_renderer;
	
	NSUInteger				_major, _minor, _release;
	NSUInteger				_glslMajor, _glslMinor, _glslRelease;
	
	NSSet					*_extensions;
	GLint					_textureImageUnitCount;
	
	OOMaterial				*_currentMaterial;
	OOShaderProgram			*_currentShaderProgram;
}

- (id) init;
#if OOLITE_MAC_OS_X
- (id) initWithOpenGLContext:(NSOpenGLContext *) nsContext;
#endif

+ (id) currentContext;
- (void) makeCurrent;

/*
	-isSharingWithContext:
	Test whether resources from context A can be used in context B.
	This is obviously true if A == B, but can be true in other cases on an
	OS-dependant basis; for instance, under Mac OS X, this comparse CGL
	“share groups”.
*/
- (BOOL) isSharingWithContext:(OOGraphicsContext *)other;

// OpenGL version.
- (NSUInteger) majorGLVersionNumber;
- (NSUInteger) minorGLVersionNumber;
- (NSUInteger) releaseGLVersionNumber;
- (void) getGLVersionMajor:(NSUInteger *)outMajor
					 minor:(unsigned *)outMinor
				   release:(unsigned *)outRelease;
- (BOOL) versionIsAtLeastMajor:(unsigned)maj minor:(unsigned)min;

// GLSL version (0.0.0 if no GLSL support).
- (NSUInteger) majorGLSLVersionNumber;
- (NSUInteger) minorGLSLVersionNumber;
- (NSUInteger) releaseGLSLVersionNumber;
- (void) getGLSLVersionMajor:(NSUInteger *)outMajor
					   minor:(unsigned *)outMinor
					 release:(unsigned *)outRelease;
- (BOOL) glslVersionIsAtLeastMajor:(unsigned)maj minor:(unsigned)min;

- (NSString *) vendorString;
- (NSString *) rendererString;

- (NSSet *) extensions;
- (BOOL) haveExtension:(NSString *)extension;

- (NSUInteger) textureImageUnitCount;

/*
	-reset
	Rebuild the context on top of the current OpenGL context. This is necessary
	to deal with state changes in SDL builds. Under Mac OS X, it is an error
	to call -reset on a context associated with an NSOpenGLContext.
	
	Objects that need to reset their state when resets occur should subscribe
	to kOOGraphicsContextDidResetNotification.
	
	FIXME: is the SDL issue real, or is Oolite overthinking it? A quick web
	search didn’t turn up anything. -- Ahruman 2011-04-17
*/
- (void) reset;

@end


extern NSString * const kOOGraphicsContextWillResetNotification;
extern NSString * const kOOGraphicsContextDidResetNotification;
