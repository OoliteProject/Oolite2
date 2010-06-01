/*
	OOOBJReader.h
	
	Parser for Wavefront OBJ files.
	
	
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

@protocol OOOBJMaterialLibraryResolver;
@class OOOBJLexer, OOAbstractMesh;


@interface OOOBJReader: NSObject <OOMeshReading>
{
@private
	id <OOProblemReportManager>			_issues;
	NSString							*_path;
	OOOBJLexer							*_lexer;
	id <OOOBJMaterialLibraryResolver>	_resolver;
	
	NSString							*_name;
	
	BOOL								_warnedAboutCurves;
	BOOL								_warnedAboutRenderAttribs;
	BOOL								_warnedAboutLinesOrPoints;
	BOOL								_warnedAboutUnknown;
	
	// ivars used only during parsing.
	NSMutableArray						*_positions;
	NSMutableArray						*_normals;
	NSMutableArray						*_texCoords;
}

- (id) initWithPath:(NSString *)path issues:(id <OOProblemReportManager>)issues;
- (id) initWithPath:(NSString *)path issues:(id <OOProblemReportManager>)issues resolver:(id <OOOBJMaterialLibraryResolver>)resolver;

- (void) parse;
- (OOAbstractMesh *) abstractMesh;

@end


/*	OBJ files may refer to one or more “material library” files. The resolver
	is responsible for finding these.
	If none is specified, a default resolver will look adjacent to the 
*/
@protocol OOOBJMaterialLibraryResolver <NSObject>

- (NSData *) oo_objReader:(OOOBJReader *)reader findMaterialLibrary:(NSString *)fileName;

@end

