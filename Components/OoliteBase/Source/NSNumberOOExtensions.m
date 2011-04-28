/*

NSNumberOOExtensions.m


Copyright © 2009 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import "NSNumberOOExtensions.h"
#import "OOFunctionAttributes.h"

#define OO_USE_CFBOOLEAN		defined(__COREFOUNDATION_CFNUMBER__)

#if !OO_USE_CFBOOLEAN
@interface OOBoolean: NSNumber
@end

static OOBoolean *sOOBooleanTrue, *sOOBooleanFalse;
#endif



@implementation NSNumber (OOExtensions)

- (BOOL) oo_isFloatingPointNumber
{
#if OO_USE_CFBOOLEAN
	return (BOOL)CFNumberIsFloatType((CFNumberRef)self);
#else
	/*	This happily assumes the compiler will inline strcmp() where one
		argument is a single-character constant string. Verified under
		apple-gcc 4.0 (even with -O0).
	*/
	const char *type = [self objCType];
	return (strcmp(type, @encode(double)) == 0 || strcmp(type, @encode(float)) == 0);
#endif
}


- (BOOL) oo_isBoolean
{
#if OO_USE_CFBOOLEAN
	CFBooleanRef boolSelf = (CFBooleanRef)self;
	return boolSelf == kCFBooleanTrue || boolSelf == kCFBooleanFalse;
#else
	return NO;
#endif
}


+ (NSNumber *) oo_numberWithBool:(BOOL)boolValue
{
#if OO_USE_CFBOOLEAN
	return (NSNumber *)(boolValue ? kCFBooleanTrue : kCFBooleanFalse);
#else
	if (sOOBooleanTrue != nil)  return (boolValue ? sOOBooleanTrue : sOOBooleanFalse);
	return [OOBoolean numberWithBool:boolValue];
#endif
}

@end


#if !OO_USE_CFBOOLEAN
@implementation OOBoolean: NSNumber

+ (NSNumber *) numberWithBool:(BOOL)value
{
	if (sOOBooleanTrue == nil)
	{
		sOOBooleanTrue = [[OOBoolean alloc] init];
		sOOBooleanFalse = [[OOBoolean alloc] init];
	}
	return (value ? sOOBooleanTrue : sOOBooleanFalse);
}


- (NSUInteger) retainCount
{
	return UINT_MAX;
}


- (id) retain
{
	return self;
}


- (void) release
{
}


- (id) autorelease
{
	return self;
}


#define OOBOOLVALUE(b) ((b) != sOOBooleanFalse)


- (char) charValue
{
	return OOBOOLVALUE(self);
}


- (unsigned char) unsignedCharValue
{
	return OOBOOLVALUE(self);
}


- (short) shortValue
{
	return OOBOOLVALUE(self);
}


- (unsigned short) unsignedShortValue
{
	return OOBOOLVALUE(self);
}


- (int) intValue
{
	return OOBOOLVALUE(self);
}


- (unsigned int) unsignedIntValue
{
	return OOBOOLVALUE(self);
}


- (long) longValue
{
	return OOBOOLVALUE(self);
}


- (unsigned long) unsignedLongValue
{
	return OOBOOLVALUE(self);
}


- (long long) longLongValue
{
	return OOBOOLVALUE(self);
}


- (unsigned long long) unsignedLongLongValue
{
	return OOBOOLVALUE(self);
}


- (float) floatValue
{
	return OOBOOLVALUE(self);
}


- (double) doubleValue
{
	return OOBOOLVALUE(self);
}


- (BOOL) boolValue
{
	return OOBOOLVALUE(self);
}


- (NSInteger) integerValue
{
	return OOBOOLVALUE(self);
}


- (NSUInteger) unsignedIntegerValue
{
	return OOBOOLVALUE(self);
}


- (NSString *) stringValue
{
	return OOBOOLVALUE(self) ? @"1" : @"0";
}


- (NSComparisonResult) compare:(NSNumber *)otherNumber
{
	if (otherNumber == self)  return NSOrderedSame;
	
	unsigned long long value = OOBOOLVALUE(self);
	unsigned long long other = [otherNumber unsignedLongLongValue];
	if (value < other)  return NSOrderedAscending;
	if (value > other)  return NSOrderedDescending;
	return NSOrderedSame;
}


- (BOOL) isEqualToNumber:(NSNumber *)number
{
	return [number unsignedLongLongValue] == OOBOOLVALUE(self);
}


- (NSString *) descriptionWithLocale:(id)locale
{
	/*	Implements precise documented behaviour of -descriptionWithLocale:,
		although as far as I'm aware it will always return the same value as
		-stringValue. In particular, it does so when given Chinese, Indic or
		Arabic locales (under Mac OS X 10.6.6).
		-- Ahruman 2011-02-16
	*/
	return [[[NSString alloc] initWithFormat:@"%i" locale:locale, OOBOOLVALUE(self)] autorelease];
}


- (NSString *) description
{
	return [self stringValue];
}


- (BOOL) oo_isBoolean
{
	return YES;
}

@end
#endif
