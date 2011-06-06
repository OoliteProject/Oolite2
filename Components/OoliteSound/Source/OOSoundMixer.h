/*

OOSoundMixer.h

Abstract mixer for sound engines that use the mixer-and-channel model.

In this model, each sound source is played through a channel, and channels are
mixed together by the mixer. The number of channels is fixed, but high enough
that the limit doesn’t practically matter.

The Core Audio and SDL engines use this approach.
 


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

#import <OoliteBase/OoliteBase.h>

@class OOMixerSoundContext, OOSoundChannel;


@interface OOSoundMixer: NSObject
{
@private
	OOWeakReference			*_context;
}

- (id) initWithContext:(OOMixerSoundContext *)context;

- (OOMixerSoundContext *) context;

/*
	A mutex, if necessary. The default implementations do nothing.
	(The Core Audio implementation provides a mutex because its channels may
	need to stop themselves on the reaper thread. Possibly.
	FIXME: check this. -- Ahruman 2011-06-06)
*/
- (void) lock;
- (void) unlock;

- (OOSoundChannel *) popChannel;
- (void) pushChannel:(OOSoundChannel *) OO_NS_CONSUMED inChannel;

@end
