/*

OOSoundChannel.h

Abstract sound channel class for audio engines that use a mixer and channels model.
(The Core Audio and SDL engines do; the OpenAL engine won’t.) Abstract but not
public.


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

#import <OoliteBase/OoliteBase.h>

@class OOSound, OOSoundContext;


@interface OOSoundChannel: NSObject
{
@private
	id							_delegate;
	OOWeakReference				*_context;
}

- (id) initWithContext:(OOSoundContext *)context;

- (OOSoundContext *) context;
- (NSUInteger) ID;

- (id) delegate;
- (void) setDelegate:(id)inDelegate;

- (BOOL) playSound:(OOSound *)inSound looped:(BOOL)inLoop;
- (void) stop;

@end


@interface NSObject(OOSoundChannelDelegate)

// Note: this will be called in a separate thread in the CA implementation.
- (void) channel:(OOSoundChannel *)inChannel didFinishPlayingSound:(OOSound *)inSound;

@end
