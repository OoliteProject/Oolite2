/*

OODebugSoundInspector.m
olite Debug OXP


Copyright (C) 2010 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
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


#import "OODebugSoundInspector.h"
#import <Cocoa/Cocoa.h>
#import <OoliteBase/OoliteBase.h>


@implementation OODebugSoundInspector

- (id) init
{
	if ((self = [super init]))
	{
		if (![NSBundle loadNibNamed:@"OODebugSoundInspector" owner:self])
		{
			OOLog(@"debugOXP.load.soundInspector.failed", @"Failed to load sound inspector nib.");
			DESTROY(self);
		}
		else  OOSoundRegisterDebugMonitor(self);
	}
	
	return self;
}


- (void) soundDebugMonitorNoteChannelMaxCount:(NSUInteger)maxChannels
{
	
}


- (void) soundDebugMonitorNoteActiveChannelCount:(NSUInteger)usedChannels
{
	[_currentField setIntValue:usedChannels];
	if (usedChannels > _channelCountHighWaterMark)
	{
		_channelCountHighWaterMark = usedChannels;
		[_maxField setIntValue:usedChannels];
	}
}


- (void) soundDebugMonitorNoteState:(OOCASoundDebugMonitorChannelState)state ofChannel:(NSUInteger)channel
{
	[[_checkBoxes cellWithTag:channel] setIntValue:state];
}


- (void) soundDebugMonitorNoteAUGraphLoad:(float)load
{
	[_loadBar setFloatValue:load * 100.0f];
	if (load > _loadHighWaterMark)
	{
		_loadHighWaterMark = load;
	}
}


- (IBAction) show:(id)sender
{
	[_inspectorWindow makeKeyAndOrderFront:sender];
}

@end
