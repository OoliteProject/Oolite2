/*
	OORenderMesh.m
	
	
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

#import "OORenderMesh.h"


@implementation OORenderMesh

- (id) initWithName:(NSString *)name vertexCount:(NSUInteger)vertexCount attributes:(NSDictionary *)attributes groups:(NSArray *)groups
{
	NSParameterAssert([attributes count] > 0 && [groups count] > 0);
	
	if ((self = [super init]))
	{
		BOOL OK = YES;
		
#ifndef NDEBUG
		_name = [name copy];
#endif
		
		_attributeCount = [attributes count];
		_groupCount = [groups count];
		
		_attributeArrays = OOAllocObjectArray(_attributeCount);
		_attributeSizes = malloc(_attributeCount * sizeof *_attributeSizes);
		_groups = OOAllocObjectArray(_groupCount);
		if (EXPECT_NOT(_attributeArrays == NULL || _attributeSizes == NULL || _groups == NULL))  OK = NO;
		else
		{
			NSMutableArray *attributeNames = [NSMutableArray arrayWithCapacity:_attributeCount];
			NSString *attributeName = nil;
			NSUInteger i = 0;
			
			foreachkey (attributeName, attributes)
			{
				NSParameterAssert([attributeName isKindOfClass:[NSString class]] && [[attributes objectForKey:attributeName] isKindOfClass:[OOFloatArray class]]);
				
				[attributeNames addObject:attributeName];
				_attributeArrays[i] = [[attributes objectForKey:attributeName] retain];
				_attributeSizes[i] = [_attributeArrays[i] count] / vertexCount;
				
				NSAssert(_attributeSizes[i] * vertexCount == [_attributeArrays[i] count], @"Attribute array size must be an integer multiple of vertex count.");
				
				i++;
			}
			if (EXPECT_NOT([attributeNames count] != _attributeCount))  OK = NO;
			else
			{
				_attributeNames = [[NSArray alloc] initWithArray:attributeNames];
				
				OOIndexArray *group = nil;
				i = 0;
				foreach (group, groups)
				{
					NSParameterAssert([group isKindOfClass:[OOIndexArray class]]);
					
					_groups[i++] = [group retain];
				}
			}

		}
		
		if (EXPECT_NOT(!OK))  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
#ifndef NDEBUG
	DESTROY(_name);
#endif
	
	if (_attributeArrays != NULL)
	{
		for (GLuint i = 0; i < _attributeCount; i++)
		{
			[_attributeArrays[i] release];
		}
		free(_attributeArrays);
		_attributeArrays = NULL;
	}
	OOFreeScanned(_attributeSizes);
	_attributeSizes = NULL;
	_attributeCount = 0;
	DESTROY(_attributeNames);
	
	if (_groups != NULL)
	{
		for (GLuint i = 0; i < _groupCount; i++)
		{
			[_groups[i] release];
		}
		OOFreeScanned(_groups);
		_groups = NULL;
	}
	_groupCount = 0;
	
	[super dealloc];
}


- (void) finalize
{
	OOFreeScanned(_attributeArrays);
	OOFreeScanned(_groups);
	
	[super finalize];
}


#ifndef NDEBUG
- (NSString *) descriptionComponents
{
	return $sprintf(@"\"%@\" - %u attributes, %u groups", _name, _attributeCount, _groupCount);
}


- (NSString *) shortDescriptionComponents
{
	return $sprintf(@"\"%@\"", _name);
}
#endif


- (NSUInteger) attributeIndexForKey:(NSString *)key
{
	return [_attributeNames indexOfObject:key];
}


- (void) renderWithMaterials:(NSArray *)materials
{
	// FIXME
}


- (NSDictionary *) attributeArrays
{
	NSString *keys[_attributeCount];
	[_attributeNames getObjects:keys];
	return [NSDictionary dictionaryWithObjects:_attributeArrays forKeys:(id *)keys count:_attributeCount];
}


- (NSArray *) indexArrays
{
	return [NSArray arrayWithObjects:_groups count:_groupCount];
}


- (NSUInteger) vertexCount
{
	return [_attributeArrays[0] count] / _attributeSizes[0];
}


#ifndef NDEBUG
- (NSString *) name
{
	return _name;
}
#endif

@end
