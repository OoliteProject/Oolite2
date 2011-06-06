/*

OOCASound.h

Shared functionality for CA implementations of OOSound. OOCASound itself is
abstract.


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

#import "OOSound.h"
#import <AudioUnit/AudioUnit.h>

@class OOCASoundContext;
typedef uintptr_t OOCASoundRenderContext;


@interface OOCASound: OOSound
{
@private
	OOCASoundContext	*_context;
	uint32_t			_playingCount;
}

- (id) initWithContext:(OOCASoundContext *)context;

/*
	Core render method.
	
	This method will be IMP cached, and will be called on the realtime rendering
	thread, so it musn’t make any ObjC method calls.
*/
- (OSStatus) renderWithFlags:(AudioUnitRenderActionFlags *)ioFlags
					  frames:(UInt32)inNumFrames
					 context:(OOCASoundRenderContext *)ioContext
						data:(AudioBufferList *)ioData;

// Called by -play and -stop only if in appropriate state
- (BOOL) prepareToPlayWithContext:(OOCASoundRenderContext *)outContext
						   looped:(BOOL)inLoop;
- (void) finishStoppingWithContext:(OOCASoundRenderContext)inContext;

- (BOOL) getAudioStreamBasicDescription:(AudioStreamBasicDescription *)outFormat;

- (void) incrementPlayingCount;
- (void) decrementPlayingCount;

- (BOOL) isPlaying;

@end
