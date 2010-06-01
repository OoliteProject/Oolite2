/*
	OOOBJReader.m
	
	
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

#import "OOOBJReader.h"
#import "OOOBJLexer.h"
#import "OOProblemReportManager.h"
#import "OOAbstractVertex.h"


@interface OOOBJReader (Private) <OOOBJMaterialLibraryResolver>

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)expected;
- (void) priv_reportMallocFailure;

- (NSString *) priv_displayName;

- (BOOL) priv_readVertexPosition;
- (BOOL) priv_readVertexNormal;
- (BOOL) priv_readVertexTexCoords;
- (BOOL) priv_readFace;
- (BOOL) priv_readMaterialLibrary;
- (BOOL) priv_readObjectName;

- (BOOL) priv_notifyIgnoredKeyword:(NSString *)keyword;

@end


@implementation OOOBJReader

- (id) initWithPath:(NSString *)path issues:(id <OOProblemReportManager>)issues
{
	return [self initWithPath:path issues:issues resolver:nil];
}


- (id) initWithPath:(NSString *)path issues:(id <OOProblemReportManager>)issues resolver:(id <OOOBJMaterialLibraryResolver>)resolver
{
	if ((self = [super init]))
	{
		if (resolver == nil)  resolver = self;
		
		_issues = [issues retain];
		_path = [path copy];
		_resolver = [resolver retain];
		
		_lexer = [[OOOBJLexer alloc] initWithPath:_path issues:_issues];
		if (_lexer == nil)  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_path);
	DESTROY(_resolver);
	DESTROY(_lexer);
	
	[super dealloc];
}


- (void) parse
{
	if (_lexer == nil)  return;
	
	BOOL OK = YES;
	
	for (;;)
	{
		if ([_lexer isAtEnd])  break;
		
		NSString *keyword = nil;
		OK = [_lexer readString:&keyword];
		if (!OK)
		{
			[self priv_reportBasicParseError:@"keyword"];
			break;
		}
		
		if ([keyword isEqualToString:@"v"])  OK = [self priv_readVertexPosition];
		else if ([keyword isEqualToString:@"vn"])  OK = [self priv_readVertexNormal];
		else if ([keyword isEqualToString:@"vt"])  OK = [self priv_readVertexTexCoords];
		else if ([keyword isEqualToString:@"f"])  OK = [self priv_readFace];
		else if ([keyword isEqualToString:@"mtllib"])  OK = [self priv_readMaterialLibrary];
		else if ([keyword isEqualToString:@"o"])  OK = [self priv_readObjectName];
		else if ([keyword isEqualToString:@"g"])  OK = [_lexer skipLine];
		else if ([keyword isEqualToString:@"mg"])  OK = [_lexer skipLine];
		else  OK = [self priv_notifyIgnoredKeyword:keyword];
	}
}


- (OOAbstractMesh *) abstractMesh
{
	[self parse];
	return nil;
}

@end


@implementation OOOBJReader (Private)

- (NSData *) oo_objReader:(OOOBJReader *)reader findMaterialLibrary:(NSString *)fileName
{
	NSString *path = [[_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
	return [NSData dataWithContentsOfFile:path];
}


- (void) priv_reportParseError:(NSString *)format, ...
{
	NSString *base = OOLocalizeProblemString(_issues, @"Parse error on line %u of %@: %@.");
	format = OOLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [_lexer lineNumber], [self priv_displayName], message];
	[_issues addProblemOfType:kOOMProblemTypeError message:message];
}


- (void) priv_reportBasicParseError:(NSString *)expected
{
	[self priv_reportParseError:@"expected %@, got %@", expected, [_lexer currentTokenString]];
}


- (void) priv_reportMallocFailure
{
	OOReportError(_issues, @"Not enough memory to read %@.", [[NSFileManager defaultManager] displayNameAtPath:_path]);
}


- (NSString *) priv_displayName
{
	return [[NSFileManager defaultManager] displayNameAtPath:_path];
}


- (BOOL) priv_readVectorForArray:(NSMutableArray *)array
{
	Vector v;
	BOOL OK = [_lexer readReal:&v.x] &&
	[_lexer readReal:&v.y] &&
	[_lexer readReal:&v.y];
	if (!OK)
	{
		[self priv_reportBasicParseError:@"number"];
		return NO;
	}
	
	if (![_lexer readNewline])
	{
		[self priv_reportBasicParseError:@"end of line"];
		return NO;
	}
	
	[array addObject:OOFloatArrayFromVector(clean_vector(v))];
	 return YES;
}


- (BOOL) priv_readVertexPosition
{
	return [self priv_readVectorForArray:_positions];
}


- (BOOL) priv_readVertexNormal
{
	return [self priv_readVectorForArray:_normals];
}


- (BOOL) priv_readVertexTexCoords
{
	Vector2D v;
	BOOL OK = [_lexer readReal:&v.x] &&
			  [_lexer readReal:&v.y];
	if (!OK)
	{
		[self priv_reportBasicParseError:@"number"];
		return NO;
	}
	
	if (![_lexer readNewline])
	{
		[self priv_reportBasicParseError:@"end of line"];
		return NO;
	}
	
	[_texCoords addObject:OOFloatArrayFromVector2D(clean_vector2D(v))];
	return YES;
}


- (BOOL) priv_readFace
{
	return NO;
}


- (BOOL) priv_readMaterialLibrary
{
	return NO;
}


- (BOOL) priv_readObjectName
{
	if (_name != nil)  return [_lexer skipLine];
	
	if (![_lexer readUntilNewline:&_name])
	{
		[self priv_reportBasicParseError:@"string"];
		return NO;
	}
	
	_name = [[_name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] retain];
	return YES;
}


- (BOOL) priv_notifyIgnoredKeyword:(NSString *)keyword
{
	//	Set of keywords that are used for curved surfaces, which we don’t support.
	NSSet *curveCommands = $set(@"vp", @"deg", @"bmat", @"step", @"cstype", @"curv", @"curv2", @"surf", @"parm", @"trim", @"hole", @"scrv", @"sp", @"end", @"con");
	
	// Rendering attributes we don’t support.
	NSSet *renderAttribCommands = $set(@"bevel", @"c_interp", @"d_interp", @"lod", @"maplib", @"usemap", @"shadow_obj", @"trace_obj", @"ctech", @"stech");
	
	if ([curveCommands containsObject:keyword])
	{
		if (!_warnedAboutCurves)
		{
			OOReportWarning(_issues, @"\"%@\" contains curve data which will be ignored.", [self priv_displayName]);
			_warnedAboutCurves = YES;
		}
	}
	else if ([renderAttribCommands containsObject:keyword])
	{
		if (!_warnedAboutRenderAttribs)
		{
			OOReportWarning(_issues, @"\"%@\" contains rendering attributes which will be ignored.", [self priv_displayName]);
			_warnedAboutRenderAttribs = YES;
		}
	}
	else if ([keyword isEqual:@"l"] || [keyword isEqual:@"l"])
	{
		if (!_warnedAboutLinesOrPoints)
		{
			OOReportWarning(_issues, @"\"%@\" contains point or line data which will be ignored.", [self priv_displayName]);
			_warnedAboutLinesOrPoints = YES;
		}
	}
	else
	{
		if (!_warnedAboutUnknown)
		{
			OOReportWarning(_issues, @"\"%@\" contains unknown commands such as \"%@\" which will be ignored.", [self priv_displayName], keyword);
			_warnedAboutUnknown = YES;
		}
	}
	
	
	return [_lexer skipLine];
}

@end
