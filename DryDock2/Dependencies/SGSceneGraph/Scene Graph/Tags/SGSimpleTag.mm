/*
	SGSimpleTag.mm
	
	
	Copyright © 2005-2006 Jens Ayton
	
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

#import "SGSimpleTag.h"
#import "JAPropertyListAccessors.h"


@implementation SGSimpleTag

+ (id) tagWithKey:(NSString *)inKey value:(id)inValue
{
	return [[[self alloc] initWithKey:inKey value:inValue] autorelease];
}


+ (id) tagWithKey:(NSString *)inKey integerValue:(NSInteger)inValue
{
	return [[[self alloc] initWithKey:inKey integerValue:inValue] autorelease];
}


+ (id) tagWithKey:(NSString *)inKey doubleValue:(double)inValue
{
	return [[[self alloc] initWithKey:inKey doubleValue:inValue] autorelease];
}


+ (id) tagWithKey:(NSString *)inKey boolValue:(bool)inValue
{
	return [[[self alloc] initWithKey:inKey boolValue:inValue] autorelease];
}



- (id) initWithKey:(NSString *)inKey
{
	self = [super init];
	if (nil != self)
	{
		if (nil == inKey)
		{
			[self release];
			self = nil;
		}
		_key = [inKey retain];
	}
	return self;
}


- (id) initWithKey:(NSString *)inKey andName:(NSString *)inName
{
	self = [self initWithKey:inKey];
	if (nil != self)
	{
		_name = [inName retain];
	}
	return self;
}


- (id) initWithKey:(NSString *)inKey value:(id)inValue
{
	self = [self initWithKey:inKey];
	if (nil != self)
	{
		[self setValue:inValue];
	}
	return self;
}


- (id) initWithKey:(NSString *)inKey integerValue:(NSInteger)inValue
{
	return [self initWithKey:inKey value:[NSNumber numberWithInteger:inValue]];
}


- (id) initWithKey:(NSString *)inKey doubleValue:(double)inValue
{
	return [self initWithKey:inKey value:[NSNumber numberWithDouble:inValue]];
}


- (id) initWithKey:(NSString *)inKey boolValue:(bool)inValue
{
	return [self initWithKey:inKey value:[NSNumber numberWithBool:inValue]];
}


- (void) dealloc
{
	[_key release];
	[_name release];
	[_value release];
	
	[super dealloc];
}


- (NSString *) key
{
	return [[_key retain] autorelease];
}


- (id) value
{
	return [[_value retain] autorelease];
}


- (void) setValue:inValue
{
	if (inValue != _value)
	{
		[_value release];
		_value = [inValue retain];
		[self becomeDirty];
	}
}


- (NSInteger) integerValue
{
#if __LP64__
	return JALongLongFromObject(self.value, 0);
#else
	return JAIntFromObject(self.value, 0);
#endif
}


- (void)setIntegerValue:(NSInteger)inValue
{
	[self setValue:[NSNumber numberWithInteger:inValue]];
}


- (double) doubleValue
{
	return JADoubleFromObject(self.value, 0.0);
}


- (void) setDoubleValue:(double)inValue
{
	[self setValue:[NSNumber numberWithDouble:inValue]];
}


- (BOOL) boolValue
{
	return JABooleanFromObject(self.value, NO);
}


- (void) setBoolValue:(BOOL)inValue
{
	[self setValue:[NSNumber numberWithBool:inValue]];
}


- (void) apply:(NSMutableDictionary *)ioState
{
	if (nil != _value) [ioState setObject:_value forKey:_key];
}


- (NSString *) name
{
	if (nil == _name)  _name = NSLocalizedString(self.key, NULL);
	return [[_name retain] autorelease];
}


- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@ %p>{%@ = %@}", [self className], self, self.key, self.value];
}

@end
