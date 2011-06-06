/*

OOCABufferedSound.m


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


@interface OOCABufferedSound (Private)

- (BOOL)bufferSound:(NSString *)inPath;

@end


@implementation OOCABufferedSound

#pragma mark NSObject

- (void)dealloc
{
	free(_bufferL);
	_bufferL = NULL;
	
	if (_stereo)  free(_bufferR);
	_bufferR = NULL;
	
	[super dealloc];
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"\"%@\", %s, %g Hz, %u bytes", [self name], _stereo ? "stereo" : "mono", _sampleRate, _size * sizeof (float) * (_stereo ? 2 : 1));
}


#pragma mark OOSound

- (NSString *) name
{
	return _name;
}


- (BOOL) getAudioStreamBasicDescription:(AudioStreamBasicDescription *)outFormat
{
	assert(NULL != outFormat);
	
	outFormat->mSampleRate = _sampleRate;
	outFormat->mFormatID = kAudioFormatLinearPCM;
	outFormat->mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kLinearPCMFormatFlagIsNonInterleaved;
	outFormat->mBytesPerPacket = sizeof (float);
	outFormat->mFramesPerPacket = 1;
	outFormat->mBytesPerFrame = sizeof (float);
	outFormat->mChannelsPerFrame = 2;
	outFormat->mBitsPerChannel = sizeof (float) * 8;
	outFormat->mReserved = 0;
	
	return YES;
}


// Context is (offset << 1) | loop. Offset is initially 0.
- (BOOL) prepareToPlayWithContext:(OOCASoundRenderContext *)outContext
						   looped:(BOOL)inLoop
{
	*outContext = inLoop ? 1 : 0;
	return YES;
}


- (OSStatus) renderWithFlags:(AudioUnitRenderActionFlags *)ioFlags
					  frames:(UInt32)inNumFrames
					 context:(OOCASoundRenderContext *)ioContext
						data:(AudioBufferList *)ioData
{
	size_t					toCopy, remaining, underflow, offset;
	BOOL					loop, done = NO;
	
	loop = (*ioContext) & 1;
	offset = (*ioContext) >> 1;
	assert (ioData->mNumberBuffers == 2);
	
	if (offset < _size)
	{
		remaining = _size - offset;
		if (remaining < inNumFrames)
		{
			toCopy = remaining;
			underflow = inNumFrames - remaining;
		}
		else
		{
			toCopy = inNumFrames;
			underflow = 0;
		}
		
		bcopy(_bufferL + offset, ioData->mBuffers[0].mData, toCopy * sizeof (float));
		bcopy(_bufferR + offset, ioData->mBuffers[1].mData, toCopy * sizeof (float));
		
		if (underflow && loop)
		{
			offset = toCopy;
			toCopy = inNumFrames - toCopy;
			if (_size < toCopy) toCopy = _size;
			
			bcopy(_bufferL, ((float *)ioData->mBuffers[0].mData) + offset, toCopy * sizeof (float));
			bcopy(_bufferR, ((float *)ioData->mBuffers[1].mData) + offset, toCopy * sizeof (float));
			
			underflow -= toCopy;
			offset = 0;
		}
		
		*ioContext = ((offset + toCopy) << 1) | loop;
	}
	else
	{
		toCopy = 0;
		underflow = inNumFrames;
		*ioFlags |= kAudioUnitRenderAction_OutputIsSilence;
		done = YES;
	}
	
	if (underflow)
	{
		bzero(ioData->mBuffers[0].mData + toCopy, underflow * sizeof (float));
		bzero(ioData->mBuffers[1].mData + toCopy, underflow * sizeof (float));
	}
	
	return done ? endOfDataReached : noErr;
}


#pragma mark OOCABufferedSound

- (id) initWithContext:(OOCASoundContext *)context
			   decoder:(OOCASoundDecoder *)decoder
{
	BOOL					OK = YES;
	
	if (decoder == nil)  return NO;
	
	if (OK)
	{
		self = [super initWithContext:context];
		if (nil == self) OK = NO;
	}
	
	if (OK)
	{
		_name = [[decoder name] copy];
		_sampleRate = [decoder sampleRate];
		if ([decoder isStereo])
		{
			OK = [decoder readStereoCreatingLeftBuffer:&_bufferL rightBuffer:&_bufferR withFrameCount:&_size];
			_stereo = YES;
		}
		else
		{
			OK = [decoder readMonoCreatingBuffer:&_bufferL withFrameCount:&_size];
			_bufferR = _bufferL;
		}
	}
	
	if (!OK)
	{
		[self release];
		self = nil;
	}
	return self;
}

@end
