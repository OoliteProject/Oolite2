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

#import "OOJMeshWriter.h"
#import "OOAbstractMesh.h"


/*	If set to 1, information about the mesh structure will be added in
	comments.
*/
#define ANNOTATE			(!defined(NDEBUG))


BOOL OOWriteOOJMesh(OOAbstractMesh *mesh, NSString *path, id <OOProblemReporting> issues)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	BOOL OK = YES;
	NSError *error = nil;
	NSString *name = [path lastPathComponent];
	
	NSData *data = OOJMeshDataFromMesh(mesh, issues);
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


NSData *OOJMeshDataFromMesh(OOAbstractMesh *mesh, id <OOProblemReporting> issues)
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
				anonMaterial = [OOMaterialSpecification anonymousMaterial];
			}
			material = anonMaterial;
		}
		
		[materials setObject:material forKey:[material materialKey]];
		
#if ANNOTATE
		faceCount += [faceGroup faceCount];
#endif
	}
	
	
	NSDictionary *vertexSchema = [mesh vertexSchemaIgnoringTemporary];
	if ([vertexSchema objectForKey:kOOSmoothGroupAttributeKey] != nil)
	{
		// Smooth groups must be baked into geometry - although they should be marked temorary anyway, surely?
		NSMutableDictionary *mutableSchema = [NSMutableDictionary dictionaryWithDictionary:vertexSchema];
		[mutableSchema removeObjectForKey:kOOSmoothGroupAttributeKey];
		vertexSchema = mutableSchema;
	}
#if 0
	NSArray *attributeKeys = [[vertexSchema allKeys] sortedArrayUsingSelector:@selector(oo_compareByVertexAttributeOrder:)];
	NSString *key = nil;
	
#if ANNOTATE
	[result appendString:@"/*\n\t"];
	NSString *name = [mesh name];
	if (name != nil)  [result appendFormat:@"%@\n\t\n\t", name];
	[result appendFormat:@"%lu vertices\n\t%u triangles in %u groups using %u materials\n\t%g uses per vertex (average)\n\t\n",
						 vertexCount, faceCount, [mesh faceGroupCount], [materials count], (faceCount * 3.0) / vertexCount];
	
	[result appendString:@"\tVertex schema:\n"];
	foreach (key, attributeKeys)
	{
		[result appendFormat:@"\t\t%@: %lu\n", key, (unsigned long)[vertexSchema oo_unsignedIntegerForKey:key]];
	}
	[result appendString:@"*/\n\n"];
#endif
#endif
	
	
	[result appendFormat:@"{\n\t\"vertexCount\": %lu,\n", (unsigned long)vertexCount];
	
	NSString *description = [mesh modelDescription];
	if (description != nil)
	{
		[result appendFormat:@"\t\"description\": \"%@\",\n", [description oo_escapedForJavaScriptLiteral]];
	}
	
	
	// Write materials.
	[result appendString:@"\"materials\":\n{\n"];
	NSArray *sortedMaterialKeys = [[materials allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSString *materialKey = nil;
	foreach (materialKey, sortedMaterialKeys)
	{
		[result appendFormat:@"\t\"%@\":\n\t", [materialKey oo_escapedForJavaScriptLiteral]];
		
		id materialProperties = [[materials objectForKey:materialKey] ja_propertyListRepresentation];
		if (materialProperties == nil)  materialProperties = [NSDictionary dictionary];
		
		/*
		[materialProperties oo_writeToOOJMesh:result
								  indentLevel:2
							 afterPunctuation:YES];
		*/
		
		[result appendString:@"\n\t"];
	}
	
	[result appendString:@"}\n"];
	
	NSData *data = [[result dataUsingEncoding:NSUTF8StringEncoding] retain];
	[pool drain];
	
	return [data autorelease];
}

#endif
