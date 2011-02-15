/*

OOColor.m

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

#import "OOColor.h"


@interface OOPermanentColor: OOColor
@end


static OOColor *sWhiteColor;
static OOColor *sBlackColor;
static OOColor *sClearColor;


@implementation OOColor

+ (void) initialize
{
	if (sWhiteColor == nil)
	{
		sWhiteColor = [[OOPermanentColor colorWithWhite:1.0f alpha:1.0f] retain];
		sBlackColor = [[OOPermanentColor colorWithWhite:0.0f alpha:1.0f] retain];
		sClearColor = [[OOPermanentColor colorWithWhite:0.0f alpha:0.0f] retain];
	}
}


// Set methods are internal, because OOColor is immutable (as seen from outside).
- (void) setRGBA:(float)r:(float)g:(float)b:(float)a
{
	_rgba[0] = r;
	_rgba[1] = g;
	_rgba[2] = b;
	_rgba[3] = a;
}


- (void) setHSBA:(float)h:(float)s:(float)b:(float)a
{
	_rgba[3] = a;
	if (s == 0.0f)
	{
		_rgba[0] = _rgba[1] = _rgba[2] = b;
		return;
	}
	float f, p, q, t;
	int i;
	h = fmodf(h, 360.0f);
	if (h < 0.0) h += 360.0f;
	h /= 60.0f;
	
	i = floor(h);
	f = h - i;
	p = b * (1.0f - s);
	q = b * (1.0f - (s * f));
	t = b * (1.0f - (s * (1.0f - f)));
	
	switch (i)
	{
		case 0:
			_rgba[0] = b;	_rgba[1] = t;	_rgba[2] = p;	break;
		case 1:
			_rgba[0] = q;	_rgba[1] = b;	_rgba[2] = p;	break;
		case 2:
			_rgba[0] = p;	_rgba[1] = b;	_rgba[2] = t;	break;
		case 3:
			_rgba[0] = p;	_rgba[1] = q;	_rgba[2] = b;	break;
		case 4:
			_rgba[0] = t;	_rgba[1] = p;	_rgba[2] = b;	break;
		case 5:
			_rgba[0] = b;	_rgba[1] = p;	_rgba[2] = q;	break;
	}
}


- (id)copyWithZone:(NSZone *)zone
{
	// Copy is implemented as retain since OOColor is immutable.
	return [self retain];
}


+ (OOColor *)colorWithHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha
{
	OOColor* result = [[OOColor alloc] init];
	[result setHSBA: 360.0 * hue : saturation : brightness : alpha];
	return [result autorelease];
}


+ (OOColor *)colorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
	OOColor* result = [[OOColor alloc] init];
	[result setRGBA:red:green:blue:alpha];
	return [result autorelease];
}


+ (OOColor *)colorWithWhite:(float)white alpha:(float)alpha
{
	return [OOColor colorWithRed:white green:white blue:white alpha:alpha];
}


+ (OOColor *)colorWithRGBAComponents:(OORGBAComponents)components
{
	return [self colorWithRed:components.r
						green:components.g
						 blue:components.b
						alpha:components.a];
}


+ (OOColor *)colorWithHSBAComponents:(OOHSBAComponents)components
{
	return [self colorWithHue:components.h * (1.0f / 360.0f)
				   saturation:components.s
				   brightness:components.b
						alpha:components.a];
}


+ (OOColor *)colorWithDescription:(id)description
{
	return [self colorWithDescription:description saturationFactor:1.0f];
}


+ (OOColor *) colorFromArray:(NSArray *)array
{
	NSUInteger count = [array count];
	if (!(count == 3 || count == 4))  return nil;
	
	float r = [array oo_floatAtIndex:0];
	float g = [array oo_floatAtIndex:1];
	float b = [array oo_floatAtIndex:2];
	float a = (count > 3) ? [array oo_floatAtIndex:3] : 1.0f;
	
	return [self colorWithRed:r green:g blue:b alpha:a];
}


+ (OOColor *)colorWithDescription:(id)description saturationFactor:(float)factor
{
	NSDictionary			*dict = nil;
	OOColor					*result = nil;
	
	if (description == nil) return nil;
	
	if ([description isKindOfClass:[OOColor class]])
	{
		result = [[description copy] autorelease];
	}
	else if ([description isKindOfClass:[NSString class]])
	{
		description = [description componentsSeparatedByString:@" "];
		result = [self colorFromArray:description];
	}
	else if ([description isKindOfClass:[NSArray class]])
	{
		result = [self colorFromArray:description];
	}
	else if ([description isKindOfClass:[NSDictionary class]])
	{
		dict = description;	// Workaround for gnu-gcc's more agressive "multiple methods named..." warnings.
		
		if ([dict objectForKey:@"hue"] != nil)
		{
			// Treat as HSB(A) dictionary
			float h = [dict oo_floatForKey:@"hue"];
			float s = [dict oo_floatForKey:@"saturation" defaultValue:1.0f];
			float b = [dict oo_floatForKey:@"brightness" defaultValue:-1.0f];
			if (b < 0.0f)  b = [dict oo_floatForKey:@"value" defaultValue:1.0f];
			float a = [dict oo_floatForKey:@"alpha" defaultValue:-1.0f];
			if (a < 0.0f)  a = [dict oo_floatForKey:@"opacity" defaultValue:1.0f];
			
			// Not "result =", because we handle the saturation scaling here to allow oversaturation.
			return [OOColor colorWithHue:h / 360.0f saturation:s * factor brightness:b alpha:a];
		}
		else
		{
			// Treat as RGB(A) dictionary
			float r = [dict oo_floatForKey:@"red"];
			float g = [dict oo_floatForKey:@"green"];
			float b = [dict oo_floatForKey:@"blue"];
			float a = [dict oo_floatForKey:@"alpha" defaultValue:-1.0f];
			if (a < 0.0f)  a = [dict oo_floatForKey:@"opacity" defaultValue:1.0f];
			
			result = [OOColor colorWithRed:r green:g blue:b alpha:a];
		}
	}
	
	if (factor != 1.0f && result != nil)
	{
		float h, s, b, a;
		[result getHue:&h saturation:&s brightness:&b alpha:&a];
		h *= 1.0 / 360.0f;	// See note in header.
		s *= factor;
		result = [self colorWithHue:h saturation:s brightness:b alpha:a];
	}
	
	return result;
}


+ (OOColor *)brightColorWithDescription:(id)description
{
	OOColor *color = [OOColor colorWithDescription:description];
	if (color == nil || 0.5f <= [color brightnessComponent])  return color;
	
	return [OOColor colorWithHue:[color hueComponent] / 360.0f saturation:[color saturationComponent] brightness:0.5f alpha:1.0f];
}


- (OOColor *)blendedColorWithFraction:(float)fraction ofColor:(OOColor *)color
{
	float	rgba1[4];
	[color getRed:&rgba1[0] green:&rgba1[1] blue:&rgba1[2] alpha:&rgba1[3]];
	OOColor *result = [[OOColor alloc] init];
	float prime = 1.0f - fraction;
	[result setRGBA: prime * _rgba[0] + fraction * rgba1[0] : prime * _rgba[1] + fraction * rgba1[1] : prime * _rgba[2] + fraction * rgba1[2] : prime * _rgba[3] + fraction * rgba1[3]];
	return [result autorelease];
}


// find a point on the sea->land scale
+ (OOColor *) planetTextureColor:(float) q:(OOColor *) seaColor:(OOColor *) paleSeaColor:(OOColor *) landColor:(OOColor *) paleLandColor
{
	float hi = 0.33;
	float oh = 1.0 / hi;
	float ih = 1.0 / (1.0 - hi);
	if (q <= 0.0)
		return seaColor;
	if (q > 1.0)
		return [OOColor whiteColor];
	if (q < 0.01)
		return [paleSeaColor blendedColorWithFraction: q * 100.0 ofColor: landColor];
	if (q > hi)
		return [paleLandColor blendedColorWithFraction: (q - hi) * ih ofColor: [OOColor whiteColor]];	// snow capped peaks
	return [paleLandColor blendedColorWithFraction: (hi - q) * oh ofColor: landColor];
}


// find a point on the sea->land scale given impress and bias
+ (OOColor *) planetTextureColor:(float) q:(float) impress:(float) bias :(OOColor *) seaColor:(OOColor *) paleSeaColor:(OOColor *) landColor:(OOColor *) paleLandColor
{
	float maxq = impress + bias;
	
	float hi = 0.66667 * maxq;
	float oh = 1.0 / hi;
	float ih = 1.0 / (1.0 - hi);
	
	if (q <= 0.0)
		return seaColor;
	if (q > 1.0)
		return [OOColor whiteColor];
	if (q < 0.01)
		return [paleSeaColor blendedColorWithFraction: q * 100.0 ofColor: landColor];
	if (q > hi)
		return [paleLandColor blendedColorWithFraction: (q - hi) * ih ofColor: [OOColor whiteColor]];	// snow capped peaks
	return [paleLandColor blendedColorWithFraction: (hi - q) * oh ofColor: landColor];
}


- (NSString *) descriptionComponents
{
	return [NSString stringWithFormat:@"%g, %g, %g, %g", _rgba[0], _rgba[1], _rgba[2], _rgba[3]];
}


// Get the red, green, or blue components.
- (float)redComponent
{
	return _rgba[0];
}


- (float)greenComponent
{
	return _rgba[1];
}


- (float)blueComponent
{
	return _rgba[2];
}


- (void)getRed:(float *)red green:(float *)green blue:(float *)blue alpha:(float *)alpha
{
	NSParameterAssert(red != NULL && green != NULL && blue != NULL && alpha != NULL);
	
	*red = _rgba[0];
	*green = _rgba[1];
	*blue = _rgba[2];
	*alpha = _rgba[3];
}


- (OORGBAComponents)rgbaComponents
{
	return (OORGBAComponents){ _rgba[0], _rgba[1], _rgba[2], _rgba[3] };
}


+ (OOColor *) whiteColor
{
	return sWhiteColor;
}


+ (OOColor *) blackColor
{
	return sBlackColor;
}


+ (OOColor *) clearColor
{
	return sClearColor;
}


- (BOOL)isBlack
{
	return _rgba[0] == 0.0f && _rgba[1] == 0.0f && _rgba[2] == 0.0f;
}


- (BOOL)isWhite
{
	return _rgba[0] == 1.0f && _rgba[1] == 1.0f && _rgba[2] == 1.0f && _rgba[3] == 1.0f;
}


// Get the components as hue, saturation, or brightness.
- (float)hueComponent
{
	float maxrgb = (_rgba[0] > _rgba[1])? ((_rgba[0] > _rgba[2])? _rgba[0]:_rgba[2]):((_rgba[1] > _rgba[2])? _rgba[1]:_rgba[2]);
	float minrgb = (_rgba[0] < _rgba[1])? ((_rgba[0] < _rgba[2])? _rgba[0]:_rgba[2]):((_rgba[1] < _rgba[2])? _rgba[1]:_rgba[2]);
	if (maxrgb == minrgb)
		return 0.0;
	float delta = maxrgb - minrgb;
	float hue = 0.0;
	if (_rgba[0] == maxrgb)
		hue = (_rgba[1] - _rgba[2]) / delta;
	else if (_rgba[1] == maxrgb)
		hue = 2.0 + (_rgba[2] - _rgba[0]) / delta;
	else if (_rgba[2] == maxrgb)
		hue = 4.0 + (_rgba[0] - _rgba[1]) / delta;
	hue *= 60.0;
	while (hue < 0.0) hue += 360.0;
	return hue;
}

- (float)saturationComponent
{
	float maxrgb = (_rgba[0] > _rgba[1])? ((_rgba[0] > _rgba[2])? _rgba[0]:_rgba[2]):((_rgba[1] > _rgba[2])? _rgba[1]:_rgba[2]);
	float minrgb = (_rgba[0] < _rgba[1])? ((_rgba[0] < _rgba[2])? _rgba[0]:_rgba[2]):((_rgba[1] < _rgba[2])? _rgba[1]:_rgba[2]);
	float brightness = 0.5 * (maxrgb + minrgb);
	if (maxrgb == minrgb)
		return 0.0;
	float delta = maxrgb - minrgb;
	return (brightness <= 0.5)? (delta / (maxrgb + minrgb)) : (delta / (2.0 - (maxrgb + minrgb)));
}

- (float)brightnessComponent
{
	float maxrgb = (_rgba[0] > _rgba[1])? ((_rgba[0] > _rgba[2])? _rgba[0]:_rgba[2]):((_rgba[1] > _rgba[2])? _rgba[1]:_rgba[2]);
	float minrgb = (_rgba[0] < _rgba[1])? ((_rgba[0] < _rgba[2])? _rgba[0]:_rgba[2]):((_rgba[1] < _rgba[2])? _rgba[1]:_rgba[2]);
	return 0.5 * (maxrgb + minrgb);
}

- (void)getHue:(float *)hue saturation:(float *)saturation brightness:(float *)brightness alpha:(float *)alpha
{
	*alpha = _rgba[3];
	
	int maxrgb = (_rgba[0] > _rgba[1])? ((_rgba[0] > _rgba[2])? 0:2):((_rgba[1] > _rgba[2])? 1:2);
	int minrgb = (_rgba[0] < _rgba[1])? ((_rgba[0] < _rgba[2])? 0:2):((_rgba[1] < _rgba[2])? 1:2);
	*brightness = 0.5 * (_rgba[maxrgb] + _rgba[minrgb]);
	if (_rgba[maxrgb] == _rgba[minrgb])
	{
		*saturation = 0.0;
		*hue = 0.0;
		return;
	}
	float delta = _rgba[maxrgb] - _rgba[minrgb];
	*saturation = (*brightness <= 0.5)? (delta / (_rgba[maxrgb] + _rgba[minrgb])) : (delta / (2.0 - (_rgba[maxrgb] + _rgba[minrgb])));

	if (maxrgb==0)
		*hue = (_rgba[1] - _rgba[2]) / delta;
	else if (maxrgb==1)
		*hue = 2.0 + (_rgba[2] - _rgba[0]) / delta;
	else if (maxrgb==2)
		*hue = 4.0 + (_rgba[0] - _rgba[1]) / delta;
	*hue *= 60.0;
	while (*hue < 0.0) *hue += 360.0;
}


- (OOHSBAComponents)hsbaComponents
{
	OOHSBAComponents c;
	[self getHue:&c.h
	  saturation:&c.s
	  brightness:&c.b
		   alpha:&c.a];
	return c;
}


// Get the alpha component.
- (float)alphaComponent
{
	return _rgba[3];
}


- (OOColor *)premultipliedColor
{
	if (_rgba[3] == 1.0f)  return [[self retain] autorelease];
	return [OOColor colorWithRed:_rgba[0] * _rgba[3]
						   green:_rgba[1] * _rgba[3]
							blue:_rgba[2] * _rgba[3]
						   alpha:1.0f];
}


- (OOColor *)colorWithBrightnessFactor:(float)factor
{
	return [OOColor colorWithRed:OOClamp_0_1_f(_rgba[0] * factor)
						   green:OOClamp_0_1_f(_rgba[1] * factor)
							blue:OOClamp_0_1_f(_rgba[2] * factor)
						   alpha:_rgba[3]];
}


- (NSArray *)normalizedArray
{
	float r, g, b, a;
	[self getRed:&r green:&g blue:&b alpha:&a];
	return [NSArray arrayWithObjects:
		[NSNumber numberWithDouble:r],
		[NSNumber numberWithDouble:g],
		[NSNumber numberWithDouble:b],
		[NSNumber numberWithDouble:a],
		nil];
}


- (NSString *)rgbaDescription
{
	return OORGBAComponentsDescription([self rgbaComponents]);
}


- (NSString *)hsbaDescription
{
	return OOHSBAComponentsDescription([self hsbaComponents]);
}


- (BOOL) isEqual:(id)other
{
	if (EXPECT_NOT(![other isKindOfClass:[OOColor class]]))  return NO;
	
	OOColor *otherColor = other;
	return memcmp(_rgba, otherColor->_rgba, sizeof _rgba) == 0;
}


- (NSUInteger) hash
{
	NSUInteger *data = (NSUInteger *)&_rgba[0];
	size_t i, count = sizeof _rgba / sizeof data;
	
	NSUInteger hash = 5381;
	for (i = 0; i < count; i++)
	{
		hash = (hash * 33) ^ data[i];
	}
	
	return hash;
}

@end


@implementation OOPermanentColor

- (void) release
{
}


- (id) autorelease
{
	return self;
}


- (NSUInteger) retainCount
{
	return INT_MAX;
}

@end


NSString *OORGBAComponentsDescription(OORGBAComponents components)
{
	return [NSString stringWithFormat:@"{%.3g, %.3g, %.3g, %.3g}", components.r, components.g, components.b, components.a];
}


NSString *OOHSBAComponentsDescription(OOHSBAComponents components)
{
	return [NSString stringWithFormat:@"{%i, %.3g, %.3g, %.3g}", (int)components.h, components.s, components.b, components.a];
}
