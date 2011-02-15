/*
	OOJMeshLexer.h
	
	Token scanner for OOJMesh files.
	
	
	Copyright © 2010-2011 Jens Ayton

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

@protocol OOProblemReporting;



typedef enum OOJMeshTokenType
{
	// Text types
	kOOJMeshTokenKeyword,			// Unquoted string.
	kOOJMeshTokenString,
	kOOJMeshTokenStringWithEscapes,	// Internal use only.
	
	// Number types
	kOOJMeshTokenNatural,			// natural = digit , { digit }
	kOOJMeshTokenReal,				// real = { "-" | "+" } , natural  ,{ "." natural }
	
	// Punctuation types
	kOOJMeshTokenColon,				// colon = ":"
	kOOJMeshTokenComma,				// comma = ","
	kOOJMeshTokenOpenBrace,			// open brace = "{"
	kOOJMeshTokenCloseBrace,			// close brace = "}"
	kOOJMeshTokenOpenBracket,		// open bracket = "["
	kOOJMeshTokenCloseBracket,		// close bracket = "]"
	
	kOOJMeshTokenEOF,
	
	// Must be last
	kOOJMeshTokenInvalid
} OOJMeshTokenType;


@interface OOJMeshLexer: NSObject
{
@private
	id <OOProblemReporting>	_issues;
	struct OOJMeshLexerState
	{
		OOJMeshTokenType				tokenType;
		const uint8_t				*cursor;
		const uint8_t				*end;
		size_t						tokenLength;
		unsigned					lineNumber;
	}								_state;
	NSData							*_data;
	NSString						*_tokenString;
}

- (id) initWithURL:(NSURL *)inURL issues:(id <OOProblemReporting>)issues;
- (id) initWithPath:(NSString *)inPath issues:(id <OOProblemReporting>)issues;
- (id) initWithData:(NSData *)inData issues:(id <OOProblemReporting>)issues;

- (NSInteger) lineNumber;	// Signed to avoid silly conflict warnings with NSXMLParser.

- (OOJMeshTokenType) currentTokenType;
- (NSString *) currentTokenString;		// Unquoted and de-escaped string for string tokens, literal text for others.
- (NSString *) currentTokenDescription;	// Human-readable description, localized if appropriate.

- (BOOL) advance;

// "Get" methods interpret the current token without advancing.
- (BOOL) getNatural:(uint64_t *)outNatural;
- (BOOL) getDouble:(double *)outDouble;
- (BOOL) getFloat:(float *)outFloat;
- (BOOL) getString:(NSString **)outString;
- (BOOL) getKeywordOrString:(NSString **)outString;
- (BOOL) getToken:(OOJMeshTokenType)type;

// "Consume" methods advance to the next token, and in some cases further.

- (BOOL) consumeToken:(OOJMeshTokenType)type;

@end
