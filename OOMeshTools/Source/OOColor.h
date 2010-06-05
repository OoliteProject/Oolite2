/*

OOColor.h

Replacement for NSColor (to avoid AppKit dependencies). Only handles RGBA
colours without colour space correction.

Oolite
Copyright (C) 2004-2010 Giles C Williams and contributors

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

#import <OOBase/OOBase.h>


typedef struct
{
	float			r, g, b, a;
} OORGBAComponents;


typedef struct
{
	float			h, s, b, a;
} OOHSBAComponents;


@interface OOColor: NSObject <NSCopying>
{
@private
	float				_rgba[4];
}

+ (OOColor *) colorWithHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha;	// Note: hue in 0..1
+ (OOColor *) colorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
+ (OOColor *) colorWithWhite:(float)white alpha:(float)alpha;
+ (OOColor *) colorWithRGBAComponents:(OORGBAComponents)components;
+ (OOColor *) colorWithHSBAComponents:(OOHSBAComponents)components;	// Note: hue in 0..360

// Flexible color creator; takes a selector name, a string with components, or an array.
+ (OOColor *) colorWithDescription:(id)description;

// Like +colorWithDescription:, but forces brightness of at least 0.5.
+ (OOColor *) brightColorWithDescription:(id)description;

/*	Like +colorWithDescription:, but multiplies saturation by provided factor.
	If the colour is an HSV dictionary, it may specify a saturation greater
	than 1.0 to override the scaling.
*/
+ (OOColor *) colorWithDescription:(id)description saturationFactor:(float)factor;

- (OOColor *) blendedColorWithFraction:(float)fraction ofColor:(OOColor *)color;

- (float) redComponent;
- (float) greenComponent;
- (float) blueComponent;
- (void) getRed:(float *)red green:(float *)green blue:(float *)blue alpha:(float *)alpha;

- (OORGBAComponents) rgbaComponents;

+ (OOColor *) whiteColor;
+ (OOColor *) blackColor;
+ (OOColor *) clearColor;

- (BOOL) isBlack;
- (BOOL) isWhite;

/*	IMPORTANT: for reasons of bugwards compatibility, these return hue values
	in the range [0, 360], but +colorWithHue:... expects values in the range [0, 1].
*/
- (float) hueComponent;
- (float) saturationComponent;
- (float) brightnessComponent;
- (void) getHue:(float *)hue saturation:(float *)saturation brightness:(float *)brightness alpha:(float *)alpha;

- (OOHSBAComponents) hsbaComponents;


// Get the alpha component.
- (float) alphaComponent;

// Returns the colour, premultiplied by its alpha channel, and with an alpha of 1.0. If the reciever's alpha is 1.0, it will return itself.
- (OOColor *) premultipliedColor;

// Multiply r, g and b components of a colour by specified factor, clamped to [0..1].
- (OOColor *) colorWithBrightnessFactor:(float)factor;

// r,g,b,a array in 0..1 range.
- (NSArray *) normalizedArray;

- (NSString *) rgbaDescription;
- (NSString *) hsbaDescription;

@end


NSString *OORGBAComponentsDescription(OORGBAComponents components);
NSString *OOHSBAComponentsDescription(OOHSBAComponents components);
