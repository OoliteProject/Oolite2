/*
	OOMProblemReportManager.h
	
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


typedef enum OOMIssueType
{
	kOOMProblemTypeInformative,
	kOOMProblemTypeWarning,
	kOOMProblemTypeError
} OOMIssueType;


@protocol OOMProblemReportManager <NSObject>

- (void) addProblemOfType:(OOMIssueType)type key:(NSString *)key message:(NSString *)message;

//	If nil is returned, -[NSBundle localizedStringForKey:value:table:] is used.
- (NSString *) localizedProblemStringForKey:(NSString *)string;

@end


/*	These helper functions will look up keys using -localizedProblemStringForKey:
	or -[NSBundle localizedStringForKey:value:table:] as appropriate.
 */
void OOMReportIssueWithArgs(id <OOMProblemReportManager> probMgr, OOMIssueType type, NSString *key, NSString *formatKey, va_list args);
void OOMReportIssue(id <OOMProblemReportManager> probMgr, OOMIssueType type, NSString *key, NSString *formatKey, ...);

void OOMReportInfo(id <OOMProblemReportManager> probMgr, NSString *key, NSString *formatKey, ...);
void OOMReportWarning(id <OOMProblemReportManager> probMgr, NSString *key, NSString *formatKey, ...);
void OOMReportError(id <OOMProblemReportManager> probMgr, NSString *key, NSString *formatKey, ...);

NSString *OOMLocalizeProblemString(id <OOMProblemReportManager> probMgr, NSString *key);


/*	Trivial implementation of OOMProblemReportManager.
	Problems are printed to stderr. Strings are not localized.
*/
@interface OOMSimpleProblemReportManager: NSObject <OOMProblemReportManager>
@end
