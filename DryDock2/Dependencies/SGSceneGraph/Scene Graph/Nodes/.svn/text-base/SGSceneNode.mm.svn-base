/*
	SGSceneNode.m
	
	
	Copyright © 2005-2007 Jens Ayton

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
#import "SGSceneTag.h"
#import "SGSimpleTag.h"

NSString *kSGSceneNodeModifiedNotification = @"se.ayton.jens SGSceneNode modified";


@interface SGSceneNode(SGPrivate)

- (void)setParent:(SGSceneNode *)inParent;
- (NSString *)recursiveDescriptionWithPrefix:(NSString *)inPrefix;

@end


@interface SGSceneTag(SGPrivate)

- (void)setOwner:(SGSceneNode *)inOwner;
- (SGSceneNode *)owner;

@end


@interface SGSceneNodeEnumerator: NSEnumerator
{
	SGSceneNode				*next;
}

- (id)initWithFirstNode:(SGSceneNode *)inNode;

@end


@implementation SGSceneNode

+ (id)node
{
	return [[[self alloc] init] autorelease];
}


- (id)init
{
	self = [super init];
	if (nil != self)
	{
		_isDirty = YES;
		[self setLocalizedName:@"unnamed"];
	}
	return self;
}


- (void)dealloc
{
	NSEnumerator			*tagEnum;
	SGSceneTag				*tag;
	
	if (self.parent != nil)
	{
		[self retain];
		[_parent removeChild:self];
		return;
	}
	while (self.firstChild != nil)
	{
		[self.firstChild setParent:nil];
	}
	for (tagEnum = [self tagEnumerator]; (tag = [tagEnum nextObject]); )
	{
		tag.owner = nil;
	}
	[_tags release];
	[_name release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:nil name:nil object:self];
	
	[super dealloc];
}


- (id)addChild:(SGSceneNode *)inNode
{
	SGSceneNode				*child;
	
#ifndef NDEBUG
	++_mutationGuard;
#endif
	
	if (nil == inNode) return self;
	if (inNode->_parent == self)
	{
		NSLog(@"%s: child already exists.", __FUNCTION__);
	}
	else if (inNode == self)
	{
		[NSException raise:NSGenericException format:@"Can't make SGSceneNode a child of itself."];
	}
	else
	{
		if (_firstChild == nil)
		{
			_firstChild = [inNode retain];
		}
		else
		{
			child = _firstChild;
			while (child->_nextSibling) child = child->_nextSibling;
			
			child->_nextSibling = [inNode retain];
		}
		[inNode setParent:self];
		inNode->_nextSibling = nil;
		++_childCount;
	}
	return self;
}


- (id)insertChild:(SGSceneNode *)inNode after:(SGSceneNode *)inExistingChild
{
	SGSceneNode				*child;
	
#ifndef NDEBUG
	++_mutationGuard;
#endif
	
	if (nil == inNode) return self;
	if (inNode->_parent == self)
	{
		NSLog(@"%s: child already exists.", __FUNCTION__);
	}
	else if (inNode == self)
	{
		[NSException raise:NSGenericException format:@"Can't make SGSceneNode a child of itself."];
	}
	else
	{
		if (nil != _firstChild)
		{
			child = _firstChild;
			while (child)
			{
				if (child == inExistingChild)
				{
					[inNode retain];
					[inNode setParent:self];
					inNode->_nextSibling = child->_nextSibling;
					child->_nextSibling = inNode;
					++_childCount;
					return self;
				}
				child = child->_nextSibling;
			}
		}
		
		NSLog(@"%s: reference child does not exist.", __FUNCTION__);
	}
	return self;
}


- (void)removeChild:(SGSceneNode *)inChild
{
	SGSceneNode				*child;
	
	if (inChild == nil)  return;
	
#ifndef NDEBUG
	++_mutationGuard;
#endif
	
	if (inChild->_parent != self)
	{
		NSLog(@"%s: no child of mine.", __FUNCTION__);
		return;
	}
	if (nil != _firstChild)
	{
		if (_firstChild == inChild)
		{
			_firstChild = inChild->_nextSibling;
			inChild->_nextSibling = NULL;
			inChild->_parent = NULL;
			[inChild autorelease];
			--_childCount;
			return;
		}
		else
		{
			child = _firstChild;
			while (child)
			{
				if (child->_nextSibling == inChild)
				{
					child->_nextSibling = inChild->_nextSibling;
					inChild->_nextSibling = NULL;
					inChild->_parent = NULL;
					[inChild autorelease];
					--_childCount;
					return;
				}
				child = child->_nextSibling;
			}
		}
	}
	
	NSLog(@"%s: internal inconsistency: input node thinks it's a child, but it isn't in child list. Setting node's parent to nil.", __FUNCTION__);
	inChild->_parent = nil;
}


- (NSUInteger) childCount
{
	return _childCount;
}


- (SGSceneNode *)childAtIndex:(uint32_t)inIndex
{
	SGSceneNode				*child;
	
	child = _firstChild;
	while  (inIndex--)  child = [child nextSibling];
	return [[child retain] autorelease];
}


- (void)setParent:(SGSceneNode *)inParent
{
#ifndef NDEBUG
	++_mutationGuard;
#endif
	
	if (inParent == _parent) return;
	
	[_parent removeChild:self];
	self->_parent = inParent;
}


- (id)firstChild
{
	return [[_firstChild retain] autorelease];
}


- (id)nextSibling
{
	return [[_nextSibling retain] autorelease];
}


- (NSEnumerator *)childEnumerator
{
	return [[[SGSceneNodeEnumerator alloc] initWithFirstNode:_firstChild] autorelease];
}


- (SGSceneNode *)parent
{
	return [[_parent retain] autorelease];
}


- (SGMatrix4x4) transform
{
	return _matrix;
}


- (void) setTransform:(SGMatrix4x4)inMatrix
{
	_matrix = inMatrix;
	_transformed = YES;
	[self becomeDirty];
}


- (void)setMatrixIdentity
{
	_matrix.SetIdentity();
	_transformed = NO;
}


- (NSValue *) boxedTransform
{
	return [NSValue sg_valueWithMatrix4x4:_matrix];
}


- (void) setBoxedTransform:(NSValue *)value
{
	self.transform = [value sg_matrix4x4Value];
}


+ (NSSet *) keyPathsForValuesAffectingBoxedTransform
{
	return [NSSet setWithObject:@"transform"];
}


- (NSUInteger) tagCount
{
	return _tags.count;
}


- (NSEnumerator *) tagEnumerator
{
	return [_tags objectEnumerator];
}


- (SGSceneTag *)tagAtIndex:(NSUInteger)inIndex
{
	return [_tags objectAtIndex:inIndex];
}


- (void)addTag:(SGSceneTag *)inTag
{
	if (self == [inTag owner]) return;
	if (nil == _tags)  _tags = [[NSMutableArray alloc] init];
	[_tags addObject:inTag];
	[inTag setOwner:self];
	[self becomeDirty];
	[self becomeDirtyDownwards];
}


- (void)insertTag:(SGSceneTag *)inTag atIndex:(size_t)inIndex
{
	if (self == [inTag owner]) return;
	if (nil == _tags)  _tags = [[NSMutableArray alloc] init];
	[_tags insertObject:inTag atIndex:inIndex];
	[inTag setOwner:self];
	[self becomeDirty];
	[self becomeDirtyDownwards];
}


- (void)removeTagAtIndex:(uint32_t)inIndex
{
	[[_tags objectAtIndex:inIndex] setOwner:nil];
	[_tags removeObjectAtIndex:inIndex];
	[self becomeDirty];
	[self becomeDirtyDownwards];
}


- (void)removeTag:(SGSceneTag *)inTag
{
	NSUInteger			index;
	if (self != [inTag owner]) return;
	index = [_tags indexOfObject:inTag];
	#ifndef NDEBUG
		if (NSNotFound == index) [NSException raise:NSInternalInconsistencyException format:@"%s: tag specifies self as owner, but is not in tag list.", __FUNCTION__];
	#endif
	[self removeTagAtIndex:index];
}


@synthesize name = _name;


- (void)setLocalizedName:(NSString *)inName
{
	[self setName:NSLocalizedString(inName, NULL)];
}


- (void)becomeDirty
{
	if (!_isDirty)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kSGSceneNodeModifiedNotification object:self];
	
		_isDirty = 1;
	}
	[_parent becomeDirty];
}


- (void)becomeDirtyDownwards
{
	NSEnumerator			*childEnumerator;
	SGSceneNode				*child;
	
	if (!_isDirty)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kSGSceneNodeModifiedNotification object:self];
	
		_isDirty = 1;
	}
	
	for (childEnumerator = [self childEnumerator]; (child = [childEnumerator nextObject]); )
	{
		[child becomeDirtyDownwards];
	}
}


- (BOOL)isDirty
{
	return _isDirty;
}


- (void)render
{
	[self renderWithState:nil];
}


- (void)renderWithState:(NSDictionary *)inState
{
	NSMutableDictionary		*state;
	NSEnumerator			*childEnum;
	SGSceneTag				*tag;
	SGSceneNode				*child;
	BOOL					wasTransformed = _transformed;
	
	// Apply transformation if necessary
	if (wasTransformed)
	{
		glPushMatrix();
		_matrix.glMult();
	}
	
	if (nil != _tags)
	{
		@try
		{
			// Apply tags
			if (nil == inState) state = [[NSMutableDictionary alloc] init];
			else state = [inState mutableCopy];
			
			for (tag in _tags)
			{
				[tag apply:state];
			}
		}
		@catch (id whatever)
		{
			NSLog(@"Exception applying tags for %@.", self);
			@throw (whatever);
		}
	}
	else
	{
		state = [inState retain];
	}
	
	// Render
	@try
	{
		tag = [state objectForKey:@"visible"];
		if (nil == tag || [(SGSimpleTag *)tag boolValue])
		{
			[self performRenderWithState:state dirty:_isDirty];
		}
	}
	@catch (id whatever)
	{
		NSLog(@"Exception %@ performing self-render of %@.", whatever, self);
	}
	_isDirty = NO;
	
	// Render children
	for (childEnum = [self childEnumerator]; (child = [childEnum nextObject]); )
	{
		[child renderWithState:state];
	}
	
	[state release];
	// Un-apply tags
	for (tag in _tags)
	{
		[tag unapply];
	}
	
	#if SCENEGRAPH_TRACE_RENDER
		LogOutdent();
	#endif
	
	// Revert transformation
	if (wasTransformed) glPopMatrix();
}


- (void)performRenderWithState:(NSDictionary *)inState dirty:(BOOL)inDirty
{
	// Do nothing, this is an abstract node
}


- (NSString*)description
{
	NSMutableString			*desc;
	id						item;
	BOOL					haveItems = NO;
	
	desc = [NSMutableString stringWithFormat:@"<%@ %p>", [self className], self];
	item = [self name];
	if (nil != item)
	{
		[desc appendFormat:@"%@name=\"%@\"", haveItems ? @", " : @"{", item];
		haveItems = YES;
	}
	item = [self itemDescription];
	if (nil != item)
	{
		[desc appendFormat:@"%@%@", haveItems ? @", " : @"{", item];
		haveItems = YES;
	}
	item = _tags;
	if (nil != item)
	{
		[desc appendFormat:@"%@%@", haveItems ? @", " : @"{", item];
		haveItems = YES;
	}
	if (haveItems)
	{
		[desc appendString:@"}"];
	}
	
	return desc;
}

- (NSString *)recursiveDescription
{
	return [self recursiveDescriptionWithPrefix:@""];
}


- (NSString *)recursiveDescriptionWithPrefix:(NSString *)inPrefix
{
	NSMutableString			*result;
	NSString				*prefix;
	NSEnumerator			*nodeEnum;
	SGSceneNode				*node;
	
	result = [NSMutableString stringWithFormat:@"%@%@", inPrefix, [self stringForRecursiveDescription]];
	if (0 != self.childCount)
	{
		prefix = [inPrefix stringByAppendingString:@"  "];
		for (nodeEnum = [self childEnumerator]; (node = [nodeEnum nextObject]); )
		{
			[result appendFormat:@"\n%@", [node recursiveDescriptionWithPrefix:prefix]];
		}
	}
	
	return result;
}


- (NSString *)itemDescription
{
	return nil;
}


- (NSString *)stringForRecursiveDescription
{
	NSMutableString			*result;
	NSString				*string;
	unsigned				i, count;
	
	result = [NSMutableString stringWithFormat:@"%@", [self className]];
	
	string = [self name];
	if (nil != string) [result appendFormat:@" \"%@\"", string];
	
	string = [self itemDescription];
	if (nil != string) [result appendFormat:@" %@", string];
	
	count = [self tagCount];
	for (i = 0; i != count; ++i)
	{
		[result appendFormat:@"%@%@", i ? @", " : @"[", [self tagAtIndex:i]];
	}
	if (0 != count) [result appendString:@"]"]; 
	
	return result;
}


- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state
								   objects:(id *)stackbuf
									 count:(NSUInteger)len
{
	SGSceneNode			*next = nil;
	NSUInteger			count = 0;
	
	// Self is used as a sentinel, since containing self is invalid.
	if (state->state == (unsigned long)self)  return 0;
	
	if (state->state == 0)
	{
		// First call, set up.
#ifndef NDEBUG
		state->mutationsPtr = &_mutationGuard;
#endif
		next = _firstChild;
	}
	else
	{
		// Repeat call, continue where we started.
		next = (SGSceneNode *)state->state;
	}
	
	// We're copying objects to the provided buffer
	state->itemsPtr = stackbuf;
	
	while (count < len && next != nil)
	{
		*stackbuf++ = next;
		next = next->_nextSibling;
		count++;
	}
	
	// Set up continuation context or end-of-list sentinel as appropriate.
	if (next == nil)  next = self;
	state->state = (unsigned long)next;
	
	return count;
}

@end


@implementation SGSceneNodeEnumerator

- (id)initWithFirstNode:(SGSceneNode *)inNode
{
	self = [super init];
	if (nil != self)
	{
		next = [inNode retain];
	}
	return self;
}


- (void)dealloc
{
	[next release];
	
	[super dealloc];
}


- (id)nextObject
{
	SGSceneNode				*result;
	
	result = next;
	next = [[next nextSibling] retain];
	
	return [result autorelease];
}

@end
