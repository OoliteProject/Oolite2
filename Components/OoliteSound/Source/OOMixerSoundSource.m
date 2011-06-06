/*

OOMixerSoundSource.m


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

#import "OOMixerSoundSource.h"
#import "OOSound.h"
#import "OOSoundChannel.h"
#import "OOSoundMixer.h"
#import "OOMixerSoundContext.h"


@implementation OOMixerSoundSource

- (id) initWithContext:(OOMixerSoundContext *)context
{
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


- (NSString *) descriptionComponents
{
	if ([self isPlaying])
	{
		return [NSString stringWithFormat:@"sound=%@, loop=%s, repeatCount=%u, playing on channel %@", _sound, [self loop] ? "YES" : "NO", [self repeatCount], _channel];
	}
	else
	{
		return [NSString stringWithFormat:@"sound=%@, loop=%s, repeatCount=%u, not playing", _sound, [self loop] ? "YES" : "NO", [self repeatCount]];
	}
}


- (void) setSound:(OOSound *)sound
{
	NSParameterAssert([sound context] == _context);
	[super setSound:sound];
}


- (void) play
{
	if ([self sound] == nil)  return;
	
	OOSoundMixer *mixer = [_context mixer];
	[mixer lock];
	
	if (_channel != nil)  [self stop];
	
	_channel = [mixer popChannel];
	if (nil != _channel)
	{
		_remainingCount = [self repeatCount];
		[_channel setDelegate:self];
		[_channel playSound:[self sound] looped:[self loop]];
		[self retain];
	}
	
	[mixer unlock];
}


- (BOOL) isPlaying
{
	return _channel != nil;
}


- (void) stop
{
	OOSoundMixer *mixer = [_context mixer];
	[mixer lock];
	
	if (nil != _channel)
	{
		[_channel setDelegate:[self class]];
		[_channel stop];
		_channel = nil;
		[self release];
	}
	
	[mixer unlock];
}


// OOCASoundChannelDelegate
- (void) channel:(OOSoundChannel *)channel didFinishPlayingSound:(OOSound *)sound
{
	assert(_channel == channel);
	
	OOSoundMixer *mixer = [_context mixer];
	[mixer lock];
	
	if (--_remainingCount)
	{
		[_channel playSound:[self sound] looped:NO];
	}
	else
	{
		[_channel setDelegate:nil];
		[[_context mixer] pushChannel:_channel];
		_channel = nil;
		[self release];
	}
	
	[mixer unlock];
}


+ (void) channel:(OOSoundChannel *)inChannel didFinishPlayingSound:(OOSound *)inSound
{
	// This delegate is used for a stopped source
	[[(OOMixerSoundContext *)[inChannel context] mixer] pushChannel:inChannel];
}

@end
