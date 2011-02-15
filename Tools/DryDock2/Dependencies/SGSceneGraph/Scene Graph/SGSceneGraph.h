/*
	SGSceneGraph.h
	
	Manages a tree of SGSceneNodes and (optionally) a lighting manager.
	
	
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


#import "SGSceneGraphBase.h"

#import "SGSceneNode.h"

#import "SGSceneTag.h"
#import "SGSimpleTag.h"
#import "SGConditionalTag.h"
#import "SGPointSizeTag.h"
#import "SGLineWidthTag.h"


#if SCENGRAPH_LIGHTING
#import "SGLight.h"
#import "SGLightManager.h"
#endif


@interface SGSceneGraph: NSObject
{
@private
	NSOpenGLContext				*_context;
	SGSceneNode					*_root;
#if SCENGRAPH_LIGHTING
	SGLightManager				*_lightManager;
#endif
}

- (id) initWithContext:(NSOpenGLContext *)context;
- (id) initWithCurrentContext;

@property (readonly) NSOpenGLContext *context;
@property (retain) SGSceneNode *rootNode;

#if SCENGRAPH_LIGHTING
@property (readonly) SGLightManager *lightManager;
#endif

- (void) render;

@end


// Key representing SGSceneGraph object in render state passed to nodes
extern NSString * const kSceneGraphStateKey;

// Notification for scene changes.
extern NSString *kSGSceneGraphModifiedNotification;


// Boxing utilities to wrap SG geometry types in objects.
@interface NSValue (SGSceneGraph)

+ (id) sg_valueWithVector2:(SGVector3)vector;
+ (id) sg_valueWithVector3:(SGVector3)vector;
+ (id) sg_valueWithMatrix4x4:(SGMatrix4x4)matrix;

- (SGVector2) sg_vector2Value;
- (SGVector3) sg_vector3Value;
- (SGMatrix4x4) sg_matrix4x4Value;

@end
