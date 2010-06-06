/*
	OOMeshWriter.h
	
	
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

#import "OOMeshWriter.h"
#import "OOProblemReportManager.h"

#import "OOAbstractMesh.h"


/*	If set to 1, information about the mesh structure will be added in
	comments.
*/
#define ANNOTATE			1


/*
	OOWriteToOOMesh
	Property for writing to OOMesh files. This is implemented for the property
	list types that are supported in meshes: NSString, NSNumber, NSArray and
	NSDictionary.
	
	The entire file is actually a plist in this format, but most of the contents
	are written using specialized code for efficiency and stylistic cleanness
	(e.g. writing the data entries of attributes and groups in an appropriate
	number of columns).
*/
@protocol OOWriteToOOMesh

- (void) oo_writeToOOMesh:(NSMutableString *)oomeshText indentLevel:(NSUInteger)indentLevel afterPunctuation:(BOOL)afterPunct;

@end


static NSString *EscapeString(NSString *string);
static NSString *FloatString(float number);


BOOL OOWriteOOMesh(OOAbstractMesh *mesh, NSString *path, id <OOProblemReportManager> issues)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	BOOL OK = YES;
	NSError *error = nil;
	NSString *name = [path lastPathComponent];
	
	NSData *data = OOMeshDataFromMesh(mesh, issues);
	OK = (data != nil);
	
	if (OK)
	{
		OK = [data writeToFile:path options:NSAtomicWrite error:&error];
		if (!OK)
		{
			OOReportNSError(issues, $sprintf(@"Could not write to %@", name), error);
		}
	}
	
	[pool drain];
	return OK;
}


NSData *OOMeshDataFromMesh(OOAbstractMesh *mesh, id <OOProblemReportManager> issues)
{
	if (mesh == nil)  return nil;
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSMutableString *result = [NSMutableString string];
	
	//	Generate list of unique vertex indices (pointer uniquing only).
	NSMutableArray *vertices = [NSMutableArray array];
	NSMutableDictionary *indices = [NSMutableDictionary dictionary];
	NSUInteger vertexCount = 0;
	
	OOAbstractFaceGroup *faceGroup = nil;
	OOAbstractFace *face = nil;
	OOAbstractVertex *vertex = nil;
	OOMaterialSpecification *material = nil;
	
	//	Unique vertices across groups, and count 'em.
#if ANNOTATE
	NSMutableArray *useCounts = [NSMutableArray array];
#endif
	foreach (faceGroup, mesh)
	{
		foreach (face, faceGroup)
		{
			NSAutoreleasePool *pool = [NSAutoreleasePool new];
			
			for (NSUInteger vIter = 0; vIter < 3; vIter++)
			{
				vertex = [face vertexAtIndex:vIter];
				
				NSNumber *index = [indices objectForKey:vertex];
				if (index == nil)
				{
					index = [NSNumber numberWithUnsignedInteger:vertexCount++];
					[indices setObject:index forKey:vertex];
					[vertices addObject:vertex];
#if ANNOTATE
					[useCounts addObject:[NSNumber numberWithUnsignedInteger:1]];
#endif
				}
				else
				{
#if ANNOTATE
					NSUInteger indexVal = [index unsignedIntegerValue];
					NSUInteger useCount = [useCounts oo_unsignedIntegerAtIndex:indexVal];
					useCount++;
					[useCounts replaceObjectAtIndex:indexVal withObject:[NSNumber numberWithUnsignedInteger:useCount]];
#endif
				}
				
			}
			
			[pool drain];
		}
	}
	
	//	Unique materials by name.
	NSMutableDictionary *materials = [NSMutableDictionary dictionaryWithCapacity:[mesh faceGroupCount]];
	OOMaterialSpecification *anonMaterial = nil;
#if ANNOTATE
	NSUInteger faceCount = 0;
#endif
	
	foreach (faceGroup, mesh)
	{
		material = [faceGroup material];
		
		if (material == nil)
		{
			// Generate a blank material.
			if (anonMaterial == nil)
			{
				anonMaterial = [[[OOMaterialSpecification alloc] initWithMaterialKey:@"<unnamed>"] autorelease];
			}
			material = anonMaterial;
		}
		
		[materials setObject:material forKey:[material materialKey]];
		
#if ANNOTATE
		faceCount += [faceGroup faceCount];
#endif
	}
	
	
	//	Write header.
	NSString *name = [mesh name];
	if (name == nil)  name = @"<unnamed>";
	[result appendFormat:@"oomesh \"%@\":\n{\n\tvertexCount: %lu", EscapeString(name), (unsigned long)vertexCount];
#if ANNOTATE
	[result appendFormat:@"\t// Average %g uses per vertex.", (float)(faceCount * 3) / (float)vertexCount];
#endif
	[result appendString:@"\n"];
	
	NSDictionary *vertexSchema = [mesh vertexSchema];
	NSArray *attributeKeys = [[vertexSchema allKeys] sortedArrayUsingSelector:@selector(oo_compareByVertexAttributeOrder:)];
	NSString *key = nil;
	
#if ANNOTATE
	[result appendString:@"\t\n\t// Vertex schema:\n"];
	foreach (key, attributeKeys)
	{
		[result appendFormat:@"\t//   %@: %lu\n", key, (unsigned long)[vertexSchema oo_unsignedIntegerForKey:key]];
	}
	[result appendFormat:@"\t//\n\t// %lu triangle%@ in %lu group%@.\n\t\n", (unsigned long)faceCount, faceCount == 1 ? @"" : @"s", (unsigned long)[mesh faceGroupCount], [mesh faceGroupCount] == 1 ? @"" : @""];
#endif
	
	
	//	Write materials.
	NSArray *sortedMaterialKeys = [[materials allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSString *materialKey = nil;
	foreach (materialKey, sortedMaterialKeys)
	{
		[result appendFormat:@"\t\n\tmaterial \"%@\":", EscapeString(materialKey)];
		
		id materialProperties = [[materials objectForKey:materialKey] ja_propertyListRepresentation];
		if (materialProperties == nil)  materialProperties = [NSDictionary dictionary];
		
		[materialProperties oo_writeToOOMesh:result
								  indentLevel:1
							 afterPunctuation:YES];
		
		[result appendString:@"\n"];
	}
	
	
	//	Write vertex attributes.
	if (vertexCount > 0)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		foreach (key, attributeKeys)
		{
			NSUInteger i, count = [vertexSchema oo_unsignedIntegerForKey:key];
			
			[result appendFormat:@"\t\n\tattribute \"%@\":\n\t{\n\t\tsize: %lu\n\t\tdata:\n\t\t[\n", EscapeString(key), (unsigned long)count];
			
#if ANNOTATE
			NSUInteger vIdx = [key isEqualToString:kOOPositionAttributeKey] ? 0 : NSNotFound;
#endif
			
			foreach (vertex, vertices)
			{
				[result appendString:@"\t\t\t"];
				
				OOFloatArray *attr = [vertex attributeForKey:key];
				for (i = 0; i < count; i++)
				{
					[result appendString:FloatString([attr floatAtIndex:i])];
					
#if ANNOTATE
					if (vIdx != NSNotFound && i == count - 1)
					{
						[result appendFormat:@"\t// Uses: %@", [useCounts objectAtIndex:vIdx++]];
					}
#endif
					
					[result appendString:(i == count - 1) ? @"\n" : @",\t"];
				}
			}
			
			[result appendString:@"\t\t]\n\t}\n"];
		}
		
		[pool drain];
	}
	
	
	//	Write groups.
	foreach (faceGroup, mesh)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		NSString *materialKey = [[faceGroup material] materialKey];
		if (materialKey == nil)  materialKey = @"<unnamed>";
		NSString *name = [faceGroup name];
		if (name == nil)  name = materialKey;
		if (name == nil)  name = @"<unnamed>";
		
		[result appendFormat:@"\t\n\tgroup \"%@\":\n\t{\n\t\tfaceCount: %lu\n\t\tmaterial: \"%@\"\n\t\tdata:\n\t\t[\n", EscapeString(name), [faceGroup faceCount], EscapeString(materialKey)];
		
		foreach (face, faceGroup)
		{
			[result appendString:@"\t\t\t"];
			
			for (NSUInteger vIter = 0; vIter < 3; vIter++)
			{
				vertex = [face vertexAtIndex:vIter];
				NSUInteger index = [indices oo_unsignedIntegerForKey:vertex];
				
				[result appendFormat:@"%lu%@", (unsigned long)index, (vIter == 2) ? @"\n" : @", "];
			}
		}
		
		[result appendString:@"\t\t]\n\t}\n"];
		
		[pool drain];
	}
	
	[result appendString:@"}\n"];
	
	NSData *data = [[result dataUsingEncoding:NSUTF8StringEncoding] retain];
	[pool drain];
	
	return [data autorelease];
}


static NSString *EscapeString(NSString *string)
{
	if (EXPECT_NOT(string == nil))  return nil;
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


static NSString *FloatString(float number)
{
	NSString *result = $sprintf(@"%.3f", number);
	
	//	This is teh nasty.
	while ([result hasSuffix:@"0"])
	{
		result = [result substringToIndex:[result length] - 1];
	}
	if ([result hasSuffix:@"."])
	{
		result = [result substringToIndex:[result length] - 1];
	}
	if ([result length] == 0)  result = @"0";
	
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


@interface NSString (OOWriteToOOMesh) <OOWriteToOOMesh>
@end

@interface NSNumber (OOWriteToOOMesh) <OOWriteToOOMesh>
@end

@interface NSArray (OOWriteToOOMesh) <OOWriteToOOMesh>
@end

@interface NSDictionary (OOWriteToOOMesh) <OOWriteToOOMesh>
@end


@implementation NSString (OOWriteToOOMesh)

- (void) oo_writeToOOMesh:(NSMutableString *)oomeshText
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


- (BOOL) oo_isValidOOMeshDictKey
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


@implementation NSNumber (OOWriteToOOMesh)

- (void) oo_writeToOOMesh:(NSMutableString *)oomeshText
			   indentLevel:(NSUInteger)indentLevel
		  afterPunctuation:(BOOL)afterPunct
{
	if (afterPunct)  [oomeshText appendString:@" "];
	if ([self oo_isFloatingPointNumber])
	{
		[oomeshText appendString:FloatString([self floatValue])];
	}
	else
	{
		[oomeshText appendFormat:@"%lli", [self longLongValue]];
	}
}

@end


enum
{
	kMaxSimpleCount = 4,
	kMaxSimpleLength = 60
};


@implementation NSArray (OOWriteToOOMesh)

- (BOOL) oo_isSimpleOOMeshArray
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


- (void) oo_writeToOOMesh:(NSMutableString *)oomeshText
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
		BOOL simple = [self oo_isSimpleOOMeshArray] && indentLevel > 1, first = YES;
		
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
			
			[object oo_writeToOOMesh:oomeshText
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


@implementation NSDictionary (OOWriteToOOMesh)

- (BOOL) oo_isSimpleOOMeshDictionary
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


- (void) oo_writeToOOMesh:(NSMutableString *)oomeshText
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
		BOOL simple = [self oo_isSimpleOOMeshDictionary] && indentLevel > 1, first = YES;
		
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
			
			if ([key oo_isValidOOMeshDictKey])
			{
				[oomeshText appendString:key];
			}
			else
			{
				[oomeshText appendFormat:@"\"%@\"", EscapeString(key)];
			}
			[oomeshText appendString:@":"];
			
			[[self objectForKey:key] oo_writeToOOMesh:oomeshText
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
