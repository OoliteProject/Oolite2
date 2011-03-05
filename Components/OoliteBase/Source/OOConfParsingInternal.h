/*

OOConfParsingInternal.h
By Jens Ayton

Internals of OOConfParsing. (This is public because the OOConf importer needs
direct access.)


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

#import "OOConfParsing.h"
#import "OOConfLexer.h"

@protocol OOProblemReporting;
@class OOConfLexer;


typedef enum
{
	kOOConfArrayBegin,
	kOOConfArrayElement,
	kOOConfArrayEnd,
	kOOConfArrayFailed,
	kOOConfDictionaryBegin,
	kOOConfDictionaryElement,
	kOOConfDictionaryEnd,
	kOOConfDictionaryFailed
} OOConfParserActionEventType;


@interface OOConfParser: NSObject
{
@private
	id <OOProblemReporting>		_issues;
	OOConfLexer					*_lexer;
	id							_delegate;
	BOOL						_strictJSON;	// Experimental
}

- (id) initWithLexer:(OOConfLexer *)lexer;
- (id) initWithData:(NSData *)url problemReporter:(id <OOProblemReporting>)issues;

- (id <OOProblemReporting>) problemReporter;
- (OOConfLexer *) lexer;

/*	OOConfParser has specialized delegate behaviour.
	The delegate is expected to remain the same object throughout parsing.
	However, different delegate actions may be called in different contexts.
	When a delegate action is called, it must either call
	-parseWithDelegateAction:result; recursively, consume the next object in
	the token stream in some other way, or return NO to indicate failure. (A
	failing action should also report an error to the problem report manager.)
	A NULL action may be passed to -parseWithDelegateAction in order to skip
	over an object.
	
	The signature for delegate actions is:
	- (BOOL) parseEvent:(OOConfParserActionEventType) key:(void *)key object:(id *)object;
	
	The delegate action is invoked for each element of a dictionary or array.
	It is ignored for non-collection types.
	
	For each collection, there are four event types: Begin, Element, End, and
	Failed. Begin is sent once, then Element for each element of the collection,
	then End if successful; Failed is sent once if parsing fails in any way.
	
	For kOOConfArrayElement events, the key parameter is an integer (cast it to
	uintptr_t). For kOOConfDictionaryElement, it’s an NSString *. For other
	event types, it’s NULL.
	
	The return value is ignored for Failed events. For other event types, return
	YES to continue parsing and NO to indicate failure.
*/
- (id) delegate;
- (void) setDelegate:(id)delegate;

- (BOOL) parseWithDelegateAction:(SEL)action result:(id *)result;

/*	parseAsPropertyList
	Parse the next value as a property list. This is similar to the high-level
	parser interface, except it doesn’t report extra tokens after the parsed
	object, so it can be used to parse subtrees.
	Failure is indicated by returning nil.
*/
- (id) parseAsPropertyList;

@end
