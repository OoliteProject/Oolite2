/*
	
	OOTexture.m
	
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

#import "OOTexture.h"
#import "OOTextureInternal.h"
#import "OOConcreteTexture.h"
#import "OONullTexture.h"

#import "OOTextureLoader.h"
#import "OOTextureGenerator.h"

#import "OOGraphicsContext.h"
#import "OOMacroOpenGL.h"
#import "OOOpenGLUtilities.h"
#import "OOPixMap.h"


static BOOL					sCheckedExtensions;
OOTextureInfo				gOOTextureInfo;


@interface OOTexture (OOPrivate)

- (void) forceRebind;

+ (void)checkExtensions;

@end


@implementation OOTexture

+ (id) textureWithSpecification:(OOTextureSpecification *)spec
				   fileResolver:(id <OOFileResolving>)resolver
				problemReporter:(id <OOProblemReporting>)problemReporter
{
	NSParameterAssert(spec != nil && resolver != nil);
	
	if (!sCheckedExtensions)  [OOTexture checkExtensions];
	
	// Load the data.
	NSString *name = [spec textureMapName];
	NSData *data = OOLoadFile(@"Textures", name, resolver, problemReporter);
	if (data == nil)  return nil;
	
	OOTextureOptionFlags options = [spec optionFlags];
	GLfloat anisotropy = [spec anisotropy];
	GLfloat lodBias = [spec lodBias];
	
	// FIXME: either make the default variable, or remove the extra value.
	if ((options & kOOTextureMinFilterMask) == kOOTextureMinFilterDefault)
	{
		options = (options & ~kOOTextureMinFilterMask) | kOOTextureMinFilterMipMap;
	}
	
	options &= kOOTextureDefinedFlags;
	
	if (!gOOTextureInfo.anisotropyAvailable || (options & kOOTextureMinFilterMask) != kOOTextureMinFilterMipMap)
	{
		anisotropy = 0.0f;
	}
	if (!gOOTextureInfo.textureLODBiasAvailable || (options & kOOTextureMinFilterMask) != kOOTextureMinFilterMipMap)
	{
		lodBias = 0.0f;
	}
	OOTextureLoader *loader = [OOTextureLoader loaderWithFileData:data
															 name:name
														  options:options
												  problemReporter:problemReporter];
	
	return [[[OOConcreteTexture alloc] initWithLoader:loader
											  options:options
										   anisotropy:anisotropy
											  lodBias:lodBias] autorelease];
}


+ (id) nullTexture
{
	return [OONullTexture sharedNullTexture];
}


+ (id) textureWithGenerator:(OOTextureGenerator *)generator
{
	if (generator == nil)  return nil;
	
	[generator enqueue];
	return [[[OOConcreteTexture alloc] initWithLoader:generator
											  options:[generator textureOptions]
										   anisotropy:[generator anisotropy]
											  lodBias:[generator lodBias]] autorelease];
}


- (void)apply
{
	OOLogGenericSubclassResponsibility();
}


+ (void)applyNone
{
	OO_ENTER_OPENGL();
	OOGL(glBindTexture(GL_TEXTURE_2D, 0));
	OOGL(glBindTexture(GL_TEXTURE_CUBE_MAP, 0));
	
#if GL_EXT_texture_lod_bias
	if (gOOTextureInfo.textureLODBiasAvailable)  OOGL(glTexEnvf(GL_TEXTURE_FILTER_CONTROL_EXT, GL_TEXTURE_LOD_BIAS_EXT, 0));
#endif
}


- (void)ensureFinishedLoading
{
}


- (BOOL) isFinishedLoading
{
	return YES;
}


- (NSString *) cacheKey
{
	return nil;
}


- (NSSize) dimensions
{
	OOLogGenericSubclassResponsibility();
	return NSZeroSize;
}


- (BOOL) isMipMapped
{
	OOLogGenericSubclassResponsibility();
	return NO;
}


- (struct OOPixMap) copyPixMapRepresentation
{
	return kOONullPixMap;
}


- (BOOL) isCubeMap
{
	return NO;
}


#ifndef NDEBUG
- (void) setTrace:(BOOL)trace
{
	if (trace && !_trace)
	{
		OOLog(@"texture.allocTrace.begin", @"Started tracing texture %p with retain count %u.", self, [self retainCount]);
	}
	_trace = trace;
}


- (size_t) dataSize
{
	NSSize dimensions = [self dimensions];
	size_t size = dimensions.width * dimensions.height;
	if ([self isCubeMap])  size *= 6;
	if ([self isMipMapped])  size = size * 4 / 3;
	
	return size;
}


- (NSString *) name
{
	OOLogGenericSubclassResponsibility();
	return nil;
}
#endif


- (void) forceRebind
{
	OOLogGenericSubclassResponsibility();
}


+ (void)checkExtensions
{
	OO_ENTER_OPENGL();
	
	// FIXME: extension check needs to be per-context.
	
	sCheckedExtensions = YES;
	
	OOGraphicsContext *context = [OOGraphicsContext currentContext];
	NSAssert(context != nil, @"Can't set up textures without an active graphics context.");
	
#if GL_EXT_texture_filter_anisotropic
	gOOTextureInfo.anisotropyAvailable = [context haveExtension:@"GL_EXT_texture_filter_anisotropic"];
	OOGL(glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &gOOTextureInfo.anisotropyScale));
	gOOTextureInfo.anisotropyScale *= OOClamp_0_1_f([[NSUserDefaults standardUserDefaults] oo_floatForKey:@"texture-anisotropy-scale" defaultValue:0.5]);
#endif
	
#if OO_GL_CLIENT_STORAGE
	gOOTextureInfo.clientStorageAvailable = [context haveExtension:@"GL_APPLE_client_storage"];
#endif
	
#if GL_EXT_texture_lod_bias
	if ([[NSUserDefaults standardUserDefaults] oo_boolForKey:@"use-texture-lod-bias" defaultValue:YES])
	{
		gOOTextureInfo.textureLODBiasAvailable = [context haveExtension:@"GL_EXT_texture_lod_bias"];
	}
	else
	{
		gOOTextureInfo.textureLODBiasAvailable = NO;
	}
#endif
}

@end


uint8_t OOTextureComponentsForFormat(OOTextureDataFormat format)
{
	switch (format)
	{
		case kOOTextureDataRGBA:
			return 4;
			
		case kOOTextureDataGrayscale:
			return 1;
			
		case kOOTextureDataGrayscaleAlpha:
			return 2;
			
		case kOOTextureDataInvalid:
			break;
	}
	
	return 0;
}


NSOperationQueue *OOTextureOperationQueue(void)
{
	static NSOperationQueue *sOpQueue = nil;
	if (EXPECT_NOT(sOpQueue == nil))
	{
		sOpQueue = [[NSOperationQueue alloc] init];
		[sOpQueue setName:@"Texture loading queue"];
	}
	return sOpQueue;
}
