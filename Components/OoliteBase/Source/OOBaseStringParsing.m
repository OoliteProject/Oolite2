/*

OOBaseStringParsing.m


Oolite
Copyright © 2004-2010 Giles C Williams and contributors

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

#import "OOBaseStringParsing.h"
#import "OOLogging.h"


static NSString * const kOOLogStringVectorConversion			= @"strings.conversion.vector";
static NSString * const kOOLogStringQuaternionConversion		= @"strings.conversion.quaternion";
static NSString * const kOOLogStringVecAndQuatConversion		= @"strings.conversion.vectorAndQuaternion";
static NSString * const kOOLogStringRandomSeedConversion		= @"strings.conversion.randomSeed";


BOOL OOScanVectorFromString(NSString *xyzString, Vector *outVector)
{
	float					xyz[] = { 0.0f, 0.0f, 0.0f };
	int						i = 0;
	NSString				*error = nil;
	NSScanner				*scanner = nil;
	
	assert(outVector != NULL);
	if (xyzString == nil) return NO;
	
	if (!error) scanner = [NSScanner scannerWithString:xyzString];
	while (![scanner isAtEnd] && i < 3 && !error)
	{
		if (![scanner scanFloat:&xyz[i++]])  error = @"could not scan a float value.";
	}
	
	if (!error && i < 3)  error = @"found less than three float values.";
	
	if (!error)
	{
		*outVector = make_vector(xyz[0], xyz[1], xyz[2]);
		return YES;
	}
	else
	{
		OOLogERR(kOOLogStringVectorConversion, @"cannot make vector from '%@': %@", xyzString, error);
		return NO;
	}
}


BOOL OOScanQuaternionFromString(NSString *wxyzString, Quaternion *outQuaternion)
{
	float					wxyz[] = { 1.0f, 0.0f, 0.0f, 0.0f };
	int						i = 0;
	NSString				*error = nil;
	NSScanner				*scanner = nil;
	
	assert(outQuaternion != NULL);
	if (wxyzString == nil) return NO;
	
	if (!error) scanner = [NSScanner scannerWithString:wxyzString];
	while (![scanner isAtEnd] && i < 4 && !error)
	{
		if (![scanner scanFloat:&wxyz[i++]])  error = @"could not scan a float value.";
	}
	
	if (!error && i < 4)  error = @"found less than four float values.";
	
	if (!error)
	{
		outQuaternion->w = wxyz[0];
		outQuaternion->x = wxyz[1];
		outQuaternion->y = wxyz[2];
		outQuaternion->z = wxyz[3];
		quaternion_normalize(outQuaternion);
		return YES;
	}
	else
	{
		OOLogERR(kOOLogStringQuaternionConversion, @"cannot make quaternion from '%@': %@", wxyzString, error);
		return NO;
	}
}


BOOL OOScanVectorAndQuaternionFromString(NSString *xyzwxyzString, Vector *outVector, Quaternion *outQuaternion)
{
	float					xyzwxyz[] = { 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f };
	int						i = 0;
	NSString				*error = nil;
	NSScanner				*scanner = nil;
	
	assert(outVector != NULL && outQuaternion != NULL);
	if (xyzwxyzString == nil) return NO;
	
	if (!error) scanner = [NSScanner scannerWithString:xyzwxyzString];
	while (![scanner isAtEnd] && i < 7 && !error)
	{
		if (![scanner scanFloat:&xyzwxyz[i++]])  error = @"Could not scan a float value.";
	}
	
	if (!error && i < 7)  error = @"Found less than seven float values.";
	
	if (error)
	{
		OOLogERR(kOOLogStringQuaternionConversion, @"cannot make vector and quaternion from '%@': %@", xyzwxyzString, error);
		return NO;
	}
	
	outVector->x = xyzwxyz[0];
	outVector->y = xyzwxyz[1];
	outVector->z = xyzwxyz[2];
	outQuaternion->w = xyzwxyz[3];
	outQuaternion->x = xyzwxyz[4];
	outQuaternion->y = xyzwxyz[5];
	outQuaternion->z = xyzwxyz[6];
	
	return YES;
}


Vector OOVectorFromString(NSString *xyzString, Vector defaultValue)
{
	Vector result;
	if (!OOScanVectorFromString(xyzString, &result))  result = defaultValue;
	return result;
}


Quaternion OOQuaternionFromString(NSString *wxyzString, Quaternion defaultValue)
{
	Quaternion result;
	if (!OOScanQuaternionFromString(wxyzString, &result))  result = defaultValue;
	return result;
}


Random_Seed OORandomSeedFromString(NSString *abcdefString)
{
	Random_Seed				result;
	int						abcdef[] = { 0, 0, 0, 0, 0, 0};
	int						i = 0;
	NSString				*error = nil;
	NSScanner				*scanner = [NSScanner scannerWithString:abcdefString];
	
	while (![scanner isAtEnd] && i < 6 && !error)
	{
		if (![scanner scanInt:&abcdef[i++]])  error = @"could not scan a int value.";
	}
	
	if (!error && i < 6)  error = @"found less than six int values.";
	
	if (!error)
	{
		result.a = abcdef[0];
		result.b = abcdef[1];
		result.c = abcdef[2];
		result.d = abcdef[3];
		result.e = abcdef[4];
		result.f = abcdef[5];
	}
	else
	{
		OOLogERR(kOOLogStringRandomSeedConversion, @"cannot make Random_Seed from '%@': %@", abcdefString, error);
		result = kNilRandomSeed;
	}
	
	return result;
}


NSString *OOStringFromRandomSeed(Random_Seed seed)
{
	return [NSString stringWithFormat: @"%d %d %d %d %d %d", seed.a, seed.b, seed.c, seed.d, seed.e, seed.f];
}
