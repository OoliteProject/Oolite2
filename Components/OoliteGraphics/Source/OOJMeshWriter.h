/*
	OOJMeshWriter.h
	
	OOJMesh (Oolite 2.0) format exporter.
	
	
	Copyright © 2010 Jens Ayton.
	
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

#if !OOLITE_LEAN

#import <OoliteBase/OoliteBase.h>

@protocol OOProblemReporting;
@class OOAbstractMesh;


typedef NSUInteger OOJMeshWriteOptions;
enum
{
	/*	kOOJMeshWriteWithAnnotations
		If this flag is set, informative comments are added. This is disabled
		if kOOJMeshWriteJSONCompatible is set.
	*/
	kOOJMeshWriteWithAnnotations			= 0x00000001UL,
	
	/*	kOOJMeshWriteWithExtendedAnnotations
		If this flag is set (along with kOOJMeshWriteWithAnnotations),
		additional comments are added - currently, a use count for each verte
		in the position attribute.
	*/
	kOOJMeshWriteWithExtendedAnnotations	= 0x00000002UL,
	
	/*	kOOJMeshWriteJSONCompatible
		If this flag is set, no comments are written (overriding the
		kOOJMeshWriteWithAnnotations flag) and all keys are quoted.
	*/
	kOOJMeshWriteJSONCompatible				= 0x00000004UL
};


NSData *OOJMeshDataFromMesh(OOAbstractMesh *mesh, OOJMeshWriteOptions options, id <OOProblemReporting> issues);
BOOL OOWriteOOJMesh(OOAbstractMesh *mesh, NSString *path, OOJMeshWriteOptions options, id <OOProblemReporting> issues);

#endif	// OOLITE_LEAN
