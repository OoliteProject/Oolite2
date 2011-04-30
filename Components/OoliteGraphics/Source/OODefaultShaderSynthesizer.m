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
	[_vertexBody appendString:@"\tvTexCoords = aTexCoords;\n"];
	
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


- (NSString *) readForTextureSpec:(OOTextureSpecification *)spec gettingChannelCount:(NSUInteger *)outCount
{
	NSParameterAssert(spec != nil && outCount != NULL);
	
	NSString	*key = [spec textureMapName];
	NSUInteger	texID = [_textureIDs oo_unsignedIntegerForKey:key];
	NSString	*swizzle = [spec extractMode];
	NSUInteger	channelCount = [swizzle length];
	
	NSAssert(1 <= channelCount && channelCount <= 4, @"Contract violation: texture specification extract mode does not meet requirements.");
	*outCount = channelCount;
	
	if ([swizzle isEqualToString:kOOTextureExtractChannelIdentity])
	{
		return $sprintf(@"tex%uSample", texID);
	}
	else
	{
		return $sprintf(@"tex%uSample.%@", texID, swizzle);
	}
}


- (void) writeDiffuseColorTerm
{
	OOTextureSpecification *diffuseMap = [_spec diffuseMap];
	OOColor *diffuseColor = [_spec diffuseColor];
	
	if ([diffuseColor isBlack])  return;
	
	[_fragmentBody appendString:@"\t// Diffuse colour\n"];
	
	BOOL haveDiffuseColor = NO;
	if (diffuseMap != nil)
	{
		NSUInteger channelCount;
		NSString *readInstr = [self readForTextureSpec:diffuseMap gettingChannelCount:&channelCount];
		switch (channelCount)
		{
			case 1:
				// Grey -> RGB, A = 1
				readInstr = $sprintf(@"vec4(vec3(%@), 1.0)", readInstr);
				break;
				
			case 2:
				// Grey + alpha -> RGB + A
				readInstr = $sprintf(@"(%@).xxxy", readInstr);
				
			case 3:
				// RGB -> RGB, A = 1
				readInstr = $sprintf(@"vec4(%@, 1.0)", readInstr);
				
			case 4:
				readInstr = readInstr;
		}
		
		[_fragmentBody appendFormat:@"\tvec4 diffuseColor = %@;\n", readInstr];
		 haveDiffuseColor = YES;
	}
	
	if (![diffuseColor isWhite])
	{
		float rgba[4];
		[[_spec diffuseColor] getRed:&rgba[0] green:&rgba[1] blue:&rgba[2] alpha:&rgba[3]];
		NSString *format = nil;
		if (haveDiffuseColor)
		{
			format = @"\tdiffuseColor *= vec4(%g, %g, %g, %g);\n";
		}
		else
		{
			format = @"\tconst vec4 diffuseColor = vec4(%g, %g, %g, %g);\n";
			haveDiffuseColor = YES;
		}
		[_fragmentBody appendFormat:format, rgba[0], rgba[1], rgba[2], rgba[3]];
	}
	else if (!haveDiffuseColor)
	{
		[_fragmentBody appendString:@"const vec4 diffuseColor = vec4(1.0);\n"];
		haveDiffuseColor = YES;
	}
	
	[_fragmentBody appendString:@"\ttotalColor += diffuseColor * diffuseLight;\n\t\n"];
}


- (void) writeDiffuseLighting
{
	// Simple placeholder lighting based on legacy OpenGL lighting.
	[self addAttribute:@"aNormal" ofType:@"vec3"];
	[self addVarying:@"vNormal" ofType:@"vec3"];
	[self addVarying:@"vLightVector" ofType:@"vec3"];
	[self addVarying:@"vPosition" ofType:@"vec4"];
	
	[_vertexBody appendString:
	@"\tvPosition = position;\n"
	 "\tvNormal = normalize(gl_NormalMatrix * aNormal);\n"
	 "\tvLightVector = gl_LightSource[0].position.xyz;\n\t\n"];
	
	[_fragmentBody appendString:
	@"\t// Placeholder lighting\n"
	 "\tvec3 eyeVector = normalize(-vPosition.xyz);\n"
	 "\tvec3 lightVector = normalize(vLightVector);\n"
	 "\tvec3 normal = normalize(vNormal);\n"
	 "\tfloat intensity = 0.8 * dot(normal, lightVector) + 0.2;\n"
	 "\tvec4 diffuseLight = vec4(vec3(intensity), 1.0);\n"];
}


- (void) writeEmission
{
	
}


- (void) writePosition
{
	[self addAttribute:@"aPosition" ofType:@"vec3"];
	
	[_vertexBody appendString:
	@"\tvec4 position = gl_ModelViewProjectionMatrix * vec4(aPosition, 1.0);\n"
	 "\tgl_Position = position;\n\t\n"];
}


- (void) writeFinalColorComposite
{
	[_fragmentBody appendString:@"\tgl_FragColor = totalColor;\n\t\n"];
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
		[_fragmentBody appendString:@"\tvec4 totalColor = vec4(0.0);\n\t\n"];
		
		[self writePosition];
		[self setUpTextures];
		[self writeDiffuseLighting];
		[self writeDiffuseColorTerm];
		[self writeEmission];
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
