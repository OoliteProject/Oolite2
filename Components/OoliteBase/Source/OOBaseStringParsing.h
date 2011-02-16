/*

OOBaseStringParsing.h

Various functions for interpreting values from strings.


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

#import <Foundation/Foundation.h>
#import "OOMaths.h"


/*	Note: these functions will leave their out values untouched if they fail
	(and return NO). They will not log an error if passed a NULL string (but
	will return NO). This means they can be used to, say, read dictionary
	entries which might not exist. They also ignore any extra components in
	the string.
*/

BOOL OOScanVectorFromString(NSString *xyzString, Vector *outVector);
BOOL OOScanQuaternionFromString(NSString *wxyzString, Quaternion *outQuaternion);
BOOL OOScanVectorAndQuaternionFromString(NSString *xyzwxyzString, Vector *outVector, Quaternion *outQuaternion);

Vector OOVectorFromString(NSString *xyzString, Vector defaultValue);
Quaternion OOQuaternionFromString(NSString *wxyzString, Quaternion defaultValue);
