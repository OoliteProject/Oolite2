/*
	JAPropertyListSerialization.h
	
	
	Copyright © 2003 Jens Ayton.
	
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

#import "JAPropertyListRepresentation.h"

#ifndef NDEBUG
#include "OoliteBase.h"
#endif


@implementation NSObject (JAPropertyListRepresentationConveniences)

- (NSData *) ja_serializedPropertyListRepresentationWithContext:(NSDictionary *)context
{
	id						plist;
	NSData					*result = nil;
	
	if (![self respondsToSelector:@selector(ja_propertyListRepresentationWithContext:)])
	{
		#ifndef NDEBUG
			OOLog(@"propertyListRepresentation.badType", @"%s: called for object of class %@, which does not implement -[%s].", __PRETTY_FUNCTION__, [self class], "ja_propertyListRepresentationWithContext:");
		#endif
		return nil;
	}
	
	plist = [(id <JAPropertyListRepresentation>)self ja_propertyListRepresentationWithContext:context];
	if (plist != nil)
	{
		result = [NSPropertyListSerialization dataFromPropertyList:plist
															format:NSPropertyListXMLFormat_v1_0
												  errorDescription:NULL];
	}
	
	return result;
}


- (NSData *) ja_serializedPropertyListRepresentation
{
	return [self ja_serializedPropertyListRepresentationWithContext:nil];
}


- (id) ja_propertyListRepresentation
{
	if (![self respondsToSelector:@selector(ja_propertyListRepresentationWithContext:)])
	{
		#ifndef NDEBUG
			OOLog(@"propertyListRepresentation.badType", @"%s: called for object of class %@, which does not implement -[%s].", __PRETTY_FUNCTION__, [self class], "ja_propertyListRepresentationWithContext:");
		#endif
		return nil;
	}
	
	return [(id <JAPropertyListRepresentation>)self ja_propertyListRepresentationWithContext:nil];
}

@end


@implementation NSString (JAPropertyListRepresentation)

- (id)ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	return [[self copy] autorelease];
}

@end


@implementation NSNumber (JAPropertyListRepresentation)

- (id)ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	return [[self copy] autorelease];
}

@end


@implementation NSDate (JAPropertyListRepresentation)

- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	return [[self copy] autorelease];
}

@end


@implementation NSData (JAPropertyListRepresentation)

- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	return [[self copy] autorelease];
}

@end


@implementation NSArray (JAPropertyListRepresentation)

- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	NSMutableArray		*result;
	NSUInteger			index, count;
	id					object, plist;
	
	result = [self mutableCopy];
	if (result != nil)
	{
		count = [self count];
		
		for (index = 0; index < count; )
		{
			object = [result objectAtIndex:index];
			if ([object respondsToSelector:@selector(ja_propertyListRepresentationWithContext:)])
			{
				plist = [object ja_propertyListRepresentationWithContext:context];
				if (plist != nil)
				{
					[result replaceObjectAtIndex:index withObject:plist];
					++index;
					continue;
				}
			}
			
			// If we got here, the object could not be plistified
			--count;
			[result removeObjectAtIndex:index];
		}
	}
	
	return [result autorelease];
}

@end


@implementation NSDictionary (JAPropertyListRepresentation)

- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	NSArray				*keys;
	NSMutableDictionary	*result;
	NSUInteger			index, count;
	id					key, value, valuePlist;
	
	count = [self count];
	result = [NSMutableDictionary dictionaryWithCapacity:count];
	if (result != nil && count != 0)
	{
		keys = [self allKeys];
		
		for (index = 0; index != count; ++index)
		{
			key = [keys objectAtIndex:index];
			value = [self objectForKey:key];
			
			if ([key isKindOfClass:[NSString class]] && [value respondsToSelector:@selector(ja_propertyListRepresentationWithContext:)])
			{
				valuePlist = [value ja_propertyListRepresentationWithContext:context];
				if (valuePlist != nil)
				{
					[result setObject:valuePlist forKey:key];
				}
			}
		}
	}
	
	return result;
}

@end


#ifndef JAPROPERTYLISTREPRESENTATION_SIMPLE

@implementation NSSet (JAPropertyListRepresentation)

- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	return [[self allObjects] ja_propertyListRepresentation];
}

@end


@implementation NSURL (JAPropertyListRepresentation)

- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	return [[self absoluteString] ja_propertyListRepresentation];
}

@end


@implementation NSTimeZone (JAPropertyListRepresentation)

- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	return [[self name] ja_propertyListRepresentation];
}

@end


@implementation NSHTTPCookie (JAPropertyListRepresentation)

- (id)ja_propertyListRepresentationWithContext:(NSDictionary *)context
{
	return [self properties];
}

@end

#endif	// JAPROPERTYLISTREPRESENTATION_SIMPLE
