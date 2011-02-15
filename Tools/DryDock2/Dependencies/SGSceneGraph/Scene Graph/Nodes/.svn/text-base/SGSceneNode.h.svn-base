/*
	SGSceneNode.h
	
	Base class for nodes in a simple scene graph.
	
	
	Copyright © 2005-2008 Jens Ayton
	
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

@class SGSceneTag;


#ifndef SCENEGRAPH_TRACE_RENDER
#define SCENEGRAPH_TRACE_RENDER			0
#endif


@interface SGSceneNode: NSObject <NSFastEnumeration>
{
	SGMatrix4x4					_matrix;
	NSMutableArray				*_tags;
	SGSceneNode __weak			*_parent;
	SGSceneNode					*_firstChild;
	SGSceneNode					*_nextSibling;
	NSString					*_name;
	uint32_t					_isDirty: 1,
								_transformed: 1,
								_childCount: 30;
#ifndef NDEBUG
	unsigned long				_mutationGuard;
#endif
}

- (id) init;
+ (id) node;

@property (copy, nonatomic) NSString *name;
- (void)setLocalizedName:(NSString *)name;	// Looks name up in Localizable.strings

// Transformation matrix
@property (nonatomic) SGMatrix4x4 transform;
@property (nonatomic, copy) NSValue *boxedTransform;
- (void) setMatrixIdentity;

// Parent and children
@property (readonly, nonatomic, assign) SGSceneNode *parent;

@property (readonly, nonatomic) NSUInteger childCount;
@property (retain, readonly, nonatomic) id firstChild;
@property (retain, readonly, nonatomic) id nextSibling;

- (SGSceneNode *) childAtIndex:(uint32_t)inIndex;	// O(n)
- (NSEnumerator *) childEnumerator;
- (id) addChild:(SGSceneNode *)inNode;	// Returns self, for simple chaining: root = [[SGSceneNode node] addChild:[[SGDisplayListCacheNode node] addChild:[SGAxisNode node]]]
- (id) insertChild:(SGSceneNode *)inNode after:(SGSceneNode *)inExistingChild;	// Returns self
- (void) removeChild:(SGSceneNode *)inChild;

// Tags
@property (readonly, nonatomic) NSUInteger tagCount;

- (SGSceneTag *) tagAtIndex:(NSUInteger)inIndex;
- (NSEnumerator *) tagEnumerator;
- (void) addTag:(SGSceneTag *)inTag;
- (void) insertTag:(SGSceneTag *)inTag atIndex:(size_t)inIndex;
- (void) removeTagAtIndex:(uint32_t)inIndex;
- (void) removeTag:(SGSceneTag *)inTag;

- (void) becomeDirty;			// Dirtiness is passed up the tree
- (void) becomeDirtyDownwards;	// Dirtiness is passed down the tree
@property (readonly, nonatomic, getter = isDirty) BOOL dirty;

- (void) render;
- (void) renderWithState:(NSDictionary *)inState;

// Subclasses should generally override this, not the above.
- (void) performRenderWithState:(NSDictionary *)inState dirty:(BOOL)inDirty;

@property (readonly, nonatomic) NSString *recursiveDescription;
@property (readonly, nonatomic) NSString *itemDescription;	// Descriptive text to be inserted in description, building a string like: 'MyNodeClass "node name" itemDescription [tag descriptions]' for -logRecursiveDescription, and also inserted in normal -description.
@property (readonly, nonatomic) NSString *stringForRecursiveDescription;	// Allows full customisation

@end


extern NSString *kSGSceneNodeModifiedNotification;
