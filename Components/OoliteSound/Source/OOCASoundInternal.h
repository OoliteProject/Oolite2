/*

OOCASoundInternal.h

Declarations used within OOCASound. This file should not be used by client
code.


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

#import "OOSoundInternal.h"
#import "OOCASoundContext.h"
#import "OOCASound.h"
#import "OOCASoundChannel.h"
#import "OOCABufferedSound.h"
#import "OOCAStreamingSound.h"
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>
#import "OOMacErrorDescription.h"


@interface OOCASoundMixer (Internal)

- (BOOL)connectChannel:(OOCASoundChannel *)inChannel;
- (OSStatus)disconnectChannel:(OOCASoundChannel *)inChannel;

@end


@interface OOCASoundChannel (Internal)

- (void) reap;
- (void) cleanUp;

#ifndef NDEBUG
- (BOOL) readyToReap;
#endif

@end


#define kOOLogSoundInitError @"sound.initialization.error"



/*	The Vorbis floating-point decoder gives us out-of-range values for certain
	built-in sounds. To compensate, we reduce overall volume slightly to avoid
	clipping. (The worst observed value is -1.341681f in bigbang.ogg.)
*/
#define kOOAudioSlop 1.341682f
