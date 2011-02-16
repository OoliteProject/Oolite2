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

#if !OOLITE_LEAN

#import "OOMeshWriter.h"
#import "OOMeshDefinitions.h"
#import <OoliteBase/OOConfGenerationInternal.h>
#import "OOAbstractMesh.h"


enum
{
	// Interval between index comments in annotation mode.
	kAnnGroupRate = 20
};


/*	Quote a key if the kOOMeshWriteJSONCompatible is set, return it unmodified
	otherwise.
*/
static NSString *SimpleKey(NSString *key, OOMeshWriteOptions options)
{
	if (!(options & kOOMeshWriteJSONCompatible))
	{
#ifndef NDEBUG
		NSCParameterAssert([key oo_isValidUnquotedOOConfKey]);
#endif
		return key;
	}
	else
	{
		return $sprintf(@"\"%@\"", [key oo_escapedForJavaScriptLiteral]);
	}
}


//	Quote a key if necessary.
static NSString *Key(NSString *key, OOMeshWriteOptions options)
{
	if (!(options & kOOMeshWriteJSONCompatible) && [key oo_isValidUnquotedOOConfKey])
	{
		return key;
	}
	else
	{
		return $sprintf(@"\"%@\"", [key oo_escapedForJavaScriptLiteral]);
	}
}


static NSString *FloatString(float number);


BOOL OOWriteOOMesh(OOAbstractMesh *mesh, NSString *path, OOMeshWriteOptions options, id <OOProblemReporting> issues)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	BOOL OK = YES;
	NSError *error = nil;
	NSString *name = [path lastPathComponent];
	
	NSData *data = OOMeshDataFromMesh(mesh, options, issues);
	OK = (data != nil);
	
	if (OK)
	{
		OK = [data writeToFile:path options:NSAtomicWrite error:&error];
		if (!OK)
		{
			OOReportNSError(issues, $sprintf(@"Could not write to file \"%@\"", name), error);
		}
	}
	
	[pool drain];
	return OK;
}


NSData *OOMeshDataFromMesh(OOAbstractMesh *mesh, OOMeshWriteOptions options, id <OOProblemReporting> issues)
{
	if (mesh == nil)  return nil;
	
	NSAutoreleasePool			*pool = [NSAutoreleasePool new];
	NSMutableString				*result = [NSMutableString string];
	OOConfGenerationOptions		confOptions = 0;
	
	if (options & kOOMeshWriteJSONCompatible)
	{
		// Comments are not permitted in JSON.
		options &= ~kOOMeshWriteWithAnnotations;
		confOptions |= kOOConfGenerationJSONCompatible;
	}
	BOOL						annotate = options & kOOMeshWriteWithAnnotations;
	BOOL						annotateExtended = annotate && (options & kOOMeshWriteWithExtendedAnnotations);
	
	//	Generate list of unique vertex indices (pointer uniquing only).
	NSMutableArray				*vertices = [NSMutableArray array];
	NSMutableDictionary			*indices = [NSMutableDictionary dictionary];
	NSUInteger					vertexCount = 0;
	
	OOAbstractFaceGroup			*faceGroup = nil;
	OOAbstractFace				*face = nil;
	OOAbstractVertex			*vertex = nil;
	OOMaterialSpecification		*material = nil;
	
	//	Unique vertices across groups, and count ’em.
	NSMutableArray *annVertexUseCounts = nil;
	if (annotateExtended)  annVertexUseCounts = [NSMutableArray array];
	
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
					
					if (annotateExtended)  [annVertexUseCounts addObject:[NSNumber numberWithUnsignedInteger:1]];
				}
				else if (annotateExtended)
				{
					NSUInteger indexVal = [index unsignedIntegerValue];
					NSUInteger useCount = [annVertexUseCounts oo_unsignedIntegerAtIndex:indexVal];
					useCount++;
					[annVertexUseCounts replaceObjectAtIndex:indexVal withObject:[NSNumber numberWithUnsignedInteger:useCount]];
				}
			}
			
			[pool drain];
		}
	}
	
	//	Unique materials by name.
	NSMutableDictionary			*materials = [NSMutableDictionary dictionaryWithCapacity:[mesh faceGroupCount]];
	OOMaterialSpecification		*anonMaterial = nil;
	NSUInteger					annFaceCount = 0;
	
	foreach (faceGroup, mesh)
	{
		material = [faceGroup material];
		
		if (material == nil)
		{
			// Generate a blank material.
			if (anonMaterial == nil)
			{
				anonMaterial = [OOMaterialSpecification anonymousMaterial];
			}
			material = anonMaterial;
		}
		
		[materials setObject:material forKey:[material materialKey]];
		
		if (annotate)  annFaceCount += [faceGroup faceCount];
	}
	
	
	NSDictionary *vertexSchema = [mesh vertexSchemaIgnoringTemporary];
	if ([vertexSchema objectForKey:kOOSmoothGroupAttributeKey] != nil)
	{
		// Smooth groups must be baked into geometry - although they should be marked temorary anyway, surely?
		NSMutableDictionary *mutableSchema = [NSMutableDictionary dictionaryWithDictionary:vertexSchema];
		[mutableSchema removeObjectForKey:kOOSmoothGroupAttributeKey];
		vertexSchema = mutableSchema;
	}
	
	// Write header comment.
	NSArray *attributeKeys = [[vertexSchema allKeys] sortedArrayUsingSelector:@selector(oo_compareByVertexAttributeOrder:)];
	if (annotate)
	{
		NSString *key = nil;
		
		[result appendString:@"/*\n\t"];
		NSString *name = [mesh name];
		if (name != nil)  [result appendFormat:@"%@\n\t\n\t", name];
		[result appendFormat:@"%lu vertices\n\t%u triangles in %u groups using %u materials\n\t%g uses per vertex (average)\n\t\n",
							 vertexCount, annFaceCount, [mesh faceGroupCount], [materials count], (annFaceCount * 3.0) / vertexCount];
		
		[result appendString:@"\tVertex schema:\n"];
		foreach (key, attributeKeys)
		{
			[result appendFormat:@"\t\t%@: %lu\n", key, (unsigned long)[vertexSchema oo_unsignedIntegerForKey:key]];
		}
		[result appendString:@"*/\n\n"];
	}
	
	
	[result appendFormat:@"{\n\t%@: %lu,\n", SimpleKey(kVertexCountKey, options), (unsigned long)vertexCount];
	
	NSString *description = [mesh modelDescription];
	if (description != nil)
	{
		[result appendFormat:@"\t%@: \"%@\",\n", SimpleKey(kMeshDescriptionKey, options), [description oo_escapedForJavaScriptLiteral]];
	}
	
	// Write materials.
	NSError *error = nil;
	[result appendFormat:@"\t%@:\n\t{\n", SimpleKey(kMaterialsSectionKey, options)];
	NSArray *sortedMaterialKeys = [[materials allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSUInteger materialIter, materialCount = [sortedMaterialKeys count];
	for (materialIter = 0; materialIter < materialCount; materialIter++)
	{
		NSString *materialKey = [sortedMaterialKeys objectAtIndex:materialIter];
		[result appendFormat:@"\t\t%@:", Key(materialKey, options)];
		
		OOMaterialSpecification *material = [materials objectForKey:materialKey];
		id materialProperties = [material ja_propertyListRepresentation];
		if (materialProperties == nil)  materialProperties = [NSDictionary dictionary];
		
		if (![materialProperties appendOOConfToString:result
										  withOptions:confOptions | kOOConfGenerationAfterPunctuation
										  indentLevel:2
												error:&error])
		{
			OOReportNSError(issues, $sprintf(OOLocalizeProblemString(issues, @"Material \"%@\" could not be written."), [material materialKey]), error);
			return nil;
		}
		
		if (materialIter + 1 < materialCount)  [result appendString:@","];
		[result appendString:@"\n\t"];
	}
	[result appendString:@"},\n\t\n"];
	
	// Write vertex attributes.
	[result appendFormat:@"\t%@:\n\t{\n", SimpleKey(kAttributesSectionKey, options)];
	if (vertexCount > 0)
	{
		NSUInteger attributeIter, attributeCount = [attributeKeys count];
		for (attributeIter = 0; attributeIter < attributeCount; attributeIter++)
		{
			NSAutoreleasePool *pool = [NSAutoreleasePool new];
			
			NSString *attributeKey = [attributeKeys objectAtIndex:attributeIter];
			NSUInteger elemIter, size = [vertexSchema oo_unsignedIntegerForKey:attributeKey];
			
			/*
					<attributeKey>:
					{
						size: <size>
						data:
						[
			*/
			[result appendFormat:@"\t\t%@:\n\t\t{\n\t\t\t%@: %lu,\n\t\t\t%@:\n\t\t\t[\n", Key(attributeKey, options), Key(kSizeKey, options), (unsigned long)size, Key(kDataKey, options)];
			
			// If annotating, comment vertex use count for position array.
			BOOL annNoteUseCounts = NO;
			if (annotateExtended && [attributeKey isEqualToString:kOOPositionAttributeKey] && annFaceCount * 3 > vertexCount) 
			{
				annNoteUseCounts = YES;
			}
			
			for (NSUInteger vertexIter = 0; vertexIter < vertexCount; vertexIter++)
			{
				vertex = [vertices objectAtIndex:vertexIter];
				[result appendString:@"\t\t\t\t"];
				
				if (annotate && (vertexIter % kAnnGroupRate) == 0 && vertexIter != 0)
				{
					[result appendFormat:@"\n\t\t\t\t// %lu:\n\t\t\t\t", (unsigned long)vertexIter];
				}
				
				OOFloatArray *attr = [vertex attributeForKey:attributeKey];
				for (elemIter = 0; elemIter < size; elemIter++)
				{
					[result appendString:FloatString([attr floatAtIndex:elemIter])];
					
					if (elemIter + 1 < size)
					{
						[result appendString:@",\t"];
					}
					else
					{
						if (vertexIter + 1 < vertexCount)  [result appendString:@","];
						if (!annNoteUseCounts)  [result appendString:@"\n"];
						else
						{
							[result appendFormat:@"\t// Uses: %@\n", [annVertexUseCounts objectAtIndex:vertexIter]];
						}
					}
				}
			}
			
			[result appendString:@"\t\t\t]\n\t\t}"];
			
			if (attributeIter + 1 < attributeCount)  [result appendString:@","];
			[result appendString:@"\n"];
			
			[pool drain];
		}
	}
	[result appendString:@"\t},\n\t\n"];
	
	// Write groups.
	[result appendFormat:@"\t%@:\n\t{\n", SimpleKey(kGroupsSectionKey, options)];
	NSUInteger groupIter, groupCount = [mesh faceGroupCount];
	for (groupIter = 0; groupIter < groupCount; groupIter++)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		faceGroup = [mesh faceGroupAtIndex:groupIter];
		
		NSString *material = [[faceGroup material] materialKey];
		NSString *name = [faceGroup name];
		if (name == nil)  name = material;
		
		NSUInteger faceIter, faceCount = [faceGroup faceCount];
		
		/*
			<name>:
			{
				faceCount: <faceCount>,
				material: <material>,
				data:
				[
		*/
		[result appendFormat:@"\t\t%@:\n\t\t{\n\t\t\t%@: %lu,\n\t\t\t%@: \"%@\",\n\t\t\t%@:\n\t\t\t[\n", Key(name, options), SimpleKey(kFaceCountKey, options), (unsigned long)faceCount, SimpleKey(kMaterialKey, options), [material oo_escapedForJavaScriptLiteral], SimpleKey(kDataKey, options)];
		
		for (faceIter = 0; faceIter < faceCount; faceIter++)
		{
			OOAbstractFace *face = [faceGroup faceAtIndex:faceIter];
			OOAbstractVertex *vertices[3];
			[face getVertices:vertices];
			
			[result appendString:@"\t\t\t\t"];
			
			if (annotate && (faceIter % kAnnGroupRate) == 0 && faceIter != 0)
			{
				[result appendFormat:@"\n\t\t\t\t// %lu:\n\t\t\t\t", (unsigned long)faceIter];
			}
			
			for (NSUInteger vertexIter = 0; vertexIter < 3; vertexIter++)
			{
				NSUInteger index = [indices oo_unsignedIntegerForKey:vertices[vertexIter]];
				[result appendFormat:@"%lu", (unsigned long)index];
				
				if (vertexIter < 2)  [result appendString:@", "];
				else if (faceIter + 1 < faceCount)  [result appendString:@",\n"];
				else  [result appendString:@"\n"];
			}
		}
		
		[result appendString:@"\t\t\t]\n\t\t}"];
		if (groupIter + 1 < groupCount)  [result appendString:@","];
		[result appendString:@"\n"];
		
		[pool drain];
	}
	
	[result appendString:@"\t}\n}\n"];
	
	NSData *data = [[result dataUsingEncoding:NSUTF8StringEncoding] retain];
	[pool drain];
	
	return [data autorelease];
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

#endif
