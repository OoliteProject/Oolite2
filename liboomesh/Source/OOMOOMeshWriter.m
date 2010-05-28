/*
	OOMOOMeshWriter.h
	
	
	Copyright © 2010 Jens Ayton.
	
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

#import "OOMOomeshWriter.h"
#import "OOMProblemReportManager.h"
#import "CollectionUtils.h"
#import "OOCollectionExtractors.h"

#import "OOMFloatArray.h"
#import "OOMVertex.h"
#import "OOMFace.h"
#import "OOMFaceGroup.h"
#import "OOMMesh.h"
#import "OOMMaterialSpecification.h"
#import "OOMTextureSpecification.h"
#import "NSNumberOOExtensions.h"


/*
	OOMWriteToOOMesh
	Property for writing to OOMesh files. This is implemented for the property
	list types that are supported in meshes: NSString, NSNumber, NSArray and
	NSDictionary.
	
	The entire file is actually a plist in this format, but most of the contents
	are written using specialized code for efficiency and stylistic cleanness
	(e.g. writing the data entries of attributes and groups in an appropriate
	number of columns).
*/
@protocol OOMWriteToOOMesh

- (void) oom_writeToOOMesh:(NSMutableString *)oomeshText indentLevel:(NSUInteger)indentLevel afterPunctuation:(BOOL)afterPunct;

@end


static NSString *EscapeString(NSString *string);


BOOL OOMWriteOOMesh(OOMMesh *mesh, NSString *path, id <OOMProblemReportManager> issues)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	BOOL OK = YES;
	NSError *error = nil;
	NSString *name = [path lastPathComponent];
	
	NSData *data = OOMDataFromMesh(mesh, name, issues);
	OK = (data != nil);
	
	if (OK)
	{
		OK = [data writeToFile:path options:NSDataWritingAtomic error:&error];
		if (!OK)
		{
			OOMReportNSError(issues, @"fileNotOpened", $sprintf(@"Could not write to %@", name), error);
		}
	}
	
	[pool drain];
	return OK;
}


NSData *OOMDataFromMesh(OOMMesh *mesh, NSString *name, id <OOMProblemReportManager> issues)
{
	if (mesh == nil)  return nil;
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSMutableString *result = [NSMutableString string];
	
	//	Generate list of unique vertex indices (pointer uniquing only).
	NSMutableArray *vertices = [NSMutableArray array];
	NSMutableDictionary *indices = [NSMutableDictionary dictionary];
	NSUInteger vertexCount = 0;
	NSUInteger dupeCount = 0;
	
	OOMFaceGroup *faceGroup = nil;
	OOMFace *face = nil;
	OOMVertex *vertex = nil;
	OOMMaterialSpecification *material = nil;
	
	//	Unique vertices across groups, and count 'em.
	//	FIXME: ensure all vertices have same attributes. Should be public utility method.
	foreach (faceGroup, mesh)
	{
		foreach (face, faceGroup)
		{
			NSAutoreleasePool *pool = [NSAutoreleasePool new];
			
			for (NSUInteger vIter = 0; vIter < 3; vIter++)
			{
				vertex = [face vertexAtIndex:vIter];
				
				NSValue *boxed = [NSValue valueWithNonretainedObject:vertex];
				NSNumber *index = [indices objectForKey:boxed];
				if (index == nil)
				{
					index = [NSNumber numberWithUnsignedInteger:vertexCount++];
					[indices setObject:index forKey:boxed];
					[vertices addObject:vertex];
				}
				else
				{
					dupeCount++;
				}

			}
			
			[pool drain];
		}
	}
	
	
	//	Unique materials by name.
	NSMutableDictionary *materials = [NSMutableDictionary dictionaryWithCapacity:[mesh faceGroupCount]];
	OOMMaterialSpecification *anonMaterial = nil;
	
	foreach (faceGroup, [mesh faceGroupEnumerator])
	{
		material = [faceGroup material];
		
		if (material == nil)
		{
			// Generate a blank material.
			if (anonMaterial == nil)
			{
				anonMaterial = [[[OOMMaterialSpecification alloc] initWithMaterialKey:@"<unnamed>"] autorelease];
			}
			material = anonMaterial;
		}
		
		[materials setObject:material forKey:[material materialKey]];
	}
	
	
	//	Write header.
	[result appendString:@"oomesh"];
	if (name != nil)
	{
		if ([[[name pathExtension] lowercaseString] isEqualToString:@"oomesh"])  name = [name stringByDeletingPathExtension];
		[result appendFormat:@" \"%@\"", EscapeString(name)];
	}
	[result appendFormat:@":\n{\n\tvertexCount: %lu // duplicates: %lu\n\tgroupCount: %lu\n", (unsigned long)vertexCount, (unsigned long)dupeCount, [mesh faceGroupCount]];
	
	
	//	Write materials.
	NSArray *sortedMaterialKeys = [[materials allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSString *materialKey = nil;
	foreach (materialKey, sortedMaterialKeys)
	{
		[result appendFormat:@"\t\n\tmaterial \"%@\":", EscapeString(materialKey)];
		
		id materialProperties = [[materials objectForKey:materialKey] ja_propertyListRepresentation];
		if (materialProperties == nil)  materialProperties = [NSDictionary dictionary];
		
		[materialProperties oom_writeToOOMesh:result
								  indentLevel:1
							 afterPunctuation:YES];
		
		[result appendString:@"\n"];
	}
	
	
	//	Write vertex attributes.
	if (vertexCount > 0)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		OOMVertex *protoVertex = [vertices objectAtIndex:0];
		NSArray *attributeKeys = [[protoVertex allAttributeKeys] sortedArrayUsingSelector:@selector(oom_compareByVertexAttributeOrder:)];
		NSString *key = nil;
		foreach (key, attributeKeys)
		{
			NSUInteger i, count = [[protoVertex attributeForKey:key] count];
			
			[result appendFormat:@"\t\n\tattribute \"%@\":\n\t{\n\t\tsize: %lu\n\t\tdata:\n\t\t[\n", EscapeString(key), (unsigned long)count];
			
			foreach (vertex, vertices)
			{
				[result appendString:@"\t\t\t"];
				
				OOMFloatArray *attr = [vertex attributeForKey:key];
				for (i = 0; i < count; i++)
				{
					[result appendFormat:@"%f%@", [attr floatAtIndex:i], (i == count - 1) ? @"\n" : @", "];
				}
			}
			
			[result appendString:@"\t\t]\n\t}\n"];
		}
		
		[pool drain];
	}
	
	
	//	Write groups.
	foreach (faceGroup, [mesh faceGroupEnumerator])
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		[result appendString:@"\t\n\tgroup"];
		if ([faceGroup name] != nil)
		{
			[result appendFormat:@" \"%@\"", EscapeString([faceGroup name])];
		}
		[result appendFormat:@":\n\t{\n\t\tfaceCount: %lu\n\t\tdata:\n\t\t[\n", [faceGroup faceCount]];
		
		foreach (face, faceGroup)
		{
			[result appendString:@"\t\t\t"];
			
			for (NSUInteger vIter = 0; vIter < 3; vIter++)
			{
				vertex = [face vertexAtIndex:vIter];
				
				NSValue *boxed = [NSValue valueWithNonretainedObject:vertex];
				NSUInteger index = [indices oo_unsignedIntegerForKey:boxed];
				
				[result appendFormat:@"%lu%@", (unsigned long)index, (vIter == 2) ? @"\n" : @", "];
			}
		}
		
		[result appendString:@"\t\t]\n\t}\n"];
		
		[pool drain];
	}
	
	[result appendString:@"}\n"];
	
	NSData *data = [[result dataUsingEncoding:NSUTF8StringEncoding] retain];
	[pool release];
	
	return [data autorelease];
}


static NSString *EscapeString(NSString *string)
{
	static NSCharacterSet *charSet = nil;
	
	if (charSet == nil)
	{
		charSet = [[NSCharacterSet characterSetWithCharactersInString:@"\\\b\f\n\r\t\v\'\""] retain];
	}
	
	NSMutableString *result = [NSMutableString stringWithCapacity:[string length]];
	NSScanner *scanner = [NSScanner scannerWithString:string];
	
	for (;;)
	{
		NSString *substr = nil;
		if (![scanner scanUpToCharactersFromSet:charSet intoString:&substr])  break;
		[result appendString:substr];
		
		if (![scanner scanCharactersFromSet:charSet intoString:&substr])  break;
		
		NSUInteger i, length = [substr length];
		for (i = 0; i < length; i++)
		{
			unichar c = [substr characterAtIndex:i];
			switch (c)
			{
				case '\\':
					[result appendString:@"\\\\"];
					break;
					
				case '\b':
					[result appendString:@"\\b"];
					break;
					
				case '\f':
					[result appendString:@"\\f"];
					break;
					
				case '\n':
					[result appendString:@"\\n"];
					break;
					
				case '\r':
					[result appendString:@"\\r"];
					break;
					
				case '\t':
					[result appendString:@"\\t"];
					break;
					
				case '\v':
					[result appendString:@"\\v"];
					break;
					
				case '\'':
					[result appendString:@"\\\'"];
					break;
					
				case '\"':
					[result appendString:@"\\\""];
					break;
					
				default:
					substr = [NSString stringWithCharacters:&c length:1];
					[NSException raise:NSInternalInconsistencyException format:@"EscapeString() bug: character \'%c\' (U+%.4X) matched by escape charset, but not switch statement.", substr, c];
			}
		}
	}
	
	return result;
}


static NSString *IndentTabs(NSUInteger count)
{
	NSString * const staticTabs[] =
	{
		@"",
		@"\t",
		@"\t\t",
		@"\t\t\t",
		@"\t\t\t\t",
		@"\t\t\t\t\t",
		@"\t\t\t\t\t\t",
		@"\t\t\t\t\t\t\t"
	};
	
	if (count < sizeof staticTabs / sizeof *staticTabs)
	{
		return staticTabs[count];
	}
	else
	{
		NSMutableString *result = [NSMutableString stringWithCapacity:count];
		for (NSUInteger i = 0; i < count; i++)
		{
			[result appendString:@"\t"];
		}
		return result;
	}

}


@interface NSString (OOMWriteToOOMesh) <OOMWriteToOOMesh>
@end

@interface NSNumber (OOMWriteToOOMesh) <OOMWriteToOOMesh>
@end

@interface NSArray (OOMWriteToOOMesh) <OOMWriteToOOMesh>
@end

@interface NSDictionary (OOMWriteToOOMesh) <OOMWriteToOOMesh>
@end


@implementation NSString (OOMWriteToOOMesh)

- (void) oom_writeToOOMesh:(NSMutableString *)oomeshText
			   indentLevel:(NSUInteger)indentLevel
		  afterPunctuation:(BOOL)afterPunct
{
	if (afterPunct)  [oomeshText appendString:@" "];
	[oomeshText appendFormat:@"\"%@\"", EscapeString(self)];
}


static BOOL IsValidInitialDictChar(unichar c)
{
	return isalpha(c) || c == '_';
}


static BOOL IsValidDictChar(unichar c)
{
	return IsValidInitialDictChar(c) || isdigit(c) || c == '.' || c == '-';
}


- (BOOL) oom_isValidDictKey
{
	NSUInteger i, length = [self length];
	if (length == 0 || length > 60)  return NO;
	
	unichar c = [self characterAtIndex:0];
	if (!IsValidInitialDictChar(c))  return NO;
	
	for (i = 1; i < length; i++)
	{
		if (!IsValidDictChar([self characterAtIndex:i]))  return NO;
	}
	
	return YES;
}

@end


@implementation NSNumber (OOMWriteToOOMesh)

- (void) oom_writeToOOMesh:(NSMutableString *)oomeshText
			   indentLevel:(NSUInteger)indentLevel
		  afterPunctuation:(BOOL)afterPunct
{
	if (afterPunct)  [oomeshText appendString:@" "];
	if ([self oo_isFloatingPointNumber])
	{
		[oomeshText appendFormat:@"%f", [self doubleValue]];
	}
	else
	{
		[oomeshText appendFormat:@"%lli", [self longLongValue]];
	}
}

@end


enum
{
	kMaxSimpleCount = 3,
	kMaxSimpleLength = 60
};


@implementation NSArray (OOMWriteToOOMesh)

- (BOOL) oom_isSimpleArray
{
	/*	A "simple" array is one that can be written on a single line
		without looking terrible. Here we use an element count limit and
		an approximate overall length, allowing only strings and numbers.
	*/
	if ([self count] > kMaxSimpleCount)  return NO;
	
	NSUInteger totalLength = 0;
	
	id object = nil;
	foreach (object, self)
	{
		totalLength += 4;		// Punctuation overhead.
		
		if ([object isKindOfClass:[NSNumber class]])
		{
			totalLength += 5;	// ish.
		}
		else if ([object isKindOfClass:[NSString class]])
		{
			totalLength += [object length];
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


- (void) oom_writeToOOMesh:(NSMutableString *)oomeshText
			   indentLevel:(NSUInteger)indentLevel
		  afterPunctuation:(BOOL)afterPunct
{
	if ([self count] == 0)
	{
		if (afterPunct)  [oomeshText appendString:@" "];
		[oomeshText appendString:@"[]"];
	}
	else
	{
		BOOL simple = [self oom_isSimpleArray] && indentLevel > 1, first = YES;
		
		NSString *indent1 = IndentTabs(indentLevel);
		NSString *indent2 = simple ? @" " : $sprintf(@"\n%@", IndentTabs(indentLevel + 1));
		
		if (afterPunct)
		{
			if (simple) [oomeshText appendString:@" ["];
			else  [oomeshText appendFormat:@"\n%@[", indent1];
		}
		else
		{
			[oomeshText appendString:@"["];
		}
		
		id object = nil;
		foreach (object, self)
		{
			if (simple)
			{
				if (!first)  [oomeshText appendString:@","];
				first = NO;
			}
			[oomeshText appendString:indent2];
			
			[object oom_writeToOOMesh:oomeshText
						  indentLevel:indentLevel + 1
					 afterPunctuation:NO];
		}
		
		if (simple)
		{
			[oomeshText appendString:@" ]"];
		}
		else
		{
			[oomeshText appendFormat:@"\n%@]", indent1];
		}
	}
}

@end


@implementation NSDictionary (OOMWriteToOOMesh)

- (BOOL) oom_isSimpleDictionary
{
	/*	A "simple" dictionary is one that can be written on a single line
		without looking terrible. Here we use an element count limit and
		an approximate overall length, allowing only strings and numbers.
	*/
	if ([self count] > kMaxSimpleCount)  return NO;
	
	NSUInteger totalLength = 0;
	
	id key = nil;
	foreachkey (key, self)
	{
		totalLength += 4;		// Punctuation overhead.
		totalLength += [key length];
		if (totalLength > kMaxSimpleLength)  return NO;
		
		id object = [self objectForKey:key];
		if ([object isKindOfClass:[NSNumber class]])
		{
			totalLength += 5;	// ish.
		}
		else if ([object isKindOfClass:[NSString class]])
		{
			totalLength += [object length];
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


- (void) oom_writeToOOMesh:(NSMutableString *)oomeshText
			   indentLevel:(NSUInteger)indentLevel
		  afterPunctuation:(BOOL)afterPunct
{
	if ([self count] == 0)
	{
		if (afterPunct)  [oomeshText appendString:@" "];
		[oomeshText appendString:@"{}"];
	}
	else
	{
		BOOL simple = [self oom_isSimpleDictionary] && indentLevel > 1, first = YES;
		
		NSString *indent1 = IndentTabs(indentLevel);
		NSString *indent2 = simple ? @" " : $sprintf(@"\n%@", IndentTabs(indentLevel + 1));
		
		if (afterPunct)
		{
			if (simple) [oomeshText appendString:@" {"];
			else  [oomeshText appendFormat:@"\n%@{", indent1];
		}
		else
		{
			[oomeshText appendString:@"{"];
		}

		
		id key = nil;
		NSArray *sortedKeys = [[self allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		foreach (key, sortedKeys)
		{
			if (simple)
			{
				if (!first)  [oomeshText appendString:@","];
				first = NO;
			}
			[oomeshText appendString:indent2];
			
			if ([key oom_isValidDictKey])
			{
				[oomeshText appendString:key];
			}
			else
			{
				[oomeshText appendFormat:@"\"%@\"", EscapeString(key)];
			}
			[oomeshText appendString:@":"];
			
			[[self objectForKey:key] oom_writeToOOMesh:oomeshText
										   indentLevel:indentLevel + 1
									  afterPunctuation:YES];
		}
		
		if (simple)
		{
			[oomeshText appendString:@" }"];
		}
		else
		{
			[oomeshText appendFormat:@"\n%@}", indent1];
		}
	}
}

@end
