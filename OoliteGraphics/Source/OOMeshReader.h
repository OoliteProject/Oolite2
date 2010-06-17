/*
	OOMeshReader.h
	
	Parser for Oolite 2.x oomesh files.
	
	
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


#import "OOMeshReading.h"

@class OOAbstractVertex, OOMeshLexer;


@interface OOMeshReader: NSObject <OOMeshReading>
{
@private
	id <OOProblemReporting>			_issues;
	NSString						*_path;
	OOMeshLexer						*_lexer;
	
	OOAbstractMesh					*_abstractMesh;
	OORenderMesh					*_renderMesh;
	
	NSString						*_meshName;
	NSUInteger						_vertexCount;
	NSMutableDictionary				*_attributeArrays;
	
	NSMutableArray					*_groupIndexArrays;
	NSMutableArray					*_groupMaterials;
	
	// ivars used only during parsing.
	NSMutableSet					*_unknownSectionTypes;
	NSMutableDictionary				*_materialsByName;
}

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues;

- (void) parse;

#if !OOLITE_LEAN
- (OOAbstractMesh *) abstractMesh;
#endif

- (void) getRenderMesh:(OORenderMesh **)renderMesh andMaterialSpecs:(NSArray **)materialSpecifications;

@end
