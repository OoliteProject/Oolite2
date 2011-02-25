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

@protocol OOProblemReporting;
@class OOConfLexer;


@interface OOConfParser: NSObject
{
@private
	id <OOProblemReporting>		_issues;
	OOConfLexer					*_lexer;
	id							_delegate;
}

- (id) initWithData:(NSData *)url problemReporter:(id <OOProblemReporting>)issues;

- (id<OOProblemReporting>) problemReporter;
- (OOConfLexer *) lexer;

/*	OOConfParser has specialized delegate behaviour.
	The delegate is expected to remain the same object throughout parsing.
	However, different delegate actions may be called in different contexts.
	When a delegate action is called, it must either call
	-parseWithDelegateAction: recursively, consume the next object in the token
	stream in some other way, or return NO to indicate failure. (A failing
	action should also report an error to the problem report manager.) A NULL
	action may be passed to -parseWithDelegateAction in order to skip over an
	object.
	
	The signature for delegate actions is:
	- (BOOL) handleElement:(void *)key isArray:(BOOL)isArray producingObject:(id *)outObject;
	
	If isArray is true, key is an NSUInteger (not an NSNumber *!). If isArray
	is false, we're dealing with a dictionary and key is an NSString *.
*/
- (id) delegate;
- (void) setDelegate:(id)delegate;

- (id) parseWithDelegateAction:(SEL)action;

@end
