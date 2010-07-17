/*
	OOAbstractFaceGroup.m
	
	A face group represents a list of faces to be drawn with the same state.
	In rendering terms, it corresponds to an element array.
	
	
	Copyright © 2010 Jens Ayton.
	
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

#if !OOLITE_LEAN

#import "OOAbstractFaceGroup.h"
#import "OOAbstractFace.h"
#import "OOAbstractVertex.h"
#import "OOFloatArray.h"
#import "OOIndexArray.h"
#import "OOMaterialSpecification.h"


NSString * const kOOAbstractFaceGroupChangedNotification = @"org.oolite OOAbstractFaceGroup changed";
NSString * const kOOAbstractFaceGroupChangeIsAdditive = @"kOOAbstractFaceGroupChangeIsAdditive";


@interface OOAbstractFaceGroup (Private)

// Must be called whenever face group is mutated.
- (void) priv_becomeDirtyWithAdditions:(BOOL)additions;

- (id) priv_initWithCapacity:(NSUInteger)capacity;
- (void) priv_updateSchemaForFace:(OOAbstractFace *)face;

@end


@implementation OOAbstractFaceGroup

// Designated initializer.
- (id) priv_initWithCapacity:(NSUInteger)capacity
{
	if ((self = [super init]))
	{
		_faces = [[NSMutableArray alloc] initWithCapacity:capacity];
		if (_faces == nil)  DESTROY(self);
	}
	return self;
}


- (id) init
{
	return [self priv_initWithCapacity:0];
}


- (id) initWithAttributeArrays:(NSDictionary *)attributeArrays
				   vertexCount:(NSUInteger)vertexCount
					indexArray:(OOIndexArray *)indexArray
{
	NSUInteger faceCount = [indexArray count];
	if (EXPECT_NOT(faceCount % 3 != 0))
	{
		[self release];
		return nil;
	}
	faceCount /= 3;
	
	if ((self = [self priv_initWithCapacity:faceCount]))
	{
		NSUInteger aIter = 0, attrCount = [attributeArrays count];
		NSMutableDictionary *schema = [NSMutableDictionary dictionaryWithCapacity:attrCount];
		NSString *attrKey = nil;
		unsigned attrSizes[attrCount];
		NSString *attrKeys[attrCount];
		OOFloatArray *attrValues[attrCount];
		OOFloatArray *sourceArrays[attrCount];
		
		//	Determine schema.
		foreachkey (attrKey, attributeArrays)
		{
			attrKeys[aIter] = attrKey;
			OOFloatArray *attrArray = [attributeArrays oo_objectOfClass:[OOFloatArray class] forKey:attrKey];
			sourceArrays[aIter] = attrArray;
			NSUInteger attrCount = [attrArray count];
			if (EXPECT_NOT(attrKey == nil || attrCount % vertexCount != 0))
			{
				[self release];
				return nil;
			}
			
			attrSizes[aIter] = attrCount / vertexCount;
			[schema setObject:[NSNumber numberWithUnsignedInt:attrSizes[aIter]] forKey:attrKey];
			aIter++;
		}
		
		_vertexSchema = [[NSDictionary alloc] initWithDictionary:schema];
		_homogeneous = YES;
		
		
		// Set up faces.
		NSUInteger fIter, vIter;
		GLuint vIdx, elemIdx = 0;
		for (fIter = 0; fIter < faceCount; fIter++)
		{
			NSAutoreleasePool *pool = [NSAutoreleasePool new];
			
			OOAbstractVertex *verts[3];
			
			for (vIter = 0; vIter < 3; vIter++)
			{
				vIdx = [indexArray unsignedIntAtIndex:elemIdx++];
				
				for (aIter = 0; aIter < attrCount; aIter++)
				{
					NSRange range = { vIdx * attrSizes[aIter], attrSizes[aIter] };
					attrValues[aIter] = (OOFloatArray *)[sourceArrays[aIter] subarrayWithRange:range];
				}
				
				// FIXME: extend vertex to bypass dict?
				NSDictionary *dict = [NSDictionary dictionaryWithObjects:attrValues forKeys:attrKeys count:attrCount];
				verts[vIter] = [(OOAbstractVertex *)[OOAbstractVertex alloc] initWithAttributes:dict];
			}
			
			OOAbstractFace *face = [[OOAbstractFace alloc] initWithVertices:verts];
			[_faces addObject:face];
			
			[face release];
			[verts[0] release];
			[verts[1] release];
			[verts[2] release];
			
			[pool drain];
		}
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_faces);
	DESTROY(_vertexSchema);
	
	[super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
	OOAbstractFaceGroup *result = [[OOAbstractFaceGroup allocWithZone:zone] initWithCapacity:[self faceCount]];
	if (EXPECT_NOT(result == nil))  return nil;
	
	[result setName:[self name]];
	[result setMaterial:[self material]];
	[result->_faces addObjectsFromArray:_faces];
	result->_vertexSchema = [_vertexSchema retain];
	result->_homogeneous = _homogeneous;
	
	return result;
}


- (NSString *) name
{
	return _name;
}


- (void) setName:(NSString *)name
{
	[self priv_becomeDirtyWithAdditions:NO];
	
	[_name autorelease];
	_name = [name copy];
}


- (OOMaterialSpecification *) material
{
	return _material;
}


- (void) setMaterial:(OOMaterialSpecification *)material
{
	[self priv_becomeDirtyWithAdditions:NO];
	
	[_material autorelease];
	_material = [material retain];
}


- (NSUInteger) faceCount
{
	return [_faces count];
}


- (OOAbstractFace *) faceAtIndex:(NSUInteger)index
{
	return [_faces objectAtIndex:index];
}


- (void) addFace:(OOAbstractFace *)face
{
	[self priv_becomeDirtyWithAdditions:YES];
	
	[_faces addObject:face];
	[self priv_updateSchemaForFace:face];
}


- (void) insertFace:(OOAbstractFace *)face atIndex:(NSUInteger)index
{
	[self priv_becomeDirtyWithAdditions:YES];
	
	[_faces insertObject:face atIndex:index];
	[self priv_updateSchemaForFace:face];
}


- (void) removeLastFace
{
	[self priv_becomeDirtyWithAdditions:NO];
	
	if (!_homogeneous)  DESTROY(_vertexSchema);
	[_faces removeLastObject];
}


- (void) removeFaceAtIndex:(NSUInteger)index
{
	[self priv_becomeDirtyWithAdditions:NO];
	
	if (!_homogeneous)  DESTROY(_vertexSchema);
	[_faces removeObjectAtIndex:index];
}


- (void) replaceFaceAtIndex:(NSUInteger)index withFace:(OOAbstractFace *)face
{
	[self priv_becomeDirtyWithAdditions:YES];
	
	if (!_homogeneous)  DESTROY(_vertexSchema);
	[_faces replaceObjectAtIndex:index withObject:face];
	[self priv_updateSchemaForFace:face];
}


- (NSEnumerator *) faceEnumerator
{
	return [_faces objectEnumerator];
}


- (NSEnumerator *) objectEnumerator
{
	return [_faces objectEnumerator];
}


- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState *)state
								   objects:(id *)stackbuf
									 count:(NSUInteger)len
{
	return [_faces countByEnumeratingWithState:state objects:stackbuf count:len];
}


- (NSDictionary *) vertexSchema
{
	if (_vertexSchema == nil)
	{
		OOAbstractFace *face = nil;
		foreach (face, _faces)
		{
			[self priv_updateSchemaForFace:face];
		}
	}
	
	return [NSDictionary dictionaryWithDictionary:_vertexSchema];
}


- (BOOL) vertexSchemaIsHomogeneous
{
	return _homogeneous && _vertexSchema != nil;
}


- (void) priv_updateSchemaForFace:(OOAbstractFace *)face
{
	for (unsigned i = 0; i < 3; i++)
	{
		NSDictionary *schema = [[face vertexAtIndex:i] schema];
		if (_vertexSchema != nil)
		{
			if (![schema isEqualToDictionary:_vertexSchema])
			{
				_homogeneous = NO;
				NSDictionary *oldSchema = _vertexSchema;
				_vertexSchema = [[NSDictionary alloc] initWithDictionary:OOUnionOfSchemata(_vertexSchema, schema)];
				[oldSchema release];
			}
		}
		else
		{
			_homogeneous = YES;
			_vertexSchema = [[NSDictionary alloc] initWithDictionary:schema];
		}
	}
}


- (void) priv_becomeDirtyWithAdditions:(BOOL)additions
{
	NSDictionary *userInfo = nil;
	if (additions)  userInfo = [NSDictionary dictionaryWithObject:$true
														   forKey:kOOAbstractFaceGroupChangeIsAdditive];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kOOAbstractFaceGroupChangedNotification
														object:self
													  userInfo:userInfo];
}

@end


NSDictionary *OOUnionOfSchemata(NSDictionary *a, NSDictionary *b)
{
	if ([a isEqualToDictionary:b])  return a;
	
	NSMutableSet *mKeys = [NSMutableSet setWithArray:[a allKeys]];
	[mKeys addObjectsFromArray:[b allKeys]];
	NSSet *keys = [NSSet setWithSet:mKeys];
	
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
	NSString *key = nil;
	foreach (key, keys)
	{
		if (EXPECT_NOT(![key isKindOfClass:[NSString class]]))  return nil;
		
		NSUInteger aVal = [a oo_unsignedIntegerForKey:key];
		NSUInteger bVal = [b oo_unsignedIntegerForKey:key];
		
		[result setObject:[NSNumber numberWithUnsignedInteger:(aVal >= bVal) ? aVal : bVal] forKey:key];
	}
	
	return result;
}

#endif	// OOLITE_LEAN
