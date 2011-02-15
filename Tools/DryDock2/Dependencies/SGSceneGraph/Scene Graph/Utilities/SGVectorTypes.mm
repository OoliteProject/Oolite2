/*
	SGVectorTypes.mm
	
	Copyright © 2003-2009 Jens Ayton

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
#import "SGVectorTypes.h"

const SGVector2 kSGVector2Zero(0, 0);
const SGVector2 kSGVector2PlusX(1, 0);
const SGVector2 kSGVector2PlusY(0, 1);
const SGVector2 kSGVector2MinusX(-1, 0);
const SGVector2 kSGVector2MinusY(0, -1);

const SGVector3 kSGVector3Zero(0);
const SGVector3 kSGVector3PlusX(1, 0, 0);
const SGVector3 kSGVector3PlusY(0, 1, 0);
const SGVector3 kSGVector3PlusZ(0, 0, 1);
const SGVector3 kSGVector3MinusX(-1, 0, 0);
const SGVector3 kSGVector3MinusY(0, -1, 0);
const SGVector3 kSGVector3MinusZ(0, 0, -1);


void SGVector2Randomize(SGVector2 *vector)
{
	vector->x = random() / (SGScalar)RAND_MAX;
	vector->y = random() / (SGScalar)RAND_MAX;
	
	vector->Normalize();
	
	SGVector2MultiplyScalarInPlace(vector, random() / (SGScalar)RAND_MAX);
}


CFStringRef SGVector2CopyDescription(SGVector2Param v)
{
	return CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("{%g, %g}"), v.x, v.y);
}


NSString *SGVector2GetDescription(SGVector2Param v)
{
	return [NSMakeCollectable(SGVector2CopyDescription(v)) autorelease];
}


void SGVector3Randomize(SGVector3 *vector)
{
	vector->x = random() / (SGScalar)RAND_MAX;
	vector->y = random() / (SGScalar)RAND_MAX;
	vector->z = random() / (SGScalar)RAND_MAX;
	
	vector->Normalize();
	
	SGVector3MultiplyScalarInPlace(vector, random() / (SGScalar)RAND_MAX);
}


CFStringRef SGVector3CopyDescription(SGVector3Param v)
{
	return CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("{%g, %g, %g}"), v.x, v.y, v.z);
}


NSString *SGVector3GetDescription(SGVector3Param v)
{
	return [NSMakeCollectable(SGVector3CopyDescription(v)) autorelease];
}
