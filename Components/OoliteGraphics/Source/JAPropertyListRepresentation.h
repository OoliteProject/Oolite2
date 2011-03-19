/*
	JAPropertyListSerialization.h
	
	JAPropertyListRepresentation (formal protocol)
	
	
	JAPropertyListRepresentation provides a common protocol for objects which
	can represent themselves as property list types, i.e. one of the following:
	NSString, NSNumber, NSDate, NSData, NSArray or NSDictionary. Most user
	classes should probably represent themselves as dictionaries.
	
	The methods can optionally take an NSDictionary parameter, context, which
	should be passed to any sub-objects.
	
	Implementations are provided for the property list types themselves and
	the following additional FoundationKit types: NSSet, NSURL, NSTimeZone,
	NSHTTPCookie. All of these implementations currently ignore the context
	parameter, but pass it on in the case of collections. Collections will
	include any values that support -ja_propertyListRepresentationWithContext:
	and silently ignore anything that doesn’t.
	
	The category PropertyListRepresentationConveniences on NSObject wraps
	JAPropertyListRepresentation calls with NSPropertyListSerialization calls
	and provides variants which don’t take a context parameter (equivalent to
	passing a context of nil).
	
	
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

#import <Foundation/Foundation.h>


@protocol JAPropertyListRepresentation <NSObject>

- (id) ja_propertyListRepresentationWithContext:(NSDictionary *)context;

@end


@interface NSObject (JAPropertyListRepresentationConveniences)

- (id) ja_propertyListRepresentation;

- (NSData *) ja_serializedPropertyListRepresentationWithContext:(NSDictionary *)context;
- (NSData *) ja_serializedPropertyListRepresentation;

@end


@interface NSString (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end


@interface NSNumber (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end


@interface NSDate (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end


@interface NSData (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end


//	Maintains order, but drops objects which don’t support -ja_propertyListRepresentationWithContext:.
@interface NSArray (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end


//	Keys must be strings. Drops objects which don’t support -ja_propertyListRepresentationWithContext:.
@interface NSDictionary (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end


#ifndef JAPROPERTYLISTREPRESENTATION_SIMPLE

//	Represented as array.
@interface NSSet (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end


//	Represented as string, always in absolute form.
@interface NSURL (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end


//	Represented as string.
@interface NSTimeZone (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end


//	Represented as dictionary.
@interface NSHTTPCookie (JAPropertyListRepresentation) <JAPropertyListRepresentation>
@end

#endif	// JAPROPERTYLISTREPRESENTATION_SIMPLE
