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


@interface OOOBJReader (Private) <OOOBJMaterialLibraryResolver>

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)expected;
- (void) priv_reportMallocFailure;

- (NSString *) priv_displayName;

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
	OOReportError(_issues, @"allocFailed", @"Not enough memory to read %@.", [[NSFileManager defaultManager] displayNameAtPath:_path]);
}


- (NSString *) priv_displayName
{
	return [[NSFileManager defaultManager] displayNameAtPath:_path];
}

@end
