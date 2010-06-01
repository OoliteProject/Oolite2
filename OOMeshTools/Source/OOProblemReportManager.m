/*
	OOProblemReportManager.m
	
	
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

#import "OOProblemReportManager.h"


void OOReportIssueWithArgs(id <OOProblemReportManager> probMgr, OOProblemReportType type, NSString *formatKey, va_list args)
{
	if (probMgr == nil || formatKey == nil)  return;
	
	NSString *localizedFormat = OOLocalizeProblemString(probMgr, formatKey);
	
	NSString *message = [[[NSString alloc] initWithFormat:localizedFormat arguments:args] autorelease];
	[probMgr addProblemOfType:type message:message];
}


NSString *OOLocalizeProblemString(id <OOProblemReportManager> probMgr, NSString *string)
{
	NSString *result = [probMgr localizedProblemStringForKey:string];
	if (result == nil)
	{
		result = [[NSBundle mainBundle] localizedStringForKey:string
														value:string
														table:nil];
	}
	return result;
}


void OOReportIssue(id <OOProblemReportManager> probMgr, OOProblemReportType type, NSString *formatKey, ...)
{
	va_list args;
	va_start(args, formatKey);
	OOReportIssueWithArgs(probMgr, type, formatKey, args);
	va_end(args);
}



void OOReportInfo(id <OOProblemReportManager> probMgr, NSString *formatKey, ...)
{
	va_list args;
	va_start(args, formatKey);
	OOReportIssueWithArgs(probMgr, kOOMProblemTypeInformative, formatKey, args);
	va_end(args);
}


void OOReportWarning(id <OOProblemReportManager> probMgr, NSString *formatKey, ...)
{
	va_list args;
	va_start(args, formatKey);
	OOReportIssueWithArgs(probMgr, kOOMProblemTypeWarning, formatKey, args);
	va_end(args);
}


void OOReportError(id <OOProblemReportManager> probMgr, NSString *formatKey, ...)
{
	va_list args;
	va_start(args, formatKey);
	OOReportIssueWithArgs(probMgr, kOOMProblemTypeError, formatKey, args);
	va_end(args);
}


void OOReportNSError(id <OOProblemReportManager> probMgr, NSString *context, NSError *error)
{
	NSString *desc = [error localizedFailureReason];
	if (desc == nil)  desc = [error localizedDescription];
	
	context = OOLocalizeProblemString(probMgr, context);
	if (desc == nil)  desc = context;
	else  desc = [NSString stringWithFormat:@"%@ %@", context, desc];
	
	[probMgr addProblemOfType:kOOMProblemTypeError message:desc];
}


@implementation OOSimpleProblemReportManager

- (void) addProblemOfType:(OOProblemReportType)type message:(NSString *)message
{
	NSString *messageClass = @"mesh.load.problem";
	switch (type)
	{
		case kOOMProblemTypeInformative:
			messageClass = @"mesh.load.note";
			break;
			
		case kOOMProblemTypeWarning:
			messageClass = @"mesh.load.warning";
			break;
			
		case kOOMProblemTypeError:
			messageClass = @"mesh.load.error";
			break;
	}
	
	OOLog(messageClass, @"%@", message);
}


- (NSString *) localizedProblemStringForKey:(NSString *)string
{
	return string;
}

@end