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

#ifndef INCLUDED_SGMATRIXTYPES_h
#define	INCLUDED_SGMATRIXTYPES_h

#include "SGVectorTypes.h"


#ifndef __cplusplus

typedef struct
{
	union
	{
		SGScalar				m[4][4];
		SGScalar				vals[16];
		#if SGVECTOR_VECTORIZE
			VectorFloat			blasVec[4][1];
		#endif
	};
} SGMatrix4x4;


SGVECTOR_INLINE SGMatrix4x4 SGMatrix4x4Construct(SGScalar AA, SGScalar AB, SGScalar AC, SGScalar AD,
												 SGScalar BA, SGScalar BB, SGScalar BC, SGScalar BD,
												 SGScalar CA, SGScalar CB, SGScalar CC, SGScalar CD,
												 SGScalar DA, SGScalar DB, SGScalar DC, SGScalar DD)
{
	SGMatrix4x4 r;
	r.m[0][0] = AA; r.m[0][1] = AB; r.m[0][2] = AC; r.m[0][3] = AD;
	r.m[1][0] = BA; r.m[1][1] = BB; r.m[1][2] = BC; r.m[1][3] = BD;
	r.m[2][0] = CA; r.m[2][1] = CB; r.m[2][2] = CC; r.m[2][3] = CD;
	r.m[3][0] = DA; r.m[3][1] = DB; r.m[3][2] = DC; r.m[3][3] = DD;
	return r;
}

// Only for inline functions - meaning varies between C and C++
typedef SGMatrix4x4 SGMatrix4x4Param;

#else	/* __cplusplus */

class SGVECTOR_VECTORIZED_ALIGNMENT(16) SGMatrix4x4
{
public:
	union
	{
		SGScalar				m[4][4];
		SGScalar				vals[16];
#if SGVECTOR_VECTORIZE
		VectorFloat				blasVec[4][1];
#endif
	};
	
private:
	class Uninited {};
	
public:
	static Uninited uninited;
	static const SGMatrix4x4 identity;
	static const SGMatrix4x4 zero;
	
	inline					SGMatrix4x4() SGVECTOR_ALWAYS_INLINE;
	inline					SGMatrix4x4(Uninited) SGVECTOR_ALWAYS_INLINE
							{ };		// Do-nothing constructor; parameter ignored.
	inline					SGMatrix4x4(SGScalar AA, SGScalar AB, SGScalar AC, SGScalar AD,
										SGScalar BA, SGScalar BB, SGScalar BC, SGScalar BD,
										SGScalar CA, SGScalar CB, SGScalar CC, SGScalar CD,
										SGScalar DA, SGScalar DB, SGScalar DC, SGScalar DD) SGVECTOR_ALWAYS_INLINE;
	inline					SGMatrix4x4(SGVector3 i, SGVector3 j, SGVector3 k, SGVector3 o = kSGVector3Zero) SGVECTOR_ALWAYS_INLINE;
//	inline					SGMatrix4x4(const SGMatrix4x4 &m) SGVECTOR_ALWAYS_INLINE;
	
	inline SGScalar			&operator[](const unsigned long inIndex) SGVECTOR_ALWAYS_INLINE
							{
								return vals[inIndex];
							}
	
	inline void				Set(SGScalar AA, SGScalar AB, SGScalar AC, SGScalar AD,
								SGScalar BA, SGScalar BB, SGScalar BC, SGScalar BD,
								SGScalar CA, SGScalar CB, SGScalar CC, SGScalar CD,
								SGScalar DA, SGScalar DB, SGScalar DC, SGScalar DD) SGVECTOR_ALWAYS_INLINE;
	inline void				Set(SGVector3 i, SGVector3 j, SGVector3 k, SGVector3 o = kSGVector3Zero) SGVECTOR_ALWAYS_INLINE;
	inline void				SetIdentity() SGVECTOR_ALWAYS_INLINE;
	inline void				Transpose() SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		Transpose() const SGVECTOR_ALWAYS_INLINE SGVECTOR_PURE;
	
	inline bool				operator==(const SGMatrix4x4 &inMatrix) const SGVECTOR_ALWAYS_INLINE;
	inline bool				operator!=(const SGMatrix4x4 &inMatrix) const SGVECTOR_ALWAYS_INLINE;
	
	inline SGMatrix4x4		operator*(const SGMatrix4x4 &inMatrix) const SGVECTOR_ALWAYS_INLINE SGVECTOR_PURE;
	inline SGMatrix4x4		&operator*=(const SGMatrix4x4 &inMatrix) SGVECTOR_ALWAYS_INLINE;
	
	static inline SGMatrix4x4 RotationXMatrix(SGScalar angle) SGVECTOR_CONST SGVECTOR_ALWAYS_INLINE;
	static inline SGMatrix4x4 RotationYMatrix(SGScalar angle) SGVECTOR_CONST SGVECTOR_ALWAYS_INLINE;
	static inline SGMatrix4x4 RotationZMatrix(SGScalar angle) SGVECTOR_CONST SGVECTOR_ALWAYS_INLINE;
	
	inline SGMatrix4x4		&RotateX(SGScalar angle) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&RotateY(SGScalar angle) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&RotateZ(SGScalar angle) SGVECTOR_ALWAYS_INLINE;
	
	SGMatrix4x4				&RotateAroundUnitAxis(SGVector3 axis, SGScalar angle) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&RotateAroundAxis(SGVector3 axis, SGScalar angle) SGVECTOR_ALWAYS_INLINE;
	
	inline SGMatrix4x4		&TranslateX(SGScalar offset) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&TranslateY(SGScalar offset) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&TranslateZ(SGScalar offset) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&Translate(SGScalar offsetX, SGScalar offsetY, SGScalar offsetZ) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&Translate(const SGVector3 &offset) SGVECTOR_ALWAYS_INLINE;
	
	inline SGMatrix4x4		&ScaleX(SGScalar factor) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&ScaleY(SGScalar factor) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&ScaleZ(SGScalar factor) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&Scale(SGScalar factorX, SGScalar factorY, SGScalar factorZ) SGVECTOR_ALWAYS_INLINE;
	inline SGMatrix4x4		&Scale(SGScalar factor) SGVECTOR_ALWAYS_INLINE;
	
	static inline SGMatrix4x4 ScaleMatrix(SGScalar factorX, SGScalar factorY, SGScalar factorZ) SGVECTOR_ALWAYS_INLINE;
	static inline SGMatrix4x4 ScaleMatrix(SGScalar factor) SGVECTOR_ALWAYS_INLINE;
	
	inline void				glLoad(void) const SGVECTOR_ALWAYS_INLINE;
	inline void				glLoadTranspose(void) const SGVECTOR_ALWAYS_INLINE;
	inline void				glMult(void) const SGVECTOR_ALWAYS_INLINE;
	inline void				glMultTranspose(void) const SGVECTOR_ALWAYS_INLINE;
	
	inline SGMatrix4x4		&Orthogonalize() SGVECTOR_ALWAYS_INLINE;
	
	inline CFStringRef		CopyDescription() const SGVECTOR_ALWAYS_INLINE;
	#if SGVECTOR_COCOA
	inline NSString			*Description(void) const SGVECTOR_ALWAYS_INLINE;
	#endif
};


SGVECTOR_INLINE SGMatrix4x4 SGMatrix4x4Construct(SGScalar AA, SGScalar AB, SGScalar AC, SGScalar AD,
												 SGScalar BA, SGScalar BB, SGScalar BC, SGScalar BD,
												 SGScalar CA, SGScalar CB, SGScalar CC, SGScalar CD,
												 SGScalar DA, SGScalar DB, SGScalar DC, SGScalar DD)
{
	return SGMatrix4x4(AA, AB, AC, AD,
					   BA, BB, BC, BD,
					   CA, CB, CC, CD,
					   DA, DB, DC, DD);
}

// Only for inline functions - meaning varies between C and C++
typedef const SGMatrix4x4 &SGMatrix4x4Param;

#endif	/* __cplusplus */


SGVECTOR_INLINE void SGMatrix4x4Set(SGMatrix4x4 *matrix,
									  SGScalar AA, SGScalar AB, SGScalar AC, SGScalar AD,
									  SGScalar BA, SGScalar BB, SGScalar BC, SGScalar BD,
									  SGScalar CA, SGScalar CB, SGScalar CC, SGScalar CD,
									  SGScalar DA, SGScalar DB, SGScalar DC, SGScalar DD) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4SetMatrix(SGMatrix4x4 *matrix, SGMatrix4x4Param m) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4SetRowVector3s(SGMatrix4x4 *matrix, SGVector3 i, SGVector3 j, SGVector3 k, SGVector3 o) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4SetIdentity(SGMatrix4x4 *matrix) SGVECTOR_NONNULL;

SGVECTOR_EXTERN SGMatrix4x4 SGMatrix4x4RotationXMatrix(SGScalar angle) SGVECTOR_CONST;
SGVECTOR_EXTERN SGMatrix4x4 SGMatrix4x4RotationYMatrix(SGScalar angle) SGVECTOR_CONST;
SGVECTOR_EXTERN SGMatrix4x4 SGMatrix4x4RotationZMatrix(SGScalar angle) SGVECTOR_CONST;
SGVECTOR_INLINE SGMatrix4x4 SGMatrix4x4ScaleMatrix(SGScalar factorX, SGScalar factorY, SGScalar factorZ) SGVECTOR_CONST;
SGVECTOR_INLINE SGMatrix4x4 SGMatrix4x4UniformScaleMatrix(SGScalar factor) SGVECTOR_ALWAYS_INLINE SGVECTOR_CONST;

SGVECTOR_EXTERN void SGMatrix4x4TransposeInPlace(SGMatrix4x4 *matrix) SGVECTOR_NONNULL;

SGVECTOR_EXTERN bool SGMatrix4x4Equal(SGMatrix4x4 ma, SGMatrix4x4 mb) SGVECTOR_PURE;

#if SGVECTOR_VECTORIZE
SGVECTOR_INLINE SGMatrix4x4 SGMatrix4x4Multiply(SGMatrix4x4 ma, SGMatrix4x4 mb) SGVECTOR_PURE;
#else
SGVECTOR_EXTERN SGMatrix4x4 SGMatrix4x4Multiply(SGMatrix4x4 ma, SGMatrix4x4 mb) SGVECTOR_PURE;
#endif
SGVECTOR_INLINE void SGMatrix4x4MultiplyInPlace(SGMatrix4x4 *ma, SGMatrix4x4 mb) SGVECTOR_PURE SGVECTOR_NONNULL;

SGVECTOR_EXTERN void SGMatrix4x4RotateX(SGMatrix4x4 *matrix, SGScalar angle) SGVECTOR_NONNULL;
SGVECTOR_EXTERN void SGMatrix4x4RotateY(SGMatrix4x4 *matrix, SGScalar angle) SGVECTOR_NONNULL;
SGVECTOR_EXTERN void SGMatrix4x4RotateZ(SGMatrix4x4 *matrix, SGScalar angle) SGVECTOR_NONNULL;
SGVECTOR_EXTERN void SGMatrix4x4RotateAroundUnitAxis(SGMatrix4x4 *matrix, SGVector3 axis, SGScalar angle) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4RotateAroundAxis(SGMatrix4x4 *matrix, SGVector3 axis, SGScalar angle) SGVECTOR_NONNULL;

SGVECTOR_INLINE void SGMatrix4x4TranslateX(SGMatrix4x4 *matrix, SGScalar offset) SGVECTOR_ALWAYS_INLINE SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4TranslateY(SGMatrix4x4 *matrix, SGScalar offset) SGVECTOR_ALWAYS_INLINE SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4TranslateZ(SGMatrix4x4 *matrix, SGScalar offset) SGVECTOR_ALWAYS_INLINE SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4Translate(SGMatrix4x4 *matrix, SGScalar offsetX, SGScalar offsetY, SGScalar offsetZ) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4TranslateVector3(SGMatrix4x4 *matrix, SGVector3Param offset) SGVECTOR_NONNULL;

SGVECTOR_INLINE void SGMatrix4x4ScaleX(SGMatrix4x4 *matrix, SGScalar factor) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4ScaleY(SGMatrix4x4 *matrix, SGScalar factor) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4ScaleZ(SGMatrix4x4 *matrix, SGScalar factor) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4Scale(SGMatrix4x4 *matrix, SGScalar factorX, SGScalar factorY, SGScalar factorZ) SGVECTOR_NONNULL;
SGVECTOR_INLINE void SGMatrix4x4ScaleUniform(SGMatrix4x4 *matrix, SGScalar factor) SGVECTOR_NONNULL;

SGVECTOR_INLINE void SGMatrix4x4GLLoadMatrix(SGMatrix4x4Param matrix) SGVECTOR_ALWAYS_INLINE;
SGVECTOR_INLINE void SGMatrix4x4GLLoadTransposeMatrix(SGMatrix4x4Param matrix) SGVECTOR_ALWAYS_INLINE;
SGVECTOR_INLINE void SGMatrix4x4GLMultMatrix(SGMatrix4x4Param matrix) SGVECTOR_ALWAYS_INLINE;
SGVECTOR_INLINE void SGMatrix4x4GLMultTransposeMatrix(SGMatrix4x4Param matrix) SGVECTOR_ALWAYS_INLINE;

SGVECTOR_EXTERN void SGMatrix4x4Orthogonalize(SGMatrix4x4 *matrix) SGVECTOR_NONNULL;

SGVECTOR_EXTERN CFStringRef SGMatrix4x4CopyDescription(SGMatrix4x4Param v);
#if SGVECTOR_COCOA
SGVECTOR_EXTERN NSString *SGMatrix4x4GetDescription(SGMatrix4x4Param v);
#endif

SGVECTOR_INLINE SGVector3 SGMatrix4x4MultiplySGVector3(SGMatrix4x4Param m, SGVector3Param v) SGVECTOR_CONST;
SGVECTOR_INLINE SGVector3 SGMatrix4x4MultiplySGVector3FromLeft(SGVector3Param v, SGMatrix4x4Param m) SGVECTOR_CONST;
SGVECTOR_INLINE void SGMatrix4x4MultiplySGVector3FromLeftInPlace(SGVector3 *v, SGMatrix4x4Param m);


SGVECTOR_INLINE void SGMatrix4x4Set(SGMatrix4x4 *matrix,
									SGScalar AA, SGScalar AB, SGScalar AC, SGScalar AD,
									SGScalar BA, SGScalar BB, SGScalar BC, SGScalar BD,
									SGScalar CA, SGScalar CB, SGScalar CC, SGScalar CD,
									SGScalar DA, SGScalar DB, SGScalar DC, SGScalar DD)
{
	matrix->m[0][0] = AA; matrix->m[0][1] = AB; matrix->m[0][2] = AC; matrix->m[0][3] = AD;
	matrix->m[1][0] = BA; matrix->m[1][1] = BB; matrix->m[1][2] = BC; matrix->m[1][3] = BD;
	matrix->m[2][0] = CA; matrix->m[2][1] = CB; matrix->m[2][2] = CC; matrix->m[2][3] = CD;
	matrix->m[3][0] = DA; matrix->m[3][1] = DB; matrix->m[3][2] = DC; matrix->m[3][3] = DD;
}


SGVECTOR_INLINE void SGMatrix4x4SetRowVector3s(SGMatrix4x4 *matrix, SGVector3 i, SGVector3 j, SGVector3 k, SGVector3 o)
{
	// Geometrically, i, j and k are basis vectors and o is an offset (translation).
	SGMatrix4x4Set(matrix,
				   i.x, i.y, i.z, 0,
				   j.x, j.y, j.z, 0,
				   k.x, k.y, k.z, 0,
				   o.x, o.y, o.z, 1);
}


SGVECTOR_INLINE void SGMatrix4x4SetMatrix(SGMatrix4x4 *matrix, SGMatrix4x4Param m)
{
	SGMatrix4x4Set(matrix,
				   m.m[0][0], m.m[0][1], m.m[0][2], m.m[0][3],
				   m.m[1][0], m.m[1][1], m.m[1][2], m.m[1][3],
				   m.m[2][0], m.m[2][1], m.m[2][2], m.m[2][3],
				   m.m[3][0], m.m[3][1], m.m[3][2], m.m[3][3]);
}


SGVECTOR_INLINE void SGMatrix4x4SetIdentity(SGMatrix4x4 *matrix)
{
	SGMatrix4x4Set(matrix,
				   1, 0, 0, 0,
				   0, 1, 0, 0,
				   0, 0, 1, 0,
				   0, 0, 0, 1);
}


SGVECTOR_INLINE SGMatrix4x4 SGMatrix4x4ScaleMatrix(SGScalar factorX, SGScalar factorY, SGScalar factorZ)
{
	return SGMatrix4x4Construct(factorX, 0, 0, 0,
								0, factorY, 0, 0,
								0, 0, factorZ, 0,
								0, 0, 0, 1);
}


SGVECTOR_INLINE SGMatrix4x4 SGMatrix4x4UniformScaleMatrix(SGScalar factor)
{
	return SGMatrix4x4ScaleMatrix(factor, factor, factor);
}


#if SGVECTOR_VECTORIZE
SGVECTOR_INLINE SGMatrix4x4 SGMatrix4x4Multiply(SGMatrix4x4 ma, SGMatrix4x4 mb)
{
	SGMatrix4x4 result;
	vMultMatMat_4x4(ma.blasVec,
					mb.blasVec,
					result.blasVec);
	return result;
}
#endif


SGVECTOR_INLINE void SGMatrix4x4MultiplyInPlace(SGMatrix4x4 *ma, SGMatrix4x4 mb)
{
	SGMatrix4x4SetMatrix(ma, SGMatrix4x4Multiply(*ma, mb));
}


SGVECTOR_INLINE SGMatrix4x4 SGMatrix4x4Transpose(SGMatrix4x4 matrix)
{
	SGMatrix4x4TransposeInPlace(&matrix);
	return matrix;
}


SGVECTOR_INLINE void SGMatrix4x4RotateAroundAxis(SGMatrix4x4 *matrix, SGVector3 axis, SGScalar angle)
{
	return SGMatrix4x4RotateAroundUnitAxis(matrix, SGVector3Normal(axis), angle);
}


SGVECTOR_INLINE void SGMatrix4x4TranslateX(SGMatrix4x4 *matrix, SGScalar offset)
{
	matrix->m[3][0] += offset;
}


SGVECTOR_INLINE void SGMatrix4x4TranslateY(SGMatrix4x4 *matrix, SGScalar offset)
{
	matrix->m[3][1] += offset;
}


SGVECTOR_INLINE void SGMatrix4x4TranslateZ(SGMatrix4x4 *matrix, SGScalar offset)
{
	matrix->m[3][2] += offset;
}


SGVECTOR_INLINE void SGMatrix4x4Translate(SGMatrix4x4 *matrix, SGScalar offsetX, SGScalar offsetY, SGScalar offsetZ)
{
	matrix->m[3][0] += offsetX;
	matrix->m[3][1] += offsetY;
	matrix->m[3][2] += offsetZ;
}


SGVECTOR_INLINE void SGMatrix4x4TranslateVector3(SGMatrix4x4 *matrix, SGVector3Param offset)
{
	matrix->m[3][0] += offset.x;
	matrix->m[3][1] += offset.y;
	matrix->m[3][2] += offset.z;
}


SGVECTOR_INLINE void SGMatrix4x4ScaleX(SGMatrix4x4 *matrix, SGScalar factor)
{
	matrix->m[0][0] *= factor;
	matrix->m[1][0] *= factor;
	matrix->m[2][0] *= factor;
}


SGVECTOR_INLINE void SGMatrix4x4ScaleY(SGMatrix4x4 *matrix, SGScalar factor)
{
	matrix->m[0][1] *= factor;
	matrix->m[1][1] *= factor;
	matrix->m[2][1] *= factor;
}


SGVECTOR_INLINE void SGMatrix4x4ScaleZ(SGMatrix4x4 *matrix, SGScalar factor)
{
	matrix->m[0][2] *= factor;
	matrix->m[1][2] *= factor;
	matrix->m[2][2] *= factor;
}


SGVECTOR_INLINE void SGMatrix4x4Scale(SGMatrix4x4 *matrix, SGScalar factorX, SGScalar factorY, SGScalar factorZ)
{
	SGMatrix4x4ScaleX(matrix, factorX);
	SGMatrix4x4ScaleY(matrix, factorY);
	SGMatrix4x4ScaleZ(matrix, factorZ);
}


SGVECTOR_INLINE void SGMatrix4x4ScaleUniform(SGMatrix4x4 *matrix, SGScalar factor)
{
	SGMatrix4x4Scale(matrix, factor, factor, factor);
}


SGVECTOR_INLINE void SGMatrix4x4GLLoadMatrix(SGMatrix4x4Param matrix)
{
#if SGVECTOR_DOUBLE_PRECISION
	glLoadMatrixd(matrix.vals);
#else
	glLoadMatrixf(matrix.vals);
#endif
}


SGVECTOR_INLINE void SGMatrix4x4GLLoadTransposeMatrix(SGMatrix4x4Param matrix)
{
#if SGVECTOR_DOUBLE_PRECISION
	glLoadTransposeMatrixd(matrix.vals);
#else
	glLoadTransposeMatrixf(matrix.vals);
#endif
}


SGVECTOR_INLINE void SGMatrix4x4GLMultMatrix(SGMatrix4x4Param matrix)
{
#if SGVECTOR_DOUBLE_PRECISION
	glMultMatrixd(matrix.vals);
#else
	glMultMatrixf(matrix.vals);
#endif
}


SGVECTOR_INLINE void SGMatrix4x4GLMultTransposeMatrix(SGMatrix4x4Param matrix)
{
#if SGVECTOR_DOUBLE_PRECISION
	glMultTransposeMatrixd(matrix.vals);
#else
	glMultTransposeMatrixf(matrix.vals);
#endif
}


SGVECTOR_INLINE SGVector3 SGMatrix4x4MultiplySGVector3(SGMatrix4x4Param m, SGVector3Param v)
{
	return SGVector3Construct(m.m[0][0] * v.x + m.m[0][1] * v.y + m.m[0][2] * v.z + m.m[0][3],
							  m.m[1][0] * v.x + m.m[1][1] * v.y + m.m[1][2] * v.z + m.m[1][3],
							  m.m[2][0] * v.x + m.m[2][1] * v.y + m.m[2][2] * v.z + m.m[2][3]);
}


SGVECTOR_INLINE SGVector3 SGMatrix4x4MultiplySGVector3FromLeft(SGVector3Param v, SGMatrix4x4Param m)
{
	return SGVector3Construct(m.m[0][0] * v.x + m.m[1][0] * v.y + m.m[2][0] * v.z + m.m[3][0],
							  m.m[0][1] * v.x + m.m[1][1] * v.y + m.m[2][1] * v.z + m.m[3][1],
							  m.m[0][2] * v.x + m.m[1][2] * v.y + m.m[2][2] * v.z + m.m[3][2]);
}


SGVECTOR_INLINE void SGMatrix4x4MultiplySGVector3FromLeftInPlace(SGVector3 *v, SGMatrix4x4Param m)
{
	*v = SGMatrix4x4MultiplySGVector3FromLeft(*v, m);
}


#if __cplusplus

// SGMatrix4x4 implementation
inline SGMatrix4x4::SGMatrix4x4()
{
	SGMatrix4x4SetIdentity(this);
}


inline SGMatrix4x4::SGMatrix4x4(SGScalar AA, SGScalar AB, SGScalar AC, SGScalar AD,
								SGScalar BA, SGScalar BB, SGScalar BC, SGScalar BD,
								SGScalar CA, SGScalar CB, SGScalar CC, SGScalar CD,
								SGScalar DA, SGScalar DB, SGScalar DC, SGScalar DD)
{
	SGMatrix4x4Set(this,
				   AA, AB, AC, AD,
				   BA, BB, BC, BD,
				   CA, CB, CC, CD,
				   DA, DB, DC, DD);
}


inline SGMatrix4x4::SGMatrix4x4(SGVector3 i, SGVector3 j, SGVector3 k, SGVector3 o)
{
	SGMatrix4x4SetRowVector3s(this, i, j, k, o);
}


/*inline SGMatrix4x4::SGMatrix4x4(const SGMatrix4x4 &m)
{
	SGMatrix4x4SetMatrix(this, m);
}*/


inline void SGMatrix4x4::Set(SGScalar AA, SGScalar AB, SGScalar AC, SGScalar AD,
							 SGScalar BA, SGScalar BB, SGScalar BC, SGScalar BD,
							 SGScalar CA, SGScalar CB, SGScalar CC, SGScalar CD,
							 SGScalar DA, SGScalar DB, SGScalar DC, SGScalar DD)
{
	SGMatrix4x4Set(this,
				   AA, AB, AC, AD,
				   BA, BB, BC, BD,
				   CA, CB, CC, CD,
				   DA, DB, DC, DD);
}


inline void SGMatrix4x4::Set(SGVector3 i, SGVector3 j, SGVector3 k, SGVector3 o)
{
	SGMatrix4x4SetRowVector3s(this, i, j, k, o);
}


inline void SGMatrix4x4::SetIdentity()
{
	SGMatrix4x4SetIdentity(this);
}


inline void SGMatrix4x4::Transpose()
{
	SGMatrix4x4TransposeInPlace(this);
}


inline SGMatrix4x4 SGMatrix4x4::Transpose() const
{
	return SGMatrix4x4Transpose(*this);
}


inline bool SGMatrix4x4::operator==(const SGMatrix4x4 &inMatrix) const
{
	return SGMatrix4x4Equal(*this, inMatrix);
}


inline bool SGMatrix4x4::operator!=(const SGMatrix4x4 &inMatrix) const
{
	return !SGMatrix4x4Equal(*this, inMatrix);
}


inline SGMatrix4x4 SGMatrix4x4::operator*(const SGMatrix4x4 &inMatrix) const
{
	return SGMatrix4x4Multiply(*this, inMatrix);
}


inline SGMatrix4x4 &SGMatrix4x4::operator*=(const SGMatrix4x4 &inMatrix)
{
	SGMatrix4x4MultiplyInPlace(this, inMatrix);
	return *this;
}


inline SGMatrix4x4 SGMatrix4x4::RotationXMatrix(SGScalar angle)
{
	return SGMatrix4x4RotationXMatrix(angle);
}


inline SGMatrix4x4 SGMatrix4x4::RotationYMatrix(SGScalar angle)
{
	return SGMatrix4x4RotationYMatrix(angle);
}


inline SGMatrix4x4 SGMatrix4x4::RotationZMatrix(SGScalar angle)
{
	return SGMatrix4x4RotationZMatrix(angle);
}


inline SGMatrix4x4 &SGMatrix4x4::RotateX(SGScalar angle)
{
	SGMatrix4x4RotateX(this, angle);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::RotateY(SGScalar angle)
{
	SGMatrix4x4RotateY(this, angle);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::RotateZ(SGScalar angle)
{
	SGMatrix4x4RotateZ(this, angle);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::RotateAroundUnitAxis(SGVector3 axis, SGScalar angle)
{
	SGMatrix4x4RotateAroundUnitAxis(this, axis, angle);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::RotateAroundAxis(SGVector3 axis, SGScalar angle)
{
	SGMatrix4x4RotateAroundAxis(this, axis, angle);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::TranslateX(SGScalar offset)
{
	SGMatrix4x4TranslateX(this, offset);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::TranslateY(SGScalar offset)
{
	SGMatrix4x4TranslateY(this, offset);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::TranslateZ(SGScalar offset)
{
	SGMatrix4x4TranslateZ(this, offset);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::Translate(SGScalar offsetX, SGScalar offsetY, SGScalar offsetZ)
{
	SGMatrix4x4Translate(this, offsetX, offsetY, offsetZ);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::Translate(const SGVector3 &offset)
{
	SGMatrix4x4TranslateVector3(this, offset);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::ScaleX(SGScalar factor)
{
	SGMatrix4x4ScaleX(this, factor);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::ScaleY(SGScalar factor)
{
	SGMatrix4x4ScaleY(this, factor);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::ScaleZ(SGScalar factor)
{
	SGMatrix4x4ScaleZ(this, factor);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::Scale(SGScalar factorX, SGScalar factorY, SGScalar factorZ)
{
	SGMatrix4x4Scale(this, factorX, factorY, factorZ);
	return *this;
}


inline SGMatrix4x4 &SGMatrix4x4::Scale(SGScalar factor)
{
	SGMatrix4x4ScaleUniform(this, factor);
	return *this;
}


inline SGMatrix4x4 SGMatrix4x4::ScaleMatrix(SGScalar factorX, SGScalar factorY, SGScalar factorZ)
{
	return SGMatrix4x4ScaleMatrix(factorX, factorY, factorZ);
}


inline SGMatrix4x4 SGMatrix4x4::ScaleMatrix(SGScalar factor)
{
	return SGMatrix4x4UniformScaleMatrix(factor);
}


inline void SGMatrix4x4::glLoad(void) const
{
	SGMatrix4x4GLLoadMatrix(*this);
}


inline void SGMatrix4x4::glLoadTranspose(void) const
{
	SGMatrix4x4GLLoadTransposeMatrix(*this);
}


inline void SGMatrix4x4::glMult(void) const
{
	SGMatrix4x4GLMultMatrix(*this);
}


inline void SGMatrix4x4::glMultTranspose(void) const
{
	SGMatrix4x4GLMultTransposeMatrix(*this);
}


inline SGMatrix4x4 &SGMatrix4x4::Orthogonalize()
{
	SGMatrix4x4Orthogonalize(this);
	return *this;
}


inline CFStringRef SGMatrix4x4::CopyDescription() const
{
	return SGMatrix4x4CopyDescription(*this);
}


#if SGVECTOR_COCOA
inline NSString *SGMatrix4x4::Description() const
{
	return SGMatrix4x4GetDescription(*this);
}
#endif


static inline const SGVector3 operator*(const SGMatrix4x4 &m, const SGVector3 &v)
{
	return SGMatrix4x4MultiplySGVector3(m, v);
}


static inline const SGVector3 operator*(const SGVector3 &v, const SGMatrix4x4 &m)
{
	return SGMatrix4x4MultiplySGVector3FromLeft(v, m);
}


static inline const SGVector3 &operator*=(SGVector3 &v, const SGMatrix4x4 &m)
{
	SGMatrix4x4MultiplySGVector3FromLeftInPlace(&v, m);
	return v;
}

#endif	/* __cplusplus */
#endif	/* INCLUDED_SGMATRIXTYPES_h */
