/*
	OOMaterialSpecification.m
	
	
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

#import "OOMaterialSpecification.h"
#import "OOTextureSpecification.h"
#import "CollectionUtils.h"


@implementation OOMaterialSpecification

- (id) initWithMaterialKey:(NSString *)materialKey
{
	if (materialKey == nil)
	{
		DESTROY(self);
		return nil;
	}
	
	if ((self = [super init]))
	{
		_materialKey = [materialKey copy];
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_materialKey);
	
	[super dealloc];
}


- (NSString *) materialKey
{
	return _materialKey;
}


- (OOTextureSpecification *) diffuseMap
{
	return _diffuseMap;
}


- (void) setDiffuseMap:(OOTextureSpecification *)texture
{
	[_diffuseMap autorelease];
	_diffuseMap = [texture retain];
}


- (void) setDiffuseMapName:(NSString *)name
{
	[self setDiffuseMap:[OOTextureSpecification textureSpecWithName:(NSString *)name]];
}


- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	id diffuseSpec = [_diffuseMap ja_propertyListRepresentation];
	if (diffuseSpec != nil)  [result setObject:diffuseSpec forKey:@"diffuseMap"];
	
#if 0
	// Test data
	[result setObject:$int(42) forKey:@"test-int"];
	[result setObject:$float(42.17) forKey:@"test-float"];
	
	[result setObject:$dict(
							@"empty-.array", [NSArray array],
							@"short_array", $array(@"", @"\""),
							@"longer array", $array(@"a", @"b", @" c ", @"d" , @"e")
						)
			   forKey:@"test-arrays"];
	
	[result setObject:$dict(@"a", @"A", @"b", @"slightly longer string") forKey:@"simple-dict"];
	[result setObject:$dict(@"a", @"A", @"b", @"B", @"c", @"C", @"d", @"D") forKey:@"non-simple-dict"];
	[result setObject:
	 $dict(@"nested",
		   $dict(@"nested",
				 $dict(@"nested", [NSDictionary dictionary]),
				 @"array", $array($int(1), @"string")
			)
	) forKey:@"nested-dict"];
	[result setObject:$array(@"This would be a simple array if it weren't for the fact that this long, rambling string is really rather long and rambling.") forKey:@"non-simple-array"];
#endif
	
	return  result;
}

@end
