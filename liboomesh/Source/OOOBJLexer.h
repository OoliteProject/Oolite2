/*
	OOOBJLexer.h
	
	Token scanner for OBJ/MTL files.
	
	
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

#import <Foundation/Foundation.h>

@protocol OOProblemReportManager;


@interface OOOBJLexer: NSObject
{
@private
	const char				*_cursor;
	const char				*_end;
	size_t					_tokenLength;
	NSData					*_data;
	unsigned				_lineNumber;
	NSString				*_tokenString;
}

- (id) initWithURL:(NSURL *)inURL issues:(id <OOProblemReportManager>)issues;
- (id) initWithPath:(NSString *)inPath issues:(id <OOProblemReportManager>)issues;
- (id) initWithData:(NSData *)inData issues:(id <OOProblemReportManager>)issues;

- (NSInteger) lineNumber;	// Signed to avoid silly conflict warnings with NSXMLParser.

- (NSString *) currentTokenString;

- (BOOL) readInteger:(NSInteger *)outInt;
- (BOOL) readReal:(float *)outReal;
- (BOOL) readString:(NSString **)outString;

- (BOOL) readNewline;	// Returns YES if it reaches newline without seeing tokens.
- (BOOL) skipNewline;	// Reads to newline and ignores tokens.

@end
