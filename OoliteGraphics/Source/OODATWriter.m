/*
	OODATWriter.m
	
	
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

#import "OODATWriter.h"
#import "OOProblemReporting.h"

#import "OOAbstractMesh.h"


BOOL OOWriteDAT(OOAbstractMesh *mesh, NSString *path, id <OOProblemReporting> issues)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	BOOL OK = YES;
	NSError *error = nil;
	NSString *name = [path lastPathComponent];
	
	NSData *data = OODATDataFromMesh(mesh, issues);
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


NSData *OODATDataFromMesh(OOAbstractMesh *mesh, id <OOProblemReporting> issues)
{
	/*
		DAT format (as we use it) has a vertex list with a fixed vertex schema:
			{ position: 3, normal: 3, tangent: 3 }
		Texture coordinates are stored separately.
		Below, these are referred to as “datVerts”.
		
		To unique this, we need three things:
		  * An array of the datVerts we need.
		  * A dictionary of datVerts->indices.
		  * A dictionary of full vertices->indices – not strictly necessary,
			but avoids converting everything to datVerts twice.
	*/
	NSAutoreleasePool		*pool = [NSAutoreleasePool new];
	
	NSDictionary			*datVertSchema = $dict(kOOPositionAttributeKey, $int(3), kOONormalAttributeKey, $int(3), kOOTangentAttributeKey, $int(3));
	
	NSMutableArray			*datVerts = [NSMutableArray array];
	NSMutableDictionary		*vertexToIndex = [NSMutableDictionary dictionary];
	
	OOAbstractFaceGroup		*faceGroup = nil;
	OOAbstractFace			*face = nil;
	OOAbstractVertex		*vertex = nil;
	OOAbstractVertex		*datVert = nil;
	NSNumber				*idx = nil;
	unsigned long			vIter, vertexCount = 0;
	unsigned long			faceCount = 0;
	
	NSAutoreleasePool		*innerPool = [NSAutoreleasePool new];
	NSMutableDictionary		*datVertToIndex = [NSMutableDictionary dictionary];
	
	foreach (faceGroup, mesh)
	{
		faceCount += [faceGroup faceCount];
		
		foreach (face, faceGroup)
		{
			for (vIter = 0; vIter < 3; vIter++)
			{
				vertex = [face vertexAtIndex:vIter];
				idx = [vertexToIndex objectForKey:vertex];
				if (idx == nil)
				{
					idx = [NSNumber numberWithUnsignedInteger:vertexCount++];
					datVert = [vertex vertexStrictlyConformingToSchema:datVertSchema];
					[datVerts addObject:datVert];
					[datVertToIndex setObject:idx forKey:datVert];
					[vertexToIndex setObject:idx forKey:vertex];
				}
			}
		}
	}
	
	datVertToIndex = nil;
	[innerPool drain];
	
	/*
		Having uniqued the vertices, write the header and VERTEX section
		(which defines the position attribute only).
	*/
	NSMutableString *result = [NSMutableString string];
	[result appendFormat:@"NVERTS %lu\nNFACES %u\n\nVERTEX\n", vertexCount, faceCount];
	
	foreach (datVert, datVerts)
	{
		Vector position = [datVert position];
		[result appendFormat:@"%g,\t%g,\t%g\n", position.x, position.y, position.z];
	}
	
	/*
		Write the FACES section, which defines smoothing groups (unused),
		face normals (unused) and face indices.
	*/
	[result appendString:@"\nFACES"];
	foreach (faceGroup, mesh)
	{
		foreach (face, faceGroup)
		{
			[result appendFormat:@"\n0 0 0\t0,0,0\t3\t"];
			
			for (vIter = 0; vIter < 3; vIter++)
			{
				vertex = [face vertexAtIndex:vIter];
				idx = [vertexToIndex objectForKey:vertex];
				[result appendFormat:@"%@%@", (vIter != 0) ? @"," : @"", idx];
			}
		}
	}
	
	/*
		Write TEXTURES section, which defines material key index and texture
		coordinates for each face.
	*/
	[result appendString:@"\n\nTEXTURES"];
	
	unsigned materialIndex = 0;
	foreach (faceGroup, mesh)
	{
		foreach (face, faceGroup)
		{
			[result appendFormat:@"\n%u\t1,1\t", materialIndex];
			
			for (vIter = 0; vIter < 3; vIter++)
			{
				Vector2D texCoords = [[face vertexAtIndex:vIter] texCoords];
				[result appendFormat:@"\t%g,%g", texCoords.x, texCoords.y];
			}
		}
		
		materialIndex++;
	}
	
	/*
		Write NAMES section, mapping material key indices to keys.
	*/
	[result appendFormat:@"\n\nNAMES %lu\n", (unsigned long)[mesh faceGroupCount]];
	materialIndex = 0;
	foreach (faceGroup, mesh)
	{
		NSString *materialKey = [[faceGroup material] materialKey];
		if (materialKey == nil)  materialKey = [faceGroup name];
		if (materialKey == nil)  materialKey = $sprintf(@"material_%u", materialIndex);
		
		[result appendFormat:@"%@\n", materialKey];
	}
	
	/*
		Write NORMALS section.
	*/
	[result appendString:@"\nNORMALS\n"];
	
	foreach (datVert, datVerts)
	{
		Vector normal = [datVert normal];
		[result appendFormat:@"%g,\t%g,\t%g\n", normal.x, normal.y, normal.z];
	}
	
	/*
		Write TANGENTS section.
	*/
	[result appendString:@"\nTANGENTS\n"];
	
	foreach (datVert, datVerts)
	{
		Vector tangent = [datVert tangent];
		[result appendFormat:@"%g,\t%g,\t%g\n", tangent.x, tangent.y, tangent.z];
	}
	
	[result appendString:@"\nEND\n"];
	
	NSData *data = [[result dataUsingEncoding:NSUTF8StringEncoding] retain];
	[pool drain];
	
	return [data autorelease];
}

#endif	// OOLITE_LEAN
