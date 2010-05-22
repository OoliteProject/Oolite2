//
//  OOMDATReader.h
//  oomesh
//
//  Created by Jens Ayton on 2010-05-21.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OOMProblemReportManager;
@class OOMVertex, OOMDATLexer;


@interface OOMDATReader: NSObject
{
@private
	id <OOMProblemReportManager>	_issues;
	NSString						*_path;
	OOMDATLexer						*_lexer;
	
	BOOL							_smoothing;
	BOOL							_brokenSmoothing;
	BOOL							_explicitNormals;
	BOOL							_explicitTangents;
	
	OOUInteger						_fileVertexCount;
	OOUInteger						_fileFaceCount;
	
	NSMutableSet					*_materialKeys;
}

- (id) initWithPath:(NSString *)path issues:(id <OOMProblemReportManager>)ioIssues;

- (void) parse;

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
- (OOUInteger) fileVertexCount;
- (OOUInteger) fileFaceCount;

@end
