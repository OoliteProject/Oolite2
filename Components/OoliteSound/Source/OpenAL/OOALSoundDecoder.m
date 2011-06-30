/*

OOALSoundDecoder.m


Copyright © 2005-2011 Jens Ayton

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

#define OV_EXCLUDE_STATIC_CALLBACKS

#import "OOALSoundDecoder.h"
#import <stdio.h>
#import <vorbis/vorbisfile.h>


static void MixDown(float *inChan1, float *inChan2, float *outMix, size_t inCount) GCC_ATTR((unused));


@interface OOALSoundVorbisCodec: OOALSoundDecoder
{
	OggVorbis_File			_vf;
	NSString				*_name;
	BOOL					_atEnd;
}

- (id) initWithPath:(NSString *)path;

@end


@implementation OOALSoundDecoder

+ (id) decoderWithPath:(NSString *)path
{
	if ([[[path pathExtension] lowercaseString] isEqualToString:@"ogg"])
	{
		return [[[OOALSoundVorbisCodec alloc] initWithPath:path] autorelease];
	}
	return nil;
}


- (NSString *) descriptionComponents
{
	return $sprintf(@"\"%@\"", [self name]);
}


- (BOOL) readDataCreatingBuffer:(ALvoid **)outBuffer
				 withFrameCount:(ALsizei *)outSize
{
	if (NULL != outBuffer) *outBuffer = NULL;
	if (NULL != outSize) *outSize = 0;
	
	OOLogGenericSubclassResponsibility();
	return NO;
}


- (ALenum) format
{
	OOLogGenericSubclassResponsibility();
	return 0;
}


- (ALsizei) frequency
{
	OOLogGenericSubclassResponsibility();
	return 0;
}


- (NSString *) name
{
	OOLogGenericSubclassResponsibility();
	return @"";
}

@end


@implementation OOALSoundVorbisCodec

- (id) initWithPath:(NSString *)path
{
	BOOL				OK = NO;
	int					err;
	FILE				*file;
	
	if ((self = [super init]))
	{
		_name = [[path lastPathComponent] retain];
		
		if (nil != path)
		{
			file = fopen([path UTF8String], "r");
			if (NULL != file) 
			{
				err = ov_open(file, &_vf, NULL, 0);
				if (0 == err)
				{
					OK = YES;
				}
			}
		}
		
		if (!OK)
		{
			[self release];
			self = nil;
		}
	}
	
	return self;
}


- (void)dealloc
{
	[_name autorelease];
	ov_clear(&_vf);
	
	[super dealloc];
}

/*	FIXME
- (BOOL) readDataCreatingBuffer:(ALvoid **)outBuffer
				 withFrameCount:(ALsizei *)outSize;
*/


- (ALenum) format
{
	if (ov_info(&_vf, -1)->channels == 1)
	{
		return AL_FORMAT_MONO16;
	}
	else
	{
		return AL_FORMAT_STEREO16;
	}
}


- (ALsizei) frequency
{
	return ov_info(&_vf, -1)->rate;
}


- (NSString *) name
{
	return _name;
}

@end


// TODO: optimise, vectorise
static void MixDown(float *inChan1, float *inChan2, float *outMix, size_t inCount)
{
	while (inCount--)
	{
		*outMix++ = (*inChan1++ + *inChan2++) * 0.5f;
	}
}
