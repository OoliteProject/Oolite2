/*

OODebugUtilities.m


Oolite Debug OXP

Copyright (C) 2007 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
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

#import "OODebugUtilities.h"


@implementation OOColor (NSColorConversion)

- (NSColor *)asNSColor
{
	OOCGFloat r, g, b, a;
	[self getRed:&r green:&g blue:&b alpha:&a];
	return [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
}

@end

@implementation NSColor (OOColorConversion)

+ (NSColor *)colorWithOOColorDescription:(id)description
{
	return [[OOColor colorWithDescription:description] asNSColor];
}


- (id)initWithOOColorDescription:(id)description
{
	[self release];
	return [[NSColor colorWithOOColorDescription:description] retain];
}


- (OOColor *)asOOColor
{
	OOCGFloat r, g, b, a;
	[[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
	return [OOColor colorWithCalibratedRed:r green:g blue:b alpha:a];
}
	
@end


@implementation NSAttributedString (OODebugExtensions)

+ (id)stringWithString:(NSString *)string
{
	return [[[self alloc] initWithString:string] autorelease];
}


+ (id)stringWithString:(NSString *)string font:(NSFont *)font
{
	if (string == nil)  return nil;
	NSDictionary *attr = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	return [[[self alloc] initWithString:string attributes:attr] autorelease];
}

@end

@implementation NSMutableAttributedString (OODebugExtensions)

- (void)setString:(NSString *)string
{
	[self setAttributedString:[string asAttributedString]];
}

@end

@implementation NSString (OODebugExtensions)

- (NSAttributedString *)asAttributedString
{
	return [NSAttributedString stringWithString:self];
}


- (NSAttributedString *)asAttributedStringWithFont:(NSFont *)font
{
	return [NSAttributedString stringWithString:self font:font];
}

@end
