/*

OOGeometryGLHelpers.h

Function-like macros to deal with Oolite geometry types and OpenGL.

These are macros rather than inline functions in order to work with macro GL
under Mac OS X.


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


#import <OoliteBase/OoliteBase.h>
#import "OOOpenGL.h"


#define GLVertexOOVector(v) do { Vector v_ = v; glVertex3f(v_.x, v_.y, v_.z); } while (0)
#define GLTranslateOOVector(v) do { Vector v_ = v; OOGL(glTranslatef(v_.x, v_.y, v_.z)); } while (0)


#define OOMatrixValuesForOpenGL(M) (&(M).m[0][0])
#define GLMultOOMatrix(M) do { OOMatrix m_ = M; OOGL(glMultMatrixf(OOMatrixValuesForOpenGL(m_))); } while (0)
#define GLLoadOOMatrix(M) do { OOMatrix m_ = M; OOGL(glLoadMatrixf(OOMatrixValuesForOpenGL(m_))); } while (0)
#define GLMultTransposeOOMatrix(M) do { OOMatrix m_ = M; OOGL(glMultTransposeMatrixf(OOMatrixValuesForOpenGL(m_))); } while (0)
#define GLLoadTransposeOOMatrix(M) do { OOMatrix m_ = M; OOGL(glLoadTransposeMatrixf(OOMatrixValuesForOpenGL(m_))); } while (0)
#define GLUniformMatrix(location, M) do { OOGL(glUniformMatrix4fvARB(location, 1, NO, OOMatrixValuesForOpenGL(M))); } while (0)


// OOMatrix OOMatrixLoadGLMatrix(GLenum matrixID)
#define OOMatrixLoadGLMatrix(matrixID) ({ OOMatrix m; glGetFloatv(matrixID, OOMatrixValuesForOpenGL(m)); m; })
