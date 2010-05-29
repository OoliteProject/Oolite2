/*
	OOProblemReportManager.h
	
	Protocol for reporting multiple errors and other issues.
	
	
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

#import <Foundation/Foundation.h>
#import <stdarg.h>


typedef enum OOProblemReportType
{
	kOOMProblemTypeInformative,
	kOOMProblemTypeWarning,
	kOOMProblemTypeError
} OOProblemReportType;


@protocol OOProblemReportManager <NSObject>

- (void) addProblemOfType:(OOProblemReportType)type message:(NSString *)message;

//	If nil is returned, -[NSBundle localizedStringForKey:value:table:] is used.
- (NSString *) localizedProblemStringForKey:(NSString *)string;

@end


/*	These helper functions will look up keys using -localizedProblemStringForKey:
	or -[NSBundle localizedStringForKey:value:table:] as appropriate.
 */
void OOReportIssueWithArgs(id <OOProblemReportManager> probMgr, OOProblemReportType type, NSString *formatKey, va_list args);
void OOReportIssue(id <OOProblemReportManager> probMgr, OOProblemReportType type, NSString *formatKey, ...);

void OOReportInfo(id <OOProblemReportManager> probMgr, NSString *formatKey, ...);
void OOReportWarning(id <OOProblemReportManager> probMgr, NSString *formatKey, ...);
void OOReportError(id <OOProblemReportManager> probMgr, NSString *formatKey, ...);

void OOReportNSError(id <OOProblemReportManager> probMgr, NSString *context, NSError *error);

NSString *OOLocalizeProblemString(id <OOProblemReportManager> probMgr, NSString *string);


/*	Trivial implementation of OOProblemReportManager.
	Problems are printed to stderr. Strings are not localized.
*/
@interface OOSimpleProblemReportManager: NSObject <OOProblemReportManager>
@end
