/*

OOConfGeneration.h
By Jens Ayton

See header comment in OOConfParsing.h.


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

#import "OOBaseErrors.h"


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
