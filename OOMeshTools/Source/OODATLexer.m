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
#import "OOProblemReportManager.h"


typedef enum OODATLexerEndMode
{
	kEndNormal,
	kEndEOL
} OODATLexerEndMode;


@interface OODATLexer (Private)

- (BOOL)advanceWithEndMode:(OODATLexerEndMode)mode;

- (NSString *)describeToken;

@end


@implementation OODATLexer

- (id) initWithURL:(NSURL *)inURL issues:(id <OOProblemReportManager>)issues
{
	if ([inURL isFileURL])
	{
		NSError *error = nil;
		NSData *data = [[NSData alloc] initWithContentsOfURL:inURL options:0 error:&error];
		if (data == nil)
		{
			OOReportError(issues, @"The document could not be loaded, because an error occurred: %@", [error localizedDescription]);
			return nil;
		}
		return [self initWithData:data issues:issues];
	}
	else
	{
		[NSException raise:NSInvalidArgumentException format:@"OODATLexer does not support non-file URLs such as %@", [inURL absoluteURL]];
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


- (void) dealloc
{
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
	if ([self advanceWithEndMode:kEndNormal])
	{
		return [self currentTokenString];
	}
	
	return nil;
}


- (BOOL) expectLiteral:(const char *)literal
{
	if ([self advanceWithEndMode:kEndNormal])
	{
		return (strncmp(literal, _cursor, _tokenLength) == 0);
	}
	
	return NO;
}


- (BOOL) readInteger:(NSUInteger *)outInt
{
	NSParameterAssert(outInt != NULL);
	
	if (EXPECT([self advanceWithEndMode:kEndNormal]))
	{
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
	
	return NO;
}


- (BOOL) readReal:(float *)outReal
{
	NSParameterAssert(outReal != NULL);
	
	if (EXPECT([self advanceWithEndMode:kEndNormal]))
	{
		/*	Make null-terminated copy of token on stack and strtod() it.
			Float parsing is way to fiddly for a custom version to be worth it.
		*/
		char buffer[_tokenLength + 1];
		memcpy(buffer, _cursor, _tokenLength);
		buffer[_tokenLength] = '\0';
		
		*outReal = strtod(buffer, NULL);
		return YES;
	}
	
	return NO;
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
	
	if (EXPECT([self advanceWithEndMode:kEndEOL]))
	{
		*outString = [self currentTokenString];
		return YES;
	}
	
	return NO;
}


static inline BOOL IsSeparatorChar(char c)
{
	return c == ' ' || c == ',' || c == '\t' || c == '\r' || c == '\n';
}


static inline BOOL IsLineEndChar(char c)
{
	return c == '\r' || c == '\n';
}


- (BOOL) advanceWithEndMode:(OODATLexerEndMode)mode
{
	_cursor += _tokenLength;
	NSAssert(_cursor <= _end, @"DAT lexer passed end of buffer");
	
	[_tokenString release];
	_tokenString = nil;
	
#define EOF_BREAK()  do { if (EXPECT_NOT(_cursor == _end))  return NO; } while (0)
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
#ifndef NDEBUG
		[NSException raise:NSInternalInconsistencyException format:@"Invalid end mode in DAT lexer: %u", mode];
#endif
	}
	
	_tokenLength = endCursor - _cursor;
	
#undef EOF_BREAK
#undef SKIP_WHILE
#undef COMMENT_AT
	
	return YES;
}

@end
