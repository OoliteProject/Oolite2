/*

NSScannerOOExtensions.m

Oolite
Copyright (C) 2004-2011 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import "NSScannerOOExtensions.h"
#import "OOFunctionAttributes.h"


@implementation NSScanner (OOExtensions)

- (BOOL) ooliteScanCharactersFromSet:(NSCharacterSet *)set intoString:(NSString **)value
{
	NSUInteger		currentLocation = [self scanLocation];
	NSRange			matchedRange = NSMakeRange( currentLocation, 0);
	NSString		*scanString = [self string];
	NSUInteger		scanLength = [scanString length];
	
	while ((currentLocation < scanLength)&&([set characterIsMember:[scanString characterAtIndex:currentLocation]]))
	{
		currentLocation++;
	}
	
	[self setScanLocation:currentLocation];
	
	matchedRange.length = currentLocation - matchedRange.location;
	
	if (!matchedRange.length)  return NO;
	
	if (value != NULL)
	{
		*value = [scanString substringWithRange:matchedRange];
	}
	
	return YES;
}


- (BOOL) ooliteScanUpToCharactersFromSet:(NSCharacterSet *)set intoString:(NSString **)value
{
	NSUInteger		currentLocation = [self scanLocation];
	NSRange			matchedRange = NSMakeRange( currentLocation, 0);
	NSString		*scanString = [self string];
	NSUInteger		scanLength = [scanString length];
	
	while ((currentLocation < scanLength)&&(![set characterIsMember:[scanString characterAtIndex:currentLocation]]))
	{
		currentLocation++;
	}
	
	[self setScanLocation:currentLocation];
	
	matchedRange.length = currentLocation - matchedRange.location;
	
	if (!matchedRange.length)  return NO;
	
	if (value != NULL)
	{
		*value = [scanString substringWithRange:matchedRange];
	}
	
	return YES;
}

@end


NSMutableArray *OOScanTokensFromString(NSString *values)
{
	NSMutableArray			*result = nil;
	NSScanner				*scanner = nil;
	NSString				*token = nil;
	static NSCharacterSet	*space_set = nil;
	
	// Note: Shark suggests we're getting a lot of early exits, but testing showed a pretty steady 2% early exit rate.
	if (EXPECT_NOT(values == nil))  return [NSArray array];
	if (EXPECT_NOT(space_set == nil)) space_set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
	
	result = [NSMutableArray array];
	scanner = [NSScanner scannerWithString:values];
	
	while (![scanner isAtEnd])
	{
		[scanner ooliteScanCharactersFromSet:space_set intoString:NULL];
		if ([scanner ooliteScanUpToCharactersFromSet:space_set intoString:&token])
		{
			[result addObject:token];
		}
	}
	
	return result;
}
