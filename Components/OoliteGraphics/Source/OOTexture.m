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

#import "OOMacroOpenGL.h"
#import "OOOpenGLUtilities.h"
#import "OOPixMap.h"


static BOOL					sCheckedExtensions;
OOTextureInfo				gOOTextureInfo;


@interface OOTexture (OOPrivate)

- (void) forceRebind;

+ (void)checkExtensions;

#ifndef NDEBUG
- (id) retainInContext:(NSString *)context;
- (void) releaseInContext:(NSString *)context;
- (id) autoreleaseInContext:(NSString *)context;
#endif

@end


#ifndef NDEBUG
static NSString *sGlobalTraceContext = nil;

#define SET_TRACE_CONTEXT(str) do { sGlobalTraceContext = (str); } while (0)
#else
#define SET_TRACE_CONTEXT(str) do { } while (0)
#endif
#define CLEAR_TRACE_CONTEXT() SET_TRACE_CONTEXT(nil)


@implementation OOTexture

+ (id)textureFromFile:(NSString *)path
			  options:(uint32_t)options
		   anisotropy:(GLfloat)anisotropy
			  lodBias:(GLfloat)lodBias
{
	if (EXPECT_NOT(path == nil))  return nil;
	if (EXPECT_NOT(!sCheckedExtensions))  [self checkExtensions];
	
	// Default is no longer handled in OOTexture.
	NSParameterAssert((options & kOOTextureMinFilterMask) != kOOTextureMinFilterDefault);
	
	options &= kOOTextureDefinedFlags;
	
	if (!gOOTextureInfo.anisotropyAvailable || (options & kOOTextureMinFilterMask) != kOOTextureMinFilterMipMap)
	{
		anisotropy = 0.0f;
	}
	if (!gOOTextureInfo.textureLODBiasAvailable || (options & kOOTextureMinFilterMask) != kOOTextureMinFilterMipMap)
	{
		lodBias = 0.0f;
	}
	
	return [[[OOConcreteTexture alloc] initWithPath:path options:options anisotropy:anisotropy lodBias:lodBias] autorelease];
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


- (GLint)glTextureName
{
	OOLogGenericSubclassResponsibility();
	return 0;
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
	
	sCheckedExtensions = YES;
	
	OOOpenGLExtensionManager	*extMgr = [OOOpenGLExtensionManager sharedManager];
	
#if GL_EXT_texture_filter_anisotropic
	gOOTextureInfo.anisotropyAvailable = [extMgr haveExtension:@"GL_EXT_texture_filter_anisotropic"];
	OOGL(glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &gOOTextureInfo.anisotropyScale));
	gOOTextureInfo.anisotropyScale *= OOClamp_0_1_f([[NSUserDefaults standardUserDefaults] oo_floatForKey:@"texture-anisotropy-scale" defaultValue:0.5]);
#endif
	
#if OO_GL_CLIENT_STORAGE
	gOOTextureInfo.clientStorageAvailable = [extMgr haveExtension:@"GL_APPLE_client_storage"];
#endif
	
#if GL_EXT_texture_lod_bias
	if ([[NSUserDefaults standardUserDefaults] oo_boolForKey:@"use-texture-lod-bias" defaultValue:YES])
	{
		gOOTextureInfo.textureLODBiasAvailable = [extMgr haveExtension:@"GL_EXT_texture_lod_bias"];
	}
	else
	{
		gOOTextureInfo.textureLODBiasAvailable = NO;
	}
#endif
}


#ifndef NDEBUG
- (id) retainInContext:(NSString *)context
{
	if (_trace)
	{
		if (context)  OOLog(@"texture.allocTrace.retain", @"Texture %p retained (retain count -> %u) - %@.", self, [self retainCount] + 1, context);
		else  OOLog(@"texture.allocTrace.retain", @"Texture %p retained.", self, [self retainCount] + 1);
	}
	
	return [super retain];
}


- (void) releaseInContext:(NSString *)context
{
	if (_trace)
	{
		if (context)  OOLog(@"texture.allocTrace.release", @"Texture %p released (retain count -> %u) - %@.", self, [self retainCount] - 1, context);
		else  OOLog(@"texture.allocTrace.release", @"Texture %p released (retain count -> %u).", self, [self retainCount] - 1);
	}
	
	[super release];
}


- (id) autoreleaseInContext:(NSString *)context
{
	if (_trace)
	{
		if (context)  OOLog(@"texture.allocTrace.autoreleased", @"Texture %p autoreleased - %@.", self, context);
		else  OOLog(@"texture.allocTrace.autoreleased", @"Texture %p autoreleased.", self);
	}
	
	return [super autorelease];
}


- (id) retain
{
	return [self retainInContext:sGlobalTraceContext];
}


- (void) release
{
	[self releaseInContext:sGlobalTraceContext];
}


- (id) autorelease
{
	return [self autoreleaseInContext:sGlobalTraceContext];
}
#endif

@end


@implementation NSDictionary (OOTextureConveniences)

- (NSDictionary *) oo_textureSpecifierForKey:(id)key defaultName:(NSString *)name
{
	return OOTextureSpecFromObject([self objectForKey:key], name);
}

@end

@implementation NSArray (OOTextureConveniences)

- (NSDictionary *) oo_textureSpecifierAtIndex:(unsigned)index defaultName:(NSString *)name
{
	return OOTextureSpecFromObject([self objectAtIndex:index], name);
}

@end

NSDictionary *OOTextureSpecFromObject(id object, NSString *defaultName)
{
	if (object == nil)  object = defaultName;
	if ([object isKindOfClass:[NSString class]])
	{
		if ([object isEqualToString:@""])  return nil;
		return [NSDictionary dictionaryWithObject:object forKey:@"name"];
	}
	if (![object isKindOfClass:[NSDictionary class]])  return nil;
	
	// If we're here, it's a dictionary.
	if (defaultName == nil || [object oo_stringForKey:@"name"] != nil)  return object;
	
	// If we get here, there's no "name" key and there is a default, so we fill it in:
	NSMutableDictionary *mutableResult = [NSMutableDictionary dictionaryWithDictionary:object];
	[mutableResult setObject:[[defaultName copy] autorelease] forKey:@"name"];
	return mutableResult;
}


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


BOOL OOInterpretTextureSpecifier(id specifier, NSString **outName, uint32_t *outOptions, float *outAnisotropy, float *outLODBias)
{
	NSString			*name = nil;
	uint32_t			options = kOOTextureDefaultOptions;
	float				anisotropy = kOOTextureDefaultAnisotropy;
	float				lodBias = kOOTextureDefaultLODBias;
	
	if ([specifier isKindOfClass:[NSString class]])
	{
		name = specifier;
	}
	else if ([specifier isKindOfClass:[NSDictionary class]])
	{
		name = [specifier oo_stringForKey:@"name"];
		if (name == nil)
		{
			OOLog(@"texture.load.noName", @"Invalid texture configuration dictionary (must specify name):\n%@", specifier);
			return NO;
		}
		
		NSString *filterString = [specifier oo_stringForKey:@"min_filter" defaultValue:@"default"];
		if ([filterString isEqualToString:@"nearest"])  options |= kOOTextureMinFilterNearest;
		else if ([filterString isEqualToString:@"linear"])  options |= kOOTextureMinFilterLinear;
		else if ([filterString isEqualToString:@"mipmap"])  options |= kOOTextureMinFilterMipMap;
		else  options |= kOOTextureMinFilterDefault;	// Covers "default"
		
		filterString = [specifier oo_stringForKey:@"mag_filter" defaultValue:@"default"];
		if ([filterString isEqualToString:@"nearest"])  options |= kOOTextureMagFilterNearest;
		else  options |= kOOTextureMagFilterLinear;	// Covers "default" and "linear"
		
		if ([specifier oo_boolForKey:@"no_shrink" defaultValue:NO])  options |= kOOTextureNoShrink;
		if ([specifier oo_boolForKey:@"repeat_s" defaultValue:NO])  options |= kOOTextureRepeatS;
		if ([specifier oo_boolForKey:@"repeat_t" defaultValue:NO])  options |= kOOTextureRepeatT;
		if ([specifier oo_boolForKey:@"cube_map" defaultValue:NO])  options |= kOOTextureCubeMap;
		anisotropy = [specifier oo_floatForKey:@"anisotropy" defaultValue:kOOTextureDefaultAnisotropy];
		lodBias = [specifier oo_floatForKey:@"texture_LOD_bias" defaultValue:kOOTextureDefaultLODBias];
		
		NSString *extractChannel = [specifier oo_stringForKey:@"extract_channel"];
		if (extractChannel != nil)
		{
			if ([extractChannel isEqualToString:@"r"])  options |= kOOTextureExtractChannelR;
			else if ([extractChannel isEqualToString:@"g"])  options |= kOOTextureExtractChannelG;
			else if ([extractChannel isEqualToString:@"b"])  options |= kOOTextureExtractChannelB;
			else if ([extractChannel isEqualToString:@"a"])  options |= kOOTextureExtractChannelA;
			else
			{
				OOLogWARN(@"texture.load.extractChannel.invalid", @"Unknown value \"%@\" for extract_channel (should be \"r\", \"g\", \"b\" or \"a\").", extractChannel);
			}
		}
	}
	else
	{
		// Bad type
		if (specifier != nil)  OOLog(kOOLogParameterError, @"%s: expected string or dictionary, got %@.", __PRETTY_FUNCTION__, [specifier class]);
		return NO;
	}
	
	if ([name length] == 0)  return NO;
	
	if (outName != NULL)  *outName = name;
	if (outOptions != NULL)  *outOptions = options;
	if (outAnisotropy != NULL)  *outAnisotropy = anisotropy;
	if (outLODBias != NULL)  *outLODBias = lodBias;
	
	return YES;
}


NSOperationQueue *OOTextureOperationQueue(void)
{
	static NSOperationQueue *sOpQueue = nil;
	if (EXPECT_NOT(sOpQueue == nil))  sOpQueue = [[NSOperationQueue alloc] init];
	return sOpQueue;
}
