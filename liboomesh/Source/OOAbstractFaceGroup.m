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

#import "OOAbstractFaceGroup.h"
#import "OOAbstractFace.h"
#import "OOAbstractVertex.h"
#import "CollectionUtils.h"
#import "OOCollectionExtractors.h"


@interface OOAbstractFaceGroup (Private)

- (void) priv_updateSchemaForFace:(OOAbstractFace *)face;

@end


@implementation OOAbstractFaceGroup

- (id) init
{
	if ((self = [super init]))
	{
		_faces = [[NSMutableArray alloc] init];
		if (_faces == nil)  DESTROY(self);
	}
	return self;
}


- (void) dealloc
{
	DESTROY(_faces);
	DESTROY(_vertexSchema);
	
	[super dealloc];
}


- (NSString *) name
{
	return _name;
}


- (void) setName:(NSString *)name
{
	[_name autorelease];
	_name = [name copy];
}


- (OOMaterialSpecification *) material
{
	return _material;
}


- (void) setMaterial:(OOMaterialSpecification *)material
{
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
	[_faces addObject:face];
	[self priv_updateSchemaForFace:face];
}


- (void) insertFace:(OOAbstractFace *)face atIndex:(NSUInteger)index
{
	[_faces insertObject:face atIndex:index];
	[self priv_updateSchemaForFace:face];
}


- (void) removeLastFace
{
	if (!_homogeneous)  DESTROY(_vertexSchema);
	[_faces removeLastObject];
}


- (void) removeFaceAtIndex:(NSUInteger)index
{
	if (!_homogeneous)  DESTROY(_vertexSchema);
	[_faces removeObjectAtIndex:index];
}


- (void) replaceFaceAtIndex:(NSUInteger)index withFace:(OOAbstractFace *)face
{
	if (!_homogeneous)  DESTROY(_vertexSchema);
	[_faces replaceObjectAtIndex:index withObject:face];
	[self priv_updateSchemaForFace:face];
}


- (NSEnumerator *) faceEnumerator
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


- (void) homogenizeSchema
{
	// FIXME
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
