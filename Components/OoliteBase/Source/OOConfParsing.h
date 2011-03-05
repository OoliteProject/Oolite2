/*

OOConfParsing.h
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
* The character escape codes \' and \v are permitted. They aren’t produced by
  the generator, though.
* The root object in an OOConf may be of any type.

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

#import "OOProblemReporting.h"


@interface NSObject (OOConfParsing)

+ (id) objectFromOOConfString:(NSString *)ooConfString error:(NSError **)outError;
+ (id) objectFromOOConfData:(NSData *)ooConfData error:(NSError **)outError;
+ (id) objectWithContentsOfOOConfURL:(NSURL *)url error:(NSError **)outError;

+ (id) objectFromOOConfString:(NSString *)ooConfString problemReporter:(id<OOProblemReporting>)problemReporter;
+ (id) objectFromOOConfData:(NSData *)ooConfData problemReporter:(id<OOProblemReporting>)problemReporter;
+ (id) objectWithContentsOfOOConfURL:(NSURL *)url problemReporter:(id<OOProblemReporting>)problemReporter;

@end
