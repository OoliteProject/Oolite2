/*
	SGDepthBufferStateTag.m
	
	Copyright © 2007 Jens Ayton
	
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#import "SGDepthBufferStateTag.h"


static inline NSString *StateName(SGStateValue inState)
{
	static NSString * const names[3] = {@"off", @"on", @"no change"};
	return (inState <= kSGNoChange) ? names[inState] : @"unknown";
}


@implementation SGDepthBufferStateTag

#pragma mark NSObject

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		testEnable = kSGNoChange;
		writeEnable = kSGNoChange;
	}
	return self;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p>{test:%@ write:%@}", [self className], self, StateName(testEnable), StateName(writeEnable)];
}


#pragma mark SGSceneTag

- (void)apply:(NSMutableDictionary *)ioState
{
	glPushAttrib(GL_DEPTH_BUFFER_BIT);
	
	if (testEnable == kSGOff) glDisable(GL_DEPTH_TEST);
	else if (testEnable == kSGOn) glEnable(GL_DEPTH_TEST);
	
	if (writeEnable != kSGNoChange) glDepthMask(writeEnable == kSGOn);
}


- (void)unapply
{
	glPopAttrib();
}


- (NSString *)name
{
	return @"depth buffer state";
}


#pragma mark SGDepthBufferStateTag

+ (id)tagForTestEnabled:(SGStateValue)inTestState writeEnabled:(SGStateValue)inWriteState
{
	SGDepthBufferStateTag *tag = [self tag];
	[tag setDepthTestEnabled:inTestState];
	[tag setDepthWriteEnabled:inWriteState];
	return tag;
}


- (SGStateValue)depthTestEnabled
{
	return testEnable;
}


- (void)setDepthTestEnabled:(SGStateValue)inState
{
	if (inState <= kSGNoChange && inState != testEnable)
	{
		testEnable = inState;
		[self becomeDirty];
	}
}


- (SGStateValue)depthWriteEnabled
{
	return writeEnable;
}


- (void)setDepthWriteEnabled:(SGStateValue)inState
{
	if (inState <= kSGNoChange && inState != writeEnable)
	{
		writeEnable = inState;
		[self becomeDirty];
	}
}


#pragma mark SGDepthBufferStateTag (GraphVizGeneration)

- (NSString *) graphVizLabel
{
	return [NSString stringWithFormat:@"test: %@, write: %@", StateName(testEnable), StateName(writeEnable)];
}

@end
