/*

OOSoundSource.m
 

Copyright (C) 2006-2011 Jens Ayton

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

#import "OOSoundInternal.h"


@implementation OOSoundSource

- (void) dealloc
{
	[self stop];
	[_sound autorelease];
	
	[super dealloc];
}


- (OOSound *) sound
{
	return _sound;
}


- (void) setSound:(OOSound *)sound
{
	if (_sound != sound)
	{
		[self stop];
		[_sound autorelease];
		_sound = [sound retain];
	}
}


- (BOOL) loop
{
	return _loop;
}


- (void) setLoop:(BOOL)loop
{
	_loop = !!loop;
}


- (uint8_t) repeatCount
{
	return _repeatCount ? _repeatCount : 1;
}


- (void) setRepeatCount:(uint8_t)count
{
	_repeatCount = count;
}


- (BOOL) isPlaying
{
	OOLogGenericSubclassResponsibility();
	return NO;
}


- (void) play
{
	OOLogGenericSubclassResponsibility();
}


- (void) playOrRepeat
{
	if (![self isPlaying])  [self play];
	else ++_remainingCount;
}


- (void) stop
{
	OOLogGenericSubclassResponsibility();
}


- (void) playSound:(OOSound *)sound
{
	[self playSound:sound repeatCount:_repeatCount];
}


- (void) playSound:(OOSound *)sound repeatCount:(uint8_t)count
{
	[self stop];
	[self setSound:sound];
	[self setRepeatCount:count];
	[self play];
}


- (void) playOrRepeatSound:(OOSound *)sound
{
	if (_sound != sound)  [self playSound:sound];
	else [self playOrRepeat];
}


- (void) setPositional:(BOOL)inPositional
{
	
}


- (void) setPosition:(Vector)inPosition
{
	
}


- (void) setVelocity:(Vector)inVelocity
{
	
}


- (void) setOrientation:(Vector)inOrientation
{
	
}


- (void) setConeAngle:(float)inAngle
{
	
}


- (void) setGainInsideCone:(float)inInside outsideCone:(float)inOutside
{
	
}


- (void) positionRelativeTo:(OOSoundReferencePoint *)inPoint
{
	
}

@end
