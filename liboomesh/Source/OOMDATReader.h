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
	
	OOUInteger						_fileVertexCount;
	OOUInteger						_fileFaceCount;
}

- (id) initWithPath:(NSString *)path issues:(id <OOMProblemReportManager>)ioIssues;

- (void) parse;

/*	Vertex count and face count of file, which won't necessarily match the
	counts of the loaded mesh.
*/
- (OOUInteger) fileVertexCount;
- (OOUInteger) fileFaceCount;

@end
