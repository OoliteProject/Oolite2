/*

OOCASoundContext.h

Core Audio implementation of OOSoundContext.


Copyright © 2005–2011 Jens Ayton

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

#import "OOMixerSoundContext.h"
#import "OOCASoundDebugMonitor.h"

#include <mach/mach.h>
#import <mach/port.h>
#include <pthread.h>
#import <AudioToolbox/AudioToolbox.h>

@class OOCASoundMixer, OOCASoundChannel, OOCASoundDebugMonitor;


enum
{
	kMixerGeneralChannels		= 32
};


@interface OOCASoundContext: OOMixerSoundContext
{
@private
	size_t						_maxBufferedSoundSize;
	
	mach_port_t					_reaperPort;
	mach_port_t					_statusPort;
	pthread_mutex_t				_reapQueueMutex;
	
	OOCASoundChannel			*_channels[kMixerGeneralChannels];
	OOCASoundChannel			*_freeList;
	OOCASoundChannel			*_deadList;
	OOCASoundChannel			*_reapQueue;
	
	NSLock						*_listLock;
	NSRecursiveLock				*_mixerLock;
	
	AUGraph						_graph;
	AUNode						_mixerNode;
	AUNode						_outputNode;
	AudioUnit					_mixerUnit;
	
	uint32_t					_activeChannels;
#ifndef NDEBUG
	uint32_t					_playMask;
	id <OOCASoundDebugMonitor>	_debugMonitor;
#endif
	
	BOOL						_reaperRunning;
}

@end


/*
	OOCASoundContextReapChannel()
	Called by a channel to return itself to the available list after it has
	finished playing. May only be called on the CA render thread.
*/
void OOCASoundContextReapChannel(OOCASoundContext *context, OOCASoundChannel *channel);
