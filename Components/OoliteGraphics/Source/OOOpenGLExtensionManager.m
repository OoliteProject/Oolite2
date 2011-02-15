/*

OOOpenGLExtensionManager.m


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

#import "OOOpenGLExtensionManager.h"
#import <stdlib.h>


enum
{
	kMinMajorVersion				= 2,
	kMinMinorVersion				= 0
};


static NSString * const kOOLogOpenGLShaderSupport		= @"rendering.opengl.shader.support";


static OOOpenGLExtensionManager *sSingleton = nil;


// Read integer from string, advancing string to end of read data.
static unsigned IntegerFromString(const GLubyte **ioString);


@interface OOOpenGLExtensionManager (OOPrivate)

- (NSDictionary *) lookUpPerGPUSettingsWithVersionString:(NSString *)version extensionsString:(NSString *)extensionsStr;

@end


static NSArray *ArrayOfExtensions(NSString *extensionString)
{
	NSArray *components = [extensionString componentsSeparatedByString:@" "];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[components count]];
	NSEnumerator *extEnum = nil;
	NSString *extStr = nil;
	for (extEnum = [components objectEnumerator]; (extStr = [extEnum nextObject]); )
	{
		if ([extStr length] > 0)  [result addObject:extStr];
	}
	return result;
}


@implementation OOOpenGLExtensionManager

- (id)init
{
	self = [super init];
	if (self != nil)
	{
#if OOOPENGLEXTMGR_LOCK_SET_ACCESS
		_lock = [[NSLock alloc] init];
#endif
		
		[self reset];
	}
	
	return self;
}


- (void) reset
{
	const GLubyte		*versionString = NULL, *curr = NULL;
	
	DESTROY(_extensions);
	DESTROY(_vendor);
	DESTROY(_renderer);
	
	NSString *extensionsStr = [NSString stringWithUTF8String:(char *)glGetString(GL_EXTENSIONS)];
	_extensions = [[NSSet alloc] initWithArray:ArrayOfExtensions(extensionsStr)];
	
	_vendor = [[NSString alloc] initWithUTF8String:(const char *)glGetString(GL_VENDOR)];
	_renderer = [[NSString alloc] initWithUTF8String:(const char *)glGetString(GL_RENDERER)];
	
	versionString = glGetString(GL_VERSION);
	if (versionString != NULL)
	{
		/*	String is supposed to be "major.minorFOO" or
			"major.minor.releaseFOO" where FOO is an empty string or
			a string beginning with space.
		*/
		curr = versionString;
		_major = IntegerFromString(&curr);
		if (*curr == '.')
		{
			curr++;
			_minor = IntegerFromString(&curr);
		}
		if (*curr == '.')
		{
			curr++;
			_release = IntegerFromString(&curr);
		}
	}
	
#if 0
	/*	For aesthetic reasons, cause the ResourceManager to initialize its
		search paths here. If we don't, the search path dump ends up in
		the middle of the OpenGL stuff.
	*/
	[ResourceManager paths];
#endif
	
	OOLog(@"rendering.opengl.version", @"OpenGL renderer version: %u.%u.%u (\"%s\"). Vendor: \"%@\". Renderer: \"%@\".", _major, _minor, _release, versionString, _vendor, _renderer);
	OOLog(@"rendering.opengl.extensions", @"OpenGL extensions (%u):\n%@", [_extensions count], [[_extensions allObjects] componentsJoinedByString:@", "]);
	
	if (![self versionIsAtLeastMajor:kMinMajorVersion minor:kMinMinorVersion])
	{
		OOLog(@"rendering.opengl.version.insufficient", @"***** Oolite requires OpenGL version %u.%u or later.", kMinMajorVersion, kMinMinorVersion);
		[NSException raise:@"OoliteOpenGLTooOldException"
					format:@"Oolite requires at least OpenGL %u.1%u. You have %u.%u (\"%s\").", kMinMajorVersion, kMinMinorVersion, _major, _minor, versionString];
	}
	
	NSString *versionStr = [[[NSString alloc] initWithUTF8String:(const char *)versionString] autorelease];
	NSDictionary *gpuConfig = [self lookUpPerGPUSettingsWithVersionString:versionStr extensionsString:extensionsStr];
	
	_complexShadersPermitted = [gpuConfig oo_boolForKey:@"complexShadersPermitted" defaultValue:YES];
	_complexShadersByDefault = [gpuConfig oo_boolForKey:@"complexShadersByDefault" defaultValue:YES];
	
	GLint texImageUnitOverride = [gpuConfig oo_unsignedIntegerForKey:@"textureImageUnits" defaultValue:_textureImageUnitCount];
	if (texImageUnitOverride < _textureImageUnitCount)  _textureImageUnitCount = texImageUnitOverride;
	
	_usePointSmoothing = [gpuConfig oo_boolForKey:@"smoothPoints" defaultValue:YES];
	_useLineSmoothing = [gpuConfig oo_boolForKey:@"smoothLines" defaultValue:YES];
}


- (void)dealloc
{
	if (sSingleton == self)  sSingleton = nil;
	
#if OOOPENGLEXTMGR_LOCK_SET_ACCESS
	DESTROY(_lock);
#endif
	DESTROY(_extensions);
	DESTROY(_vendor);
	DESTROY(_renderer);
	
	[super dealloc];
}


+ (id)sharedManager
{
	// NOTE: assumes single-threaded first access. See header.
	if (sSingleton == nil)  sSingleton = [[self alloc] init];
	return sSingleton;
}


- (BOOL)haveExtension:(NSString *)extension
{
// NSSet is documented as thread-safe under OS X, but I'm not sure about GNUstep. -- Ahruman
#if OOOPENGLEXTMGR_LOCK_SET_ACCESS
	[_lock lock];
#endif
	
	BOOL result = [_extensions containsObject:extension];
	
#if OOOPENGLEXTMGR_LOCK_SET_ACCESS
	[_lock unlock];
#endif
	
	return result;
}


- (BOOL) complexShadersPermitted
{
	return _complexShadersPermitted;
}


- (BOOL) complexShadersByDefault
{
	return _complexShadersByDefault;
}


- (OOUInteger)textureImageUnitCount
{
	return _textureImageUnitCount;
}


- (OOUInteger)majorVersionNumber
{
	return _major;
}


- (OOUInteger)minorVersionNumber
{
	return _minor;
}


- (OOUInteger)releaseVersionNumber
{
	return _release;
}


- (void)getVersionMajor:(unsigned *)outMajor minor:(unsigned *)outMinor release:(unsigned *)outRelease
{
	if (outMajor != NULL)  *outMajor = _major;
	if (outMinor != NULL)  *outMinor = _minor;
	if (outRelease != NULL)  *outRelease = _release;
}


- (BOOL) versionIsAtLeastMajor:(unsigned)maj minor:(unsigned)min
{
	return _major > maj || (_major == maj && _minor >= min);
}


- (NSString *) vendorString
{
	return _vendor;
}


- (NSString *) rendererString
{
	return _renderer;
}


- (BOOL) usePointSmoothing
{
	return _usePointSmoothing;
}


- (BOOL) useLineSmoothing
{
	return _useLineSmoothing;
}

@end


static unsigned IntegerFromString(const GLubyte **ioString)
{
	if (EXPECT_NOT(ioString == NULL))  return 0;
	
	unsigned		result = 0;
	const GLubyte	*curr = *ioString;
	
	while ('0' <= *curr && *curr <= '9')
	{
		result = result * 10 + *curr++ - '0';
	}
	
	*ioString = curr;
	return result;
}


@implementation OOOpenGLExtensionManager (OOPrivate)

#if 0

// regexps may be a single string or an array of strings (in which case results are ANDed).
static BOOL CheckRegExps(NSString *string, id regexps)
{
	if (regexps == nil)  return YES;	// No restriction == match.
	if ([regexps isKindOfClass:[NSString class]])
	{
		return [string oo_matchesRegularExpression:regexps];
	}
	if ([regexps isKindOfClass:[NSArray class]])
	{
		NSEnumerator *regexpEnum = nil;
		NSString *regexp = nil;
		
		for (regexpEnum = [regexps objectEnumerator]; (regexp = [regexpEnum nextObject]); )
		{
			if (EXPECT_NOT(![regexp isKindOfClass:[NSString class]]))
			{
				// Invalid type -- match fails.
				return NO;
			}
			
			if (![string oo_matchesRegularExpression:regexp])  return NO;
		}
		return YES;
	}
	
	// Invalid type -- match fails.
	return NO;
}


static OOInteger CompareGPUSettingsByPriority(id a, id b, void *context)
{
	NSString		*keyA = a;
	NSString		*keyB = b;
	NSDictionary	*configurations = context;
	NSDictionary	*dictA = [configurations oo_dictionaryForKey:keyA];
	NSDictionary	*dictB = [configurations oo_dictionaryForKey:keyB];
	double			precedenceA = [dictA oo_doubleForKey:@"precedence" defaultValue:1];
	double			precedenceB = [dictB oo_doubleForKey:@"precedence" defaultValue:1];
	
	if (precedenceA > precedenceB)  return NSOrderedAscending;
	if (precedenceA < precedenceB)  return NSOrderedDescending;
	
	return [keyA caseInsensitiveCompare:keyB];
}
#endif


- (NSDictionary *) lookUpPerGPUSettingsWithVersionString:(NSString *)versionStr extensionsString:(NSString *)extensionsStr
{
#if 0
	NSDictionary *configurations = [ResourceManager dictionaryFromFilesNamed:@"gpu-settings.plist"
																	inFolder:@"Config"
																	andMerge:YES];
	
	NSArray *keys = [[configurations allKeys] sortedArrayUsingFunction:CompareGPUSettingsByPriority context:configurations];
	
	NSEnumerator *keyEnum = nil;
	NSString *key = nil;
	NSDictionary *config = nil;
	
	for (keyEnum = [keys objectEnumerator]; (key = [keyEnum nextObject]); )
	{
		config = [configurations oo_dictionaryForKey:key];
		if (EXPECT_NOT(config == nil))  continue;
		
		NSDictionary *match = [config oo_dictionaryForKey:@"match"];
		NSString *expr = nil;
		
		expr = [match objectForKey:@"vendor"];
		if (!CheckRegExps(vendor, expr))  continue;
		
		expr = [match oo_stringForKey:@"renderer"];
		if (!CheckRegExps(renderer, expr))  continue;
		
		expr = [match oo_stringForKey:@"version"];
		if (!CheckRegExps(versionStr, expr))  continue;
		
		expr = [match oo_stringForKey:@"extensions"];
		if (!CheckRegExps(extensionsStr, expr))  continue;
		
		OOLog(@"rendering.opengl.gpuSpecific", @"Matched GPU configuration \"%@\".", key);
		return config;
	}
#endif
	
	return [NSDictionary dictionary];
}

@end


@implementation OOOpenGLExtensionManager (Singleton)

/*	Canonical singleton boilerplate.
	See Cocoa Fundamentals Guide: Creating a Singleton Instance.
	See also +sharedManager above.
	
	// NOTE: assumes single-threaded first access.
*/

+ (id)allocWithZone:(NSZone *)inZone
{
	if (sSingleton == nil)
	{
		sSingleton = [super allocWithZone:inZone];
		return sSingleton;
	}
	return nil;
}


- (id)copyWithZone:(NSZone *)inZone
{
	return self;
}


- (id)retain
{
	return self;
}


- (OOUInteger)retainCount
{
	return UINT_MAX;
}


- (void)release
{}


- (id)autorelease
{
	return self;
}

@end


#if OOLITE_WINDOWS

static void OOBadOpenGLExtensionUsed(void)
{
	OOLog(@"rendering.opengl.badExtension", @"***** An uninitialized OpenGL extension function has been called, terminating. This is a serious error, please report it. *****");
	exit(EXIT_FAILURE);
}

#endif
