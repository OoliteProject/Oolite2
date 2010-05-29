/*
	OOMeshLexer.h
	
	Token scanner for oomesh files.
	
	
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



typedef enum OOMeshTokenType
{
	// Text types
	kOOMeshTokenKeyword,
	kOOMeshTokenString,
	kOOMeshTokenStringWithEscapes,	// Internal use only.
	
	// Number types
	kOOMeshTokenNatural,			// natural = digit , { digit }
	kOOMeshTokenReal,				// real = { "-" | "+" } , natural  ,{ "." natural }
	
	kOOMeshTokenNewline,
	
	// Punctuation types
	kOOMeshTokenColon,				// colon = ":"
	kOOMeshTokenComma,				// comma = ","
	kOOMeshTokenOpenBrace,			// open brace = "{"
	kOOMeshTokenCloseBrace,			// close brace = "}"
	kOOMeshTokenOpenBracket,		// open bracket = "["
	kOOMeshTokenCloseBracket,		// close bracket = "]"
	
	kOOMeshTokenEOF,
	
	// Must be last
	kOOMeshTokenInvalid
} OOMeshTokenType;


@interface OOMeshLexer: NSObject
{
@private
	id <OOProblemReportManager>	_issues;
	struct OOMeshLexerState
	{
		OOMeshTokenType				tokenType;
		const uint8_t				*cursor;
		const uint8_t				*end;
		size_t						tokenLength;
		unsigned					lineNumber;
	}								_state;
	NSData							*_data;
	NSString						*_tokenString;
}

- (id) initWithURL:(NSURL *)inURL issues:(id <OOProblemReportManager>)ioIssues;
- (id) initWithPath:(NSString *)inPath issues:(id <OOProblemReportManager>)ioIssues;
- (id) initWithData:(NSData *)inData issues:(id <OOProblemReportManager>)ioIssues;

- (NSInteger) lineNumber;	// Signed to avoid silly conflict warnings with NSXMLParser.

- (OOMeshTokenType) currentTokenType;
- (NSString *) currentTokenString;		// Unquoted and de-escaped string for string tokens, literal text for others.
- (NSString *) currentTokenDescription;	// Human-readable description, localized if appropriate.

- (BOOL) advance;

// "Get" methods interpret the current token without advancing.
- (BOOL) getNatural:(uint64_t *)outNatural;
- (BOOL) getReal:(float *)outReal;
- (BOOL) getString:(NSString **)outString;
- (BOOL) getKeywordOrString:(NSString **)outString;
- (BOOL) getToken:(OOMeshTokenType)type;

// "Consume" methods advance to the next token, and in some cases further.
- (BOOL) consumeNatural:(uint64_t *)outNatural;
- (BOOL) consumeReal:(float *)outReal;
- (BOOL) consumeString:(NSString **)outString;
- (BOOL) consumeKeywordOrString:(NSString **)outString;

- (BOOL) consumeToken:(OOMeshTokenType)type;
- (BOOL) consumeOptionalNewlines;
// comma or newline = comma | newlines { comma { newlines }}
- (BOOL) consumeCommaOrNewlines;

@end
