/*

OOLogging.m


Copyright © 2007-2010 Jens Ayton and contributors

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


#define OOLOG_POISON_NSLOG 0

#import "OOLoggingExtended.h"
#import "OOFunctionAttributes.h"
#import "NSThreadOOExtensions.h"
#import "OOLogOutputHandler.h"

#undef NSLog		// We need to be able to call the real NSLog.


#if OOLITE_USE_TLS	// Define to use __thread keyword where supported
	#define USE_INDENT_GLOBALS		1
	#define THREAD_LOCAL			__thread
#else
	#define USE_INDENT_GLOBALS		0
	static NSString * const kIndentLevelKey = @"org.oolite.oolog.indentLevel";
	static NSString * const kIndentStackKey = @"org.oolite.oolog.indentStack";
#endif


// Control flags for OOLogInternal() - like message classes, but less cool.
#define OOLOG_INIT_FAILED			1
#define OOLOG_SETTING_SET			0
#define OOLOG_SETTING_RETRIEVE		0
#define OOLOG_METACLASS_LOOP		1
#define OOLOG_UNDEFINED_METACLASS	1
#define OOLOG_BAD_SETTING			1
#define OOLOG_BAD_DEFAULT_SETTING	1
#define OOLOG_BAD_POP_INDENT		1
#define OOLOG_EXCEPTION_IN_LOG		1


// Used to track OOLogPushIndent()/OOLogPopIndent() state.
typedef struct OOLogIndentStackElement OOLogIndentStackElement;
struct OOLogIndentStackElement
{
	OOLogIndentStackElement		*link;
	unsigned					indent;
};


typedef void (*PrintLogMessageIMP)(id self, SEL _cmd, NSString *message);
typedef BOOL (*ShouldShowMessageInClassIMP)(id self, SEL _cmd, NSString *messageClass);


static OOLogOutputHandler			*sHandler = nil;
static PrintLogMessageIMP			sPrintLogMessage;
static ShouldShowMessageInClassIMP	sShouldShowMessageInClass;


// We could probably use less state variables.
static NSLock						*sLock = nil;
#if USE_INDENT_GLOBALS
static THREAD_LOCAL unsigned		sIndentLevel = 0;
static THREAD_LOCAL OOLogIndentStackElement
									*sIndentStack = NULL;
#endif
static BOOL							sShowFunction = NO;
static BOOL							sShowFileAndLine = NO;
static BOOL							sShowClass = YES;


// To avoid recursion/self-dependencies, OOLog gets its own logging function.
#define OOLogInternal(cond, format, ...) do { if ((cond)) { OOLogInternal_(OOLOG_FUNCTION_NAME, format, ## __VA_ARGS__); }} while (0)
static void OOLogInternal_(const char *function, NSString *format, ...);


OOINLINE unsigned GetIndentLevel(void);
OOINLINE void SetIndentLevel(unsigned level);


#ifndef OOLOG_NO_FILE_NAME
static NSMutableDictionary		*sFileNamesCache = nil;
#endif


OOINLINE void CheckInited(void)
{
	if (EXPECT_NOT(sHandler == nil))
	{
		OOLoggingInit(NULL);
	}
}


BOOL OOLogWillDisplayMessagesInClass(NSString *messageClass)
{
	CheckInited();
	return sShouldShowMessageInClass(sHandler, @selector(shouldShowMessageInClass:), messageClass);
}


void OOLogSetDisplayMessagesInClass(NSString *messageClass, BOOL flag)
{
	CheckInited();
	[sHandler setShouldShowMessage:flag inClass:messageClass];
}


NSString *OOLogGetParentMessageClass(NSString *messageClass)
{
	NSRange					range;
	
	if (messageClass == nil) return nil;
	
	range = [messageClass rangeOfString:@"." options:NSCaseInsensitiveSearch | NSLiteralSearch | NSBackwardsSearch];	// Only NSBackwardsSearch is important, others are optimizations
	if (range.location == NSNotFound) return nil;
	
	return [messageClass substringToIndex:range.location];
}


OOINLINE void OOLogOutputHandlerPrint(NSString *message)
{
	sPrintLogMessage(sHandler, @selector(printLogMessage:), message);
}


#if USE_INDENT_GLOBALS

#if OOLITE_USE_TLS
	#define INDENT_LOCK()		do {} while (0)
	#define INDENT_UNLOCK()		do {} while (0)
#else
	#define INDENT_LOCK()		[sLock lock]
	#define INDENT_UNLOCK()		[sLock unlock]
#endif


OOINLINE unsigned GetIndentLevel(void)
{
	return sIndentLevel;
}


OOINLINE void SetIndentLevel(unsigned value)
{
	sIndentLevel = value;
}


void OOLogPushIndent(void)
{
	OOLogIndentStackElement	*elem = NULL;
	
	elem = malloc(sizeof *elem);
	if (elem != NULL)
	{
		INDENT_LOCK();
		
		elem->indent = sIndentLevel;
		elem->link = sIndentStack;
		sIndentStack = elem;
		
		INDENT_UNLOCK();
	}
}


void OOLogPopIndent(void)
{
	INDENT_LOCK();
	
	OOLogIndentStackElement	*elem = sIndentStack;
	
	if (elem != NULL)
	{
		sIndentStack = elem->link;
		sIndentLevel = elem->indent;
		free(elem);
	}
	else
	{
		OOLogInternal(OOLOG_BAD_POP_INDENT, @"OOLogPopIndent(): state stack underflow.");
	}
	INDENT_UNLOCK();
}

#else	// !USE_INDENT_GLOBALS

#define INDENT_LOCK()			do {} while (0)
#define INDENT_UNLOCK()			do {} while (0)


OOINLINE unsigned GetIndentLevel(void)
{
	NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
	return [[threadDict objectForKey:kIndentLevelKey] unsignedIntValue];
}


OOINLINE void SetIndentLevel(unsigned value)
{
	NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
	[threadDict setObject:[NSNumber numberWithUnsignedInt:value] forKey:kIndentLevelKey];
}


void OOLogPushIndent(void)
{
	OOLogIndentStackElement	*elem = NULL;
	NSMutableDictionary		*threadDict = nil;
	NSValue					*val = nil;
	
	elem = malloc(sizeof *elem);
	if (elem != NULL)
	{
		threadDict = [[NSThread currentThread] threadDictionary];
		val = [threadDict objectForKey:kIndentStackKey];
		
		elem->indent = [[threadDict objectForKey:kIndentLevelKey] intValue];
		elem->link = [val pointerValue];
		[threadDict setObject:[NSValue valueWithPointer:elem] forKey:kIndentStackKey];
	}
}


void OOLogPopIndent(void)
{
	OOLogIndentStackElement	*elem = NULL;
	NSMutableDictionary		*threadDict = nil;
	NSValue					*val = nil;
	
	threadDict = [[NSThread currentThread] threadDictionary];
	val = [threadDict objectForKey:kIndentStackKey];
	
	elem = [val pointerValue];
	
	if (elem != NULL)
	{
		[threadDict setObject:[NSNumber numberWithUnsignedInt:elem->indent] forKey:kIndentLevelKey];
		[threadDict setObject:[NSValue valueWithPointer:elem->link] forKey:kIndentStackKey];
		free(elem);
	}
	else
	{
		OOLogInternal(OOLOG_BAD_POP_INDENT, @"OOLogPopIndent(): state stack underflow.");
	}
}

#endif	// USE_INDENT_GLOBALS


void OOLogIndent(void)
{
	INDENT_LOCK();

	SetIndentLevel(GetIndentLevel() + 1);
	
	INDENT_UNLOCK();
}


void OOLogOutdent(void)
{
	INDENT_LOCK();
	
	unsigned indentLevel = GetIndentLevel();
	if (indentLevel != 0)  SetIndentLevel(indentLevel - 1);
	
	INDENT_UNLOCK();
}


void OOLogWithPrefix(NSString *messageClass, const char *function, const char *fileName, unsigned long line, NSString *prefix, NSString *format, ...)
{
	if (!OOLogWillDisplayMessagesInClass(messageClass)) return;
	
	va_list args;
	va_start(args, format);
	OOLogWithFunctionFileAndLineAndArguments(messageClass, function, fileName, line, [prefix stringByAppendingString:format], args);
	va_end(args);
}


void OOLogWithFunctionFileAndLine(NSString *messageClass, const char *function, const char *fileName, unsigned long line, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	OOLogWithFunctionFileAndLineAndArguments(messageClass, function, fileName, line, format, args);
	va_end(args);
}


void OOLogWithFunctionFileAndLineAndArguments(NSString *messageClass, const char *function, const char *fileName, unsigned long line, NSString *format, va_list arguments)
{
	NSAutoreleasePool	*pool = nil;
	NSString			*formattedMessage = nil;
	unsigned			indentLevel;
	
	if (EXPECT_NOT(format == nil))  return;
	CheckInited();
	
	pool = [[NSAutoreleasePool alloc] init];
	
	NS_DURING
		// Do argument substitution
		formattedMessage = [[[NSString alloc] initWithFormat:format arguments:arguments] autorelease];
		
		// Apply various prefix options
	#ifndef OOLOG_NO_FILE_NAME
		if (sShowFileAndLine && fileName != NULL)
		{
			if (sShowFunction)
			{
				formattedMessage = [NSString stringWithFormat:@"%s (%@:%u): %@", function, OOLogAbbreviatedFileName(fileName), line, formattedMessage];
			}
			else
			{
				formattedMessage = [NSString stringWithFormat:@"%@:%u: %@", OOLogAbbreviatedFileName(fileName), line, formattedMessage];
			}
		}
		else
	#endif
		{
			if (sShowFunction)
			{
				formattedMessage = [NSString stringWithFormat:@"%s: %@", function, formattedMessage];
			}
		}
		
		if (sShowClass)
		{
			if (sShowFunction || sShowFileAndLine)
			{
				formattedMessage = [NSString stringWithFormat:@"[%@] %@", messageClass, formattedMessage];
			}
			else
			{
				formattedMessage = [NSString stringWithFormat:@"[%@]: %@", messageClass, formattedMessage];
			}
		}
		
		// Apply indentation
		indentLevel = GetIndentLevel();
		if (indentLevel != 0)
		{
			#define INDENT_FACTOR	2		/* Spaces per indent level */
			#define MAX_INDENT		64		/* Maximum number of indentation _spaces_ */
			
			unsigned			indent;
								// String of 64 spaces (null-terminated)
			const char			spaces[MAX_INDENT + 1] =
								"                                                                ";
			const char			*indentString;
			
			indent = INDENT_FACTOR * indentLevel;
			if (MAX_INDENT < indent) indent = MAX_INDENT;
			indentString = &spaces[MAX_INDENT - indent];
			
			formattedMessage = [NSString stringWithFormat:@"%s%@", indentString, formattedMessage];
		}
		
		OOLogOutputHandlerPrint(formattedMessage);
	NS_HANDLER
		OOLogInternal(OOLOG_EXCEPTION_IN_LOG, @"***** Exception thrown during logging: %@ : %@", [localException name], [localException reason]);
	NS_ENDHANDLER
	
	[pool release];
}


void OOLogGenericParameterErrorForFunction(const char *function)
{
	OOLog(kOOLogParameterError, @"***** %s: bad parameters. (This is an internal programming error, please report it.)", function);
}


void OOLogGenericSubclassResponsibilityForFunction(const char *function)
{
	OOLog(kOOLogSubclassResponsibility, @"***** %s is a subclass responsibility. (This is an internal programming error, please report it.)", function);
}


BOOL OOLogShowFunction(void)
{
	return sShowFunction;
}


void OOLogSetShowFunction(BOOL flag)
{
	CheckInited();
	
	flag = !!flag;
	
	if (flag != sShowFunction)
	{
		sShowFunction = flag;
		[sHandler setShowFunction:flag];
	}
}


BOOL OOLogShowFileAndLine(void)
{
	return sShowFileAndLine;
}


void OOLogSetShowFileAndLine(BOOL flag)
{
	CheckInited();
	
	flag = !!flag;
	
	if (flag != sShowFileAndLine)
	{
		sShowFileAndLine = flag;
		[sHandler setShowFunction:flag];
	}
}


BOOL OOLogShowMessageClass(void)
{
	return sShowClass;
}


void OOLogSetShowMessageClass(BOOL flag)
{
	CheckInited();
	
	flag = !!flag;
	
	if (flag != sShowClass)
	{
		sShowClass = flag;
		[sHandler setShowFunction:flag];
	}
}


void OOLogSetShowMessageClassTemporary(BOOL flag)
{
	sShowClass = !!flag;
}


void OOLoggingInit(OOLogOutputHandler *logHandler)
{
	if (sHandler != nil)  return;
	if (logHandler != nil)  sHandler = [logHandler retain];
	else  sHandler = [[OOLogOutputHandler alloc] init];
	
	sLock = [[NSLock alloc] init];
	[sLock ooSetName:@"OOLogging lock"];
	if (sLock == nil)
	{
		OOLogInternal(OOLOG_INIT_FAILED, @"***** Failed to allocate log lock.");
		exit(EXIT_FAILURE);
	}
	
	sPrintLogMessage = (PrintLogMessageIMP)[sHandler methodForSelector:@selector(printLogMessage:)];
	sShouldShowMessageInClass = (ShouldShowMessageInClassIMP)[sHandler methodForSelector:@selector(shouldShowMessageInClass:)];
	
	if (sPrintLogMessage == NULL || sShouldShowMessageInClass == NULL)
	{
		OOLogInternal(OOLOG_INIT_FAILED, @"***** Invalid log handler.");
		exit(EXIT_FAILURE);
	}
	
	sShowFunction = [sHandler showFunction];
	sShowFileAndLine = [sHandler showFileAndLine];
	sShowClass = [sHandler showMessageClass];
}


void OOLoggingTerminate(void)
{
	[sHandler release];
	sHandler = nil;
}


void OOLogInsertMarker(void)
{
	CheckInited();
	
	static unsigned		lastMarkerID = 0;
	unsigned			thisMarkerID;
	NSString			*marker = nil;
	
	[sLock lock];
	thisMarkerID = ++lastMarkerID;
	[sLock unlock];
	
	marker = [NSString stringWithFormat:@"\n\n========== [Marker %u] ==========", thisMarkerID];
	OOLogOutputHandlerPrint(marker);
}


NSString * const kOOLogSubclassResponsibility		= @"general.error.subclassResponsibility";
NSString * const kOOLogParameterError				= @"general.error.parameterError";
NSString * const kOOLogDeprecatedMethod				= @"general.error.deprecatedMethod";
NSString * const kOOLogAllocationFailure			= @"general.error.allocationFailure";
NSString * const kOOLogInconsistentState			= @"general.error.inconsistentState";
NSString * const kOOLogException					= @"exception";
NSString * const kOOLogFileNotFound					= @"files.notFound";
NSString * const kOOLogFileNotLoaded				= @"files.notLoaded";
NSString * const kOOLogOpenGLError					= @"rendering.opengl.error";
NSString * const kOOLogUnconvertedNSLog				= @"unclassified";


/*	OOLogInternal_()
	Implementation of OOLogInternal(), private logging function used by
	OOLogging so it doesn’t depend on itself (and risk recursiveness).
*/
static void OOLogInternal_(const char *function, NSString *format, ...)
{
	va_list				args;
	NSString			*formattedMessage = nil;
	NSAutoreleasePool	*pool = nil;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	NS_DURING
		va_start(args, format);
		formattedMessage = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
		va_end(args);
		
		formattedMessage = [NSString stringWithFormat:@"OOLogging internal - %s: %@", function, formattedMessage];
		
		if (sHandler != nil)
		{
			OOLogOutputHandlerPrint(formattedMessage);
		}
		else
		{
			fprintf(stderr, "%s\n", [formattedMessage UTF8String]);
		}
	NS_HANDLER
		fprintf(stderr, "***** Exception in OOLogInternal_(): %s : %s", [[localException name] UTF8String], [[localException reason] UTF8String]);
	NS_ENDHANDLER
	
	[pool release];
}


/*	OOLogAbbreviatedFileName()
	Map full file paths provided by __FILE__ to more mananagable file names,
	with caching.
*/
NSString *OOLogAbbreviatedFileName(const char *inName)
{
	CheckInited();
	
#ifndef OOLOG_NO_FILE_NAME
	NSValue				*key = nil;
	NSString			*name = nil;
	
	if (inName == NULL)  return @"unspecified file";
	
	[sLock lock];
	key = [NSValue valueWithPointer:inName];
	name = [sFileNamesCache objectForKey:key];
	if (name == nil)
	{
		name = [[NSString stringWithUTF8String:inName] lastPathComponent];
		if (sFileNamesCache == nil) sFileNamesCache = [[NSMutableDictionary alloc] init];
		[sFileNamesCache setObject:name forKey:key];
	}
	[sLock unlock];
	
	return name;
#else
	return nil;
#endif
}
