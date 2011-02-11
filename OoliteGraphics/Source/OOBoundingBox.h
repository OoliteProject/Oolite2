/*

OOBoundingBox.h


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

#include <OoliteBase/OOMaths.h>


typedef struct OOBoundingBox
{
	Vector		min;
	Vector		max;
} OOBoundingBox;


extern const OOBoundingBox kOOZeroBoundingBox;		/* (0, 0, 0), (0, 0, 0) */


/* Extend bounding box to contain specified point. */
OOINLINE void OOBoundingBoxAddVector(OOBoundingBox *box, Vector vec)  NONNULL_FUNC;
OOINLINE void OOBoundingBoxAddXYZ(OOBoundingBox *box, GLfloat x, GLfloat y, GLfloat z)  NONNULL_FUNC;

OOINLINE void OOBoundingBoxMerge(OOBoundingBox *box, OOBoundingBox other)  NONNULL_FUNC;

/* Reset bounding box to a zero-sized box surrounding specified vector. */
OOINLINE void OOBoundingBoxResetToVector(OOBoundingBox *box, Vector vec)  ALWAYS_INLINE_FUNC NONNULL_FUNC;

OOINLINE void OOBoundingBoxGetDimensions(OOBoundingBox bb, GLfloat *xSize, GLfloat *ySize, GLfloat *zSize)  ALWAYS_INLINE_FUNC;



/*** Only inline definitions beyond this point ***/

OOINLINE void OOBoundingBoxAddVector(OOBoundingBox *box, Vector vec)
{
	assert(box != NULL);
	box->min.x = fminf(box->min.x, vec.x);
	box->max.x = fmaxf(box->max.x, vec.x);
	box->min.y = fminf(box->min.y, vec.y);
	box->max.y = fmaxf(box->max.y, vec.y);
	box->min.z = fminf(box->min.z, vec.z);
	box->max.z = fmaxf(box->max.z, vec.z);
}


OOINLINE void OOBoundingBoxAddXYZ(OOBoundingBox *box, GLfloat x, GLfloat y, GLfloat z)
{
	assert(box != NULL);
	box->min.x = fminf(box->min.x, x);
	box->max.x = fmaxf(box->max.x, x);
	box->min.y = fminf(box->min.y, y);
	box->max.y = fmaxf(box->max.y, y);
	box->min.z = fminf(box->min.z, z);
	box->max.z = fmaxf(box->max.z, z);
}


OOINLINE void OOBoundingBoxMerge(OOBoundingBox *box, OOBoundingBox other)
{
	OOBoundingBoxAddVector(box, other.min);
	OOBoundingBoxAddVector(box, other.max);
}


OOINLINE void OOBoundingBoxResetToVector(OOBoundingBox *box, Vector vec)
{
	assert(box != NULL);
	box->min = vec;
	box->max = vec;
}


OOINLINE void OOBoundingBoxGetDimensions(OOBoundingBox bb, GLfloat *xSize, GLfloat *ySize, GLfloat *zSize)
{
	if (xSize != NULL)  *xSize = bb.max.x - bb.min.y;
	if (ySize != NULL)  *ySize = bb.max.y - bb.min.y;
	if (zSize != NULL)  *zSize = bb.max.z - bb.min.z;
}
