/*

OOConfGeneration.m
By Jens Ayton


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

#import "OOConfGenerationInternal.h"
#import "OOFunctionAttributes.h"
#import "NSStringOOExtensions.h"
#import "NSNumberOOExtensions.h"
#import "MYCollectionUtilities.h"


NSString * const kOOConfGenerationErrorDomain = @"org.oolite OOConfGeneration error domain";

static NSError *OOConfGenerationError(NSInteger code, NSString *format, ...);


@implementation NSObject (OOConfGeneration)

- (NSString *) ooConfStringWithOptions:(OOConfGenerationOptions)options error:(NSError **)outError
{
	if (![self conformsToProtocol:@protocol(OOConfGeneration)])
	{
		[NSException raise:NSGenericException format:@"%@ does not support OOConf generation.", [self class]];
	}
	
	NSError *error = nil;
	NSMutableString *result = [NSMutableString string];
	@try
	{
		if ([(id<OOConfGeneration>)self appendOOConfToString:result withOptions:options indentLevel:0 error:&error])
		{
#ifndef NDEBUG
			return [NSString stringWithString:result];
#else
			return result;
#endif
		}
		else
		{
			if (outError != NULL)
			{
				if (error == nil)
				{
					error = OOConfGenerationError(kOOConfGenerationErrorUnknownError, @"Internal error: OOConf generation failed, but no error was reported.");
				}
				*outError = error;
			}
			return nil;
		}

	}
	@catch (NSException *exception)
	{
		if (outError != NULL)
		{
			*outError = OOConfGenerationError(kOOConfGenerationErrorUnknownError, @"Internal error: unhandled exception in OOConf generation. %@", [exception reason]);
		}
		return nil;
	}
}


- (NSData *) ooConfDataWithOptions:(OOConfGenerationOptions)options error:(NSError **)outError
{
	NSString *string = [self ooConfStringWithOptions:options error:outError];
	if (string != nil)
	{
		return [string dataUsingEncoding:NSUTF8StringEncoding];
	}
	else
	{
		return nil;
	}
}


- (BOOL) writeOOConfDataWithOptions:(OOConfGenerationOptions)options toURL:(NSURL *)url error:(NSError **)outError
{
	NSData *data = [self ooConfDataWithOptions:options error:outError];
	if (data != nil)
	{
		return [data writeToURL:url options:NSDataWritingAtomic error:outError];
	}
	else
	{
		return NO;
	}
}


/*
	To avoid checks for <OOConfGeneration> conformance in the dictionary and
	array serializers, implement default behaviour on everything.
*/
- (BOOL) appendOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	NSParameterAssert(outError != NULL);
	
	if (options & kOOConfGenerationIgnoreInvalid)
	{
		return [[NSNull null] appendOOConfToString:string withOptions:options indentLevel:indentLevel error:outError];
	}
	else
	{
		*outError = OOConfGenerationError(kOOConfGenerationErrorInvalidValue, @"Objects of class %@ cannot be serialized to OOConf.", [self class]);
		return NO;
	}
}

@end


enum
{
	kMaxSimpleCount = 4,
	kMaxSimpleLength = 60
};


@implementation NSDictionary (OOConfGeneration)

- (BOOL) ooConf_isSimpleDictionary
{
	/*	A “simple” dictionary is one that can be written on a single line
		without looking terrible. Here we use an element count limit and
		an approximate overall length, allowing only strings and numbers.
	*/
	if ([self count] > kMaxSimpleCount)  return NO;
	
	NSUInteger totalLength = 0;
	
	id key = nil;
	foreachkey (key, self)
	{
		totalLength += [key length] + 4;
		if (totalLength > kMaxSimpleLength)  return NO;
		
		id object = [self objectForKey:key];
		if ([object isKindOfClass:[NSNumber class]])
		{
			totalLength += 8;	// ish.
		}
		else if ([object isKindOfClass:[NSString class]])
		{
			totalLength += [object length] + 4;
		}
		else
		{
			// Not string or number
			return NO;
		}
		
		if (totalLength > kMaxSimpleLength)  return NO;
	}
	
	return YES;
}


typedef enum
{
	kKeyError,
	kSkipKey,
	kIncludeKey
} OOConfKeyBehaviour;


- (OOConfKeyBehaviour) ooConf_appendKey:(id)key toString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options error:(NSError **)outError
{
	NSParameterAssert(outError != NULL);
	
	if (![key isKindOfClass:[NSString class]])
	{
		if (options & kOOConfGenerationIgnoreInvalid)  return kSkipKey;
		*outError = OOConfGenerationError(kOOConfGenerationErrorInvalidKey, @"Dictionary keys must be strings when serializing to OOConf.");
		return kKeyError;
	}
	
	if (!(options & kOOConfGenerationNoUnquotedKeys) && [key oo_isValidUnquotedOOConfKey])
	{
		[string appendString:key];
		return kIncludeKey;
	}
	
	[string appendFormat:@"\"%@\"", [key oo_escapedForJavaScriptLiteral]];
	return kIncludeKey;
}


- (BOOL) appendUglyOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	[string appendString:@"{"];
	
	BOOL first = YES;
	id key = nil;
	foreachkey (key, self)
	{
		if (!first)  [string appendString:@","];
		else  first = NO;
		
		OOConfKeyBehaviour behaviour = [self ooConf_appendKey:key toString:string withOptions:options error:outError];
		if (behaviour == kKeyError)  return NO;
		if (behaviour == kIncludeKey)
		{
			[string appendString:@":"];
			if (![[self objectForKey:key] appendOOConfToString:string withOptions:options indentLevel:0 error:outError])  return NO;
		}
	}
	[string appendString:@"}"];
	
	return YES;
}


- (BOOL) appendPrettyOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	if ([self count] == 0)
	{
		// Empty dictionary always goes on a single line.
		if (options & kOOConfGenerationAfterPunctuation)  [string appendString:@" {}"];
		else  [string appendString:@"{}"];
		return YES;
	}
	
	// For short dictionaries inside structures, use a single line.
	BOOL simple = [self ooConf_isSimpleDictionary] && indentLevel > 1;
	NSString *indent1 = OOTabString(indentLevel);
	NSString *indent2 = simple ? @" " : $sprintf(@"\n\t%@", indent1);
	
	// The complex business of printing an opening brace.
	if (options & kOOConfGenerationAfterPunctuation)
	{
		if (simple)  [string appendString:@" {"];
		else  [string appendFormat:@"\n%@{", indent1];
		
		options &= ~kOOConfGenerationAfterPunctuation;
	}
	else
	{
		[string appendString:@"{"];
	}
	
	// Now, let’s print some contents.
	BOOL first = YES;
	NSArray *sortedKeys = [[self allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	id key = nil;
	foreach (key, sortedKeys)
	{
		if (!first)  [string appendString:@","];
		else  first = NO;
			
		[string appendString:indent2];
		
		OOConfKeyBehaviour behaviour = [self ooConf_appendKey:key toString:string withOptions:options error:outError];
		if (behaviour == kKeyError)  return NO;
		if (behaviour == kIncludeKey)
		{
			[string appendString:@":"];
			if (![[self objectForKey:key] appendOOConfToString:string
												   withOptions:options | kOOConfGenerationAfterPunctuation
												   indentLevel:indentLevel + 1
														 error:outError])  return NO;
		}		
	}
	
	// Close brace.
	if (simple)
	{
		[string appendString:@" }"];
	}
	else
	{
		[string appendFormat:@"\n%@}", indent1];
	}
	
	return YES;
}


- (BOOL) appendOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	NSParameterAssert(outError != NULL);
	
	if (options & kOOConfGenerationNoPrettyPrint)
	{
		return [self appendUglyOOConfToString:string withOptions:options indentLevel:indentLevel error:outError];
	}
	else
	{
		return [self appendPrettyOOConfToString:string withOptions:options indentLevel:indentLevel error:outError];
	}
}

@end


@implementation NSArray (OOConfGeneration)

- (BOOL) ooConf_isSimpleArray
{
	/*	A “simple” array is one that can be written on a single line
		without looking terrible. Here we use an element count limit and
		an approximate overall length, allowing only strings and numbers.
	*/
	if ([self count] > kMaxSimpleCount)  return NO;
	
	NSUInteger totalLength = 0;
	
	id object = nil;
	foreach (object, self)
	{
		if ([object isKindOfClass:[NSNumber class]])
		{
			totalLength += 8;	// ish, including comma.
		}
		else if ([object isKindOfClass:[NSString class]])
		{
			totalLength += [object length] + 4; // 4 is for commas and quotes.
		}
		else
		{
			// Not string or number
			return NO;
		}
		
		if (totalLength > kMaxSimpleLength)  return NO;
	}
	
	return YES;
}


- (BOOL) appendUglyOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	[string appendString:@"["];
	
	BOOL first = YES;
	id object = nil;
	foreach (object, self)
	{
		if (!first)  [string appendString:@","];
		else  first = NO;
		
		if (![object appendOOConfToString:string withOptions:options indentLevel:0 error:outError])  return NO;
	}
	[string appendString:@"]"];
	
	return YES;
}


- (BOOL) appendPrettyOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	if ([self count] == 0)
	{
		// Empty array always goes on a single line.
		if (options & kOOConfGenerationAfterPunctuation)  [string appendString:@" []"];
		else  [string appendString:@"[]"];
		return YES;
	}
	
	// For short arrays inside structures, use a single line.
	BOOL simple = [self ooConf_isSimpleArray] && indentLevel > 1;
	NSString *indent1 = OOTabString(indentLevel);
	NSString *indent2 = simple ? @" " : $sprintf(@"\n\t%@", indent1);
	
	// The complex business of printing an opening bracket.
	if (options & kOOConfGenerationAfterPunctuation)
	{
		if (simple)  [string appendString:@" ["];
		else  [string appendFormat:@"\n%@[", indent1];
		
		options &= ~kOOConfGenerationAfterPunctuation;
	}
	else
	{
		[string appendString:@"["];
	}
	
	// Now, let’s print some contents.
	BOOL first = YES;
	id object = nil;
	foreach (object, self)
	{
		if (!first)  [string appendString:@","];
		else  first = NO;
		
		[string appendString:indent2];
		
		if (![object appendOOConfToString:string
							  withOptions:options
							  indentLevel:indentLevel + 1
									error:outError])  return NO;
	}
	
	// Close bracket.
	if (simple)
	{
		[string appendString:@" ]"];
	}
	else
	{
		[string appendFormat:@"\n%@]", indent1];
	}
	
	return YES;
}


- (BOOL) appendOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	NSParameterAssert(outError != NULL);
	
	if (options & kOOConfGenerationNoPrettyPrint)
	{
		return [self appendUglyOOConfToString:string withOptions:options indentLevel:indentLevel error:outError];
	}
	else
	{
		return [self appendPrettyOOConfToString:string withOptions:options indentLevel:indentLevel error:outError];
	}
}

@end


@implementation NSNumber (OOConfGeneration)

- (BOOL) appendOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	if (options & kOOConfGenerationAfterPunctuation)  [string appendString:@" "];
	
	if ([self oo_isBoolean])
	{
		if ([self boolValue])
		{
			[string appendString:@"true"];
		}
		else
		{
			[string appendString:@"false"];
		}
	}
	else
	{
		[string appendFormat:@"%@", self];
	}
	
	return YES;
}

@end


@implementation NSNull (OOConfGeneration)

- (BOOL) appendOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	if (options & kOOConfGenerationAfterPunctuation)  [string appendString:@" "];
	
	[string appendString:@"null"];
	return YES;
}

@end


@implementation NSString (OOConfGeneration)

- (BOOL) appendOOConfToString:(NSMutableString *)string withOptions:(OOConfGenerationOptions)options indentLevel:(NSUInteger)indentLevel error:(NSError **)outError
{
	if (options & kOOConfGenerationAfterPunctuation)  [string appendString:@" "];
	
	[string appendFormat:@"\"%@\"", [self oo_escapedForJavaScriptLiteral]];
	return YES;
}


- (BOOL) oo_isValidUnquotedOOConfKey
{
	NSUInteger length = [self length];
	if (length == 0)  return NO;
	
	static NSCharacterSet *unquotedInitialChars = nil;
	static NSCharacterSet *disallowedTailChars = nil;
	
	if (unquotedInitialChars == nil)
	{
		unquotedInitialChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ$_"] retain];
		disallowedTailChars = [[[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ$_0123456789"] invertedSet] retain];
	}
	
	if (![unquotedInitialChars characterIsMember:[self characterAtIndex:0]])  return NO;
	return [self rangeOfCharacterFromSet:disallowedTailChars options:NSLiteralSearch range:(NSRange){ 1, length - 1 }].location == NSNotFound;
}

@end


static NSError *OOConfGenerationError(NSInteger code, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	return [NSError errorWithDomain:kOOConfGenerationErrorDomain code:code userInfo:$dict(NSLocalizedFailureReasonErrorKey, message)];
}
