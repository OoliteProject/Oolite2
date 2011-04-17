/*

OOGraphicsContext.m


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

#import "OOGraphicsContext.h"


static OOGraphicsContext *sCurrentContext = nil;


static NSSet *SetOfExtensions(NSString *extensionString);
static void ParseVersionString(const GLubyte *versionString, NSUInteger *major, NSUInteger *minor, NSUInteger *release);


NSString * const kOOGraphicsContextWillResetNotification = @"org.oolite OOGraphicsContext Will Reset";
NSString * const kOOGraphicsContextDidResetNotification = @"org.oolite OOGraphicsContext Did Reset";


@implementation OOGraphicsContext

- (id) init
{
	if ((self = [super init]))
	{
		[self reset];
		OOLog(@"temp", @"Created context %@", self);
	}
	
	return self;
}


#if OOLITE_MAC_OS_X
- (id) initWithOpenGLContext:(NSOpenGLContext *) nsContext
{
	NSOpenGLContext *restoreContext = [NSOpenGLContext currentContext];
	[nsContext makeCurrentContext];
	
	if ((self = [self init]))
	{
		_nsContext = [nsContext retain];
	}
	
	[restoreContext makeCurrentContext];
	
	return self;
}
#endif


- (void) dealloc
{
	if (sCurrentContext == self)
	{
		sCurrentContext = nil;
#if OOLITE_MAC_OS_X
		[NSOpenGLContext clearCurrentContext];
#endif
	}
	
#if OOLITE_MAC_OS_X
	DESTROY(_nsContext);
#endif
	
	DESTROY(_vendor);
	DESTROY(_renderer);
	DESTROY(_extensions);
	
	[super dealloc];
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"OpenGL version %lu.%lu.%lu - %@", _major, _minor, _release, _renderer);
}


- (void) reset
{
#if OOLITE_MAC_OS_X
	NSAssert(_nsContext == nil, @"-[OOGraphicsContext reset] cannot be used on contexts with an associated NSOpenGLContext.");
#endif
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kOOGraphicsContextWillResetNotification object:self];
	
	DESTROY(_vendor);
	DESTROY(_renderer);
	DESTROY(_extensions);
	
	NSString *extensionsString = [NSString stringWithUTF8String:(char *)glGetString(GL_EXTENSIONS)];
	_extensions = [SetOfExtensions(extensionsString) retain];
	
	_vendor = [[NSString alloc] initWithUTF8String:(const char *)glGetString(GL_VENDOR)];
	_renderer = [[NSString alloc] initWithUTF8String:(const char *)glGetString(GL_RENDERER)];
	
	const GLubyte *versionString = glGetString(GL_VERSION);
	ParseVersionString(versionString, &_major, &_minor, &_release);
	
	if ([self versionIsAtLeastMajor:2 minor:0] || [self haveExtension:@"GL_ARB_fragment_shader"])
	{
		glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &_textureImageUnitCount);
	}
	else
	{
		_textureImageUnitCount = 0;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kOOGraphicsContextDidResetNotification object:self];
}


+ (OOGraphicsContext *) currentContext
{
	return sCurrentContext;
}


- (void) makeCurrent
{
	sCurrentContext = self;
	
#if OOLITE_MAC_OS_X
	[_nsContext makeCurrentContext];
#endif
}


- (NSUInteger) majorGLVersionNumber
{
	return _major;
}


- (NSUInteger) minorGLVersionNumber
{
	return _minor;
}


- (NSUInteger) releaseGLVersionNumber
{
	return _release;
}


- (void) getGLVersionMajor:(NSUInteger *)outMajor
					 minor:(unsigned *)outMinor
				   release:(unsigned *)outRelease
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


- (NSSet *) extensions
{
	return _extensions;
}


- (BOOL) haveExtension:(NSString *)extension
{
	return extension != nil && [_extensions containsObject:extension];
}


- (NSUInteger) textureImageUnitCount
{
	return _textureImageUnitCount;
}

@end


static NSSet *SetOfExtensions(NSString *extensionString)
{
	NSArray *components = [extensionString componentsSeparatedByString:@" "];
	NSMutableSet *result = [NSMutableSet setWithCapacity:[components count]];
	
	NSString *extStr = nil;
	foreach (extStr, components)
	{
		if ([extStr length] > 0)  [result addObject:extStr];
	}
	
	return [NSSet setWithSet:result];
}


static NSUInteger IntegerFromString(const GLubyte **ioString)
{
	NSCParameterAssert(ioString != NULL);
	
	unsigned		result = 0;
	const GLubyte	*curr = *ioString;
	
	while ('0' <= *curr && *curr <= '9')
	{
		result = result * 10 + *curr++ - '0';
	}
	
	*ioString = curr;
	return result;
}


static void ParseVersionString(const GLubyte *versionString, NSUInteger *major, NSUInteger *minor, NSUInteger *release)
{
	/*	String is supposed to be "major.minorFOO" or
	 "major.minor.releaseFOO" where FOO is an empty string or
	 a string beginning with space.
	 */
	*major = IntegerFromString(&versionString);
	if (*versionString == '.')
	{
		versionString++;
		*minor = IntegerFromString(&versionString);
	}
	if (*versionString == '.')
	{
		versionString++;
		*release = IntegerFromString(&versionString);
	}
}
