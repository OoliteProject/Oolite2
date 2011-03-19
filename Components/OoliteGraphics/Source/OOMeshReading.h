/*
	OOMeshReading.h
	
	
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

#import <OoliteBase/OoliteBase.h>

@class OOAbstractMesh;
@class OORenderMesh;

@protocol OOProgressReporting;


@protocol OOMeshReading <NSObject>

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues;

- (void) parse;

- (void) getRenderMesh:(OORenderMesh **)renderMesh andMaterialSpecs:(NSArray **)materialSpecifications;

#if !OOLITE_LEAN
- (OOAbstractMesh *) abstractMesh;

// True if it is more efficient to load the abstract mesh, false if it is more efficient to load the render mesh.
- (BOOL) prefersAbstractMesh;

- (NSString *) meshName;
- (NSString *) meshDescription;
#endif

@end


Class OOSelectMeshReaderForExtension(NSString *fileNameExtension);

#if !OOLITE_LEAN
Class OOSelectMeshReaderForUTI(NSString *uti);
#endif

id <OOMeshReading> OOReadMeshFromFile(NSString *path, id < OOProgressReporting> progressReporter, id <OOProblemReporting> issues);
