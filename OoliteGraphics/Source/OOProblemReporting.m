/*
	OOProblemReporting.m
	
	
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

#import "OOProblemReporting.h"


void OOReportIssueWithArgs(id <OOProblemReporting> probMgr, OOProblemReportType type, NSString *formatKey, va_list args)
{
	if (probMgr == nil || formatKey == nil)  return;
	
	NSString *localizedFormat = OOLocalizeProblemString(probMgr, formatKey);
	
	NSString *message = [[[NSString alloc] initWithFormat:localizedFormat arguments:args] autorelease];
	[probMgr addProblemOfType:type message:message];
}


NSString *OOLocalizeProblemString(id <OOProblemReporting> probMgr, NSString *string)
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


void OOReportIssue(id <OOProblemReporting> probMgr, OOProblemReportType type, NSString *formatKey, ...)
{
	va_list args;
	va_start(args, formatKey);
	OOReportIssueWithArgs(probMgr, type, formatKey, args);
	va_end(args);
}



void OOReportInfo(id <OOProblemReporting> probMgr, NSString *formatKey, ...)
{
	va_list args;
	va_start(args, formatKey);
	OOReportIssueWithArgs(probMgr, kOOProblemTypeInformative, formatKey, args);
	va_end(args);
}


void OOReportWarning(id <OOProblemReporting> probMgr, NSString *formatKey, ...)
{
	va_list args;
	va_start(args, formatKey);
	OOReportIssueWithArgs(probMgr, kOOProblemTypeWarning, formatKey, args);
	va_end(args);
}


void OOReportError(id <OOProblemReporting> probMgr, NSString *formatKey, ...)
{
	va_list args;
	va_start(args, formatKey);
	OOReportIssueWithArgs(probMgr, kOOProblemTypeError, formatKey, args);
	va_end(args);
}


void OOReportNSError(id <OOProblemReporting> probMgr, NSString *context, NSError *error)
{
	NSString *desc = [error localizedFailureReason];
	if (desc == nil)  desc = [error localizedDescription];
	
	context = OOLocalizeProblemString(probMgr, context);
	if (desc == nil)  desc = context;
	else  desc = [NSString stringWithFormat:@"%@ %@", context, desc];
	
	[probMgr addProblemOfType:kOOProblemTypeError message:desc];
}


@implementation OOSimpleProblemReportManager

// Designated initializer: -init.


- (id) initWithContextString:(NSString *)context messageClassPrefix:(NSString *)messageClassPrefix
{
	if ((self = [self init]))
	{
		_contextString = [context retain];
		_messageClassPrefix = [messageClassPrefix retain];
	}
	return self;
}


- (id) initWithMeshFilePath:(NSString *)path forReading:(BOOL)forReading
{
	return [self initWithContextString:[NSString stringWithFormat:@"%@ \"%@\":", forReading ? @"Loading" : @"Writing", [[NSFileManager defaultManager] displayNameAtPath:path]]
					messageClassPrefix:@"mesh.load"];
}


- (void) dealloc
{
	DESTROY(_contextString);
	DESTROY(_messageClassPrefix);
	
	[super dealloc];
}


- (void) addProblemOfType:(OOProblemReportType)type message:(NSString *)message
{
	if (_contextString != nil)
	{
		OOLog((_messageClassPrefix != nil) ? _messageClassPrefix : @"problems", @"%@", _contextString);
		DESTROY(_contextString);
		_hadContextString = YES;
	}
	
	NSString *messageClass = @"problem";
	switch (type)
	{
		case kOOProblemTypeInformative:
			messageClass = @"note";
			break;
			
		case kOOProblemTypeWarning:
			messageClass = @"warning";
			break;
			
		case kOOProblemTypeError:
			messageClass = @"error";
			break;
	}
	
	if (_messageClassPrefix != nil)
	{
		messageClass = [NSString stringWithFormat:@"%@.%@", _messageClassPrefix, messageClass];
	}
	
	if (_hadContextString)  OOLogIndent();
	OOLog(messageClass, @"%@", message);
	if (_hadContextString)  OOLogOutdent();
}


- (NSString *) localizedProblemStringForKey:(NSString *)string
{
	return string;
}

@end