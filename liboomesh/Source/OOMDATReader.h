/*
	OOMDATReader.h
	
	Parser for Oolite 1.x DAT files.
	
	
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


#import <Foundation/Foundation.h>

@protocol OOMProblemReportManager;
@class OOMVertex, OOMDATLexer, OOMMesh;


@interface OOMDATReader: NSObject
{
@private
	id <OOMProblemReportManager>	_issues;
	NSString						*_path;
	OOMDATLexer						*_lexer;
	
	OOMMesh							*_mesh;
	
	unsigned						_smoothing: 1,
									_brokenSmoothing: 1,
									_explicitNormals: 1,
									_explicitTangents: 1,
									_usesSmoothGroups: 1,
									_haveTriangleAreas: 1;
	
	NSUInteger						_materialCount;
	NSUInteger						_fileVertexCount;
	NSUInteger						_fileFaceCount;
	
	// ivars used only during parsing.
	struct RawDATTriangle			*_rawTriangles;
	OOMVertex						**_fileVertices;
	struct VertexFaceRef			*_faceRefs;
	NSMutableArray					*_materialKeys;
}

- (id) initWithPath:(NSString *)path issues:(id <OOMProblemReportManager>)ioIssues;

- (void) parse;

- (OOMMesh *) mesh;

/*	Smoothing:
	Before parsing, this determines whether smoothing should be applied to
	meshes without per-vertex normals.
	After parsing, it is NO for meshes without per-vertex normals which were
	not smoothed, and YES for meshes which were smoothed or had per-vertex
	normals. After parsing it cannot be changed with -setSmooth:.
*/
- (BOOL) smoothing;
- (void) setSmoothing:(BOOL)value;

/*	BrokenSmoothing:
	Oolite's smoothing algorithm calculates triangle weights incorrectly. If
	smoothing is used and brokenSmoothing is set (default: YES), this
	behaviour is replicated. Otherwise, a correct implementation is used.
	After parsing, brokenSmoothing is YES only if smoothing was applied and
	broken smoothing was in effect at the time, and can't be changed.
*/
- (BOOL) brokenSmoothing;
- (void) setBrokenSmoothing:(BOOL)value;

/*	Vertex count and face count of file, which won't necessarily match the
	counts of the loaded mesh.
*/
- (NSUInteger) fileVertexCount;
- (NSUInteger) fileFaceCount;

@end
