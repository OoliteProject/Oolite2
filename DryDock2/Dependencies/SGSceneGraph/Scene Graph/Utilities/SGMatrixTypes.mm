/*
	SGMatrixTypes.mm
	
	
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
#import "SGMatrixTypes.h"


const SGMatrix4x4 SGMatrix4x4::identity;
const SGMatrix4x4 SGMatrix4x4::zero(0, 0, 0, 0,
									0, 0, 0, 0,
									0, 0, 0, 0,
									0, 0, 0, 0);


SGVECTOR_EXTERN void SGMatrix4x4TransposeInPlace(SGMatrix4x4 *matrix)
{
	SGScalar temp;
	#define SWAPM(a, b) { temp = matrix->m[a][b]; matrix->m[a][b] = matrix->m[b][a]; matrix->m[b][a] = temp; }
	SWAPM(0, 1); SWAPM(0, 2); SWAPM(0, 3);
	SWAPM(1, 2); SWAPM(1, 3); SWAPM(2, 3);
	#undef SWAPM
}


SGVECTOR_EXTERN bool SGMatrix4x4Equal(SGMatrix4x4 ma, SGMatrix4x4 mb)
{
	uint_fast8_t i;
	
	for (i = 0; i < 16; i++)
	{
		if (ma.vals[i] != mb.vals[i])  return false;
	}
	
	return true;
}


#if !SGVECTOR_VECTORIZE
SGVECTOR_EXTERN SGMatrix4x4 SGMatrix4x4Multiply(SGMatrix4x4 ma, SGMatrix4x4 mb)
{
	SGMatrix4x4			result(SGMatrix4x4::uninited);
	
	unsigned			i = 0;
	
	for (i = 0; i != 4; ++i)
	{
		result.m[i][0] = ma.m[i][0] * mb.m[0][0] + ma.m[i][1] * mb.m[1][0] + ma.m[i][2] * mb.m[2][0] + ma.m[i][3] * mb.m[3][0];
		result.m[i][1] = ma.m[i][0] * mb.m[0][1] + ma.m[i][1] * mb.m[1][1] + ma.m[i][2] * mb.m[2][1] + ma.m[i][3] * mb.m[3][1];
		result.m[i][2] = ma.m[i][0] * mb.m[0][2] + ma.m[i][1] * mb.m[1][2] + ma.m[i][2] * mb.m[2][2] + ma.m[i][3] * mb.m[3][2];
		result.m[i][3] = ma.m[i][0] * mb.m[0][3] + ma.m[i][1] * mb.m[1][3] + ma.m[i][2] * mb.m[2][3] + ma.m[i][3] * mb.m[3][3];
	}
	
	return result;
}
#endif


#if SGVECTOR_DOUBLE_PRECISION
	#define		SINCOS(a, s, c) do { s = sin(a); c = cos(a); } while(0)
#else
	#define		SINCOS(a, s, c) do { s = sinf(a); c = cosf(a); } while(0)
#endif


SGVECTOR_EXTERN SGMatrix4x4 SGMatrix4x4RotationXMatrix(SGScalar angle)
{
	SGScalar s, c;
	SINCOS(angle, s, c);
	
	return SGMatrix4x4(1,  0,  0,  0,
					   0,  c,  s,  0,
					   0, -s,  c,  0,
					   0,  0,  0,  1);
}


SGVECTOR_EXTERN SGMatrix4x4 SGMatrix4x4RotationYMatrix(SGScalar angle)
{
	SGScalar s, c;
	SINCOS(angle, s, c);
	
	return SGMatrix4x4(c,  0, -s,  0,
					   0,  1,  0,  0,
					   s,  0,  c,  0,
					   0,  0,  0,  1);
}


SGVECTOR_EXTERN SGMatrix4x4 SGMatrix4x4RotationZMatrix(SGScalar angle)
{
	SGScalar s, c;
	SINCOS(angle, s, c);
	
	return SGMatrix4x4(c,  s,  0,  0,
					  -s,  c,  0,  0,
					   0,  0,  1,  0,
					   0,  0,  0,  1);
}


SGVECTOR_EXTERN void SGMatrix4x4RotateX(SGMatrix4x4 *matrix, SGScalar angle)
{
	SGMatrix4x4MultiplyInPlace(matrix, SGMatrix4x4RotationXMatrix(angle));
}


SGVECTOR_EXTERN void SGMatrix4x4RotateY(SGMatrix4x4 *matrix, SGScalar angle)
{
	SGMatrix4x4MultiplyInPlace(matrix, SGMatrix4x4RotationYMatrix(angle));
}


SGVECTOR_EXTERN void SGMatrix4x4RotateZ(SGMatrix4x4 *matrix, SGScalar angle)
{
	SGMatrix4x4MultiplyInPlace(matrix, SGMatrix4x4RotationZMatrix(angle));
}


SGVECTOR_EXTERN void SGMatrix4x4RotateAroundUnitAxis(SGMatrix4x4 *matrix, SGVector3 axis, SGScalar angle)
{
	SGScalar			x, y, z, s, c, t;
	
	x = axis.x;
	y = axis.y;
	z = axis.z;
	
	SINCOS(angle, s, c);
	t = 1.0f - c;
	
	SGMatrix4x4 xform(	t * x * x + c,		t * x * y + s * z,	t * x * z - s * y,	0,
						t * x * y - s * z,	t * y * y + c,		t * y * z + s * x,	0,
						t * x * y + s * y,	t * y * z - s * x,	t * z * z + c,		0,
						0,					0,					0,					1);
	
//	SGMatrix4x4MultiplyInPlace(matrix, xform);
	*matrix = SGMatrix4x4Multiply(*matrix, xform);
	SGMatrix4x4Orthogonalize(matrix);
}


SGVECTOR_EXTERN void SGMatrix4x4Orthogonalize(SGMatrix4x4 *matrix)
{
	/*	Mathematically unsatisfactory but simple orthogonalization, i.e.
		conversion to a "proper" transformation matrix. The approach is
		basically to make everything the cross product of everything else.
	*/
	SGVector3			i(matrix->m[0][0], matrix->m[1][0], matrix->m[2][0]),
						j(matrix->m[0][1], matrix->m[1][1], matrix->m[2][1]),
						k(matrix->m[0][2], matrix->m[1][2], matrix->m[2][2]);
	
	k.Normalize();
	i = (j % k).Normal();
	j = k % i;
	
	matrix->m[0][0] = i[0]; matrix->m[1][0] = i[1]; matrix->m[2][0] = i[2];
	matrix->m[0][1] = j[0]; matrix->m[1][1] = j[1]; matrix->m[2][1] = j[2];
	matrix->m[0][2] = k[0]; matrix->m[1][2] = k[1]; matrix->m[2][2] = k[2];
}


SGVECTOR_EXTERN CFStringRef SGMatrix4x4CopyDescription(SGMatrix4x4Param m)
{
	return CFStringCreateWithFormat(kCFAllocatorDefault, NULL,
									CFSTR("{{%g, %g, %g, %g}, {%g, %g, %g, %g}, {%g, %g, %g, %g}, {%g, %g, %g, %g}}"),
									m.m[0][0], m.m[0][1], m.m[0][2], m.m[0][3],
									m.m[1][0], m.m[1][1], m.m[1][2], m.m[1][3],
									m.m[2][0], m.m[2][1], m.m[2][2], m.m[2][3],
									m.m[3][0], m.m[3][1], m.m[3][2], m.m[3][3]);
}


SGVECTOR_EXTERN NSString *SGMatrix4x4GetDescription(SGMatrix4x4Param m)
{
	return [NSMakeCollectable(SGMatrix4x4CopyDescription(m)) autorelease];
}


SGVECTOR_EXTERN NSString *SGMatrix4x4PGetDescription(const SGMatrix4x4 * const mp)
{
	return SGMatrix4x4GetDescription(*mp);
}
