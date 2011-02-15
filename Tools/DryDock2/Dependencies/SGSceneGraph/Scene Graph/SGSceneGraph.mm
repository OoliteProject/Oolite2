/*
	SGSceneGraph.mm
	
	
	Copyright © 2008 Jens Ayton
	
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

#import "SGSceneGraph.h"
#import "SGSceneNode.h"
#import "CollectionUtils.h"


NSString * const kSceneGraphStateKey = @"SGSceneGraph";
NSString *kSGSceneGraphModifiedNotification = @"se.ayton.jens SGSceneGraph modified";


@implementation SGSceneGraph

@synthesize context = _context;


- (id) initWithContext:(NSOpenGLContext *)context
{
	if (context == nil)
	{
		context = [NSOpenGLContext currentContext];
		if (context == nil)
		{
			[self release];
			return nil;
		}
	}
	
	self = [super init];
	if (self != nil)
	{
		_context = [context retain];
	}
	
	return self;
}


- (id) initWithCurrentContext
{
	return [self initWithContext:nil];
}


- (id) init
{
	return [self initWithCurrentContext];
}


- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:nil name:nil object:self];
	
	[_context release];
	[_root release];
#if SCENGRAPH_LIGHTING
	[_lightManager release];
#endif
	
	[super dealloc];
}


- (SGSceneNode *) rootNode
{
	return _root;
}


- (void) setRootNode:(SGSceneNode *)rootNode
{
	if (_root != rootNode)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:kSGSceneNodeModifiedNotification
													  object:_root];
		
		[_root release];
		_root = [rootNode retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rootNodeChanged:)
													 name:kSGSceneNodeModifiedNotification
												   object:_root];
	}
}


- (void) rootNodeChanged:(NSNotificationCenter *)n
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kSGSceneGraphModifiedNotification object:self];
}


#if SCENGRAPH_LIGHTING
- (SGLightManager *) lightManager
{
	if (_lightManager == nil)
	{
		_lightManager = [[SGLightManager alloc] initWithContext:self.context];
	}
	return _lightManager;
}
#endif

- (void) render
{
	NSOpenGLContext *saved = [NSOpenGLContext currentContext];
	if (saved != _context)  [_context makeCurrentContext];
	
	NSAutoreleasePool *releasePool = nil;
	@try
	{
		releasePool = [[NSAutoreleasePool alloc] init];
		
#if SCENGRAPH_LIGHTING
		if (_lightManager != nil)
		{
			glMatrixMode(GL_MODELVIEW);
			glPushMatrix();
			glLoadIdentity();
			[_lightManager setUpLights];
			glPopMatrix();
		}
#endif
		
		[_root renderWithState:$dict({kSceneGraphStateKey, self})];
	}
	@catch (id exception)
	{
		// Hoist exception out of our autorelease pool
		[exception retain];
		[releasePool release];
		releasePool = nil;
		[exception autorelease];
		@throw (exception);
	}
	@finally
	{
		[releasePool drain];
		if (saved != _context)  [saved makeCurrentContext];
	}
}

@end


@implementation NSValue (SGSceneGraph)

+ (id) sg_valueWithVector2:(SGVector3)vector
{
	return [self valueWithBytes:&vector objCType:@encode(SGScalar[2])];
}


+ (id) sg_valueWithVector3:(SGVector3)vector
{
	return [self valueWithBytes:&vector objCType:@encode(SGScalar[3])];
}


+ (id) sg_valueWithMatrix4x4:(SGMatrix4x4)matrix
{
	return [self valueWithBytes:&matrix objCType:@encode(SGScalar[16])];
}

- (SGVector2) sg_vector2Value
{
	NSAssert(strcmp([self objCType], @encode(SGScalar[2])) == 0, @"Boxed type mismatch.");
	
	SGVector2 result;
	[self getValue:&result];
	return result;
}


- (SGVector3) sg_vector3Value
{
	NSAssert(strcmp([self objCType], @encode(SGScalar[3])) == 0, @"Boxed type mismatch.");
	
	SGVector3 result;
	[self getValue:&result];
	return result;
}


- (SGMatrix4x4) sg_matrix4x4Value
{
	NSAssert(strcmp([self objCType], @encode(SGScalar[16])) == 0, @"Boxed type mismatch.");
	
	SGMatrix4x4 result;
	[self getValue:&result];
	return result;
}

@end
