/*

OOLogOutputHandler.h
By Jens Ayton

Output handler interface for Oolite logging system.

OOLogOutputHandler is a base class for logging system back ends.

The default implementation accepts all messages and prints them to stderr.


Copyright © 2010 Jens Ayton

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

#import <Cocoa/Cocoa.h>


@interface OOLogOutputHandler: NSObject

/*	Main interface.
	The method may not be dynamically altered: the logging system will IMP
	cache it.
	This method may be called on any thread.
	
	Note: the message class will have been integrated into the message if
	-showMessageClass returns YES. It is included in case additional filtering
	is desired.
*/
- (void) printLogMessage:(NSString *)message ofClass:(NSString *)mclass;

/*	Used to determine which messages to show.
	This is called very often, from any thread, and is IMP cached.
*/
- (BOOL) shouldShowMessageInClass:(NSString *)messageClass;


- (void) setShouldShowMessage:(BOOL)flag inClass:(NSString *)messageClass;


/*	Configuration interface.
*/
- (BOOL) showFunction;
- (void) setShowFunction:(BOOL)flag;

- (BOOL) showFileAndLine;
- (void) setShowFileAndLine:(BOOL)flag;

- (BOOL) showMessageClass;
- (void) setShowMessageClass:(BOOL)flag;

@end
