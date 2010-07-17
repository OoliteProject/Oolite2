/*
	OOOBJReader.m
	
	
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

#import "OOCTMReader.h"
#import "openctm.h"

#import "OOFloatArray.h"
#import "OOIndexArray.h"
#import "OORenderMesh.h"
#import "OOAbstractMesh.h"


@interface OOCTMReader (Private)

- (NSString *) priv_displayName;
- (void) priv_destroyContext;

@end


@implementation OOCTMReader

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues
{
	if ((self = [super init]))
	{
		_issues = [issues retain];
		_progressReporter = [progressReporter retain];
		_path = [path copy];
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_progressReporter);
	DESTROY(_path);
	DESTROY(_comment);
	DESTROY(_materials);
	
	[self priv_destroyContext];
	
	[super dealloc];
}


- (void) finalize
{
	[self priv_destroyContext];
	
	[super finalize];
}


- (BOOL) loadAttributeNamed:(CTMenum)attrName key:(NSString *)key componentCount:(unsigned)components
{
	const float *rawAttr = ctmGetFloatArray(_ctmContext, attrName);
	if (EXPECT_NOT(rawAttr == NO))  return NO;
	OOFloatArray *attr = [OOFloatArray arrayWithFloats:rawAttr count:components * _vertexCount];
	if (EXPECT_NOT(attr == NO))  return NO;
	
	[_attributes setObject:attr forKey:key];
	return YES;
}


static NSString *LoadString(const char *string)
{
	if (string == NULL || string[0] == '\0')
	{
		return nil;
	}
	
	// OpenCTM requires all strings to be UTF-8, but paranoia is healthy.
	NSString *result = [NSString stringWithUTF8String:string];
	if (result == nil)  result = [[[NSString alloc] initWithCString:string encoding:NSWindowsCP1252StringEncoding] autorelease];
	
	return result;
}


- (void) parse
{
	if (_parsed)  return;
	_parsed = YES;
	
	_ctmContext = ctmNewContext(CTM_IMPORT);
	if (EXPECT_NOT(_ctmContext == NULL))
	{
		OOReportError(_issues, @"Failed to allocate CTM import context.");
		return;
	}
	
	ctmLoad(_ctmContext, [_path fileSystemRepresentation]);
	CTMenum error = ctmGetError(_ctmContext);
	if (error == CTM_NONE)
	{
		_vertexCount = ctmGetInteger(_ctmContext, CTM_VERTEX_COUNT);
		_faceCount = ctmGetInteger(_ctmContext, CTM_TRIANGLE_COUNT);
		
		_comment = [LoadString(ctmGetString(_ctmContext, CTM_FILE_COMMENT)) retain];
		
		// Load attributes.
		_attributes = [NSMutableDictionary dictionary];
		
		// CTM_VERTICES is required.
		[self loadAttributeNamed:CTM_VERTICES key:kOOPositionAttributeKey componentCount:3];
		
		// CTM_NORMALS is optional.
		if (ctmGetInteger(_ctmContext, CTM_HAS_NORMALS))
		{
			[self loadAttributeNamed:CTM_NORMALS key:kOONormalAttributeKey componentCount:3];
		}
		
		// Read UV mappings (two components each).
		unsigned i, count;
		count = ctmGetInteger(_ctmContext, CTM_UV_MAP_COUNT);
		for (i = 0; i < count; i++)
		{
			NSString *key = (i == 0) ? kOOTexCoordsAttributeKey : [NSString stringWithFormat:@"%@%u", kOOTexCoordsAttributeKey, i + 1];
			[self loadAttributeNamed:CTM_UV_MAP_1 + i key:key componentCount:2];
		}
		if (count > 0)
		{
			
			/*	There is an impedance mismatch between the standard Oolite
				model of one texture coordinate set and potentially multiple
				materials, and OpenCTM’s model of coordinate sets with
				attached names and (optional) file names. Since our mesh
				representations require at most one material per face, we load
				multiple coordinate sets as attributes but only define one
				material based on the first coordinate set, and generate a
				warning (below) if more than one exists.
			 */
			NSString *name = LoadString(ctmGetUVMapString(_ctmContext, CTM_UV_MAP_1, CTM_NAME));
			NSString *fileName = LoadString(ctmGetUVMapString(_ctmContext, CTM_UV_MAP_1, CTM_FILE_NAME));
			
			OOMaterialSpecification *material = [[[OOMaterialSpecification alloc] initWithMaterialKey:name] autorelease];
			if (fileName != nil)  [material setDiffuseMap:[OOTextureSpecification textureSpecWithName:fileName]];
			_materials = [[NSArray arrayWithObject:material] retain];
			
			if (count > 1)
			{
				OOReportWarning(_issues, @"The document contains %u UV mappings, which may have textures associated with them. All UV mappings have been imported, but only one material has been generated.", count);
			}
		}
		
		// Read attribute maps (four components each).
		count = ctmGetInteger(_ctmContext, CTM_ATTRIB_MAP_COUNT);
		for (i = 0; i < count; i++)
		{
			NSString *baseKey = LoadString(ctmGetAttribMapString(_ctmContext, CTM_ATTRIB_MAP_1 + i, CTM_NAME));
			NSString *key = baseKey;
			
			// Ensure unique name.
			if (key != nil)
			{
				if ([_attributes objectForKey:key] != nil)
				{
					unsigned nameI = 2;
					NSString *newKey = nil;
					do
					{
						newKey = [NSString stringWithFormat:@"%@%u", key, nameI++];
					}  while ([_attributes objectForKey:key] != nil);
					
					OOReportWarning(_issues, @"Attribute \"%@\" renamed to \"%@\" to ensure uniqueness.", key, newKey);
					key = newKey;
				}
			}
			else
			{
				unsigned nameI = i;
				do
				{
					key = [NSString stringWithFormat:@"attrib%u", nameI++];
				}  while ([_attributes objectForKey:key] != nil);
			}
			
			[self loadAttributeNamed:CTM_ATTRIB_MAP_1 + i key:key componentCount:4];
		}
		
		// Read index array.
		const uint32_t *indices = ctmGetIntegerArray(_ctmContext, CTM_INDICES);
		OOIndexArray *indexArray = [OOIndexArray arrayWithUnsignedInts:indices count:_faceCount * 3 maximum:_vertexCount];
		
		if (_attributes != nil && indexArray != nil)
		{
			NSString *name = [self priv_displayName];
			if ([[[name pathExtension] lowercaseString] isEqualToString:@"ctm"])  name = [name stringByDeletingPathExtension];
			_name = [name retain];
			
			_renderMesh = [[OORenderMesh alloc] initWithName:name
												 vertexCount:_vertexCount
												  attributes:_attributes
													  groups:[NSArray arrayWithObject:indexArray]];
		}
		
		_attributes = nil;
	}
	else
	{
		OOReportError(_issues, @"Failed to load the document, because an OpenCTM error occurred: %s.", ctmErrorString(error));
	}
	
	[self priv_destroyContext];
}


- (OOAbstractMesh *) abstractMesh
{
	[self parse];
	
	OOAbstractMesh *mesh = [_renderMesh abstractMesh];
	if (_materials != nil)
	{
		NSAssert([mesh faceGroupCount] == 1 && [_materials count] == 1, @"Expected a single face group and material in OOCTMReader.");
		
		[[mesh faceGroupAtIndex:0] setMaterial:[_materials objectAtIndex:0]];
	}
	
	if (_name != nil)  [mesh setName:_name];
	if (_comment != nil)  [mesh setModelDescription:_comment];
	
	return mesh;
}


- (void) getRenderMesh:(OORenderMesh **)renderMesh andMaterialSpecs:(NSArray **)materialSpecifications
{
	[self parse];
	
	if (renderMesh != NULL)  *renderMesh = _renderMesh;
	if (materialSpecifications != NULL)  *materialSpecifications = _materials;
}


- (NSString *) fileComment
{
	[self parse];
	
	return _comment;
}

@end


@implementation OOCTMReader (Private)

- (NSString *) priv_displayName
{
	return [[NSFileManager defaultManager] displayNameAtPath:_path];
}


- (void) priv_destroyContext
{
	if (_ctmContext != NULL)
	{
		ctmFreeContext(_ctmContext);
		_ctmContext = NULL;
	}
}

@end

#endif	// OOLITE_LEAN
