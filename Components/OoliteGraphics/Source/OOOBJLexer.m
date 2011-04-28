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

#if !OOLITE_LEAN

#import "OOOBJLexer.h"


typedef enum OOOBJLexerEndMode
{
	kEndNormal,			// End at whitespace
	kEndNonInteger,		// End at anything other than \-[0-9]+
	kEndNonSpace,		// End at anything other than space, tab or comment.
	kEndEOLNoComment,	// End at end of line or start of a comment
	kEndEOL				// End at end of line only
} OOOBJLexerEndMode;


@interface OOOBJLexer (Private)

- (BOOL) advanceWithEndMode:(OOOBJLexerEndMode)mode;

@end


@implementation OOOBJLexer

- (id) initWithURL:(NSURL *)url issues:(id <OOProblemReporting>)issues
{
	if ([url isFileURL])
	{
		NSError *error = nil;
		NSData *data = [[NSData alloc] initWithContentsOfURL:url options:0 error:&error];
		if (data == nil)
		{
			OOReportError(issues, @"The document could not be loaded, because an error occurred: %@", [error localizedDescription]);
			return nil;
		}
		return [self initWithData:data issues:issues];
	}
	else
	{
		[NSException raise:NSInvalidArgumentException format:@"OOOBJLexer does not support non-file URLs such as %@", [url absoluteURL]];
	}
	
	return nil;
}


- (id) initWithPath:(NSString *)path issues:(id <OOProblemReporting>)issues
{
	return [self initWithURL:[NSURL fileURLWithPath:path] issues:issues];
}


- (id) initWithData:(NSData *)data issues:(id <OOProblemReporting>)issues
{
	if ([data length] == 0)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_issues = [issues retain];
		_data = [data retain];
		_cursor = _start = [data bytes];
		_end = _cursor + [data length];
		_tokenLength = 0;
		_lineNumber = 1;
		_startOfLine = YES;
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_data);
	DESTROY(_tokenString);
	
	[super dealloc];
}


- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@ %p>{next token = \"%@\"}", [self class], self, [self currentTokenString]];
}


- (NSInteger) lineNumber
{
	return _lineNumber;
}


- (NSString *) currentTokenString
{
	if (_tokenString == nil)
	{
		_tokenString = [[NSString alloc] initWithBytes:_cursor length:_tokenLength encoding:NSUTF8StringEncoding];
		if (_tokenString == nil)
		{
			_tokenString = [[NSString alloc] initWithBytes:_cursor length:_tokenLength encoding:NSISOLatin1StringEncoding];
		}
	}
	
	return _tokenString;
}


- (BOOL) readInteger:(NSInteger *)outInt
{
	NSParameterAssert(outInt != NULL);
	if (EXPECT_NOT(![self advanceWithEndMode:kEndNonInteger]))  return NO;
	
	unsigned result = 0;
	const char *str = _cursor;
	size_t rem = _tokenLength;
	BOOL negative = NO;
	
	if (EXPECT_NOT(rem == 0))  return NO;
	
	if (*str == '-' || *str == '+')
	{
		if (*str == '-')  negative = YES;
		
		str++;
		rem--;
		
		if (EXPECT_NOT(rem == 0))  return NO;
	}
	
	do
	{
		char c = *str++;
		if (EXPECT('0' <= c && c <= '9'))
		{
			result = result * 10 + c - '0';
		}
		else
		{
			return NO;
		}
	}
	while (--rem);
	
	if (negative)  result = -result;
	*outInt = result;
	return YES;
}


- (BOOL) readReal:(float *)outReal
{
	NSParameterAssert(outReal != NULL);
	if (EXPECT_NOT(![self advanceWithEndMode:kEndNormal]))  return NO;
	
	//	Make null-terminated copy of token on stack and strtod() it.
	char buffer[_tokenLength + 1];
	memcpy(buffer, _cursor, _tokenLength);
	buffer[_tokenLength] = '\0';
	
	*outReal = strtof(buffer, NULL);
	return YES;
}


- (BOOL) readString:(NSString **)outString
{
	NSParameterAssert(outString != NULL);
	if (EXPECT_NOT(![self advanceWithEndMode:kEndNormal]))  return NO;
	
	*outString = [[[self currentTokenString] retain] autorelease];
	return YES;
}


- (BOOL) readUntilNewline:(NSString **)outString
{
	NSParameterAssert(outString != NULL);
	if (EXPECT_NOT(![self advanceWithEndMode:kEndEOLNoComment]))  return NO;
	
	*outString = [[self currentTokenString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if (EXPECT_NOT(![self advanceWithEndMode:kEndEOL]))  return NO;
	
	return YES;
}


- (BOOL) readNewline
{
	if (EXPECT_NOT(![self advanceWithEndMode:kEndNonSpace]))  return NO;
	
	_startOfLine = YES;
	return YES;
}


- (BOOL) skipLine
{
	if (EXPECT_NOT(![self advanceWithEndMode:kEndEOL]))  return NO;
	
	_startOfLine = YES;
	return YES;
}


- (BOOL) isAtSlash
{
	return _cursor < _end && *_cursor == '/';
}


- (BOOL) skipSlash
{
	_cursor += _tokenLength;
	_tokenLength = 0;
	
	if (_cursor < _end && *_cursor == '/')
	{
		_cursor++;
		return YES;
	}
	return NO;
}


static inline BOOL IsLineEndChar(char c)
{
	return c == '\r' || c == '\n';
}


- (BOOL) isAtEndOfLine
{
	_cursor += _tokenLength;
	_tokenLength = 0;
	
	return _cursor < _end && IsLineEndChar(*_cursor);
}


- (BOOL) isAtEndOfFile
{
	_cursor += _tokenLength;
	_tokenLength = 0;
	
	return _cursor >= _end;
}


- (float) progressEstimate
{
	off_t total = _end - _start;
	off_t processed = _cursor - _start;
	return (float)processed / (float)total;
}


static inline BOOL IsWhitespace(char c)
{
	return c == ' ' || c == '\t';
}


static BOOL IsIntegerChar(char c)
{
	return '0' <= c && c <= '9';
}


- (BOOL) advanceWithEndMode:(OOOBJLexerEndMode)mode
{
	_cursor += _tokenLength;
	NSAssert(_cursor <= _end, @"DAT lexer passed end of buffer");
	
	DESTROY(_tokenString);
	_tokenLength = 0;
	
#define EOF_BREAK()  do { if (EXPECT_NOT(_cursor == _end))  return YES; } while (0)
#define COMMENT_AT(loc)  (*(loc) == '#')
	
#define SKIP_WHILE(predicate)  do { while (predicate) { \
			if (!IsLineEndChar(*_cursor))  lastIsCR = NO; \
			else \
			{ \
				if (!lastIsCR || *_cursor != '\n') \
				{ \
					_lineNumber++; \
					lastIsCR = NO; \
				} \
				if (*_cursor == '\r')  lastIsCR = YES; \
			} \
			_cursor++; \
			EOF_BREAK(); \
		}} while (0)
	
	EOF_BREAK();
	BOOL lastIsCR = NO;
	
	// Find beginning of next token.
	for (;;)
	{
		if (_startOfLine)
		{
			SKIP_WHILE(IsWhitespace(*_cursor) || IsLineEndChar(*_cursor));
		}
		else
		{
			SKIP_WHILE(IsWhitespace(*_cursor));
		}
		
		// Skip comments.
		if (COMMENT_AT(_cursor))
		{
			SKIP_WHILE(!IsLineEndChar(*_cursor));
		}
		else
		{
			break;
		}
	}
	
	_startOfLine = NO;
	
	// Find length of current token.
	const char *endCursor = _cursor;
	switch (mode)
	{
		case kEndNormal:
			while (endCursor < _end && !IsWhitespace(*endCursor) && !IsLineEndChar(*endCursor) && !COMMENT_AT(endCursor))
			{
				endCursor++;
			}
			break;
			
		case kEndNonInteger:
			if (*endCursor == '-' || *endCursor == '+')  endCursor++;
			while (endCursor < _end && IsIntegerChar(*endCursor) && !COMMENT_AT(endCursor))
			{
				endCursor++;
			}
			break;
			
		case kEndNonSpace:
			while (endCursor < _end && IsWhitespace(*endCursor) && !COMMENT_AT(endCursor))
			{
				endCursor++;
			}
			break;
			
		case kEndEOL:
			while (endCursor < _end && !IsLineEndChar(*endCursor))
			{
				endCursor++;
			}
			break;
			
		case kEndEOLNoComment:
			while (endCursor < _end && !IsLineEndChar(*endCursor) && !COMMENT_AT(endCursor))
			{
				endCursor++;
			}
			break;
			
		default:
			OOReportError(_issues, @"Internal error: unknown OBJ lexer end mode %u.", mode);
			return NO;
	}
	
	_tokenLength = endCursor - _cursor;
	
#undef EOF_BREAK
#undef SKIP_WHILE
#undef COMMENT_AT
	
	return YES;
}

@end

#endif	// OOLITE_LEAN
