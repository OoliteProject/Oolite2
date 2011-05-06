/*
	OOOBJWriter.m
	
	
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

#import "OOOBJWriter.h"

#import "OOAbstractMesh.h"


BOOL OOWriteOBJ(OOAbstractMesh *mesh, NSString *path, id <OOProblemReporting> issues)
{
	NSAutoreleasePool	*pool = [NSAutoreleasePool new];
	BOOL				OK = YES;
	NSError				*error = nil;
	NSString			*name = [path lastPathComponent];
	NSData				*mtlData = nil;
	NSString			*mtlName = nil;
	
	NSData *data = OOOBJDataFromMesh(mesh, [path lastPathComponent], &mtlData, &mtlName, issues);
	OK = (data != nil);
	
	if (OK)
	{
		OK = [data writeToFile:path options:NSAtomicWrite error:&error];
		if (OK)
		{
			NSString *mtlPath = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"mtl"];
			OK = [mtlData writeToFile:mtlPath options:NSAtomicWrite error:&error];
		}
		if (!OK)
		{
			OOReportNSError(issues, $sprintf(@"Could not write to file \"%@\"", name), error);
		}
	}
	
	[pool drain];
	return OK;
}


static void CheckSchema(OOAbstractMesh *mesh, BOOL *outHavePositions, BOOL *outHaveNormals, NSUInteger *outTexSize, id <OOProblemReporting> issues) ALWAYS_INLINE_FUNC;

static NSData *GenerateMTLData(OOAbstractMesh *mesh, NSString *meshName, id <OOProblemReporting> issues) ALWAYS_INLINE_FUNC;


NSData *OOOBJDataFromMesh(OOAbstractMesh *mesh, NSString *name, NSData **outMtlData, NSString **outMtlName, id <OOProblemReporting> issues)
{
	if (mesh == nil)  return nil;
	
	NSString *meshName = [mesh name];
	if (name == nil)  name = meshName;
	if (name == nil)  name = @"untitled";
	if (meshName == nil)
	{
		meshName = name;
		if ([[meshName pathExtension] caseInsensitiveCompare:@"obj"] == NSOrderedSame)
		{
			meshName = [meshName stringByDeletingPathExtension];
		}
	}
	
	NSString *mtlName = [[name stringByDeletingPathExtension] stringByAppendingPathExtension:@"mtl"];
	if (outMtlName != NULL)  *outMtlName = mtlName;
	
	BOOL havePositions = NO, haveNormals = NO;
	NSUInteger texSize = 0;
	CheckSchema(mesh, &havePositions, &haveNormals, &texSize, issues);
	
	if (outMtlData != NULL)  *outMtlData = GenerateMTLData(mesh, meshName, issues);
	
	
	NSMutableString *obj = [NSMutableString stringWithFormat:@"# %@\n# Written by OoliteGraphics " OOLITE_VERSION "\n\n", meshName];
	if (mtlName != nil)  [obj appendFormat:@"mtllib %@\n", mtlName];
	
	NSMutableDictionary *posIndicies = [NSMutableDictionary dictionary];
	NSMutableDictionary *normIndicies = [NSMutableDictionary dictionary];
	NSMutableDictionary *texIndicies = [NSMutableDictionary dictionary];
	
	NSUInteger nextPosIdx = 1;
	NSUInteger nextNormIdx = 1;
	NSUInteger nextTexIdx = 1;
	
	[obj appendFormat:@"o %@\n\n", meshName];
	
	/*
		Iterate over groups and faces and write uniqued vertex attributes.
	*/
	OOAbstractFaceGroup *group = nil;
	foreach (group, mesh)
	{
		OOAbstractFace *face = nil;
		foreach (face, group)
		{
			OOAbstractVertex *verts[3];
			[face getVertices:verts];
			
			unsigned i;
			for (i = 0; i < 3; i++)
			{
				if (havePositions)
				{
					OOFloatArray *pos = [verts[i] attributeForKey:kOOPositionAttributeKey];
					if ([posIndicies objectForKey:pos] == nil)
					{
						// Flip for left-handed Oolite coordinate system.
						[obj appendFormat:@"v  %g %g %g\n", -[pos floatAtIndex:0], [pos floatAtIndex:1], [pos floatAtIndex:2]];
						[posIndicies setObject:$int(nextPosIdx++) forKey:pos];
					}
				}
				
				if (texSize > 0)
				{
					OOFloatArray *tex = [verts[i] attributeForKey:kOOTexCoordsAttributeKey];
					if ([texIndicies objectForKey:tex] == nil)
					{
						[obj appendString:@"vt"];
						NSUInteger j;
						for (j = 0; j < texSize; j++)
						{
							[obj appendFormat:@" %g", [tex floatAtIndex:j]];
						}
						[obj appendString:@"\n"];
						[texIndicies setObject:$int(nextTexIdx++) forKey:tex];
					}
				}
				
				if (haveNormals)
				{
					OOFloatArray *norm = [verts[i] attributeForKey:kOONormalAttributeKey];
					if ([normIndicies objectForKey:norm] == nil)
					{
						[obj appendFormat:@"vn %g %g %g\n", [norm floatAtIndex:0], [norm floatAtIndex:1], [norm floatAtIndex:2]];
						[normIndicies setObject:$int(nextNormIdx++) forKey:norm];
					}
				}
			}
		}
	}
	
	/*
		Iterate over groups and faces and write, er, groups and faces.
	*/
	OOUInteger groupIdx = 0;
	foreach (group, mesh)
	{
		groupIdx++;
		
		NSString *groupName = [group name];
		if (groupName == nil)  groupName = $sprintf(@"group_%lu", groupIdx);
		
		[obj appendFormat:@"\ng %@\nusemtl %@", groupName, [[group material] materialKey]];
		
		OOAbstractFace *face = nil;
		foreach (face, group)
		{
			OOAbstractVertex *verts[3];
			[face getVertices:verts];
			
			[obj appendString:@"\nf"];
			unsigned i;
			for (i = 0; i < 3; i++)
			{
				[obj appendString:@" "];
				
				if (havePositions)
				{
					OOFloatArray *pos = [verts[i] attributeForKey:kOOPositionAttributeKey];
					[obj appendFormat:@"%lu", [posIndicies oo_unsignedIntegerForKey:pos]];
				}
				
				[obj appendString:@"/"];
				
				if (texSize > 0)
				{
					OOFloatArray *tex = [verts[i] attributeForKey:kOOTexCoordsAttributeKey];
					[obj appendFormat:@"%lu", [texIndicies oo_unsignedIntegerForKey:tex]];
				}
				
				[obj appendString:@"/"];
				
				if (haveNormals)
				{
					OOFloatArray *norm = [verts[i] attributeForKey:kOONormalAttributeKey];
					[obj appendFormat:@"%lu", [normIndicies oo_unsignedIntegerForKey:norm]];
				}
			}
		}
		[obj appendString:@"\n"];
	}
	
	return [obj dataUsingEncoding:NSUTF8StringEncoding];
}


static void CheckSchema(OOAbstractMesh *mesh, BOOL *outHavePositions, BOOL *outHaveNormals, NSUInteger *outTexSize, id <OOProblemReporting> issues)
{
	NSCParameterAssert(mesh != nil && outHavePositions != NULL && outHaveNormals != NULL && outTexSize != NULL);
	
	/*
	 Check vertex schema and warn if we’re discarding information. For
	 polygonal surfaces, OBJ files can only represent 3-component vertices,
	 3-component normals and up to 3-component texture coordinates.
	 */
	NSDictionary	*schema = [mesh vertexSchema];
	NSString		*key = nil;
	NSMutableArray	*unknownAttrs = nil;
	
	foreachkey (key, schema)
	{
		if ([key isEqualToString:kOOPositionAttributeKey])  *outHavePositions = YES;
		else if ([key isEqualToString:kOONormalAttributeKey])  *outHaveNormals = YES;
		else if ([key isEqualToString:kOOTexCoordsAttributeKey])
		{
			*outTexSize = [schema oo_unsignedIntegerForKey:key];
			if (*outTexSize > 3)
			{
				OOReportWarning(issues, @"This mesh uses texture coordinates with %lu components, but OBJ format supports at most 3.", *outTexSize);
				*outTexSize = 3;
			}
		}
		else
		{
			if (unknownAttrs == nil)  unknownAttrs = [NSMutableArray array];
			[unknownAttrs addObject:key];
		}
	}
	
	if (unknownAttrs != nil)
	{
		if ([unknownAttrs count] == 1)
		{
			OOReportWarning(issues, @"This mesh uses an attribute, %@, which is not representable in OBJ format.", [unknownAttrs objectAtIndex:0]);
		}
		else
		{
			[unknownAttrs sortUsingSelector:@selector(caseInsensitiveCompare:)];
			OOReportWarning(issues, @"This mesh uses aattributes which is not representable in the OBJ format: %@", [unknownAttrs componentsJoinedByString:@", "]);
		}
	}
}


static void WriteMTLColor(NSMutableString *mtl, OOColor *color, NSString *mtlKey, NSString *key, NSString *name, BOOL multiplyAlpha, id <OOProblemReporting> issues);


static void WriteMTLTexture(NSMutableString *mtl, OOTextureSpecification *texture, NSString *mtlKey, NSString *key, NSString *name, NSString *defaultSwizzle, id <OOProblemReporting> issues);


static NSData *GenerateMTLData(OOAbstractMesh *mesh, NSString *meshName, id <OOProblemReporting> issues)
{
	NSCParameterAssert(mesh != nil);
	
	NSMutableString *mtl = [NSMutableString string];
	
	[mtl appendFormat:@"# Materials for mesh %@\n# Written by OoliteGraphics " OOLITE_VERSION "\n\n", meshName];
	
	NSMutableSet *seenMaterials = [NSMutableSet set];
	
	OOAbstractFaceGroup *group = nil;
	foreach (group, mesh)
	{
		OOMaterialSpecification *material = [group material];
		NSString *key = [material materialKey];
		
		// Multiple groups with the same material are allowed, even if they're currently pointless.
		if ([seenMaterials containsObject:key])  continue;
		
		// FIXME: restrict to ASCII identifiers.
		[mtl appendFormat:@"\nnewmtl %@\n", key];
		
		WriteMTLColor(mtl, [material diffuseColor], key, @"Kd", @"diffuse", NO, issues);
		WriteMTLTexture(mtl, [material diffuseMap], key, @"map_Kd", @"diffuse", @"rgb", issues);
		
		WriteMTLColor(mtl, [material specularColor], key, @"Ks", @"specular", NO, issues);
		WriteMTLTexture(mtl, [material specularColorMap], key, @"map_Ks", @"specular color", @"rgb", issues);
		[mtl appendFormat:@"Ns %lu\n", [material specularExponent]];
		WriteMTLTexture(mtl, [material specularExponentMap], key, @"map_Ns", @"specular exponent", @"r", issues);
		
		// FIXME: light maps.
		
		if ([material normalMap] != nil)
		{
			OOReportWarning(issues, @"The material \"%@\" uses a %@ map, which cannot be represented in the OBJ format.", key, @"normal");
		}
		if ([material parallaxMap] != nil)
		{
			OOReportWarning(issues, @"The material \"%@\" uses a %@ map, which cannot be represented in the OBJ format.", key, @"parallax");
		}
	}
	
	return [mtl dataUsingEncoding:NSUTF8StringEncoding];
}


static void WriteMTLColor(NSMutableString *mtl, OOColor *color, NSString *mtlKey, NSString *key, NSString *name, BOOL multiplyAlpha, id <OOProblemReporting> issues)
{
	NSCParameterAssert(mtl != nil && color != nil && key != nil);
	
	float red, green, blue, alpha;
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	if (alpha != 1.0)
	{
		if (multiplyAlpha)
		{
			red *= alpha;
			green *= alpha;
			blue *= alpha;
		}
		else
		{
			OOReportWarning(issues, @"The alpha channel of the %@ color of material \"%@\" was discarded.", name, mtlKey);
		}
	}
	
	[mtl appendFormat:@"%@ %.4f %.4f %.4f\n", key, red, green, blue];
}


static void WriteMTLTexture(NSMutableString *mtl, OOTextureSpecification *texture, NSString *mtlKey, NSString *key, NSString *name, NSString *defaultSwizzle, id <OOProblemReporting> issues)
{
	NSCParameterAssert(mtl != nil && key != nil);
	if (texture == nil)  return;
	
	NSString *options = @"";
	
#if 0
	/*
		In principle, repeat settings can be represented in MTL files, but
		neither OoliteGraphics nor Wings3D can read them.
	*/
	BOOL repeatS = [texture repeatS], repeatT = [texture repeatT];
	if (!repeatS && !repeatT)
	{
		options = [options stringByAppendingString:@" -clamp on"];
	}
	else if (repeatS != repeatT)
	{
		OOReportWarning(issues, @"The %@ map for material \"%@\" repeats in one direction and is clamped in the other. In the OBJ format, textures must either repeat in both directions or be clamped in both directions.", name, mtlKey);
	}
#endif
	
	NSString *swizzle = [texture extractMode];
	if (swizzle != nil && ![swizzle isEqualToString:defaultSwizzle])
	{
		OOReportWarning(issues, @"The material \"%@\" uses a %@ map with extract mode \"%@\", which cannot be represented in the OBJ format.", mtlKey, name, swizzle);
	}
	
	// FIXME: file name restrictions?
	[mtl appendFormat:@"%@%@ %@\n", key, options, [texture textureMapName]];
}

#endif	// OOLITE_LEAN
