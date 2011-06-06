/*

OOCASoundChannel.m


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

#import "OOCASoundChannel.h"
#import "OOCASoundInternal.h"
#include <mach/mach.h>
#include <pthread.h>
#include </usr/include/libkern/OSAtomic.h>


static NSString * const kOOLogSoundPlaySuccess			= @"sound.play.success";
static NSString * const kOOLogSoundBadReuse				= @"sound.play.failed.badReuse";
static NSString * const kOOLogSoundSetupFailed			= @"sound.play.failed.setupFailed";
static NSString * const kOOLogSoundPlayAUError			= @"sound.play.failed.auError";
static NSString * const kOOLogSoundPlayUnknownError		= @"sound.play.failed";
static NSString * const kOOLogSoundCleanUpSuccess		= @"sound.channel.cleanup.success";
static NSString * const kOOLogSoundCleanUpBroken		= @"sound.channel.cleanup.failed.broken";
static NSString * const kOOLogSoundCleanUpBadState		= @"sound.channel.cleanup.failed.badState";


static OOCASoundChannel_RenderIMP	SoundChannelRender = NULL;

typedef enum
{
	kState_Stopped,
	kState_Playing,
	kState_Ended,
	kState_Reap,
	
	kState_Broken
} States;


#define kAURenderSelector		@selector(renderWithFlags:frames:context:data:)


@interface OOCASoundChannel(OOPrivate)

- (OSStatus) renderWithFlags:(AudioUnitRenderActionFlags *)ioFlags
					  frames:(UInt32)inNumFrames
					 context:(OOCASoundRenderContext *)ioContext
						data:(AudioBufferList *)ioData;

@end


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


static OSStatus ChannelRenderProc(void *inRefCon, AudioUnitRenderActionFlags *ioFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumFrames, AudioBufferList *ioData);


@implementation OOCASoundChannel

- (id) init
{
	[self release];
	return nil;
}


- (id) initWithContext:(OOCASoundContext *)context
					ID:(uint8_t)inID
			   auGraph:(AUGraph)inGraph
{
	OSStatus					err = noErr;
	AudioComponentDescription	desc;
	AURenderCallbackStruct		input;
	
	NSParameterAssert(context != nil);
	
	if ((self = [super initWithContext:context]))
	{
		_id = inID;
		
		if (SoundChannelRender == NULL)
		{
			SoundChannelRender = (OOCASoundChannel_RenderIMP)[OOCASoundChannel instanceMethodForSelector:kAURenderSelector];
		}
		
		// Create a subgraph (since we can’t have multiple output units otherwise)
		err = AUGraphNewNodeSubGraph(inGraph, &_subGraphNode);
		if (!err) err = AUGraphGetNodeInfoSubGraph(inGraph, _subGraphNode, &_subGraph);
		
		// Create an output unit
		desc.componentType = kAudioUnitType_Output;
		desc.componentSubType = kAudioUnitSubType_GenericOutput;
		desc.componentManufacturer = kAudioUnitManufacturer_Apple;
		desc.componentFlags = 0;
		desc.componentFlagsMask = 0;
		if (!err) err = AUGraphAddNode(_subGraph, &desc, &_node);
		if (!err) err = AUGraphNodeInfo(_subGraph, _node, NULL, &_au);
		
		// Set render callback
		input.inputProc = ChannelRenderProc;
		input.inputProcRefCon = self;
		if (!err) err = AudioUnitSetProperty(_au, kAudioUnitProperty_SetRenderCallback,
									kAudioUnitScope_Input, 0, &input, sizeof input);
		
		// Init & check errors
		if (!err) err = AudioUnitInitialize(_au);
		
		if (err)
		{
			OOLog(kOOLogSoundInitErrorGlavin, @"AudioUnit setup error %@ preparing channel ID %u.", AudioErrorNSString(err), inID);
			
			[self release];
			self = nil;
		}
	}
	
	return self;
}


- (void) dealloc
{
	[self stop];
	if (NULL != _au) CloseComponent(_au);
	
	[super dealloc];
}


- (OOCASoundMixer *) mixer
{
	OOCASoundContext *context = (OOCASoundContext *)[self context];
	return (OOCASoundMixer *)[context mixer];
}


- (NSUInteger) ID
{
	return _id;
}


- (AUNode) auSubGraphNode
{
	return _subGraphNode;
}


- (OOCASoundChannel *) next
{
	return _next;
}


- (void)setNext:(OOCASoundChannel *)inNext
{
	_next = inNext;
}


- (OOSound *)sound
{
	return _sound;
}


- (BOOL) playSound:(OOSound *)inSound looped:(BOOL)inLooped
{
	NSParameterAssert([inSound isKindOfClass:[OOCASound class]] && [inSound context] == [inSound context]);
	
	BOOL						OK = YES;
	OSStatus					err = noErr;
	AudioStreamBasicDescription	format;
	OOCASound					*sound = (OOCASound *)inSound, *temp = nil;
	
	if (nil != sound)
	{
		OOCASoundMixer *mixer = [self mixer];
		
		[mixer lock];
		if (kState_Stopped != _state)
		{
			OOLog(kOOLogSoundBadReuse, @"Channel %@ reused while playing.", self);
			
			[mixer disconnectChannel:self];
			if (_sound)
			{
				Render = NULL;
				temp = _sound;
				_sound = nil;
				[temp finishStoppingWithContext:_renderContext];
				_renderContext = 0;
				[temp release];
			}
			_stopReq = NO;
			_state = kState_Stopped;
		}
		
		Render = (OOCASoundChannel_RenderIMP)[(OOCASound *)sound methodForSelector:kAURenderSelector];
		OK = (NULL != Render);
		
		if (OK) OK = [sound getAudioStreamBasicDescription:&format];
		if (OK) OK = [sound prepareToPlayWithContext:&_renderContext looped:inLooped];
		
		if (!OK)
		{
			OOLog(kOOLogSoundSetupFailed, @"Failed to play sound %@ - set-up failed.", sound);
		}
		
		if (OK)
		{
			_sound = sound;
			
			err = AudioUnitSetProperty(_au, kAudioUnitProperty_StreamFormat,
						kAudioUnitScope_Input, 0, &format, sizeof format);
			
			if (err) OOLog(kOOLogSoundPlayAUError, @"Failed to play %@ (error %@)", sound, AudioErrorNSString(err));
			OK = !err;
		}
		
		if (OK) OK = [mixer connectChannel:self];
		
		if (OK)
		{
			[_sound retain];
			_state = kState_Playing;
			OOLog(kOOLogSoundPlaySuccess, @"Playing sound %@", _sound);
		}
		else
		{
			_sound = nil;
			if (!err) OOLog(kOOLogSoundPlayUnknownError, @"Failed to play %@", sound);
		}
		[mixer unlock];
	}
	
	return OK;
}


- (void)stop
{
	if (kState_Playing == _state)
	{
		_stopReq = YES;
	}
	
	if (kState_Ended == _state) [self cleanUp];
}


- (void)reap
{
	OSStatus err = [[self mixer] disconnectChannel:self];
	
	if (noErr == err)
	{
		_state = kState_Ended;
	}
	else
	{
		_state = kState_Broken;
		_error = err;
	}
}


#ifndef NDEBUG
- (BOOL) readyToReap
{
	return _state == kState_Reap;
}
#endif


- (void) cleanUp
{
	OOCASoundMixer *mixer = [self mixer];
	[mixer lock];
	
	if (kState_Broken == _state)
	{
		OOLog(kOOLogSoundCleanUpBroken, @"Sound channel %@ broke with error %@.", self, AudioErrorNSString(_error));
	}
	
	if (kState_Ended == _state || kState_Broken == _state)
	{
		Render = NULL;
		OOCASound *sound = _sound;
		_sound = nil;
		[sound finishStoppingWithContext:_renderContext];
		_renderContext = 0;
		
		_state = kState_Stopped;
		_stopReq = NO;
		
		id delegate = [self delegate];
		if (nil != delegate && [delegate respondsToSelector:@selector(channel:didFinishPlayingSound:)])
		{
			[delegate channel:self didFinishPlayingSound:sound];
		}
		[sound release];
		
		OOLog(kOOLogSoundCleanUpSuccess, @"Sound channel id %u cleaned up successfully.", _id);
	}
	else
	{
		OOLog(kOOLogSoundCleanUpBadState, @"Sound channel %@ cleaned up in invalid state %u.", self, _state);
	}
	
	[mixer unlock];
}


- (BOOL) isOK
{
	return kState_Broken != _state;
}


#ifndef NDEBUG
- (OOCASoundDebugMonitorChannelState) soundInspectorState
{
	switch ((States)_state)
	{
		case kState_Stopped:
			return kOOCADebugStateIdle;
			
		case kState_Playing:
			return kOOCADebugStatePlaying;
			
		case kState_Ended:
		case kState_Reap:
		case kState_Broken:
			return kOOCADebugStateOther;
	}
	
	return kOOCADebugStateOther;
}
#endif


- (NSString *)description
{
	OOCASoundMixer *mixer = [self mixer];
	[mixer lock];
	
	NSString *stateString = nil;
	switch ((States)_state)
	{
		case kState_Stopped:
			stateString = @"stopped";
			break;
		
		case kState_Playing:
			stateString = @"playing";
			break;
			
		case kState_Ended:
			stateString = @"ended";
			break;
			
		case kState_Reap:
			stateString = @"waiting to be reaped";
			break;
		
		case kState_Broken:
			stateString = [NSString stringWithFormat:@"broken (%@)", AudioErrorShortNSString(_error)];
			break;
		
		default:
			stateString = [NSString stringWithFormat:@"unknown (%u)", _state];
	}
	
	NSString *result = [NSString stringWithFormat:@"<%@ %p>{ID=%u, state=%@, sound=%@}", [self className], self, _id, stateString, _sound];
	
	[mixer unlock];
	
	return result;
}


- (OSStatus)renderWithFlags:(AudioUnitRenderActionFlags *)ioFlags
					 frames:(UInt32)inNumFrames
					context:(OOCASoundRenderContext *)ioContext
					   data:(AudioBufferList *)ioData
{
	OSStatus					err = noErr;
	BOOL						renderSilence = NO;
	
	if (EXPECT_NOT(_stopReq)) err = endOfDataReached;
	else if (EXPECT(kState_Playing == _state))
	{
		if (NULL != Render && nil != _sound)
		{
			err = Render(_sound, kAURenderSelector, ioFlags, inNumFrames, &_renderContext, ioData);
		}
		else
		{
			err = endOfDataReached;
			renderSilence = YES;
		}
	}
	else
	{
		renderSilence = YES;
	}
	
	if (EXPECT_NOT(renderSilence))
	{
		unsigned			i, count = ioData->mNumberBuffers;
		
		for (i = 0; i != count; i++)
		{
			bzero(ioData->mBuffers[i].mData, ioData->mBuffers[i].mDataByteSize);
		}
		*ioFlags |= kAudioUnitRenderAction_OutputIsSilence;
	}
	
	if (err == endOfDataReached)
	{
		err = noErr;
		if (EXPECT(kState_Playing == _state))
		{
			_state = kState_Reap;
			OOCASoundContextReapChannel((OOCASoundContext *)[self context], self);
		}
	}
	
	return err;
}

@end


static OSStatus ChannelRenderProc(void *inRefCon, AudioUnitRenderActionFlags *ioFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumFrames, AudioBufferList *ioData)
{
	return SoundChannelRender((id)inRefCon, kAURenderSelector, ioFlags, inNumFrames, 0, ioData);
}
