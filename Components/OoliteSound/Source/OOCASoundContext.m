/*

OOCASoundContext.m


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

#import "OOCASoundContext.h"
#import "OOCASoundInternal.h"
#import "OOCASoundDecoder.h"
#import "OOCASoundDebugMonitor.h"


enum
{
	kDefaultMaxBufferSize		= 1 << 20	// 1 MiB
};

#define kPrefsKeyMaxBufferSize	@"maxSoundBufferSize"


enum
{
	// Port messages
	kMsgThreadUp				= 1UL,
	kMsgDie,
	kMsgThreadDied,
	kMsgWakeUp
};


typedef struct
{
	uintptr_t					tag;
	void						*value;
} PortMessage;


typedef struct
{
	mach_msg_header_t			header;
	mach_msg_size_t				descCount;
	mach_msg_descriptor_t		descriptor;
	PortMessage					message;
} PortSendMsgBody;


typedef struct
{
	mach_msg_header_t			header;
	mach_msg_size_t				descCount;
	mach_msg_descriptor_t		descriptor;
	PortMessage					message;
	mach_msg_trailer_t			trailer;
} PortWaitMsgBody;


static mach_port_t CreatePort(void);
static void PortSend(mach_port_t inPort, PortMessage inMessage);
static BOOL PortWait(mach_port_t inPort, PortMessage *outMessage);


#define kOOLogSoundMachPortError				@"sound.channel.machPortError"
#define kOOLogSoundLoadingSuccess				@"sound.load.success"
#define kOOLogSoundLoadingError					@"sound.load.error"
#define kOOLogSoundInspetorNotLoaded			@"sound.inspector.loadFailed"
#define kOOLogSoundMixerOutOfChannels			@"sound.outOfChannels"
#define kOOLogSoundMixerReplacingBrokenChannel	@"sound.replacingBrokenChannel"
#define kOOLogSoundMixerFailedToConnectChannel	@"sound.failedToConnectChannel"


@interface OOCASoundContext ()

- (BOOL) priv_setUpMixer;

@end


@implementation OOCASoundContext

- (id) init
{
	if ((self = [super init]))
	{
		BOOL OK = YES;
		
		if (OK)
		{
			_reaperPort = CreatePort();
			if (_reaperPort == MACH_PORT_NULL)  OK = NO;
		}
		
		if (OK)
		{
			_statusPort = CreatePort();
			if (_statusPort == MACH_PORT_NULL)  OK = NO;
		}
		
		if (OK)
		{
			if (pthread_mutex_init(&_reapQueueMutex, NULL) != 0)  OK = NO;
		}
		
		if (OK)
		{
			[NSThread detachNewThreadSelector:@selector(reaperThread:) toTarget:self withObject:nil];
			PortMessage message;
			OK = PortWait(_statusPort, &message);
			if (OK && message.tag != kMsgThreadUp)  OK = NO;
		}
		
		if (OK)
		{
			OK = [self priv_setUpMixer];
		}
		
		if (OK)
		{
			[self setMasterVolume:[self masterVolume]];
			
			_maxBufferedSoundSize = [[NSUserDefaults standardUserDefaults] oo_unsignedLongForKey:kPrefsKeyMaxBufferSize defaultValue:kDefaultMaxBufferSize];
		}
		
		if (!OK)
		{
			OOLog(@"sound.setup.failed", @"Could not set up Core Audio sound engine.");
			DESTROY(self);
			return nil;
		}
	}
	
	return self;
}


- (BOOL) priv_setUpMixer
{
	_listLock = [[NSLock alloc] init];
	if (_listLock == nil)  return NO;
	[_listLock ooSetName:@"OOSoundMixer list lock"];
	_mixerLock = [[NSRecursiveLock alloc] init];
	if (_mixerLock == nil)  return NO;
	[_mixerLock ooSetName:@"OOCASoundMixer synchronization lock"];
	
	// Create audio graph.
	OSStatus err = NewAUGraph(&_graph);
	
	// Add output node.
	err = AUGraphAddNode(_graph, &(AudioComponentDescription)
	{
		.componentType = kAudioUnitType_Output,
		.componentSubType = kAudioUnitSubType_DefaultOutput,
		.componentManufacturer = kAudioUnitManufacturer_Apple
	}, &_outputNode);
	if (err != noErr)  return NO;
	
	// Add mixer node.
	err = AUGraphAddNode(_graph, &(AudioComponentDescription)
	{
		.componentType = kAudioUnitType_Mixer,
		.componentSubType = kAudioUnitSubType_StereoMixer,
		.componentManufacturer = kAudioUnitManufacturer_Apple
	}, &_mixerNode);
	if (err != noErr)  return NO;
	
	// Connect mixer to output.
	if (!err)  err = AUGraphConnectNodeInput(_graph, _mixerNode, 0, _outputNode, 0);
	
	// Open the graph (turn it into concrete AUs) and extract mixer AU.
	if (!err)  err = AUGraphOpen(_graph);
	if (!err)  err = AUGraphNodeInfo(_graph, _mixerNode, NULL, &_mixerUnit);
	
	if (!err)  [self setMasterVolume:1.0];
	
	if (err != noErr)  return NO;
	
	// Allocate channels.
	uint32_t idx = 0, count = kMixerGeneralChannels;
	do
	{
		OOCASoundChannel *channel = [[OOCASoundChannel alloc] initWithContext:self
																		   ID:count
																	  auGraph:_graph];
		if (channel != nil)
		{
			_channels[idx++] = channel;
			[channel setNext:_freeList];
			_freeList = channel;
		}
	} while (--count);
	
	if (AUGraphInitialize(_graph) != noErr)  return NO;
	
	// Force CA to do any lazy setup.
	AUGraphStart(_graph);
	AUGraphStop(_graph);
	
	return YES;
}


- (void) dealloc
{
#ifndef NDEBUG
	DESTROY(_debugMonitor);
#endif
	
	if (_reaperRunning)
	{
		PortMessage message = { kMsgDie, NULL };
		PortSend(_reaperPort, message);
		PortWait(_statusPort, &message);
	}
	
	ipc_space_t task = mach_task_self();
	if (_reaperPort != MACH_PORT_NULL)  mach_port_destroy(task, _reaperPort);
	if (_statusPort != MACH_PORT_NULL)  mach_port_destroy(task, _statusPort);
	
	if (_graph != NULL)
	{
		AUGraphStop(_graph);
		AUGraphUninitialize(_graph);
		AUGraphClose(_graph);
		DisposeAUGraph(_graph);
	}
	for (uint32_t idx = 0; idx != kMixerGeneralChannels; ++idx)
	{
		DESTROY(_channels[idx]);
	}
	
	DESTROY(_listLock);
	DESTROY(_mixerLock);
	
	[super dealloc];
}


#ifndef NDEBUG
#define GET_PLAYMASK(n)		((_playMask & (1 << ((n) - 1))) != 0)
#define SET_PLAYMASK(n)		do { _playMask |= (1 << ((n) - 1)); } while (0)
#define CLEAR_PLAYMASK(n)	do { _playMask &= ~(1 << ((n) - 1));  } while (0)
#endif


#ifndef NDEBUG
- (void) update
{
	if (_debugMonitor != nil)
	{
		[_debugMonitor soundDebugMonitorNoteActiveChannelCount:_activeChannels];
		unsigned i;
		for (i = 0; i != kMixerGeneralChannels; ++i)
		{
			uint32_t	ID = [_channels[i] ID];
			BOOL		playMaskValue = GET_PLAYMASK(ID);
			OOCASoundDebugMonitorChannelState state = [_channels[i] soundInspectorState];
			
			// Because of asynchrony, channel may be in stopped state but not reenqueued.
			if (playMaskValue && state == kOOCADebugStateIdle)  state = kOOCADebugStateOther;
			
			[_debugMonitor soundDebugMonitorNoteState:state ofChannel:ID - 1];
		}
		
		Float32 load;
		if (!AUGraphGetCPULoad(_graph, &load))
		{
			[_debugMonitor soundDebugMonitorNoteAUGraphLoad:load];
		}
	}
}
#endif


- (NSString *) implementationName
{
	return @"Core Audio";
}


- (void) setMasterVolume:(float)fraction
{
	AudioUnitSetParameter(_mixerUnit, kStereoMixerParam_Volume, kAudioUnitScope_Output, 0, fraction / kOOAudioSlop, 0);
	[super setMasterVolume:fraction];
}


- (OOSoundChannel *) popChannel
{
	[_listLock lock];
	OOCASoundChannel *result = _freeList;
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


- (void) pushChannel:(OOSoundChannel *) OO_NS_CONSUMED inChannel
{
	NSCParameterAssert([inChannel isKindOfClass:[OOCASoundChannel class]] && [inChannel context] == self);
	OOCASoundChannel *channel = (OOCASoundChannel *)inChannel;
	
	[_listLock lock];
	
	[channel setNext:_freeList];
	_freeList = channel;
	
	if (0 == --_activeChannels)
	{
		AUGraphStop(_graph);
	}
	
#ifndef NDEBUG
	CLEAR_PLAYMASK([channel ID]);
#endif
	[_listLock unlock];
}


- (void) lockChannelLock
{
	[_mixerLock lock];
}


- (void) unlockChannelLock
{
	[_mixerLock unlock];
}


- (BOOL) connectChannel:(OOCASoundChannel *)channel
{
	NSCParameterAssert(channel != nil);
	
	AUNode node = [channel auSubGraphNode];
	OSStatus err = AUGraphConnectNodeInput(_graph, node, 0, _mixerNode, [channel ID]);
	if (!err) err = AUGraphUpdate(_graph, NULL);
	
	if (err) OOLog(kOOLogSoundMixerFailedToConnectChannel, @"Sound mixer: failed to connect channel %@, error = %@.", channel, AudioErrorNSString(err));
	
	return !err;
}


- (OSStatus) disconnectChannel:(OOCASoundChannel *)channel
{
	NSCParameterAssert(nil != channel);
	
	OSStatus err = AUGraphDisconnectNodeInput(_graph, _mixerNode, [channel ID]);
	if (noErr == err) AUGraphUpdate(_graph, NULL);
	
	return err;
}


- (void) channel:(OOCASoundChannel *)channel didFinishPlayingSound:(OOCASound *)sound
{
	[sound decrementPlayingCount];
	
	if (![channel isOK])
	{
		OOLog(kOOLogSoundMixerReplacingBrokenChannel, @"Sound mixer: replacing broken channel %@.", channel);
		uint32_t ID = [channel ID];
		[channel release];
		channel = [[OOCASoundChannel alloc] initWithContext:self
														   ID:ID
													  auGraph:_graph];
	}
	
	[self pushChannel:channel];
}


- (pthread_mutex_t *) reapQueueMutex
{
	return &_reapQueueMutex;
}


- (void) reaperThread:junk
{
	NSAutoreleasePool *rootPool = [[NSAutoreleasePool alloc] init];
	
	[NSThread ooSetCurrentThreadName:@"OOCASoundChannel reaper thread"];
	_reaperRunning = YES;
	PortSend(_statusPort, (PortMessage){ kMsgThreadUp });
	
	[NSThread setThreadPriority:0.5];
	
	for (;;)
	{
		PortMessage message;
		if (PortWait(_reaperPort, &message))
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			if (kMsgWakeUp == message.tag)
			{
				assert (!pthread_mutex_lock(&_reapQueueMutex));
				
				while (_reapQueue)
				{
					OOCASoundChannel *channel = _reapQueue;
					_reapQueue = channel->_next;
#ifndef NDEBUG
					if (![channel readyToReap])
					{
						OOLog(@"sound.bug", @"Sound channel queued for reaping but not ready to reap.");
						continue;
					}
#endif
					
					[channel reap];
					[channel cleanUp];
				}
				
				pthread_mutex_unlock(&_reapQueueMutex);
			}
			else if (kMsgDie == message.tag)
			{
				[pool release];
				break;
			}
			
			[pool release];
		}
	}
	
	PortSend(_statusPort, (PortMessage){ kMsgThreadDied });
	[rootPool release];
}


- (OOSound *) soundWithContentsOfFile:(NSString *)file
{
	OOCASoundDecoder *decoder = [[OOCASoundDecoder alloc] initWithPath:file];
	if (decoder == nil)  return nil;
	
	OOSound *result = nil;
	if ([decoder sizeAsBuffer] <= _maxBufferedSoundSize)
	{
		result = [[OOCABufferedSound alloc] initWithContext:self decoder:decoder];
	}
	else
	{
		result = [[OOCAStreamingSound alloc] initWithContext:self decoder:decoder];
	}
	[decoder release];
	
	if (result != nil)
	{
#ifndef NDEBUG
		OOLog(kOOLogSoundLoadingSuccess, @"Loaded sound %@", self);
#endif
	}
	else
	{
		OOLog(kOOLogSoundLoadingError, @"Failed to load sound \"%@\"", file);
	}
	
	return result;
}


/*
	In order to avoid grabbing a mutex in the realtime render thread, reaped
	channels are initially pushed to the “dead list”, which is local to the
	RT thread, and then pushed to the “reap queue” if the reap queue mutex
	is unlocked. If it isn’t, the channel will languish on the “dead list”
	until another channel is reaped. The contention rate of the mutex is quite
	low, so this is unlikely to leave more than one or two channels on the dead
	list at a time.
*/
void OOCASoundContextReapChannel(OOCASoundContext *context, OOCASoundChannel *channel)
{
	assert(context != nil && channel != nil);
	
	channel->_next = context->_deadList;
	context->_deadList = channel;
	
	if (!pthread_mutex_trylock(&context->_reapQueueMutex))
	{
		OOCASoundChannel *curr = context->_deadList;
		while (nil != curr->_next)  curr = curr->_next;
		
		curr->_next = context->_reapQueue;
		context->_reapQueue = context->_deadList;
		context->_deadList = nil;
		
		pthread_mutex_unlock(&context->_reapQueueMutex);
		
		// Wake up reaper thread.
		PortSend(context->_reaperPort, (PortMessage) { kMsgWakeUp });
	}
}

@end


#ifndef NDEBUG

@implementation OOCASoundContext (OOCASoundDebugMonitor)

- (void) setDebugMonitor:(id <OOCASoundDebugMonitor>)monitor
{
	[_debugMonitor autorelease];
	_debugMonitor = [monitor retain];
}

@end


@implementation OOSoundContext (OOCASoundDebugMonitor)

- (void) setDebugMonitor:(id <OOCASoundDebugMonitor>)monitor
{
	// Do nothing.
}

@end

#endif


static mach_port_t CreatePort(void)
{
	kern_return_t				err;
	mach_port_t					result;
	ipc_space_t					task;
	mach_msg_type_name_t		type;
	mach_port_t					sendRight;
	
	task = mach_task_self();
	err = mach_port_allocate(task, MACH_PORT_RIGHT_RECEIVE, &result);
	if (KERN_SUCCESS == err) err = mach_port_insert_right(task, result, result, MACH_MSG_TYPE_MAKE_SEND);
	if (KERN_SUCCESS == err) err = mach_port_extract_right(task, result, MACH_MSG_TYPE_MAKE_SEND, &sendRight, &type);
	
	if (KERN_SUCCESS != err)
	{
		OOLog(kOOLogSoundInitError, @"Mach port creation failure: %@", KernelResultNSString(err));
		result = MACH_PORT_NULL;
	}
	
	return result;
}


static void PortSend(mach_port_t inPort, PortMessage inMessage)
{
	PortSendMsgBody				message;
	mach_msg_return_t			result;
	
	bzero(&message, sizeof message);
	
	message.header.msgh_bits = MACH_MSGH_BITS_REMOTE(MACH_MSG_TYPE_MAKE_SEND);
	message.header.msgh_size = sizeof message;
	message.header.msgh_remote_port = inPort;
	message.header.msgh_local_port = MACH_PORT_NULL;
	
	message.descCount = 1;
	
	message.message = inMessage;
	
	result = mach_msg(&message.header, MACH_SEND_MSG | MACH_SEND_TIMEOUT, sizeof message, 0, MACH_PORT_NULL, 0, MACH_PORT_NULL);
	if (MACH_MSG_SUCCESS != result)
	{
		OOLog(kOOLogSoundMachPortError, @"Mach port transient send failure: %@", KernelResultNSString(result));
		result = mach_msg(&message.header, MACH_SEND_MSG, sizeof message, 0, MACH_PORT_NULL, 0, MACH_PORT_NULL);
		if (MACH_MSG_SUCCESS != result)
		{
			OOLog(kOOLogSoundMachPortError, @"Mach port send failure: %@", KernelResultNSString(result));
		}
	}
}


static BOOL PortWait(mach_port_t inPort, PortMessage *outMessage)
{
	PortWaitMsgBody				message;
	mach_msg_return_t			result;
	
	bzero(&message, sizeof message);
	
	message.header.msgh_bits = MACH_MSGH_BITS_LOCAL(MACH_MSG_TYPE_COPY_RECEIVE);
	message.header.msgh_size = sizeof message;
	message.header.msgh_local_port = inPort;
	
	result = mach_msg_receive(&message.header);
	if (MACH_MSG_SUCCESS == result)
	{
		if (NULL != outMessage) *outMessage = message.message;
	}
	else
	{
		if (MACH_RCV_TIMED_OUT != result) OOLog(kOOLogSoundMachPortError, @"Mach port receive failure: %@", KernelResultNSString(result));
	}
	
	return MACH_MSG_SUCCESS == result;
}
