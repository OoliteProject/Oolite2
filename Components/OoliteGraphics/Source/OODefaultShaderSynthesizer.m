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
	
	NSMutableString				*_attributes;
	NSMutableString				*_varyings;
	NSMutableString				*_vertexUniforms;
	NSMutableString				*_fragmentUniforms;
	NSMutableString				*_vertexHelpers;
	NSMutableString				*_fragmentHelpers;
	NSMutableString				*_vertexBody;
	NSMutableString				*_fragmentBody;
	
	// _textures: dictionary mapping texture file names to texture specifications.
	NSMutableDictionary			*_textures;
	// _textureIDs: dictionary mapping texture file names to numerical IDs used to name variables.
	NSMutableDictionary			*_textureIDs;
}

- (id) initWithMaterialSpecifiction:(OOMaterialSpecification *)spec
							   mesh:(OORenderMesh *)mesh
					problemReporter:(id <OOProblemReporting>) problemReporter;

- (BOOL) run;

- (NSString *) vertexShader;
- (NSString *) fragmentShader;

- (void) createTemporaries;
- (void) destroyTemporaries;

@end


BOOL OOSynthesizeMaterialShader(OOMaterialSpecification *materialSpec, OORenderMesh *mesh, NSString **outVertexShader, NSString **outFragmentShader, id <OOProblemReporting> problemReporter)
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
	}
	else
	{
		*outVertexShader = nil;
		*outFragmentShader = nil;
	}
	[pool release];
	
	[*outVertexShader autorelease];
	[*outFragmentShader autorelease];
	
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
	OOTextureSpecification *existing = [_textures objectForKey:name];
	if (existing == nil)
	{
		[_textures setObject:spec forKey:name];
		[_textureIDs setObject:$int([_textures count]) forKey:name];
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
	_textures = [[NSMutableDictionary alloc] init];
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
	
	if ([_textures count] == 0)  return;
	
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
	
	NSString *name = nil;
	foreachkey(name, _textureIDs)
	{
		NSUInteger texID = [_textureIDs oo_unsignedIntegerForKey:name];
		
		[_fragmentBody appendFormat:@"\tvec4 tex%uSample = texture2D(uTexture%u, texCoords);  // %@\n", texID, texID, name];
		[self addFragmentUniform:$sprintf(@"uTexture%u", texID) ofType:@"sampler2D"];
	}
	
	[_fragmentBody appendString:@"\t\n"];
}


- (NSString *) readForTextureSpec:(OOTextureSpecification *)spec gettingChannelCount:(NSUInteger *)outCount
{
	NSParameterAssert(spec != nil && outCount != NULL);
	
	NSString *key = [spec textureMapName];
	NSUInteger texID = [_textureIDs oo_unsignedIntegerForKey:key];
	
	// FIXME: Support swizzling (generalization of extract_channel to support multiple channels).
	// FIXME: Support different channel counts.
	
	*outCount = 4;
	return $sprintf(@"tex%uSample", texID);
}


- (void) writeDiffuseColorTerm
{
	[_fragmentBody appendString:@"\t// Diffuse colour\n"];
	
	BOOL haveDiffuseColor = NO;
	OOTextureSpecification *diffuseMap = [_spec diffuseMap];
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
	
	OOColor *diffuseColor = [_spec diffuseColor];
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
	
	[_fragmentBody appendString:@"\t\n"];
}


- (void) writeDiffuseLighting
{
	// Simple placeholder lighting; light is always at y = ∞ (in model space).
	[self addAttribute:@"aNormal" ofType:@"vec3"];
	[self addVarying:@"vNormal" ofType:@"vec3"];
	
	[_vertexBody appendString:@"\tvNormal = aNormal;\n\n"];
	
	[_fragmentBody appendString:@"\t// Placeholder diffuse light\n\tvec4 diffuseLight = vec4(vec3(max(0.0, normalize(vNormal).y)), 1.0);\n\n"];
}


- (void) writePosition
{
	[self addAttribute:@"aPosition" ofType:@"vec3"];
	
	[_vertexBody appendString:@"\tgl_Position = gl_ModelViewProjectionMatrix * vec4(aPosition, 1.0);\n"];
}


- (void) writeFinalColorComposite
{
	[_fragmentBody appendString:@"\tgl_FragColor = diffuseColor * diffuseLight;\n"];
}


- (void) composeVertexShader
{
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
	[_vertexBody appendString:@"void main(void)\n{\n"];
	[_fragmentBody appendString:@"void main(void)\n{\n"];
	
	@try
	{
		[self setUpTextures];
		[self writeDiffuseColorTerm];
		[self writeDiffuseLighting];
		[self writeFinalColorComposite];
		[self writePosition];
		
		[_vertexBody appendString:@"}"];
		[_fragmentBody appendString:@"}"];
		
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
	
	DESTROY(_textures);
	DESTROY(_textureIDs);
}

@end
