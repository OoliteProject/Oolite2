/*
	SGVectorTypes.h
	
	
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

#ifndef INCLUDED_SGVECTORTYPES_h
#define	INCLUDED_SGVECTORTYPES_h

#define SGVECTOR_DOUBLE_PRECISION		0

#ifndef SGVECTOR_VECTORIZE
#if __ppc__
	#define SGVECTOR_VECTORIZE			0
#else
	#define SGVECTOR_VECTORIZE			1
#endif
#endif

#ifndef SGVECTOR_COCOA
	#ifdef NSFoundationVersionNumber10_0	// Just a macro that's declared in NSObjCRuntime.h
		#define SGVECTOR_COCOA			1
	#else
		#define SGVECTOR_COCOA			0
	#endif
#endif


#include <math.h>
#include <stdlib.h>
#if __ppc__ || __ppc64__
#include <gcc/darwin/default/ppc_intrinsics.h>
#endif
#include <Accelerate/Accelerate.h>
#include <CoreFoundation/CoreFoundation.h>
#include <OpenGL/gl.h>


#ifndef GCC_ATTR
	#ifdef __GNUC__
		#define GCC_ATTR	__attribute__
	#else
		#define GCC_ATTR(foo)
	#endif
#endif


#ifndef SGVECTOR_NO_FORCE_INLINE
	#define SGVECTOR_ALWAYS_INLINE GCC_ATTR((always_inline))
#else
	#define SGVECTOR_ALWAYS_INLINE
#endif


#if SGVECTOR_VECTORIZE
	#define SGVECTOR_VECTORIZED_ALIGNMENT(n) GCC_ATTR((aligned(n)))
#else
	#define SGVECTOR_VECTORIZED_ALIGNMENT(n)
#endif


#define SGVECTOR_NONNULL GCC_ATTR((nonnull))
#define SGVECTOR_PURE GCC_ATTR((pure))
#define SGVECTOR_CONST GCC_ATTR((const))


#define kSGVectorComparisonMargin		1e-6f


#if SGVECTOR_DOUBLE_PRECISION
	typedef GLdouble		SGScalar;
	#define GL_SGSCALAR		GL_DOUBLE
#else
	typedef GLfloat			SGScalar;
	#define GL_SGSCALAR		GL_FLOAT
#endif


#ifndef __cplusplus

#define SGVECTOR_INLINE static inline
#define SGVECTOR_EXTERN extern


typedef struct
{
	union
	{
		SGScalar			v[2];
		struct
		{
			SGScalar		x, y;
		};
	};
} SGVector2;


typedef struct
{
	union
	{
		SGScalar			v[3];
		struct
		{
			SGScalar		x, y, z;
		};
	};
} SGVector3;


SGVECTOR_INLINE SGVector2 SGVector2Construct(SGScalar x, SGScalar y) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector3Construct(SGScalar x, SGScalar y, SGScalar z) SGVECTOR_CONST;

SGVECTOR_INLINE SGVector2 SGVector2Construct(SGScalar x, SGScalar y)
{
	SGVector2 r;
	r.x = x;
	r.y = y;
	return r;
}


SGVECTOR_INLINE SGVector3 SGVector3Construct(SGScalar x, SGScalar y, SGScalar z)
{
	SGVector3 r;
	r.x = x;
	r.y = y;
	r.z = z;
	return r;
}

// Only for inline functions - meaning varies between C and C++
typedef SGVector2 SGVector2Param;
typedef SGVector3 SGVector3Param;


#else	/* __cplusplus */

#define SGVECTOR_INLINE inline
#define SGVECTOR_EXTERN extern "C"


class						SGVector2;
class						SGVector3;

// Only for inline functions - meaning varies between C and C++
typedef const SGVector2 &SGVector2Param;
typedef const SGVector3 &SGVector3Param;


SGVECTOR_INLINE SGVector2 SGVector2Construct(SGScalar x, SGScalar y) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector3Construct(SGScalar x, SGScalar y, SGScalar z) SGVECTOR_CONST;


class SGVector2
{
public:
	union
	{
		SGScalar			v[2];
		struct
		{
			SGScalar		x, y;
		};
	};
	
	inline					SGVector2() SGVECTOR_ALWAYS_INLINE {}
	inline					SGVector2(SGScalar inX, SGScalar inY) SGVECTOR_ALWAYS_INLINE
							: x(inX), y(inY) {}
	
	inline SGScalar			&operator[](const unsigned long inIndex) SGVECTOR_ALWAYS_INLINE
							{
								return v[inIndex];
							}
	
	inline const SGScalar		&operator[](const unsigned long inIndex) const SGVECTOR_ALWAYS_INLINE
							{
								return v[inIndex];
							}
	
	inline SGVector2		&Set(const SGScalar inX, const SGScalar inY = 0) SGVECTOR_ALWAYS_INLINE;
	inline SGVector2		&Randomize(void) SGVECTOR_ALWAYS_INLINE;
	
	
	// Nondestructive operators
	inline const SGVector2	operator-() const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector2	operator+(const SGVector2 &inVector) const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector2	operator-(const SGVector2 &inVector) const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	operator+(const SGVector3 &inVector) const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	operator-(const SGVector3 &inVector) const SGVECTOR_ALWAYS_INLINE;
	
	inline const SGVector2	operator*(const SGScalar inScalar) const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector2	operator/(const SGScalar inScalar) const SGVECTOR_ALWAYS_INLINE;
	
	// Dot product
	inline const SGScalar	operator*(const SGVector2 &inVector) const SGVECTOR_ALWAYS_INLINE;
	// Cross product
	inline const SGVector2	operator%(const SGVector2 &other) const SGVECTOR_ALWAYS_INLINE;
	
	inline const bool		operator==(const SGVector2 &inVector) const SGVECTOR_ALWAYS_INLINE;
	inline const bool		operator!=(const SGVector2 &inVector) const SGVECTOR_ALWAYS_INLINE;
	
	
	// Assignment operators
	inline const SGVector2	&operator=(const SGVector2 &inVector) SGVECTOR_ALWAYS_INLINE;
	inline const SGVector2	&operator+=(const SGVector2 &inVector) SGVECTOR_ALWAYS_INLINE;
	inline const SGVector2	&operator-=(const SGVector2 &inVector) SGVECTOR_ALWAYS_INLINE;
	inline const SGVector2	&operator*=(const SGScalar inScalar) SGVECTOR_ALWAYS_INLINE;	
	inline const SGVector2	&operator/=(SGScalar inScalar) SGVECTOR_ALWAYS_INLINE;
	
	
	inline const SGScalar	SquareMagnitude() const SGVECTOR_ALWAYS_INLINE;
	inline const SGScalar	Magnitude() const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector2	Normal() const SGVECTOR_ALWAYS_INLINE;
	inline SGVector2		&Normalize() SGVECTOR_ALWAYS_INLINE;
	
	inline void				glVertex() const SGVECTOR_ALWAYS_INLINE;
	inline void				glNormal() const SGVECTOR_ALWAYS_INLINE;
	inline void				glTranslate() const SGVECTOR_ALWAYS_INLINE;
	
	inline SGVector2		&CleanZeros() SGVECTOR_ALWAYS_INLINE;
	
	inline CFStringRef		CopyDescription() const SGVECTOR_ALWAYS_INLINE;
	#if SGVECTOR_COCOA
	inline NSString			*Description() const SGVECTOR_ALWAYS_INLINE;
	#endif
};


class SGVector3
{
public:
	union
	{
		SGScalar			v[3];
		struct
		{
			SGScalar		x, y, z;
		};
	};
	
	inline					SGVector3() SGVECTOR_ALWAYS_INLINE {}
	inline					SGVector3(SGScalar inX, SGScalar inY = 0.0, SGScalar inZ = 0.0) SGVECTOR_ALWAYS_INLINE
							: x(inX), y(inY), z(inZ) {}
	
	inline SGScalar			&operator[](const unsigned long inIndex) SGVECTOR_ALWAYS_INLINE
							{
								return v[inIndex];
							}
	
	inline const SGScalar	&operator[](const unsigned long inIndex) const SGVECTOR_ALWAYS_INLINE
							{
								return v[inIndex];
							}
	
	inline SGVector3		&Set(const SGScalar inX, const SGScalar inY = 0, const SGScalar inZ = 0) SGVECTOR_ALWAYS_INLINE;
	inline SGVector3		&Randomize(void) SGVECTOR_ALWAYS_INLINE;
	
	
	// Nondestructive operators
	inline const SGVector3	operator-() const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	operator+(const SGVector3 &inVector) const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	operator-(const SGVector3 &inVector) const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	operator+(const SGVector2 &inVector) const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	operator-(const SGVector2 &inVector) const SGVECTOR_ALWAYS_INLINE;
	
	inline const SGVector3	operator*(const SGScalar inScalar) const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	operator/(const SGScalar inScalar) const SGVECTOR_ALWAYS_INLINE;
	
	// Dot product
	inline const SGScalar	operator*(const SGVector3 &inVector) const SGVECTOR_ALWAYS_INLINE;
	// Cross product
	inline const SGVector3	operator%(const SGVector3 &other) const SGVECTOR_ALWAYS_INLINE;
	
	inline const bool		operator==(const SGVector3 &inVector) const SGVECTOR_ALWAYS_INLINE;
	inline const bool		operator!=(const SGVector3 &inVector) const SGVECTOR_ALWAYS_INLINE;
	
	
	// Assignment operators
	inline const SGVector3	&operator=(const SGVector3 &inVector) SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	&operator+=(const SGVector3 &inVector) SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	&operator-=(const SGVector3 &inVector) SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	&operator+=(const SGVector2 &inVector) SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	&operator-=(const SGVector2 &inVector) SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	&operator*=(const SGScalar inScalar) SGVECTOR_ALWAYS_INLINE;	
	inline const SGVector3	&operator/=(SGScalar inScalar) SGVECTOR_ALWAYS_INLINE;
	
	
	inline const SGScalar	SquareMagnitude() const SGVECTOR_ALWAYS_INLINE;
	inline const SGScalar	Magnitude() const SGVECTOR_ALWAYS_INLINE;
	inline const SGVector3	Normal() const SGVECTOR_ALWAYS_INLINE;
	inline SGVector3		&Normalize() SGVECTOR_ALWAYS_INLINE;
	
	inline void				glVertex() const SGVECTOR_ALWAYS_INLINE;
	inline void				glNormal() const SGVECTOR_ALWAYS_INLINE;
	inline void				glTranslate() const SGVECTOR_ALWAYS_INLINE;
	
	inline SGVector3		&CleanZeros() SGVECTOR_ALWAYS_INLINE;
	
	inline CFStringRef		CopyDescription() const SGVECTOR_ALWAYS_INLINE;
	#if SGVECTOR_COCOA
	inline NSString			*Description() const SGVECTOR_ALWAYS_INLINE;
	#endif
};


SGVECTOR_INLINE SGVector2 SGVector2Construct(SGScalar x, SGScalar y)
{
	return SGVector2(x, y);
}


SGVECTOR_INLINE SGVector3 SGVector3Construct(SGScalar x, SGScalar y, SGScalar z)
{
	return SGVector3(x, y, z);
}

#endif	/* __cplusplus */


extern const SGVector2 kSGVector2Zero;			// 0, 0
extern const SGVector2 kSGVector2PlusX;			// 1, 0
extern const SGVector2 kSGVector2PlusY;			// 0, 1
extern const SGVector2 kSGVector2MinusX;		// -1, 0
extern const SGVector2 kSGVector2MinusY;		// 0, -1

extern const SGVector3 kSGVector3Zero;			// 0
extern const SGVector3 kSGVector3PlusX;			// 1, 0, 0
extern const SGVector3 kSGVector3PlusY;			// 0, 1, 0
extern const SGVector3 kSGVector3PlusZ;			// 0, 0, 1
extern const SGVector3 kSGVector3MinusX;		// -1, 0, 0
extern const SGVector3 kSGVector3MinusY;		// 0, -1, 0
extern const SGVector3 kSGVector3MinusZ;		// 0, 0, -1


SGVECTOR_INLINE void SGVector2Set(SGVector2 *vector, SGScalar x, SGScalar y) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector2SetVector(SGVector2 *vector, SGVector2Param v) SGVECTOR_NONNULL;
SGVECTOR_EXTERN void SGVector2Randomize(SGVector2 *vector) SGVECTOR_NONNULL;	// uses random(), seed accordingly.

SGVECTOR_INLINE void SGVector2CleanZeros(SGVector2 *vector) SGVECTOR_NONNULL;

SGVECTOR_INLINE bool SGVector2Equal(SGVector2Param u, SGVector2Param v) SGVECTOR_CONST;

SGVECTOR_INLINE SGVector2 SGVector2Reverse(SGVector2Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector2 SGVector2Add(SGVector2Param u, SGVector2Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector2 SGVector2Subtract(SGVector2Param u, SGVector2Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector2 SGVector2MultiplyScalar(SGVector2Param v, SGScalar c) SGVECTOR_CONST;
SGVECTOR_INLINE SGScalar SGVector2Dot(SGVector2Param u, SGVector2Param v) SGVECTOR_CONST;

SGVECTOR_INLINE void SGVector2ReverseInPlace(SGVector2 *vector) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector2AddInPlace(SGVector2 *vector, SGVector2Param v) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector2SubtractInPlace(SGVector2 *vector, SGVector2Param v) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector2MultiplyScalarInPlace(SGVector2 *vector, SGScalar c) SGVECTOR_NONNULL;

SGVECTOR_INLINE SGScalar SGVector2SquareMagnitude(SGVector2Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGScalar SGVector2Magnitude(SGVector2Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector2 SGVector2Normal(SGVector2Param v) SGVECTOR_CONST;
SGVECTOR_INLINE void SGVector2NormalizeInPlace(SGVector2 *vector) SGVECTOR_NONNULL;

SGVECTOR_INLINE void SGVector2GLVertex(SGVector2Param v) SGVECTOR_ALWAYS_INLINE;

SGVECTOR_EXTERN CFStringRef SGVector2CopyDescription(SGVector2Param v);
#if SGVECTOR_COCOA
SGVECTOR_EXTERN NSString *SGVector2GetDescription(SGVector2Param v);
#endif


SGVECTOR_INLINE void SGVector3Set(SGVector3 *vector, SGScalar x, SGScalar y, SGScalar z) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector3SetVector(SGVector3 *vector, SGVector3Param v) SGVECTOR_NONNULL;
SGVECTOR_EXTERN void SGVector3Randomize(SGVector3 *vector) SGVECTOR_NONNULL;	// uses random(), seed accordingly.

SGVECTOR_INLINE void SGVector3CleanZeros(SGVector3 *vector) SGVECTOR_NONNULL;

SGVECTOR_INLINE bool SGVector3Equal(SGVector3Param u, SGVector3Param v) SGVECTOR_CONST;

SGVECTOR_INLINE SGVector3 SGVector3Reverse(SGVector3Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector3Add(SGVector3Param u, SGVector3Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector3AddVector2(SGVector3Param u, SGVector2Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector3Subtract(SGVector3Param u, SGVector3Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector3SubtractVector2(SGVector3Param u, SGVector2Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector2SubtractVector3(SGVector2Param u, SGVector3Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector3MultiplyScalar(SGVector3Param v, SGScalar c) SGVECTOR_CONST;
SGVECTOR_INLINE SGScalar SGVector3Dot(SGVector3Param u, SGVector3Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector3Cross(SGVector3Param u, SGVector3Param v) SGVECTOR_CONST;

SGVECTOR_INLINE void SGVector3ReverseInPlace(SGVector3 *vector) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector3AddInPlace(SGVector3 *vector, SGVector3Param v) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector3SubtractInPlace(SGVector3 *vector, SGVector3Param v) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector3AddVector2InPlace(SGVector3 *vector, SGVector2Param v) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector3SubtractVector2InPlace(SGVector3 *vector, SGVector2Param v) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGVector3MultiplyScalarInPlace(SGVector3 *vector, SGScalar c) SGVECTOR_NONNULL;

SGVECTOR_INLINE SGScalar SGVector3SquareMagnitude(SGVector3Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGScalar SGVector3Magnitude(SGVector3Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGVector3Normal(SGVector3Param v) SGVECTOR_CONST;
SGVECTOR_INLINE void SGVector3NormalizeInPlace(SGVector3 *vector) SGVECTOR_NONNULL;

SGVECTOR_INLINE void SGVector3GLVertex(SGVector3Param v) SGVECTOR_ALWAYS_INLINE;
SGVECTOR_INLINE void SGVector3GLNormal(SGVector3Param v) SGVECTOR_ALWAYS_INLINE;
SGVECTOR_INLINE void SGVector3Translate(SGVector3Param v) SGVECTOR_ALWAYS_INLINE;

SGVECTOR_EXTERN CFStringRef SGVector3CopyDescription(SGVector3Param v);
#if SGVECTOR_COCOA
SGVECTOR_EXTERN NSString *SGVector3GetDescription(SGVector3Param v);
#endif


// SGVector2 functions
SGVECTOR_INLINE void SGVector2Set(SGVector2 *vector, SGScalar x, SGScalar y)
{
	vector->x = x;
	vector->y = y;
}


SGVECTOR_INLINE void SGVector2SetVector(SGVector2 *vector, SGVector2Param v)
{
	vector->x = v.x;
	vector->y = v.y;
}


SGVECTOR_INLINE void SGVector2CleanZeros(SGVector2 *vector)
{
	if (vector->x == (SGScalar)-0.0)  vector->x = (SGScalar)0.0;
	if (vector->y == (SGScalar)-0.0)  vector->y = (SGScalar)0.0;
}


SGVECTOR_INLINE bool SGVector2Equal(SGVector2Param u, SGVector2Param v)
{
	return u.x == v.x && u.y == v.y;
}


SGVECTOR_INLINE SGVector2 SGVector2Reverse(SGVector2Param v)
{
	return SGVector2Construct(-v.x, -v.y);
}


SGVECTOR_INLINE SGVector2 SGVector2Add(SGVector2Param u, SGVector2Param v)
{
	return SGVector2Construct(u.x + v.x, u.y + v.y);
}


SGVECTOR_INLINE SGVector2 SGVector2Subtract(SGVector2Param u, SGVector2Param v)
{
	return SGVector2Construct(u.x - v.x, u.y - v.y);
}


SGVECTOR_INLINE SGVector2 SGVector2MultiplyScalar(SGVector2Param v, SGScalar c)
{
	return SGVector2Construct(v.x * c, v.y * c);
}


SGVECTOR_INLINE SGScalar SGVector2Dot(SGVector2Param u, SGVector2Param v)
{
	return u.x * v.x + u.y * v.y;
}


SGVECTOR_INLINE void SGVector2ReverseInPlace(SGVector2 *vector)
{
	vector->x = -vector->x;
	vector->y = -vector->y;
}


SGVECTOR_INLINE void SGVector2AddInPlace(SGVector2 *vector, SGVector2Param v)
{
	vector->x += v.x;
	vector->y += v.y;
}


SGVECTOR_INLINE void SGVector2SubtractInPlace(SGVector2 *vector, SGVector2Param v)
{
	vector->x -= v.x;
	vector->y -= v.y;
}


SGVECTOR_INLINE void SGVector2MultiplyScalarInPlace(SGVector2 *vector, SGScalar c)
{
	vector->x *= c;
	vector->y *= c;
}


SGVECTOR_INLINE SGScalar SGVector2SquareMagnitude(SGVector2Param v)
{
	return v.x * v.x + v.y * v.y;
}


SGVECTOR_INLINE SGScalar SGVector2Magnitude(SGVector2Param v)
{
#if SGVECTOR_DOUBLE_PRECISION
	return sqrt(SGVector2SquareMagnitude(v));
#else
	return sqrtf(SGVector2SquareMagnitude(v));
#endif
}


SGVECTOR_INLINE SGVector2 SGVector2Normal(SGVector2Param v)
{
	return SGVector2MultiplyScalar(v, (SGScalar)1.0 / SGVector2Magnitude(v));
}


SGVECTOR_INLINE void SGVector2NormalizeInPlace(SGVector2 *vector)
{
	return SGVector2MultiplyScalarInPlace(vector, (SGScalar)1.0 / SGVector2Magnitude(*vector));
}


SGVECTOR_INLINE void SGVector2GLVertex(SGVector2Param v)
{
#if SGVECTOR_DOUBLE_PRECISION
	glVertex2d(v.x, v.y);
#else
	glVertex2f(v.x, v.y);
#endif
}


// SGVector3 functions
SGVECTOR_INLINE void SGVector3Set(SGVector3 *vector, SGScalar x, SGScalar y, SGScalar z)
{
	vector->x = x;
	vector->y = y;
	vector->z = z;
}


SGVECTOR_INLINE void SGVector3SetVector(SGVector3 *vector, SGVector3Param v)
{
	vector->x = v.x;
	vector->y = v.y;
	vector->z = v.z;
}


SGVECTOR_INLINE void SGVector3CleanZeros(SGVector3 *vector)
{
	if (vector->x == (SGScalar)-0.0)  vector->x = (SGScalar)0.0;
	if (vector->y == (SGScalar)-0.0)  vector->y = (SGScalar)0.0;
	if (vector->z == (SGScalar)-0.0)  vector->z = (SGScalar)0.0;
}


SGVECTOR_INLINE bool SGVector3Equal(SGVector3Param u, SGVector3Param v)
{
	return u.x == v.x && u.y == v.y && u.z == v.z;
}


SGVECTOR_INLINE SGVector3 SGVector3Reverse(SGVector3Param v)
{
	return SGVector3Construct(-v.x, -v.y, -v.z);
}


SGVECTOR_INLINE SGVector3 SGVector3Add(SGVector3Param u, SGVector3Param v)
{
	return SGVector3Construct(u.x + v.x, u.y + v.y, u.z + v.z);
}


SGVECTOR_INLINE SGVector3 SGVector3AddVector2(SGVector3Param u, SGVector2Param v)
{
	return SGVector3Construct(u.x + v.x, u.y + v.y, u.z);
}


SGVECTOR_INLINE SGVector3 SGVector3Subtract(SGVector3Param u, SGVector3Param v)
{
	return SGVector3Construct(u.x - v.x, u.y - v.y, u.z - v.z);
}


SGVECTOR_INLINE SGVector3 SGVector3SubtractVector2(SGVector3Param u, SGVector2Param v)
{
	return SGVector3Construct(u.x - v.x, u.y - v.y, u.z);
}


SGVECTOR_INLINE SGVector3 SGVector2SubtractVector3(SGVector2Param u, SGVector3Param v)
{
	return SGVector3Construct(u.x - v.x, u.y - v.y, -v.z);
}


SGVECTOR_INLINE SGVector3 SGVector3MultiplyScalar(SGVector3Param v, SGScalar c)
{
	return SGVector3Construct(v.x * c, v.y * c, v.z * c);
}


SGVECTOR_INLINE SGScalar SGVector3Dot(SGVector3Param u, SGVector3Param v)
{
	return u.x * v.x + u.y * v.y + u.z * v.z;
}


SGVECTOR_INLINE SGVector3 SGVector3Cross(SGVector3Param u, SGVector3Param v)
{
	return SGVector3Construct(u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x);
}


SGVECTOR_INLINE void SGVector3ReverseInPlace(SGVector3 *vector)
{
	vector->x = -vector->x;
	vector->y = -vector->y;
	vector->z = -vector->z;
}


SGVECTOR_INLINE void SGVector3AddInPlace(SGVector3 *vector, SGVector3Param v)
{
	vector->x += v.x;
	vector->y += v.y;
	vector->z += v.z;
}


SGVECTOR_INLINE void SGVector3AddVector2InPlace(SGVector3 *vector, SGVector2Param v)
{
	vector->x += v.x;
	vector->y += v.y;
}


SGVECTOR_INLINE void SGVector3SubtractInPlace(SGVector3 *vector, SGVector3Param v)
{
	vector->x -= v.x;
	vector->y -= v.y;
	vector->z -= v.z;
}


SGVECTOR_INLINE void SGVector3SubtractVector2InPlace(SGVector3 *vector, SGVector2Param v)
{
	vector->x -= v.x;
	vector->y -= v.y;
}


SGVECTOR_INLINE void SGVector3MultiplyScalarInPlace(SGVector3 *vector, SGScalar c)
{
	vector->x *= c;
	vector->y *= c;
	vector->z *= c;
}


SGVECTOR_INLINE SGScalar SGVector3SquareMagnitude(SGVector3Param v)
{
	return v.x * v.x + v.y * v.y + v.z * v.z;
}


SGVECTOR_INLINE SGScalar SGVector3Magnitude(SGVector3Param v)
{
#if SGVECTOR_DOUBLE_PRECISION
	return sqrt(SGVector3SquareMagnitude(v));
#else
	return sqrtf(SGVector3SquareMagnitude(v));
#endif
}


SGVECTOR_INLINE SGVector3 SGVector3Normal(SGVector3Param v)
{
	return SGVector3MultiplyScalar(v, (SGScalar)1.0 / SGVector3Magnitude(v));
}


SGVECTOR_INLINE void SGVector3NormalizeInPlace(SGVector3 *vector)
{
	return SGVector3MultiplyScalarInPlace(vector, (SGScalar)1.0 / SGVector3Magnitude(*vector));
}


SGVECTOR_INLINE void SGVector3GLVertex(SGVector3Param v)
{
#if SGVECTOR_DOUBLE_PRECISION
	glVertex3d(v.x, v.y, v.z);
#else
	glVertex3f(v.x, v.y, v.z);
#endif
}


SGVECTOR_INLINE void SGVector3GLNormal(SGVector3Param v)
{
#if SGVECTOR_DOUBLE_PRECISION
	glNormal3d(v.x, v.y, v.z);
#else
	glNormal3f(v.x, v.y, v.z);
#endif
}


SGVECTOR_INLINE void SGVector3Translate(SGVector3Param v)
{
#if SGVECTOR_DOUBLE_PRECISION
	glTranslated(v.x, v.y, v.z);
#else
	glTranslatef(v.x, v.y, v.z);
#endif
}


#if __cplusplus

// SGVector2 implementation
inline SGVector2 &SGVector2::Set(const SGScalar inX, const SGScalar inY)
{
	SGVector2Set(this, inX, inY);
	return *this;
}


inline SGVector2 &SGVector2::Randomize(void)
{
	SGVector2Randomize(this);
	return *this;
}


// Nondestructive operators
inline const SGVector2 SGVector2::operator-() const
{
	return SGVector2Reverse(*this);
}


inline const SGVector2 SGVector2::operator+(const SGVector2 &inVector) const
{
	return SGVector2Add(*this, inVector);
}


inline const SGVector2 SGVector2::operator-(const SGVector2 &inVector) const
{
	return SGVector2Subtract(*this, inVector);
}


inline const SGVector3 SGVector2::operator+(const SGVector3 &inVector) const
{
	return SGVector3AddVector2(inVector, *this);
}


inline const SGVector3 SGVector2::operator-(const SGVector3 &inVector) const
{
	return SGVector2SubtractVector3(*this, inVector);
}


inline const SGVector2 SGVector2::operator*(const SGScalar inScalar) const
{
	return SGVector2MultiplyScalar(*this, inScalar);
}


inline const SGVector2 SGVector2::operator/(const SGScalar inScalar) const
{
	return SGVector2MultiplyScalar(*this, (SGScalar)1.0 / inScalar);
}


inline const SGVector2 operator*(const SGScalar inScalar, const SGVector2 &inVector)
{
	return SGVector2MultiplyScalar(inVector, inScalar);
}


inline const SGScalar SGVector2::operator*(const SGVector2 &inVector) const
{
	return SGVector2Dot(*this, inVector);
}


inline const bool SGVector2::operator==(const SGVector2 &inVector) const
{
	return SGVector2Equal(*this, inVector);
}


inline const bool SGVector2::operator!=(const SGVector2 &inVector) const
{
	return !SGVector2Equal(*this, inVector);
}


// Assignment operators
inline const SGVector2 &SGVector2::operator=(const SGVector2 &inVector)
{
	SGVector2SetVector(this, inVector);
	return *this;
}


inline const SGVector2 &SGVector2::operator+=(const SGVector2 &inVector)
{
	SGVector2AddInPlace(this, inVector);
	return *this;
}


inline const SGVector2 &SGVector2::operator-=(const SGVector2 &inVector)
{
	SGVector2SubtractInPlace(this, inVector);
	return *this;
}


inline const SGVector2 &SGVector2::operator*=(const SGScalar inScalar)
{
	SGVector2MultiplyScalarInPlace(this, inScalar);
	return *this;
}


inline const SGVector2 &SGVector2::operator/=(const SGScalar inScalar)
{
	SGVector2MultiplyScalarInPlace(this, (SGScalar)1.0 / inScalar);
	return *this;
}


inline const SGScalar SGVector2::SquareMagnitude() const
{
	return SGVector2SquareMagnitude(*this);
}


inline const SGScalar SGVector2::Magnitude() const
{
	return SGVector2Magnitude(*this);
}


inline const SGVector2 SGVector2::Normal() const
{
	return SGVector2Normal(*this);
}


inline SGVector2 &SGVector2::Normalize()
{
	SGVector2NormalizeInPlace(this);
	return *this;
}


inline void SGVector2::glVertex(void) const
{
	SGVector2GLVertex(*this);
}


inline SGVector2 &SGVector2::CleanZeros()
{
	SGVector2CleanZeros(this);
	return *this;
}


inline CFStringRef SGVector2::CopyDescription() const
{
	return SGVector2CopyDescription(*this);
}


#if SGVECTOR_COCOA
inline NSString *SGVector2::Description() const
{
	return SGVector2GetDescription(*this);
}
#endif


// SGVector3 implementation
inline SGVector3 &SGVector3::Set(const SGScalar inX, const SGScalar inY, const SGScalar inZ)
{
	SGVector3Set(this, inX, inY, inZ);
	return *this;
}


inline SGVector3 &SGVector3::Randomize(void)
{
	SGVector3Randomize(this);
	return *this;
}


// Nondestructive operators
inline const SGVector3 SGVector3::operator-() const
{
	return SGVector3Reverse(*this);
}


inline const SGVector3 SGVector3::operator+(const SGVector3 &inVector) const
{
	return SGVector3Add(*this, inVector);
}


inline const SGVector3 SGVector3::operator-(const SGVector3 &inVector) const
{
	return SGVector3Subtract(*this, inVector);
}


inline const SGVector3 SGVector3::operator+(const SGVector2 &inVector) const
{
	return SGVector3AddVector2(*this, inVector);
}


inline const SGVector3 SGVector3::operator-(const SGVector2 &inVector) const
{
	return SGVector3SubtractVector2(*this, inVector);
}


inline const SGVector3 SGVector3::operator*(const SGScalar inScalar) const
{
	return SGVector3MultiplyScalar(*this, inScalar);
}


inline const SGVector3 SGVector3::operator/(const SGScalar inScalar) const
{
	return SGVector3MultiplyScalar(*this, (SGScalar)1.0 / inScalar);
}


inline const SGVector3 operator*(const SGScalar inScalar, const SGVector3 &inVector)
{
	return SGVector3MultiplyScalar(inVector, inScalar);
}


inline const SGScalar SGVector3::operator*(const SGVector3 &inVector) const
{
	return SGVector3Dot(*this, inVector);
}


inline const SGVector3 SGVector3::operator%(const SGVector3 &inVector) const
{
	return SGVector3Cross(*this, inVector);
}


inline const bool SGVector3::operator==(const SGVector3 &inVector) const
{
	return SGVector3Equal(*this, inVector);
}


inline const bool SGVector3::operator!=(const SGVector3 &inVector) const
{
	return !SGVector3Equal(*this, inVector);
}


// Assignment operators
inline const SGVector3 &SGVector3::operator=(const SGVector3 &inVector)
{
	SGVector3SetVector(this, inVector);
	return *this;
}


inline const SGVector3 &SGVector3::operator+=(const SGVector3 &inVector)
{
	SGVector3AddInPlace(this, inVector);
	return *this;
}


inline const SGVector3 &SGVector3::operator-=(const SGVector3 &inVector)
{
	SGVector3SubtractInPlace(this, inVector);
	return *this;
}


inline const SGVector3 &SGVector3::operator+=(const SGVector2 &inVector)
{
	SGVector3AddVector2InPlace(this, inVector);
	return *this;
}


inline const SGVector3 &SGVector3::operator-=(const SGVector2 &inVector)
{
	SGVector3SubtractVector2InPlace(this, inVector);
	return *this;
}


inline const SGVector3 &SGVector3::operator*=(const SGScalar inScalar)
{
	SGVector3MultiplyScalarInPlace(this, inScalar);
	return *this;
}


inline const SGVector3 &SGVector3::operator/=(const SGScalar inScalar)
{
	SGVector3MultiplyScalarInPlace(this, (SGScalar)1.0 / inScalar);
	return *this;
}


inline const SGScalar SGVector3::SquareMagnitude() const
{
	return SGVector3SquareMagnitude(*this);
}


inline const SGScalar SGVector3::Magnitude() const
{
	return SGVector3Magnitude(*this);
}


inline const SGVector3 SGVector3::Normal() const
{
	return SGVector3Normal(*this);
}


inline SGVector3 &SGVector3::Normalize()
{
	SGVector3NormalizeInPlace(this);
	return *this;
}


inline void SGVector3::glVertex(void) const
{
	SGVector3GLVertex(*this);
}


inline void SGVector3::glNormal(void) const
{
	SGVector3GLNormal(*this);
}


inline void SGVector3::glTranslate(void) const
{
	SGVector3Translate(*this);
}


inline SGVector3 &SGVector3::CleanZeros()
{
	SGVector3CleanZeros(this);
	return *this;
}


inline CFStringRef SGVector3::CopyDescription() const
{
	return SGVector3CopyDescription(*this);
}


#if SGVECTOR_COCOA
inline NSString *SGVector3::Description() const
{
	return SGVector3GetDescription(*this);
}
#endif

#endif	/* __cplusplus */


#include "SGMatrixTypes.h"

#endif	/* INCLUDED_SGVECTORTYPES_h */
