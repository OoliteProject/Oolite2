/*
	OOOBJReader.h
	
	Parser for OpenCTM files.
	
	
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

#import "OOMeshReading.h"


@interface OOCTMReader: NSObject <OOMeshReading>
{
@private
	id <OOProblemReporting>				_issues;
	id <OOProgressReporting>			_progressReporter;
	NSString							*_path;
	
	NSString							*_name;
	NSString							*_comment;
	
	BOOL								_parsed;
	
	uint32_t							_vertexCount;
	uint32_t							_faceCount;
	
	OORenderMesh						*_renderMesh;
	NSArray								*_materials;
	
	// Used only while parsing.
	void								*_ctmContext;
	NSMutableDictionary					*_attributes;
}

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues;

- (void) parse;
- (OOAbstractMesh *) abstractMesh;
- (void) getRenderMesh:(OORenderMesh **)renderMesh andMaterialSpecs:(NSArray **)materialSpecifications;

- (NSString *) fileComment;

@end

#endif	// OOLITE_LEAN
