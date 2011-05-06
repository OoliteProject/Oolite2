/*
	OOOBJWriter.h
	
	WaveFront OBJ format exporter.
	
	
	Copyright © 2011 Jens Ayton.
	
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


/*
	NOTE: OBJ format requires two files, the OBJ file and a MTL (material
	library) file. OOOBJDataFromMesh() provides the material data through the
	outMtlData parameter. OOWriteOBJ() will write the MTL file next to the OBJ
	file, overwriting any existing file of the same name!
	
	The name parameter to OOOBJDataFromMesh() is the expected file name. This
	is used to generate a MTL file name (passed out in the optional **outMtlName
	parameter). This is used to find the MTL file when loading the OBJ.
*/
NSData *OOOBJDataFromMesh(OOAbstractMesh *mesh, NSString *name, NSData **outMtlData, NSString **outMtlName, id <OOProblemReporting> issues);
BOOL OOWriteOBJ(OOAbstractMesh *mesh, NSString *path, id <OOProblemReporting> issues);

#endif	// OOLITE_LEAN
