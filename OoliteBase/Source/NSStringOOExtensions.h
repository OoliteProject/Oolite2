/*

NSStringOOExtensions.h

Convenience extensions to NSString.

Oolite
Copyright (C) 2004-2010 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import <Foundation/Foundation.h>


@interface NSString (OOExtensions)

/*	+oo_stringWithContentsOfUnicodeFile:
	
	Like +stringWithContentsOfFile:, but biased towards Unicode encodings and
	cross-system consistency. Specifically:
	* If the file starts with a UTF-16 BOM, assume UTF-16.
	* Otherwise, if the file can be interpreted as UTF-8, assume UTF-8.
	* Otherwise, assume ISO-Latin-1.
*/
+ (id) oo_stringWithContentsOfUnicodeFile:(NSString *)path;


/*	+oo_stringWithUTF16String:
	
	Takes a NUL-terminated native-endian UTF-16 string.
*/
+ (id) oo_stringWithUTF16String:(const unichar *)chars;


/*	-oo_utf16DataWithBOM:
	
	Convert to native-endian UTF-16 data.
*/
- (NSData *) oo_utf16DataWithBOM:(BOOL)includeByteOrderMark;

/*	-oo_hash
	
	Hash function for when we want consistency across platforms and versions.
	It implements modified djb2 (with xor rather than addition) in terms of
	UTF-16 code elements.
*/
- (uint32_t) oo_hash;


/*	-oo_escapedForJavaScriptLiteral
	
	Add escape codes for string so that it's a valid JavaScript literal (if
	you put "" or '' around it). Also valid for GraphViz and, of course, JSON.
	
	This is here rather than in JavaScript support because it's used by
	OoliteGraphics.
*/
- (NSString *) oo_escapedForJavaScriptLiteral;

@end


@interface NSMutableString (OOExtensions)

- (void) oo_appendLine:(NSString *)line;
- (void) oo_appendFormatLine:(NSString *)fmt, ...;
- (void) oo_appendFormatLine:(NSString *)fmt arguments:(va_list)args;

- (void) oo_deleteCharacterAtIndex:(unsigned long)index;

@end
