/*
	OOOBJLexer.m
	
	
	Copyright © 2010 Jens Ayton

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

#import "OOOBJLexer.h"
#import "OOProblemReportManager.h"


@implementation OOOBJLexer

- (id) initWithURL:(NSURL *)inURL issues:(id <OOProblemReportManager>)issues
{
	if ([inURL isFileURL])
	{
		NSError *error = nil;
		NSData *data = [[NSData alloc] initWithContentsOfURL:inURL options:0 error:&error];
		if (data == nil)
		{
			OOReportError(issues, @"noReadFile", @"The document could not be loaded, because an error occurred: %@", [error localizedDescription]);
			return nil;
		}
		return [self initWithData:data issues:issues];
	}
	else
	{
		[NSException raise:NSInvalidArgumentException format:@"OOOBJLexer does not support non-file URLs such as %@", [inURL absoluteURL]];
	}
	
	return nil;
}


- (id) initWithPath:(NSString *)inPath issues:(id <OOProblemReportManager>)issues
{
	return [self initWithURL:[NSURL fileURLWithPath:inPath] issues:issues];
}


- (id) initWithData:(NSData *)inData issues:(id <OOProblemReportManager>)issues
{
	if ([inData length] == 0)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_data = [inData retain];
		_cursor = [inData bytes];
		_end = _cursor + [inData length];
		_tokenLength = 0;
		_lineNumber = 1;
	}
	
	return self;
}


- (NSInteger) lineNumber
{
	return _lineNumber;
}


- (NSString *) currentTokenString
{
	// FIXME
	return nil;
}


- (BOOL) readInteger:(NSInteger *)outInt
{
	// FIXME
	return NO;
}


- (BOOL) readReal:(float *)outReal
{
	// FIXME
	return NO;
}


- (BOOL) readString:(NSString **)outString
{
	// FIXME
	return NO;
}


- (BOOL) readUntilNewline:(NSString **)outString
{
	// FIXME
	return NO;
}


- (BOOL) readNewline
{
	// FIXME
	return NO;
}


- (BOOL) skipLine
{
	// FIXME
	return NO;
}


- (BOOL) isAtEnd
{
	// FIXME
	return YES;
}

@end
