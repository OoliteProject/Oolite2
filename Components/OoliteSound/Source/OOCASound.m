/*

OOCASound.m


OOCASound - Core Audio sound implementation for Oolite.
Copyright (C) 2005-2011 Jens Ayton

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

#import "OOCASoundInternal.h"
#import "OOCASoundDecoder.h"
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>


@implementation OOCASound

- (id) initWithContext:(OOCASoundContext *)context
{
	NSParameterAssert(context != nil);
	
	if ((self = [super init]))
	{
		_context = [context retain];
	}
	
	return self;
}


- (void) dealloc
{
	[_context release];
	
	[super dealloc];
}


- (OOSoundContext *) context
{
	return _context;
}


- (OSStatus) renderWithFlags:(AudioUnitRenderActionFlags *)ioFlags
					  frames:(UInt32)inNumFrames
					 context:(OOCASoundRenderContext *)ioContext
						data:(AudioBufferList *)ioData
{
	return unimpErr;
}


- (void) incrementPlayingCount
{
	++_playingCount;
}


- (void) decrementPlayingCount
{
	if (EXPECT(_playingCount != 0))  --_playingCount;
	else  OOLog(@"sound.playUnderflow", @"Playing count for %@ dropped below 0!", self);
}


- (BOOL) isPlaying
{
	return 0 != _playingCount;
}


- (uint32_t) playingCount
{
	return _playingCount;
}


- (BOOL) prepareToPlayWithContext:(OOCASoundRenderContext *)outContext
						   looped:(BOOL)inLoop
{
	return YES;
}


- (void) finishStoppingWithContext:(OOCASoundRenderContext)inContext
{
	
}


- (BOOL) doPlay
{
	return YES;
}


- (BOOL) doStop
{
	return YES;
}


- (NSString *) name
{
	return nil;
}


- (BOOL) getAudioStreamBasicDescription:(AudioStreamBasicDescription *)outFormat
{
	return NO;
}

@end
