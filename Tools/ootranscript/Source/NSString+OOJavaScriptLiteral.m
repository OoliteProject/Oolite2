/*

NSString+OOJavaScriptLiteral.m


Copyright © 2010-2011 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import "NSString+OOJavaScriptLiteral.h"
#import <OoliteBase/OoliteBase.h>


#ifndef OOJS_PROFILE_ENTER
#define OOJS_PROFILE_ENTER
#define OOJS_PROFILE_EXIT
#endif


@implementation NSString (OOJavaScriptLiteral)

- (NSString *) oo_javaScriptLiteral
{
	return $sprintf(@"\"%@\"", [self oo_escapedForJavaScriptLiteral]);
}


static inline BOOL IsIdentifierFirstChar(unichar c)
{
	return	('a' <= c && c <= 'z') ||
			('A' <= c && c <= 'Z') ||
			c == '_';
}


static inline BOOL IsIdentifierChar(unichar c)
{
	return	IsIdentifierFirstChar(c) || ('0' <= c && c <= '9');
}


- (BOOL) oo_isSimpleJSIdentifier
{
	static NSCharacterSet		*notIdentifierCharSet = nil;
	unichar						first;
	
	if ([self oo_isJavaScriptKeyword])  return NO;
	
	if (notIdentifierCharSet == nil)
	{
		notIdentifierCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"_0123456789QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm$"] invertedSet];
		[notIdentifierCharSet retain];
	}
	
	if ([self length] == 0)  return NO;
	
	// Identifiers may not start with a digit.
	first = [self characterAtIndex:0];
	if ('0' <= first && first <= '9')  return NO;
	
	// Look for any non-identifier char.
	if ([self rangeOfCharacterFromSet:notIdentifierCharSet].location != NSNotFound)  return NO;
	
	return YES;
}


static NSSet *KeywordList(void)
{
	NSString *kKeywords[] =
	{
		@"break",
		@"continue",
		@"do",
		@"for",
		@"import",
		@"new",
		@"this",
		@"void",
		@"case",
		@"default",
		@"else",
		@"function",
		@"in",
		@"return",
		@"typeof",
		@"while",
		@"comment",
		@"delete",
		@"export",
		@"if",
		@"label",
		@"switch",
		@"var",
		@"with",
		@"abstract",
		@"implements",
		@"protected",
		@"boolean",
		@"instanceof",
		@"public",
		@"byte",
		@"int",
		@"short",
		@"char",
		@"interface",
		@"static",
		@"double",
		@"long",
		@"synchronized",
		@"false",
		@"native",
		@"throws",
		@"final",
		@"null",
		@"transient",
		@"float",
		@"package",
		@"true",
		@"goto",
		@"private",
		@"catch",
		@"enum",
		@"throw",
		@"class",
		@"extends",
		@"try",
		@"const",
		@"finally",
		@"debugger",
		@"super"
	};
	
	return [NSSet setWithObjects:kKeywords count:sizeof kKeywords / sizeof *kKeywords];
}


- (BOOL) oo_isJavaScriptKeyword
{
	static NSSet				*keywords = nil;
	
	if (keywords == nil)  keywords = [KeywordList() retain];
	
	return [keywords containsObject:self];
}

@end
