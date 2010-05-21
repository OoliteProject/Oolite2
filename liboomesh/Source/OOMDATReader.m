//
//  OOMDATReader.m
//  oomesh
//
//  Created by Jens Ayton on 2010-05-21.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "OOMDATReader.h"
#import "OOMProblemReportManager.h"
#import "OOMDATLexer.h"
#import "OOMVertex.h"


static void CleanVector(Vector *v)
{
	/*	Avoid duplicate vertices that differ only in sign of 0. This happens
		quite easily in practice.
	 */
	if (v->x == -0.0f)  v->x = 0.0f;
	if (v->y == -0.0f)  v->y = 0.0f;
	if (v->z == -0.0f)  v->z = 0.0f;
}


@implementation OOMDATReader


- (id) initWithPath:(NSString *)path issues:(id <OOMProblemReportManager>)ioIssues
{
	if ((self = [super init]))
	{
		_issues = [ioIssues retain];
		_path = [path copy];
		_lexer = [[DDDATLexer alloc] initWithPath:_path issues:_issues];
		if (_lexer == nil)  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_path);
	DESTROY(_lexer);
	
	[super dealloc];
}


- (void) reportParseError:(NSString *)format, ...
{
	NSString *base = OOMLocalizeProblemString(_issues, @"Parse error on line %u of %@: %@.");
	format = OOMLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [_lexer lineNumber], [_path lastPathComponent], format];
	[_issues addProblemOfType:kOOMProblemTypeError key:@"parseError" message:message];
}


- (void) reportBasicParseError:(NSString *)expected
{
	[self reportParseError:@"expected %@, got %@", expected, [_lexer currentTokenString]];
}


- (void) parse
{
	if (_lexer == nil)  return;
	
	BOOL			OK = YES;
	NSMutableArray	*fileVertices = nil;
	OOUInteger		vIter;
	
	// Get vertex count.
	if (OK)
	{
		OK = [_lexer expectLiteral:"NVERTS"] && [_lexer readInteger:&_fileVertexCount];
		if (!OK)  [self reportBasicParseError:@"NVERTS"];
	}
	
	// Get face count.
	if (OK)
	{
		OK = [_lexer expectLiteral:"NFACES"] && [_lexer readInteger:&_fileFaceCount];
		if (!OK)  [self reportBasicParseError:@"NFACES"];
	}
	
	// Load vertices.
	if (OK)
	{
		OK = [_lexer expectLiteral:"VERTEX"];
		if (!OK)  [self reportBasicParseError:@"VERTEX"];
	}
	if (OK)
	{
		fileVertices = [NSMutableArray arrayWithCapacity:_fileVertexCount];
		if (fileVertices == nil)
		{
			OK = NO;
			OOMReportError(_issues, @"allocFailed", @"Not enough memory to read %@.", [_path lastPathComponent]);
		}
	}
	if (OK)
	{
		for (vIter = 0; vIter < _fileVertexCount; vIter++)
		{
			Vector v;
			OK = [_lexer readReal:&v.x] && [_lexer readReal:&v.y] && [_lexer readReal:&v.z];
			if (!OK)
			{
				[self reportBasicParseError:@"number"];
				break;
			}
			CleanVector(&v);
			
			[fileVertices addObject:[OOMVertex vertexWithPosition:v]];
		}
	}
	
	if (OK)
	{
		for (vIter = 0; vIter < _fileVertexCount; vIter++)
		{
			Vector v = [[fileVertices oom_vertexAtIndex:vIter] position];
			printf("%g, %g, %g\n", v.x, v.y, v.z);
		}
	}
	
	DESTROY(_lexer);
}


- (OOUInteger) fileVertexCount
{
	[self parse];
	return _fileVertexCount;
}


- (OOUInteger) fileFaceCount
{
	[self parse];
	return _fileFaceCount;
}

@end
