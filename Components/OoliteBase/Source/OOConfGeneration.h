/*

OOConfGeneration.h
By Jens Ayton

OOConf seraliziation of property list types, more or less. (Supported classes:
NSDictionary, NSArray, NSString, NSNumber, NSNull. Not NSDate or NSData.)

OOConf format is similar to JSON, but with the following changes:
* OOConf files must be encoded in UTF-8. A BOM (the byte sequence
  0xEF,0xBB,0xBF at the beginning of the file) is permitted, but not
  recommended.
* Object keys which are ASCII identifiers do not require quotation marks.
  Specifically, unquoted keys are permitted if they match:
  /\b[a-zA-Z\$_][a-zA-Z\$_0-9]*\b/
* JavaScript-style comments (both types) are allowed. Note that JavaScript,
  and hence OOConf, does not share the C++/C99 misfeature that a backslash at
  the end of a single-line comment wraps it to the next line.

The following relationships hold:
* Every valid OOConf file is a valid JavaScript file that does nothing.
* Every valid JSON file in UTF-8 is a valid OOConf file.
* Every OOConf file that does not use unquoted object keys or comments is a
  valid JSON file.

Many similar JSON-like formats exist, but I haven't found one that adds the
desired features without also adding other extensions, hence the need for a
new name.


Copyright © 2011 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import <Foundation/Foundation.h>


typedef NSUInteger OOConfGenerationOptions;
enum
{
	/*	kOOConfGenerationNoUnquotedKeys
		If this flag is set, all dictionary keys will be quoted. If it is not,
		dictionary keys will be unquoted wherever possible.
	*/
	kOOConfGenerationNoUnquotedKeys		= 0x00000001UL,
	
	/*	kOOConfGenerationNoComments
		If this flag is set, no comments will be generated. Normally comments
		aren't generated anyway, but they may be as part of debug features.
	*/
	kOOConfGenerationNoComments			= 0x00000002UL,
	
	/*	kOOConfGenerationNoPrettyPrint
		By default, OOConf generation inserts line breaks and tabs for
		readability. If this flag is set, unneeded whitespace is avoided.
	*/
	kOOConfGenerationNoPrettyPrint		= 0x00000004UL,
	
	/*	kOOConfGenerationIgnoreInvalid
		If this flag is set, invalid (non-string, non-integer) dictionary keys
		will be ignored, and invalid array or dictionary values will be
		replaced with nulls.
	*/
	kOOConfGenerationIgnoreInvalid		= 0x00000008UL,
	
	// Useful combinations.
	kOOConfGenerationJSONCompatible		= kOOConfGenerationNoUnquotedKeys | kOOConfGenerationNoComments,
	kOOConfGenerationSmall				= kOOConfGenerationNoComments | kOOConfGenerationNoPrettyPrint,
	kOOConfGenerationFast				= kOOConfGenerationNoUnquotedKeys | kOOConfGenerationNoComments | kOOConfGenerationNoPrettyPrint,
	
	kOOConfGenerationDefault			= 0
};


@interface NSObject (OOConfGeneration)

/*	ooConfStringWithOptions:error:
	ooConfDataWithOptions:error:
	Generate an OOConf representation of a property list.
	
	writeOOConfDataWithOptions:toURL:error:
	Write OOConf data to the specified file.
	
	These methods will thrown an exception if called on an object that does not
	conform to <OOConfGeneration>. Other problems, such as nested objects not
	conforming to <OOConfGeneration> or otherwise not having appropriate
	structure, are reported by returning nil/NO and setting outError if it is
	not NULL.
*/
- (NSString *) ooConfStringWithOptions:(OOConfGenerationOptions)options error:(NSError **)outError;
- (NSData *) ooConfDataWithOptions:(OOConfGenerationOptions)options error:(NSError **)outError;
- (BOOL) writeOOConfDataWithOptions:(OOConfGenerationOptions)options toURL:(NSURL *)url error:(NSError **)outError;

@end


extern NSString * const kOOConfGenerationErrorDomain;

enum
{
	kOOConfGenerationErrorNone,
	kOOConfGenerationErrorUnknownError,
	kOOConfGenerationErrorInvalidValue,
	kOOConfGenerationErrorInvalidKey,
};
