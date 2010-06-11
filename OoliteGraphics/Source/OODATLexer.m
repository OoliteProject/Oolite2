/*
	OODATLexer.m
	
	
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

#import "OODATLexer.h"
#import "OOProblemReporting.h"


typedef enum OODATLexerEndMode
{
	kEndNormal,
	kEndEOL
} OODATLexerEndMode;


@interface OODATLexer (Private)

- (BOOL) priv_advanceWithEndMode:(OODATLexerEndMode)mode;

@end


@implementation OODATLexer

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
		[NSException raise:NSInvalidArgumentException format:@"OODATLexer does not support non-file URLs such as %@", [url absoluteURL]];
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


- (NSString *) nextToken
{
	if ([self priv_advanceWithEndMode:kEndNormal])
	{
		return [self currentTokenString];
	}
	
	return nil;
}


- (BOOL) expectLiteral:(const char *)literal
{
	if ([self priv_advanceWithEndMode:kEndNormal])
	{
		return (strncmp(literal, _cursor, _tokenLength) == 0);
	}
	
	return NO;
}


- (BOOL) readInteger:(NSUInteger *)outInt
{
	NSParameterAssert(outInt != NULL);
	if (EXPECT_NOT(![self priv_advanceWithEndMode:kEndNormal]))  return NO;
	
	unsigned result = 0;
	const char *str = _cursor;
	size_t rem = _tokenLength;
	
	if (EXPECT_NOT(rem == 0))  return NO;
	
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
	
	*outInt = result;
	return YES;
}


- (BOOL) readReal:(float *)outReal
{
	NSParameterAssert(outReal != NULL);
	if (EXPECT_NOT(![self priv_advanceWithEndMode:kEndNormal]))  return NO;
	
	//	Make null-terminated copy of token on stack and strtod() it.
	char buffer[_tokenLength + 1];
	memcpy(buffer, _cursor, _tokenLength);
	buffer[_tokenLength] = '\0';
	
	*outReal = strtod(buffer, NULL);
	
	return YES;
}


- (BOOL) readString:(NSString **)outString
{
	NSParameterAssert(outString != NULL);
	
	NSString *token = [self nextToken];
	if (token == nil)  return NO;
	
	*outString = [[token retain] autorelease];
	
	return YES;
}


- (BOOL) readUntilNewline:(NSString **)outString
{
	NSParameterAssert(outString != NULL);
	
	if (EXPECT([self priv_advanceWithEndMode:kEndEOL]))
	{
		*outString = [self currentTokenString];
		return YES;
	}
	
	return NO;
}


- (float) progressEstimate
{
	off_t total = _end - _start;
	off_t processed = _cursor - _start;
	return (float)processed / (float)total;
}


static inline BOOL IsSeparatorChar(char c)
{
	return c == ' ' || c == ',' || c == '\t' || c == '\r' || c == '\n';
}


static inline BOOL IsLineEndChar(char c)
{
	return c == '\r' || c == '\n';
}


- (BOOL) priv_advanceWithEndMode:(OODATLexerEndMode)mode
{
	_cursor += _tokenLength;
	NSAssert(_cursor <= _end, @"DAT lexer passed end of buffer");
	
	DESTROY(_tokenString);
	_tokenLength = 0;
	
#define EOF_BREAK()  do { if (EXPECT_NOT(_cursor == _end))  return YES; } while (0)
#define COMMENT_AT(loc)  (*(loc) == '#' || (*(loc) == '/' && (loc) + 1 < _end && *((loc) + 1) == '/'))
	
	/*	SKIP_WHILE: skip characters matching predicate, returning if we reach
		end of data, and counting lines as we go.
	*/
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
		SKIP_WHILE(IsSeparatorChar(*_cursor));
		
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
	
	// Find length of current token.
	const char *endCursor = _cursor + 1;
	if (mode == kEndNormal)
	{
		while (endCursor < _end && !IsSeparatorChar(*endCursor) && !COMMENT_AT(endCursor))
		{
			endCursor++;
		}
	}
	else if (mode == kEndEOL)
	{
		while (endCursor < _end && !IsLineEndChar(*endCursor) && !COMMENT_AT(endCursor))
		{
			endCursor++;
		}
	}
	else
	{
		OOReportError(_issues, @"Internal error: unknown DAT lexer end mode %u.", mode);
		return NO;
	}
	
	_tokenLength = endCursor - _cursor;
	
#undef EOF_BREAK
#undef SKIP_WHILE
#undef COMMENT_AT
	
	return YES;
}

@end
