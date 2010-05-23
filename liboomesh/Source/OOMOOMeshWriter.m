/*
	OOMOOMeshWriter.h
	liboomesh
	
	
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
	OOUInteger vertexCount = 0;
	
	OOMFaceGroup *faceGroup = nil;
	OOMFace *face = nil;
	OOMVertex *vertex = nil;
	
	foreach(faceGroup, mesh)
	{
		foreach(face, faceGroup)
		{
			NSAutoreleasePool *pool = [NSAutoreleasePool new];
			
			for (OOUInteger vIter = 0; vIter < 3; vIter++)
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
			}
			
			[pool drain];
		}
	}
	
	//	FIXME: ensure all vertices have same attributes. Should be public utility method.
	
	//	Write header.
	[result appendString:@"OOMesh"];
	if (name != nil)
	{
		if ([[[name pathExtension] lowercaseString] isEqualToString:@"oomesh"])  name = [name stringByDeletingPathExtension];
		//	FIXME: escape string.
		[result appendFormat:@" \"%@\"", name];
	}
	[result appendFormat:@"\n\tvertexCount: %lu\n\tgroupCount: %lu\n\n", (unsigned long)vertexCount, [mesh faceGroupCount]];
	
	//	TODO: write materials.
	
	if (vertexCount > 0)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		//	Write vertex attributes.
		OOMVertex *protoVertex = [vertices objectAtIndex:0];
		NSArray *attributeKeys = [[protoVertex allAttributeKeys] sortedArrayUsingSelector:@selector(oom_compareByVertexAttributeOrder:)];
		NSString *key = nil;
		foreach(key, attributeKeys)
		{
			OOUInteger i, count = [[protoVertex attributeForKey:key] count];
			
			//	FIXME: escape string.
			[result appendFormat:@"attribute \"%@\"\n\tsize: %lu\n\tdata:\n", key, (unsigned long)count];
			
			foreach(vertex, vertices)
			{
				[result appendString:@"\t"];
				
				OOMFloatArray *attr = [vertex attributeForKey:key];
				for (i = 0; i < count; i++)
				{
					[result appendFormat:@"% .5f%@", [attr floatAtIndex:i], (i == count - 1) ? @"\n" : @", "];
				}
			}
			
			[result appendString:@"\n\n"];
		}
		
		[pool drain];
	}
	
	//	Write groups.
	foreach(faceGroup, mesh)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		[result appendString:@"group"];
		if ([faceGroup name] != nil)
		{
			//	FIXME: escape string.
			[result appendFormat:@" \"%@\"", [faceGroup name]];
		}
		[result appendFormat:@"\n\tfaceCount: %lu\n\tdata:\n", [faceGroup name], [faceGroup faceCount]];
		
		foreach(face, faceGroup)
		{
			[result appendString:@"\t"];
			
			for (OOUInteger vIter = 0; vIter < 3; vIter++)
			{
				vertex = [face vertexAtIndex:vIter];
				
				NSValue *boxed = [NSValue valueWithNonretainedObject:vertex];
				OOUInteger index = [indices oo_unsignedIntegerForKey:boxed];
				
				[result appendFormat:@"%lu%@", (unsigned long)index, (vIter == 2) ? @"\n" : @", "];
			}
		}
		
		[pool drain];
	}
	
	NSData *data = [[result dataUsingEncoding:NSUTF8StringEncoding] retain];
	[pool release];
	
	return [data autorelease];
}
