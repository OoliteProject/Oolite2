/*

OOCASoundMixer.m


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
#import "OOCASoundChannel.h"
#import "OOCASoundDebugMonitor.h"


static NSString * const kOOLogSoundInspetorNotLoaded			= @"sound.mixer.inspector.loadFailed";
static NSString * const kOOLogSoundMixerOutOfChannels			= @"sound.mixer.outOfChannels";
static NSString * const kOOLogSoundMixerReplacingBrokenChannel	= @"sound.mixer.replacingBrokenChannel";
static NSString * const kOOLogSoundMixerFailedToConnectChannel	= @"sound.mixer.failedToConnectChannel";


@interface OOCASoundMixer (Private)

- (void)pushChannel:(OOCASoundChannel *)inChannel;
- (OOCASoundChannel *)popChannel;

@end


#ifndef NDEBUG
id <OOCASoundDebugMonitor> gOOCASoundDebugMonitor = nil;

void OOSoundRegisterDebugMonitor(id <OOCASoundDebugMonitor> monitor)
{
	if (monitor != gOOCASoundDebugMonitor)
	{
		gOOCASoundDebugMonitor = monitor;
		[monitor soundDebugMonitorNoteChannelMaxCount:kMixerGeneralChannels];
	}
}
#endif


@implementation OOCASoundMixer

- (id) initWithContext:(OOCASoundContext *)context
{
	OSStatus					err = noErr;
	BOOL						OK;
	uint32_t					idx = 0, count = kMixerGeneralChannels;
	OOCASoundChannel			*temp;
	AudioComponentDescription	desc;
	
	if ((self = [super initWithContext:context]))
	{
		_listLock = [[NSLock alloc] init];
		[_listLock ooSetName:@"OOSoundMixer list lock"];
		_mixerLock = [[NSRecursiveLock alloc] init];
		[_mixerLock ooSetName:@"OOCASoundMixer synchronization lock"];
		
		OK = nil != _listLock && nil != _mixerLock;
		
		if (OK)
		{
			// Create audio graph
			err = NewAUGraph(&_graph);
			
			// Add output node
			desc.componentType = kAudioUnitType_Output;
			desc.componentSubType = kAudioUnitSubType_DefaultOutput;
			desc.componentManufacturer = kAudioUnitManufacturer_Apple;
			desc.componentFlags = 0;
			desc.componentFlagsMask = 0;
			if (!err)  err = AUGraphAddNode(_graph, &desc, &_outputNode);
			
			// Add mixer node
			desc.componentType = kAudioUnitType_Mixer;
			desc.componentSubType = kAudioUnitSubType_StereoMixer;
			desc.componentManufacturer = kAudioUnitManufacturer_Apple;
			desc.componentFlags = 0;
			desc.componentFlagsMask = 0;
			if (!err)  err = AUGraphAddNode(_graph, &desc, &_mixerNode);
			
			// Connect mixer to output
			if (!err)  err = AUGraphConnectNodeInput(_graph, _mixerNode, 0, _outputNode, 0);
			
			// Open the graph (turn it into concrete AUs) and extract mixer AU
			if (!err)  err = AUGraphOpen(_graph);
			if (!err)  err = AUGraphNodeInfo(_graph, _mixerNode, NULL, &_mixerUnit);
			
			if (!err)  [self setMasterVolume:1.0];
			
			if (err)  OK = NO;
		}
		
		if (OK)
		{
			// Allocate channels
			do
			{
				temp = [[OOCASoundChannel alloc] initWithContext:context
															  ID:count
														 auGraph:_graph];
				if (nil != temp)
				{
					_channels[idx++] = temp;
					[temp setNext:_freeList];
					_freeList = temp;
				}
			} while (--count);
			
			if (noErr != AUGraphInitialize(_graph)) OK = NO;
		}
		
		if (OK)
		{
			// Force CA to do any lazy setup.
			AUGraphStart(_graph);
			AUGraphStop(_graph);
		}
		
		if (!OK)
		{
			static bool onlyOnce;
			if (!onlyOnce)
			{
				onlyOnce = YES;
				OOLog(@"sound.mixer.init.failed", @"Failed to initialize sound mixer - error %i ('%.4s')", err, &err);
			}
			[super release];
			self = nil;
		}
	}
	
	return self;
}


- (void) dealloc
{
	if (_graph != NULL)
	{
		AUGraphStop(_graph);
		AUGraphUninitialize(_graph);
		AUGraphClose(_graph);
		DisposeAUGraph(_graph);
	}
	for (uint32_t idx = 0; idx != kMixerGeneralChannels; ++idx)
	{
		[_channels[idx] release];
	}
	
	[_listLock release];
	[_mixerLock release];
	
	[super dealloc];
}


- (void) channel:(OOCASoundChannel *)inChannel didFinishPlayingSound:(OOCASound *)inSound
{
	uint32_t				ID;
		
	[inSound decrementPlayingCount];
	
	if (![inChannel isOK])
	{
		OOLog(kOOLogSoundMixerReplacingBrokenChannel, @"Sound mixer: replacing broken channel %@.", inChannel);
		ID = [inChannel ID];
		[inChannel release];
		inChannel = [[OOCASoundChannel alloc] initWithContext:(OOCASoundContext *)[self context]
														   ID:ID
													  auGraph:_graph];
	}
	
	[self pushChannel:inChannel];
}


#ifndef NDEBUG
#define GET_PLAYMASK(n)		((_playMask & (1 << ((n) - 1))) != 0)
#define SET_PLAYMASK(n)		do { _playMask |= (1 << ((n) - 1)); } while (0)
#define CLEAR_PLAYMASK(n)	do { _playMask &= ~(1 << ((n) - 1));  } while (0)
#endif


- (void) update
{
#ifndef NDEBUG
	if (gOOCASoundDebugMonitor != nil)
	{
		[gOOCASoundDebugMonitor soundDebugMonitorNoteActiveChannelCount:_activeChannels];
		unsigned i;
		for (i = 0; i != kMixerGeneralChannels; ++i)
		{
			uint32_t	ID = [_channels[i] ID];
			BOOL		playMaskValue = GET_PLAYMASK(ID);
			OOCASoundDebugMonitorChannelState state = [_channels[i] soundInspectorState];
			
			// Because of asynchrony, channel may be in stopped state but not reenqueued.
			if (playMaskValue && state == kOOCADebugStateIdle)  state = kOOCADebugStateOther;
			
			[gOOCASoundDebugMonitor soundDebugMonitorNoteState:state ofChannel:ID - 1];
		}
		
		Float32 load;
		if (!AUGraphGetCPULoad(_graph, &load))
		{
			[gOOCASoundDebugMonitor soundDebugMonitorNoteAUGraphLoad:load];
		}
	}
#endif
}


- (void) setMasterVolume:(float)inVolume
{
	AudioUnitSetParameter(_mixerUnit, kStereoMixerParam_Volume, kAudioUnitScope_Output, 0, inVolume / kOOAudioSlop, 0);
}


- (OOCASoundChannel *) popChannel
{
	OOCASoundChannel				*result;
	
	[_listLock lock];
	result = _freeList;
	_freeList = [result next];
	
	if (nil != result)
	{
		if (0 == _activeChannels++)
		{
			AUGraphStart(_graph);
		}
		
#ifndef NDEBUG
		SET_PLAYMASK([result ID]);
#endif
	}
	[_listLock unlock];
	
	return result;
}


- (void) pushChannel:(OOCASoundChannel *) OO_NS_CONSUMED inChannel
{
	assert(nil != inChannel);
	
	[_listLock lock];
	
	[inChannel setNext:_freeList];
	_freeList = inChannel;
	
	if (0 == --_activeChannels)
	{
		AUGraphStop(_graph);
	}
	
#ifndef NDEBUG
	CLEAR_PLAYMASK([inChannel ID]);
#endif
	[_listLock unlock];
}


- (BOOL) connectChannel:(OOCASoundChannel *)inChannel
{
	AUNode						node;
	OSStatus					err;
	
	assert(nil != inChannel);
	
	node = [inChannel auSubGraphNode];
	err = AUGraphConnectNodeInput(_graph, node, 0, _mixerNode, [inChannel ID]);
	if (!err) err = AUGraphUpdate(_graph, NULL);
	
	if (err) OOLog(kOOLogSoundMixerFailedToConnectChannel, @"Sound mixer: failed to connect channel %@, error = %@.", inChannel, AudioErrorNSString(err));
	
	return !err;
}


- (OSStatus) disconnectChannel:(OOCASoundChannel *)inChannel
{
	OSStatus					err;
	
	assert(nil != inChannel);
	
	err = AUGraphDisconnectNodeInput(_graph, _mixerNode, [inChannel ID]);
	if (noErr == err) AUGraphUpdate(_graph, NULL);
	
	return err;
}


- (void) lock
{
	[_mixerLock lock];
}


- (void) unlock
{
	[_mixerLock unlock];
}

@end
