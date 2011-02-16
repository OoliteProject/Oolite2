/*

OOConfGenerationInternal.h
By Jens Ayton

Internals of OOConfGeneration. (This is public because the OOConf exporter
needs direct access.)


Copyright © 2011 Jens Ayton

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

#import "OOConfGeneration.h"


enum
{
	/*	kOOConfGenerationAfterPunctuation
		Flag used internally for pretty-print formatting. If set, the receiver
		will print a space before its data, unless it wraps to a new line.
	*/
	kOOConfGenerationAfterPunctuation	= 0x01000000UL
};


@protocol OOConfGeneration

/*
	-appendOOConfToString:withOptions:indentLevel:error:
	
	Implementation of OOConf generation.
	In a deliberate breach of convention, outError is required not to be NULL.
*/
- (BOOL) appendOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError;

@end


@interface NSDictionary (OOConfGeneration) <OOConfGeneration> @end
@interface NSArray (OOConfGeneration) <OOConfGeneration> @end
@interface NSNumber (OOConfGeneration) <OOConfGeneration> @end
@interface NSNull (OOConfGeneration) <OOConfGeneration> @end

@interface NSString (OOConfGeneration) <OOConfGeneration>

- (BOOL) oo_isValidUnquotedOOConfKey;

@end
