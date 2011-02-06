/*

OOLogging.h
By Jens Ayton

More flexible alternative to NSLog().


Copyright (C) 2007-2009 Jens Ayton and contributors

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

#import "OOCocoa.h"
#import <stdarg.h>


#ifndef OOLOG_FUNCTION_NAME
	#if defined (__GNUC__) && __GNUC__ >= 2
		#define OOLOG_FUNCTION_NAME	__PRETTY_FUNCTION__
	#elif 199901L <= __STDC_VERSION__
		#define OOLOG_FUNCTION_NAME	__func__
	#else
		#define OOLOG_FUNCTION_NAME	NULL
	#endif
#endif

#ifndef OOLOG_FILE_NAME
	#ifdef OOLOG_NO_FILE_NAME
		#define OOLOG_FILE_NAME NULL
	#else
		#define OOLOG_FILE_NAME __FILE__
	#endif
#endif


/*	General usage:
		OOLog(messageClass, format, parameters);
	is conceptually equivalent to:
		NSLog(format, parameters);
	except that it will do nothing if logging is disabled for messageClass.
	
	IMPORTANT: these are distinctly unhygenic macros. The format string and
	parameters are only evaluted if the message will actually be shown.
	
	A message class is a hierarchical string, such as:
		@"all.script.debug"
	
	To determine whether scripting is enabled for this class, a setting for
	@"all.script.debug" is looked up in a settings table. If it is not found,
	@"all.script" is tried, followed by @"all".
	
	Message class display settings can be manipulated with
	OOLogSetDisplayMessagesInClass() and tested with
	OOLogWillDisplayMessagesInClass().
*/
#define OOLog(class, format, ...)				do { if (OOLogWillDisplayMessagesInClass(class)) { OOLogWithFunctionFileAndLine(class, OOLOG_FUNCTION_NAME, OOLOG_FILE_NAME, __LINE__, format, ## __VA_ARGS__); }} while (0)
#define OOLogWithArgmuents(class, format, args)	do { if (OOLogWillDisplayMessagesInClass(class)) { OOLogWithFunctionFileAndLineAndArguments(class, OOLOG_FUNCTION_NAME, OOLOG_FILE_NAME, __LINE__, format, args); }} while (0)


#define OOLogERR(class, format, ...) OOLogWithPrefix(class, OOLOG_FUNCTION_NAME, OOLOG_FILE_NAME, __LINE__, @"***** ERROR: ",format, ## __VA_ARGS__)
#define OOLogWARN(class, format, ...) OOLogWithPrefix(class, OOLOG_FUNCTION_NAME, OOLOG_FILE_NAME, __LINE__, @"----- WARNING: ",format, ## __VA_ARGS__)


BOOL OOLogWillDisplayMessagesInClass(NSString *messageClass);

void OOLogIndent(void);
void OOLogOutdent(void);

#define OOLogIndentIf(class)		do { if (OOLogWillDisplayMessagesInClass(class)) OOLogIndent(); } while (0)
#define OOLogOutdentIf(class)		do { if (OOLogWillDisplayMessagesInClass(class)) OOLogOutdent(); } while (0)

// Remember/restore indent levels, for cases where an exception may occur while indented.
void OOLogPushIndent(void);
void OOLogPopIndent(void);

void OOLogWithPrefix(NSString *messageClass, const char *function, const char *fileName, unsigned long line, NSString *prefix, NSString *format, ...);
void OOLogWithFunctionFileAndLine(NSString *messageClass, const char *function, const char *fileName, unsigned long line, NSString *format, ...);
void OOLogWithFunctionFileAndLineAndArguments(NSString *messageClass, const char *function, const char *fileName, unsigned long line, NSString *format, va_list arguments);

// OOLogGenericParameterError(): general parameter error message, "***** $function_name: bad parameters. (This is an internal programming error, please report it.)"
#define OOLogGenericParameterError()	OOLogGenericParameterErrorForFunction(OOLOG_FUNCTION_NAME)
void OOLogGenericParameterErrorForFunction(const char *function);

// OOLogGenericSubclassResponsibility(): general subclass responsibility message, "***** $function_name is a subclass responsibility. (This is an internal programming error, please report it.)"
#define OOLogGenericSubclassResponsibility()	OOLogGenericSubclassResponsibilityForFunction(OOLOG_FUNCTION_NAME)
void OOLogGenericSubclassResponsibilityForFunction(const char *function);


// OODebugLog() is only included in debug builds.
#if OO_DEBUG
#define OODebugLog OOLog
#else
#define OODebugLog(...)  do {} while (0)
#endif


// OOExtraLog() is included in debug and test-release builds, but not deployment builds.
#ifndef NDEBUG
#define OOExtraLog OOLog
#else
#define OOExtraLog(...)  do {} while (0)
#endif


// *** Predefined message classes.
/*	These are general coding error types. Generally a subclass should be used
	for each instance -- for instance, -[Entity warnAboutHostiles] uses
	@"general.error.subclassResponsibility.Entity-warnAboutHostiles".
*/

extern NSString * const kOOLogSubclassResponsibility;		// @"general.error.subclassResponsibility"
extern NSString * const kOOLogParameterError;				// @"general.error.parameterError"
extern NSString * const kOOLogDeprecatedMethod;				// @"general.error.deprecatedMethod"
extern NSString * const kOOLogAllocationFailure;			// @"general.error.allocationFailure"
extern NSString * const kOOLogInconsistentState;			// @"general.error.inconsistentState"
extern NSString * const kOOLogException;					// @"exception"

extern NSString * const kOOLogFileNotFound;					// @"files.notfound"
extern NSString * const kOOLogFileNotLoaded;				// @"files.notloaded"

extern NSString * const kOOLogOpenGLError;					// @"rendering.opengl.error"

// Don't use. However, #defining it as @"unclassified.module" can be used as a stepping stone to OOLog support.
extern NSString * const kOOLogUnconvertedNSLog;				// @"unclassified"


#define JA_DUMP_LOG(...) OOLog(@"temp.dump", __VA_ARGS__)
#define OODUMP JA_DUMP
#import "JAValueToString.h"
