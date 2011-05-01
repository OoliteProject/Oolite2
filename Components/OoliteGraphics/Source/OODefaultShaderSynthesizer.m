/*

OODefaultShaderSynthesizer.m


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

#import "OODefaultShaderSynthesizer.h"
#import "OORenderMesh.h"
#import	"OOMaterialSpecification.h"
#import "OOTextureSpecification.h"
#import "OOAbstractVertex.h"


typedef enum
{
	kLightingUndetermined,
	kLightingUniform,			// No normals can be determined
	kLightingNormalOnly,		// No tangents, so no normal mapping possible
	kLightingNormalTangent,		// Normal and tangent defined, bitangent determined by cross product
	kLightingTangentBitangent	// Tangent and bitangent defined, normal determined by cross product
} LightingMode;


@interface OODefaultShaderSynthesizer: NSObject
{
@private
	OOMaterialSpecification		*_spec;
	OORenderMesh				*_mesh;
	id <OOProblemReporting>		_problemReporter;
	
	NSString					*_vertexShader;
	NSString					*_fragmentShader;
	NSMutableArray				*_textures;
	NSMutableDictionary			*_uniforms;
	
	NSMutableString				*_attributes;
	NSMutableString				*_varyings;
	NSMutableString				*_vertexUniforms;
	NSMutableString				*_fragmentUniforms;
	NSMutableString				*_vertexHelpers;
	NSMutableString				*_fragmentHelpers;
	NSMutableString				*_vertexBody;
	NSMutableString				*_fragmentBody;
	
	// _texturesByName: dictionary mapping texture file names to texture specifications.
	NSMutableDictionary			*_texturesByName;
	// _textureIDs: dictionary mapping texture file names to numerical IDs used to name variables.
	NSMutableDictionary			*_textureIDs;
	
	LightingMode				_lightingMode;
	uint8_t						_normalAttrSize;
	uint8_t						_tangentAttrSize;
	uint8_t						_bitangentAttrSize;
}

- (id) initWithMaterialSpecifiction:(OOMaterialSpecification *)spec
							   mesh:(OORenderMesh *)mesh
					problemReporter:(id <OOProblemReporting>) problemReporter;

- (BOOL) run;

- (NSString *) vertexShader;
- (NSString *) fragmentShader;
- (NSArray *) textureSpecifications;
- (NSDictionary *) uniformSpecifications;

- (void) createTemporaries;
- (void) destroyTemporaries;

- (LightingMode) lightingMode;

@end


BOOL OOSynthesizeMaterialShader(OOMaterialSpecification *materialSpec, OORenderMesh *mesh, NSString **outVertexShader, NSString **outFragmentShader, NSArray **outTextureSpecs, NSDictionary **outUniformSpecs, id <OOProblemReporting> problemReporter)
{
	NSCParameterAssert(materialSpec != nil && outVertexShader != NULL && outFragmentShader != NULL);
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	OODefaultShaderSynthesizer *synthesizer = [[OODefaultShaderSynthesizer alloc]
											   initWithMaterialSpecifiction:materialSpec
											   mesh:mesh
											   problemReporter:problemReporter];
	[synthesizer autorelease];
	
	BOOL OK = [synthesizer run];
	if (OK)
	{
		*outVertexShader = [[synthesizer vertexShader] retain];
		*outFragmentShader = [[synthesizer fragmentShader] retain];
		*outTextureSpecs = [[synthesizer textureSpecifications] retain];
		*outUniformSpecs = [[synthesizer uniformSpecifications] retain];
	}
	else
	{
		*outVertexShader = nil;
		*outFragmentShader = nil;
		*outTextureSpecs = nil;
		*outUniformSpecs = nil;
	}
	[pool release];
	
	[*outVertexShader autorelease];
	[*outFragmentShader autorelease];
	[*outTextureSpecs autorelease];
	[*outUniformSpecs autorelease];
	
	return YES;
}


@implementation OODefaultShaderSynthesizer

- (id) initWithMaterialSpecifiction:(OOMaterialSpecification *)spec
							   mesh:(OORenderMesh *)mesh
					problemReporter:(id <OOProblemReporting>) problemReporter
{
	if ((self = [super init]))
	{
		_spec = [spec retain];
		_mesh = [mesh retain];
		_problemReporter = [problemReporter retain];
	}
	
	return self;
}


- (void) dealloc
{
	[self destroyTemporaries];
	DESTROY(_spec);
	DESTROY(_mesh);
	DESTROY(_problemReporter);
	DESTROY(_vertexShader);
	DESTROY(_fragmentShader);
	DESTROY(_textures);
	
    [super dealloc];
}


- (NSString *) vertexShader
{
	return _vertexShader;
}


- (NSString *) fragmentShader
{
	return _fragmentShader;
}


- (NSArray *) textureSpecifications
{
#ifndef NDEBUG
	return [NSArray arrayWithArray:_textures];
#else
	return _textures;
#endif
}


- (NSDictionary *) uniformSpecifications
{
#ifndef NDEBUG
	return [NSDictionary dictionaryWithDictionary:_uniforms];
#else
	return _uniforms;
#endif
}


static void AppendIfNotEmpty(NSMutableString *buffer, NSString *segment, NSString *name)
{
	if ([segment length] > 0)
	{
		if ([buffer length] > 0)  [buffer appendString:@"\n\n"];
		if ([name length] > 0)  [buffer appendFormat:@"// %@\n", name];
		[buffer appendString:segment];
	}
}


- (void) appendVariable:(NSString *)name ofType:(NSString *)type withPrefix:(NSString *)prefix to:(NSMutableString *)buffer
{
	NSUInteger typeDeclLength = [prefix length] + [type length] + 1;
	NSUInteger padding = (typeDeclLength < 20) ? (23 - typeDeclLength) / 4 : 1;
	[buffer appendFormat:@"%@ %@%@%@;\n", prefix, type, OOTabString(padding), name];
}


- (void) addAttribute:(NSString *)name ofType:(NSString *)type
{
	[self appendVariable:name ofType:type withPrefix:@"attribute" to:_attributes];
}


- (void) addVarying:(NSString *)name ofType:(NSString *)type
{
	[self appendVariable:name ofType:type withPrefix:@"varying" to:_varyings];
}


- (void) addVertexUniform:(NSString *)name ofType:(NSString *)type
{
	[self appendVariable:name ofType:type withPrefix:@"uniform" to:_vertexUniforms];
}


- (void) addFragmentUniform:(NSString *)name ofType:(NSString *)type
{
	[self appendVariable:name ofType:type withPrefix:@"uniform" to:_fragmentUniforms];
}


- (void) setUpOneTexture:(OOTextureSpecification *)spec
{
	if (spec == nil)  return;
	
	if ([spec isCubeMap])
	{
		OOReportError(_problemReporter, @"The material \"%@\" of \"%@\" specifies a cube map texture, but doesn't have custom shaders. Cube map textures are not supported with the default shaders.", [_spec materialKey], [_mesh name]);
		[NSException raise:NSGenericException format:@"Invalid material"];
	}
	
	NSString *name = [spec textureMapName];
	OOTextureSpecification *existing = [_texturesByName objectForKey:name];
	if (existing == nil)
	{
		NSNumber *texID = $int([_texturesByName count]);
		[_textures addObject:spec];
		[_texturesByName setObject:spec forKey:name];
		[_textureIDs setObject:texID forKey:name];
		[_uniforms setObject:$dict(@"type", @"texture", @"value", texID) forKey:$sprintf(@"uTexture%@", texID)];
	}
	else
	{
		if (![spec isEqual:existing])
		{
			OOReportWarning(_problemReporter, @"The texture map \"%@\" is used more than once in material \"%@\" of \"%@\", and the options specified are not consistent. Only one set of options will be used.", name, [_spec materialKey], [_mesh name]);
		}
	}
}


- (void) setUpTextures
{
	_textures = [[NSMutableArray alloc] init];
	_texturesByName = [[NSMutableDictionary alloc] init];
	_textureIDs = [[NSMutableDictionary alloc] init];
	
	[self setUpOneTexture:[_spec diffuseMap]];
	[self setUpOneTexture:[_spec specularMap]];
	[self setUpOneTexture:[_spec emissionMap]];
	[self setUpOneTexture:[_spec illuminationMap]];
	[self setUpOneTexture:[_spec normalMap]];
#if 0
	// Parallax map needs to be handled separately.
	[self setUpOneTexture:[_spec parallaxMap]];
#endif
	
	if ([_texturesByName count] == 0)  return;
	
	// Ensure we have valid texture coordinates.
	NSUInteger texCoordsSize = [_mesh attributeSizeForKey:kOOTexCoordsAttributeKey];
	switch (texCoordsSize)
	{
		case 0:
			OOReportError(_problemReporter, @"The material \"%@\" of \"%@\" uses textures, but the mesh has no %@ attribute.", [_spec materialKey], [_mesh name], kOOTexCoordsAttributeKey);
			[NSException raise:NSGenericException format:@"Invalid material"];
			
		case 1:
		OOReportError(_problemReporter, @"The material \"%@\" of \"%@\" uses textures, but the mesh has no %@ attribute.", [_spec materialKey], [_mesh name], kOOTexCoordsAttributeKey);
		[NSException raise:NSGenericException format:@"Invalid material"];
			
		case 2:
			break;	// Perfect!
			
		default:
			OOReportWarning(_problemReporter, @"The mesh \"%@\" has a %@ attribute with %u values per vertex. Only the first two will be used by standard materials.", [_mesh name], kOOTexCoordsAttributeKey, texCoordsSize);
	}
	
	[self addAttribute:@"aTexCoords" ofType:@"vec2"];
	[self addVarying:@"vTexCoords" ofType:@"vec2"];
	[_vertexBody appendString:@"\tvTexCoords = aTexCoords;\n\t\n"];
	
	// FIXME: texCoords will need to be handled differently if parallax mapping.
	[_fragmentBody appendString:@"\t// Texture reads\n\tvec2 texCoords = vTexCoords;\n"];
	
	OOTextureSpecification *spec = nil;
	foreach (spec, _textures)
	{
		NSString *name = [spec textureMapName];
		NSUInteger texID = [_textureIDs oo_unsignedIntegerForKey:name];
		
		[_fragmentBody appendFormat:@"\tvec4 tex%uSample = texture2D(uTexture%u, texCoords);  // %@\n", texID, texID, name];
		[self addFragmentUniform:$sprintf(@"uTexture%u", texID) ofType:@"sampler2D"];
		
	}
	
	[_fragmentBody appendString:@"\t\n"];
}


- (void) getSampleName:(NSString **)outSampleName andSwizzleOp:(NSString **)outSwizzleOp forTextureSpec:(OOTextureSpecification *)spec
{
	NSParameterAssert(outSampleName != NULL && outSwizzleOp != NULL && spec != nil);
	
	NSString	*key = [spec textureMapName];
	NSUInteger	texID = [_textureIDs oo_unsignedIntegerForKey:key];
	
	*outSampleName = $sprintf(@"tex%uSample", texID);
	*outSwizzleOp = [spec extractMode];
}


// Generate a read for an RGB value, or a single channel splatted across RGB.
- (NSString *) readRGBForTextureSpec:(OOTextureSpecification *)textureSpec mapName:(NSString *)mapName
{
	NSString *sample, *swizzle;
	[self getSampleName:&sample andSwizzleOp:&swizzle forTextureSpec:textureSpec];
	
	if (swizzle == nil)
	{
		return [sample stringByAppendingString:@".rgb"];
	}
	
	NSUInteger channelCount = [swizzle length];
	
	if (channelCount == 1)
	{
		return $sprintf(@"%@.%@%@%@", sample, swizzle, swizzle, swizzle);
	}
	else if (channelCount == 3)
	{
		return $sprintf(@"%@.%@", sample, swizzle);
	}
	
	OOReportWarning(_problemReporter, @"The %@ map for material \"%@\" of \"%@\" specifies %u channels to extract, but only 1 or 3 may be used.", mapName, [_spec materialKey], [_mesh name], channelCount);
	return nil;
}


- (void) writeDiffuseColorTerm
{
	OOTextureSpecification	*diffuseMap = [_spec diffuseMap];
	OOColor					*diffuseColor = [_spec diffuseColor];
	
	if ([diffuseColor isBlack])  return;
	
	[_fragmentBody appendString:@"\t// Diffuse colour\n"];
	
	BOOL haveDiffuseColor = NO;
	if (diffuseMap != nil)
	{
		NSString *readInstr = [self readRGBForTextureSpec:diffuseMap mapName:@"diffuse"];
		if (EXPECT_NOT(readInstr == nil))
		{
			[_fragmentBody appendString:@"\t// INVALID EXTRACTION KEY\n\t\n"];
		}
		else
		{
			[_fragmentBody appendFormat:@"\tvec3 diffuseColor = %@;\n", readInstr];
			 haveDiffuseColor = YES;
		}
	}
	
	if (!haveDiffuseColor || ![diffuseColor isWhite])
	{
		float rgba[4];
		[diffuseColor getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
		NSString *format = nil;
		if (haveDiffuseColor)
		{
			format = @"\tdiffuseColor *= vec3(%g, %g, %g);\n";
		}
		else
		{
			format = @"\tconst vec3 diffuseColor = vec3(%g, %g, %g);\n";
			haveDiffuseColor = YES;
		}
		[_fragmentBody appendFormat:format, rgba[0], rgba[1], rgba[2]];
	}
	
	[_fragmentBody appendString:@"\ttotalColor += diffuseColor * diffuseLight;\n\t\n"];
}


- (LightingMode) lightingMode
{
	if (_lightingMode == kLightingUndetermined)
	{
		_normalAttrSize = [_mesh attributeSizeForKey:kOONormalAttributeKey];
		_tangentAttrSize = [_mesh attributeSizeForKey:kOOTangentAttributeKey];
		_bitangentAttrSize = [_mesh attributeSizeForKey:kOOBitangentAttributeKey];
		
		if (_tangentAttrSize >= 3)
		{
			if (_bitangentAttrSize >= 3)
			{
				_lightingMode = kLightingTangentBitangent;
			}
			else if (_normalAttrSize >= 3)
			{
				_lightingMode = kLightingNormalTangent;
			}
		}
		else
		{
			if (_normalAttrSize >= 3)
			{
				_lightingMode = kLightingNormalOnly;
			}
		}
		
		if (_lightingMode == kLightingUndetermined)
		{
			_lightingMode = kLightingUniform;
			OOReportWarning(_problemReporter, @"Mesh \"%@\" does not provide normals or tangents and bitangents, so no lighting is possible.", [_mesh name]);
		}
	}
	return _lightingMode;
}


- (void) writeDiffuseLighting
{
	BOOL needFragEyeVector = NO;	// Will be needed for specular light and parallax mapping.
	
	// Simple placeholder lighting based on legacy OpenGL lighting.
	BOOL tangentSpace = NO;
	switch ([self lightingMode])
	{
		case kLightingNormalOnly:
			[self addAttribute:@"aNormal" ofType:@"vec3"];
			[self addVarying:@"vLightVector" ofType:@"vec3"];
			[self addVarying:@"vNormal" ofType:@"vec3"];
			
			// FIXME: do we really need to normalize here?
			[_vertexBody appendString:
			@"\tvNormal = normalize(gl_NormalMatrix * aNormal);\n"
			 "\tvLightVector = gl_LightSource[0].position.xyz;\n"];
			
			if (needFragEyeVector)
			{
				[self addVarying:@"vEyeVector" ofType:@"vec3"];
				[_vertexBody appendString:@"\tvEyeVector = -position.xyz;\n"];
			}
			
			[_vertexBody appendString:@"\t\n"];
			
			[_fragmentBody appendString:
			@"\t// Placeholder lighting (world space)\n"
			 "\tvec3 normal = normalize(vNormal);\n"];
			break;
			
		case kLightingNormalTangent:
			[self addAttribute:@"aNormal" ofType:@"vec3"];
			[self addAttribute:@"aTangent" ofType:@"vec3"];
			tangentSpace = YES;
			// FIXME: do we really need to normalize here?
			[_vertexBody appendString:
			@"\t// Build tangent space basis\n"
			 "\tvec3 n = normalize(gl_NormalMatrix * aNormal);\n"
			 "\tvec3 t = normalize(gl_NormalMatrix * aTangent);\n"
			 "\tvec3 b = cross(n, t);\n"];
			break;
			
		case kLightingTangentBitangent:
			[self addAttribute:@"aTangent" ofType:@"vec3"];
			[self addAttribute:@"aBitangent" ofType:@"vec3"];
			tangentSpace = YES;
			// FIXME: do we really need to normalize here?
			[_vertexBody appendString:
			@"\t// Build tangent space basis\n"
			 "\tvec3 t = normalize(gl_NormalMatrix * aTangent);\n"
			 "\tvec3 b = normalize(gl_NormalMatrix * aBitangent);\n"
			 "\tvec3 n = cross(t, b);\n"];
			break;
		
		case kLightingUniform:
		case kLightingUndetermined:
			[_fragmentBody appendString:@"\t// No lighting because the mesh has no normals.\n\tconst vec3 diffuseLight = vec3(1.0);\n\t\n"];
			return;
	}
	
	if (tangentSpace)
	{
		// Shared code for kLightingNormalTangent and kLightingTangentBitangent.
		[self addVarying:@"vLightVector" ofType:@"vec3"];
		[self addVarying:@"vEyeVector" ofType:@"vec3"];
		
		[_vertexBody appendString:
		@"\tmat3 TBN = mat3(t, b, n);\n\t\n"
		 "\tvec3 eyeVector = -position.xyz;\n"];
		
		if (needFragEyeVector)
		{
			[_vertexBody appendString:@"\tvEyeVector = eyeVector * TBN;\n\t\n"];
		}
		
		[_vertexBody appendString:
		@"\tvec3 lightVector = gl_LightSource[0].position.xyz + eyeVector;\n"
		 "\tvLightVector = lightVector * TBN;\n\t\n"];
		
		// FIXME: normal mapping.
		[_fragmentBody appendString:@"\tconst vec3 normal = vec3(0.0, 0.0, 1.0);\n\t\n"];
		
		[_fragmentBody appendString:
		@"\t// Placeholder lighting (tangent space)\n"];
	}
	
	// Shared code for all lighting modes.
	[_fragmentBody appendString:
	@"\tvec3 lightVector = normalize(vLightVector);\n"
	 "\tfloat intensity = 0.8 * max(0.0, dot(normal, lightVector)) + 0.2;"
	 "\tvec3 diffuseLight = vec3(intensity);\n\t\n"];
}


- (void) writeEmission
{
	OOTextureSpecification	*emissionMap = [_spec emissionMap];
	OOColor					*emissionColor = [_spec emissionColor];
	
	if ([emissionColor isBlack])  return;
	
	[_fragmentBody appendString:@"\t// Emission (glow)\n"];
	
	BOOL haveEmissionColor = NO;
	if (emissionMap != nil)
	{
		NSString *readInstr = [self readRGBForTextureSpec:emissionMap mapName:@"emission"];
		if (EXPECT_NOT(readInstr == nil))
		{
			[_fragmentBody appendString:@"\t// INVALID EXTRACTION KEY\n\t\n"];
			return;
		}
		
		[_fragmentBody appendFormat:@"\tvec3 emissionColor = %@;\n", readInstr];
		haveEmissionColor = YES;
	}
	
	if (!haveEmissionColor || ![emissionColor isWhite])
	{
		float rgba[4];
		[emissionColor getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
		NSString *format = nil;
		if (haveEmissionColor)
		{
			format = @"\temissionColor *= vec3(%g, %g, %g);\n";
		}
		else
		{
			format = @"\tconst vec3 emissionColor = vec3(%g, %g, %g);\n";
			haveEmissionColor = YES;
		}
		[_fragmentBody appendFormat:format, rgba[0] * rgba[3], rgba[1] * rgba[3], rgba[2] * rgba[3]];
	}
	
	[_fragmentBody appendString:@"\ttotalColor += emissionColor;\n\t\n"];
}


- (void) writeIllumination
{
	OOTextureSpecification	*illuminationMap = [_spec illuminationMap];
	OOColor					*illuminationColor = [_spec illuminationColor];
	
	if ([illuminationColor isBlack])  return;
	
	[_fragmentBody appendString:@"\t// Illumination\n"];
	
	BOOL haveIlluminationColor = NO;
	if (illuminationMap != nil)
	{
		NSString *readInstr = [self readRGBForTextureSpec:illuminationMap mapName:@"illumination"];
		if (EXPECT_NOT(readInstr == nil))
		{
			[_fragmentBody appendString:@"\t// INVALID EXTRACTION KEY\n\t\n"];
			return;
		}
		
		[_fragmentBody appendFormat:@"\tvec3 illuminationColor = %@;\n", readInstr];
		haveIlluminationColor = YES;
	}
	
	if (!haveIlluminationColor || ![illuminationColor isWhite])
	{
		float rgba[4];
		[illuminationColor getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
		NSString *format = nil;
		if (haveIlluminationColor)
		{
			format = @"\tilluminationColor *= vec3(%g, %g, %g);\n";
		}
		else
		{
			format = @"\tconst vec3 illuminationColor = vec3(%g, %g, %g);\n";
			haveIlluminationColor = YES;
		}
		[_fragmentBody appendFormat:format, rgba[0] * rgba[3], rgba[1] * rgba[3], rgba[2] * rgba[3]];
	}
	
	[_fragmentBody appendString:@"\ttotalColor += illuminationColor * diffuseColor;\n\t\n"];
}


- (void) writePosition
{
	[self addAttribute:@"aPosition" ofType:@"vec3"];
	
	[_vertexBody appendString:
	@"\tvec4 position = gl_ModelViewMatrix * vec4(aPosition, 1.0);\n"
	 "\tgl_Position = gl_ProjectionMatrix * position;\n\t\n"];
}


- (void) writeFinalColorComposite
{
	[_fragmentBody appendString:@"\tgl_FragColor = vec4(totalColor, 1.0);\n\t\n"];
}


- (void) composeVertexShader
{
	while ([_vertexBody hasSuffix:@"\t\n"])
	{
		[_vertexBody deleteCharactersInRange:(NSRange){ [_vertexBody length] - 2, 2 }];
	}
	[_vertexBody appendString:@"}"];
	
	NSMutableString *vertexShader = [NSMutableString string];
	AppendIfNotEmpty(vertexShader, _attributes, @"Attributes");
	AppendIfNotEmpty(vertexShader, _vertexUniforms, @"Uniforms");
	AppendIfNotEmpty(vertexShader, _varyings, @"Varyings");
	AppendIfNotEmpty(vertexShader, _vertexHelpers, @"Helper functions");
	AppendIfNotEmpty(vertexShader, _vertexBody, nil);
	_vertexShader = [vertexShader copy];
}


- (void) composeFragmentShader
{
	while ([_fragmentBody hasSuffix:@"\t\n"])
	{
		[_fragmentBody deleteCharactersInRange:(NSRange){ [_fragmentBody length] - 2, 2 }];
	}
	[_fragmentBody appendString:@"}"];
	
	NSMutableString *fragmentShader = [NSMutableString string];
	AppendIfNotEmpty(fragmentShader, _fragmentUniforms, @"Uniforms");
	AppendIfNotEmpty(fragmentShader, _varyings, @"Varyings");
	AppendIfNotEmpty(fragmentShader, _fragmentHelpers, @"Helper functions");
	AppendIfNotEmpty(fragmentShader, _fragmentBody, nil);
	_fragmentShader = [fragmentShader copy];
}


- (BOOL) run
{
	[self createTemporaries];
	_uniforms = [[NSMutableDictionary alloc] init];
	[_vertexBody appendString:@"void main(void)\n{\n"];
	[_fragmentBody appendString:@"void main(void)\n{\n"];
	
	@try
	{
		[_fragmentBody appendString:@"\tvec3 totalColor = vec3(0.0);\n\t\n"];
		
		[self writePosition];
		[self setUpTextures];
		[self writeDiffuseLighting];
		[self writeDiffuseColorTerm];
		[self writeEmission];
		[self writeIllumination];
		[self writeFinalColorComposite];
		
		[self composeVertexShader];
		[self composeFragmentShader];
	}
	@catch (NSException *exception)
	{
		// Error should have been reported already.
		return NO;
	}
	@finally
	{
		[self destroyTemporaries];
	}
	
	return YES;
}


- (void) createTemporaries
{
	_attributes = [NSMutableString string];
	_varyings = [NSMutableString string];
	_vertexUniforms = [NSMutableString string];
	_fragmentUniforms = [NSMutableString string];
	_vertexBody = [NSMutableString string];
	_fragmentBody = [NSMutableString string];
}


- (void) destroyTemporaries
{
	DESTROY(_attributes);
	DESTROY(_varyings);
	DESTROY(_vertexUniforms);
	DESTROY(_fragmentUniforms);
	DESTROY(_vertexHelpers);
	DESTROY(_fragmentHelpers);
	DESTROY(_vertexBody);
	DESTROY(_fragmentBody);
	
	DESTROY(_texturesByName);
	DESTROY(_textureIDs);
}

@end
