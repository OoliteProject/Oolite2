/*

OOSoundContext.h

A sound context represents the shared state for sound playback, and is also
the factory for all sound system related objects. As such, it encapsulates the
sound engine being used.


Copyright © 2011 Jens Ayton

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

@class OOSound, OOSoundSource;


@interface OOSoundContext: OOWeakRefObject
{
@private
	float				_masterVolume;
}

- (id) init;

- (void) update;

- (NSString *) implementationName;

- (void) setMasterVolume:(float)fraction;
- (float) masterVolume;

// Factory methods.
- (OOSound *) soundWithContentsOfFile:(NSString *)file;
- (OOSoundSource *) soundSource;

@end
