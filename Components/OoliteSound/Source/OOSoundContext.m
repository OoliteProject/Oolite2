/*

OOSoundContext.m


Copyright (C) 2005-2011 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/


#import "OOSoundContext.h"
#import "OOSound.h"
#import "OOSoundSource.h"

#import "OOALSoundContext.h"

#if OOLITE_MAC_OS_X
#import "OOCASoundContext.h"
#endif
#if OOLITE_SDL
#import "OOSDLSoundContext.h"
#endif

#define kDefaultMasterVolume			0.75f
#define kPrefKeyMasterVolume			@"masterVolume"


@implementation OOSoundContext

- (id) init
{
	if (!(self = [super init]))
	{
		return nil;
	}
	
	_masterVolume = [[NSUserDefaults standardUserDefaults] oo_floatForKey:kPrefKeyMasterVolume defaultValue:kDefaultMasterVolume];
	_masterVolume = OOClamp_0_1_f(_masterVolume);
	
	if (![self isMemberOfClass:[OOSoundContext class]])
	{
		// Subclass callthrough.
		return self;
	}
	
	// Instantiate best available subclass.
	id result = nil;
	
	if (result == nil)  result = [[OOALSoundContext alloc] init];
	
#if OOLITE_MAC_OS_X
	if (result == nil)  result = [[OOCASoundContext alloc] init];
#endif
#if OOLITE_SDL
	if (result == nil)  result = [[OOSDLSoundContext alloc] init];
#endif
	
	if (result != nil)
	{
		DESTROY(self);
		return result;
	}
	else
	{
		// As a fallback, a plain OOSoundContext can act as a do-nothing “dummy” sound context.
		OOLog(@"sound.setup.failed", @"Could not initialize a sound engine, playing silently.");
		return self;
	}
}


- (void) update
{
	
}


- (void) setMasterVolume:(float) fraction
{
	if (fraction != _masterVolume)
	{
		_masterVolume = fraction;
		[[NSUserDefaults standardUserDefaults] setFloat:fraction forKey:kPrefKeyMasterVolume];
	}
}


- (float) masterVolume
{
	return _masterVolume;
}


- (OOSound *) soundWithContentsOfFile:(NSString *)file
{
	return [[[OOSound alloc] init] autorelease];
}


- (OOSoundSource *) soundSource
{
	return [[[OOSoundSource alloc] init] autorelease];
}

@end
