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

#if !OOLITE_LEAN

#import "OOMeshReading.h"

@protocol OOOBJMaterialLibraryResolving;
@class OOOBJLexer, OOAbstractMesh, OOAbstractFaceGroup, OOMaterialSpecification;


@interface OOOBJReader: NSObject <OOMeshReading>
{
@private
	id <OOProblemReporting>				_issues;
	id <OOProgressReporting>			_progressReporter;
	float								_lastProgress;
	NSString							*_path;
	OOOBJLexer							*_lexer;
	id <OOOBJMaterialLibraryResolving>	_resolver;
	
	OOAbstractMesh						*_abstractMesh;
	NSString							*_name;
	
	unsigned							_warnedAboutCurves: 1,
										_warnedAboutRenderAttribs: 1,
										_warnedAboutLinesOrPoints: 1,
										_warnedAboutUnknown: 1,
										_haveAllTexCoords: 1,
										_haveAllNormals: 1;
	
	NSInteger							_positionCount;
	NSInteger							_texCoordCount;
	NSInteger							_normalCount;
	NSUInteger							_faceCount;
	
	// ivars used only during parsing.
	NSMutableArray						*_positions;
	NSMutableArray						*_texCoords;
	NSMutableArray						*_normals;
	NSMutableArray						*_currentSmoothGroup;
	NSMutableDictionary					*_smoothGroups;
	NSMutableDictionary					*_materials;
	NSMutableDictionary					*_materialGroups;
	NSMutableDictionary					*_vertexCache;
	OOAbstractFaceGroup					*_currentGroup;
	
	// ivars used only during material library parsing.
	OOMaterialSpecification				*_currentMaterial;
	NSString							*_currentMaterialLibraryName;
}

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues;

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues
		   resolver:(id <OOOBJMaterialLibraryResolving>)resolver;

- (void) parse;
- (OOAbstractMesh *) abstractMesh;
- (void) getRenderMesh:(OORenderMesh **)renderMesh andMaterialSpecs:(NSArray **)materialSpecifications;

- (NSString *) name;

@end


/*	OBJ files may refer to one or more “material library” files. The resolver
	is responsible for finding these.
	If none is specified, a default resolver will look adjacent to the 
*/
@protocol OOOBJMaterialLibraryResolving <NSObject>

- (NSData *) oo_objReader:(OOOBJReader *)reader findMaterialLibrary:(NSString *)fileName;

@end

#endif	// OOLITE_LEAN
