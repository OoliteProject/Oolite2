/*

OOCASoundChannel.h

A channel for audio playback.

This class is an implementation detail. Do not use it directly; use an
OOSoundSource to play an OOSound.


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

#import "OOSoundChannel.h"
#import <AudioToolbox/AudioToolbox.h>
#import "OOCASoundDebugMonitor.h"
#import "OOCASound.h"


typedef  OSStatus (*OOCASoundChannel_RenderIMP)(id inSelf, SEL inSelector, AudioUnitRenderActionFlags *ioFlags, UInt32 inNumFrames, OOCASoundRenderContext *ioContext, AudioBufferList *ioData);


@interface OOCASoundChannel: OOSoundChannel
{
@public
	// Exposed for internal use on RT thread, not really public.
	OOCASoundChannel			*_next;
	
@private
	AUNode						_subGraphNode;
	AUGraph						_subGraph;
	AUNode						_node;
	AudioUnit					_au;
	OOCASound					*_sound;
	OOCASoundRenderContext		_renderContext;
	OOCASoundChannel_RenderIMP	Render;
	uint8_t						_state,
								_id,
								_stopReq;
	OSStatus					_error;
}

- (id) initWithContext:(OOCASoundContext *)context
					ID:(uint8_t)inID
			   auGraph:(AUGraph)inGraph;

- (AUNode) auSubGraphNode;

// Unretained pointer used to maintain simple stack
- (OOCASoundChannel *) next;
- (void) setNext:(OOCASoundChannel *)inNext;

- (OOSound *) sound;

- (BOOL) isOK;


#ifndef NDEBUG
- (OOCASoundDebugMonitorChannelState) soundInspectorState;
#endif

@end
