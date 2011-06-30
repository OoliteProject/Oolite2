/*

OOALSoundContext.m


Copyright © 2011 Jens Ayton

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

#import "OOALSoundContext.h"
#import "OOALSoundInternal.h"


@implementation OOALSoundContext

- (id) init
{
	if ([[NSUserDefaults standardUserDefaults] oo_boolForKey:@"disableOpenAL" defaultValue:YES])
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		BOOL OK = YES;
		
		_device = alcOpenDevice(NULL);
		if (_device == NULL)
		{
			OOLog(@"sound.al.device.open.error", @"Failed to open default OpenAL device.");
			OK = NO;
		}
		
		if (OK)
		{
			_context = alcCreateContext(_device, NULL);
			if (_context == NULL)
			{
				OOLog(@"sound.al.device.open.error", @"Failed to create OpenAL context: %@.", [self alcErrorString]);
				OK = NO;
			}
		}
		
		if (OK)
		{
			alcMakeContextCurrent(_context);
			alDistanceModel(AL_NONE);	// We don’t support positional audio yet.
			
			[self setMasterVolume:[self masterVolume]];
		}
		
		if (OK)
		{
			OOLog(@"sound.al.device.open", @"Opened OpenAL device \"%s\".", alcGetString(_device, ALC_DEVICE_SPECIFIER));
		}
		
		if (!OK)
		{
			DESTROY(self);
		}
	}
	
	return self;
}


- (void) dealloc
{
	alcMakeContextCurrent(NULL);
	
	if (_context != NULL)
	{
		alcDestroyContext(_context);
		_context = NULL;
	}
	
	if (_device != NULL)
	{
		if (!alcCloseDevice(_device))
		{
			OOLog(@"sound.al.device.close.error", @"Failed to close OpenAL device.");
		}
		_device = NULL;
	}
	
	[super dealloc];
}


- (NSString *) implementationName
{
	return $sprintf(@"OpenAL (%s, %s)", alGetString(AL_VERSION), alGetString(AL_RENDERER));
}


- (void) setMasterVolume:(float)fraction
{
	alcMakeContextCurrent(_context);
	alListenerf(AL_GAIN, fraction);
	
	[super setMasterVolume:fraction];
}


/*
- (OOSound *) soundWithContentsOfFile:(NSString *)file;
- (OOSoundSource *) soundSource;
*/


- (NSString *) alErrorString
{
	alcMakeContextCurrent(_context);
	ALenum error = alGetError();
	
	switch (error)
	{
		case AL_NO_ERROR: return @"no error";
		case AL_INVALID_NAME: return @"invalid name";
		case AL_INVALID_ENUM: return @"invalid enumerant";
		case AL_INVALID_VALUE: return @"invalid value";
		case AL_INVALID_OPERATION: return @"invalid operation";
		case AL_OUT_OF_MEMORY: return @"out of memory";
		default:
			return $sprintf(@"error %i", error);			
	}
}


- (NSString *) alcErrorString
{
	ALCenum error = ALC_NO_ERROR;
	if (_device != NULL)
	{
		error = alcGetError(_device);
	}
	
	switch (error)
	{
		case ALC_NO_ERROR: return @"no error";
		case ALC_INVALID_DEVICE: return @"invalid device";
		case ALC_INVALID_CONTEXT: return @"invalid context";
		case ALC_INVALID_ENUM: return @"invalid enumerant";
		case ALC_INVALID_VALUE: return @"invalid value";
		case ALC_OUT_OF_MEMORY: return @"out of memory";
		default:
			return $sprintf(@"error %i", error);
	}
}

@end
