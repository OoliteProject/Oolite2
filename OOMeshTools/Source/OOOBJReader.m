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

#import "OOOBJReader.h"
#import "OOOBJLexer.h"
#import "OOProblemReportManager.h"

#import "OOAbstractMesh.h"


#define kAnonymousMaterialName @"<unnamed>"


@interface OOOBJReader (Private) <OOOBJMaterialLibraryResolver>

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)expected;
- (void) priv_reportMaterialParseError:(NSString *)format, ...;
- (void) priv_reportBasicMaterialParseError:(NSString *)expected;
- (void) priv_reportMallocFailure;

- (NSString *) priv_displayName;

- (BOOL) priv_readVertexPosition;
- (BOOL) priv_readVertexNormal;
- (BOOL) priv_readVertexTexCoords;
- (BOOL) priv_readFace;
- (BOOL) priv_readMaterialLibrary;
- (BOOL) priv_readUseMaterial;
- (BOOL) priv_readObjectName;
- (BOOL) priv_readSmoothGroup;

- (BOOL) priv_readMaterialNewMaterial;
- (BOOL) priv_readMaterialDiffuseColor;
- (BOOL) priv_readMaterialAmbientColor;
- (BOOL) priv_readMaterialSpecularColor;
- (BOOL) priv_readMaterialEmissionColor;
- (BOOL) priv_readMaterialDiffuseMap;
- (BOOL) priv_readMaterialSpecularMap;
- (BOOL) priv_readMaterialEmissionMap;
- (BOOL) priv_readMaterialSpecularExponent;
- (BOOL) priv_readMaterialOverallAlpha;

- (BOOL) priv_notifyIgnoredKeyword:(NSString *)keyword;
- (BOOL) priv_notifyIgnoredMaterialKeyword:(NSString *)keyword;

@end


@implementation OOOBJReader

- (id) initWithPath:(NSString *)path issues:(id <OOProblemReportManager>)issues
{
	return [self initWithPath:path issues:issues resolver:nil];
}


- (id) initWithPath:(NSString *)path issues:(id <OOProblemReportManager>)issues resolver:(id <OOOBJMaterialLibraryResolver>)resolver
{
	if ((self = [super init]))
	{
		if (resolver == nil)  resolver = self;
		
		_issues = [issues retain];
		_path = [path copy];
		_resolver = [resolver retain];
		
		_lexer = [[OOOBJLexer alloc] initWithPath:_path issues:_issues];
		if (_lexer == nil)  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_path);
	DESTROY(_resolver);
	DESTROY(_lexer);
	DESTROY(_abstractMesh);
	
	[super dealloc];
}


- (void) parse
{
	if (_lexer == nil)  return;
	
	BOOL OK = YES;
	
	NSAutoreleasePool *rootPool = [NSAutoreleasePool new];
	_positions = [NSMutableArray array];
	_texCoords = [NSMutableArray array];
	_normals = [NSMutableArray array];
	_smoothGroups = [NSMutableDictionary dictionary];
	_materials = [NSMutableDictionary dictionary];
	_materialGroups = [NSMutableDictionary dictionary];
	_vertexCache = [NSMutableSet set];
	_haveAllTexCoords = YES;
	_haveAllNormals = YES;
	_currentGroup = [[[OOAbstractFaceGroup alloc] init] autorelease];
	
	OOMaterialSpecification *anonMaterial = [[OOMaterialSpecification alloc] initWithMaterialKey:kAnonymousMaterialName];
	[_currentGroup setMaterial:anonMaterial];
	[_materials setObject:anonMaterial forKey:kAnonymousMaterialName];
	[_materialGroups setObject:_currentGroup forKey:kAnonymousMaterialName];
	[anonMaterial release];
	
	while (OK && ![_lexer isAtEndOfFile])
	{
		NSString *keyword = nil;
		OK = [_lexer readString:&keyword];
		if (!OK)
		{
			[self priv_reportBasicParseError:@"keyword"];
			break;
		}
		if (EXPECT_NOT([keyword length] == 0))  continue;
		
		if ([keyword isEqualToString:@"v"])  OK = [self priv_readVertexPosition];
		else if ([keyword isEqualToString:@"vn"])  OK = [self priv_readVertexNormal];
		else if ([keyword isEqualToString:@"vt"])  OK = [self priv_readVertexTexCoords];
		else if ([keyword isEqualToString:@"f"])  OK = [self priv_readFace];
		else if ([keyword isEqualToString:@"mtllib"])  OK = [self priv_readMaterialLibrary];
		else if ([keyword isEqualToString:@"usemtl"])  OK = [self priv_readUseMaterial];
		else if ([keyword isEqualToString:@"o"])  OK = [self priv_readObjectName];
		else if ([keyword isEqualToString:@"s"])  OK = [self priv_readSmoothGroup];
		else if ([keyword isEqualToString:@"g"])  OK = [_lexer skipLine];
		else if ([keyword isEqualToString:@"mg"])  OK = [_lexer skipLine];
		else  OK = [self priv_notifyIgnoredKeyword:keyword];
		
		if (OK && ![_lexer readNewline])
		{
			[self priv_reportBasicParseError:@"end of line"];
			OK = NO;
		}
	}
	
	DESTROY(_lexer);
	
	if (OK)
	{
		OOLog(@"temp.objParser", @"Read OBJ \"%@\" with %u vertex positions, %u normals, %u tex coords, %u effective vertices, %u smooth groups, %u faces, %u materials.", [self name], (unsigned long)_positionCount, (unsigned long)_texCoordCount, (unsigned long)_normalCount, (unsigned long)[_vertexCache count], (unsigned long)[_smoothGroups count], (unsigned long)_faceCount, (unsigned long)[_materials count]);
	}
	else
	{
		OOLog(@"temp.objParser.failed", @"OBJ parser failed.");
	}
	
	_abstractMesh = [[OOAbstractMesh alloc] init];
	[_abstractMesh setName:[self name]];
	OOAbstractFaceGroup *group = nil;
	foreach (group, [_materialGroups allValues])
	{
		if ([group faceCount] > 0)
		{
			[_abstractMesh addFaceGroup:group];
		}
	}
	
	_positions = nil;
	_texCoords = nil;
	_normals = nil;
	_smoothGroups = nil;
	_currentSmoothGroup = nil;
	_materials = nil;
	_materialGroups = nil;
	_vertexCache = nil;
	_currentGroup = nil;
	
	[rootPool drain];
}


- (OOAbstractMesh *) abstractMesh
{
	[self parse];
	return _abstractMesh;
}


- (NSString *) name
{
	[self parse];
	
	if (_name == nil)
	{
		_name = [_path lastPathComponent];
		if ([[[_name pathExtension] lowercaseString] isEqualToString:@"obj"])
		{
			_name = [_name stringByDeletingPathExtension];
		}
		[_name retain];
	}
	
	return _name;
}

@end


@implementation OOOBJReader (Private)

- (NSData *) oo_objReader:(OOOBJReader *)reader findMaterialLibrary:(NSString *)fileName
{
	NSString *path = [[_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
	return [NSData dataWithContentsOfFile:path];
}


- (void) priv_reportParseError:(NSString *)format, ...
{
	NSString *base = OOLocalizeProblemString(_issues, @"Parse error on line %u of %@: %@.");
	format = OOLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [_lexer lineNumber], [self priv_displayName], message];
	[_issues addProblemOfType:kOOMProblemTypeError message:message];
}


- (void) priv_reportBasicParseError:(NSString *)expected
{
	[self priv_reportParseError:@"expected %@, got \"%@\"", expected, [_lexer currentTokenString]];
}


- (void) priv_reportMaterialParseError:(NSString *)format, ...
{
	NSString *base = OOLocalizeProblemString(_issues, @"Parse error on line %u of %@: %@. Rest of material library will be ignored.");
	format = OOLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [_lexer lineNumber], _currentMaterialLibraryName, message];
	[_issues addProblemOfType:kOOMProblemTypeWarning message:message];
}


- (void) priv_reportBasicMaterialParseError:(NSString *)expected
{
	[self priv_reportParseError:@"expected %@, got \"%@\"", expected, [_lexer currentTokenString]];
}


- (void) priv_reportMallocFailure
{
	OOReportError(_issues, @"Not enough memory to read %@.", [[NSFileManager defaultManager] displayNameAtPath:_path]);
}


- (NSString *) priv_displayName
{
	return [[NSFileManager defaultManager] displayNameAtPath:_path];
}


- (BOOL) priv_readVectorForArray:(NSMutableArray *)array
{
	Vector v;
	BOOL OK = [_lexer readReal:&v.x] &&
			  [_lexer readReal:&v.y] &&
			  [_lexer readReal:&v.z];
	if (!OK)
	{
		[self priv_reportBasicParseError:@"number"];
		return NO;
	}
	
	// Flip for left-handed Oolite coordinate system.
	v.x = -v.x;
	
	[array addObject:OOFloatArrayFromVector(clean_vector(v))];
	 return YES;
}


- (BOOL) priv_readVertexPosition
{
	_positionCount++;
	return [self priv_readVectorForArray:_positions];
}


- (BOOL) priv_readVertexNormal
{
	_normalCount++;
	return [self priv_readVectorForArray:_normals];
}


- (BOOL) priv_readVertexTexCoords
{
	_texCoordCount++;
	Vector2D v;
	BOOL OK = [_lexer readReal:&v.x] &&
			  [_lexer readReal:&v.y];
	if (!OK)
	{
		[self priv_reportBasicParseError:@"number"];
		return NO;
	}
	
	[_texCoords addObject:OOFloatArrayFromVector2D(clean_vector2D(v))];
	return YES;
}


static BOOL ReadFaceTriple(OOOBJReader *self, OOOBJLexer *lexer, NSInteger *v, NSInteger *vt, NSInteger *vn)
{
	NSCParameterAssert(v != NULL && vt != NULL && vn != NULL);
	
	/*	A face triple is required to consist of three elements separated by
		slashes, with no spaces between. The elements may be positive or
		negative integers, or empty strings.
		Here, empty strings are represented as NSNotFound.
	*/
	if (![lexer readInteger:v])
	{
		[self priv_reportBasicParseError:@"integer"];
		return NO;
	}
	if (![lexer skipSlash])
	{
		[self priv_reportBasicParseError:@"\"/\""];
		return NO;
	}
	if (![lexer isAtSlash])
	{
		if (![lexer readInteger:vt])
		{
			[self priv_reportBasicParseError:@"integer"];
			return NO;
		}
	}
	else
	{
		*vt = NSNotFound;
	}
	if (![lexer skipSlash])
	{
		[self priv_reportBasicParseError:@"\"/\""];
		return NO;
	}
	if (![lexer isAtSlash])
	{
		if (![lexer readInteger:vn])
		{
			[self priv_reportBasicParseError:@"integer"];
			return NO;
		}
	}
	else
	{
		*vn = NSNotFound;
	}
	
	return YES;
}


- (OOAbstractVertex *) priv_vertexWithPositionIdx:(NSInteger)v texCoordIdx:(NSInteger)vt normalIdx:(NSInteger)vn
{
	NSInteger ev = (v > 0) ? v : (v - _positionCount);
	NSInteger evt = (vt > 0) ? vt : (vt - _texCoordCount);
	NSInteger evn = (vn > 0) ? vn : (vn - _normalCount);
	
	if (EXPECT_NOT(ev > _positionCount))
	{
		[self priv_reportParseError:@"vertex index out of range: %lu out of %lu", (unsigned long)ev, (unsigned long)_positionCount];
		return nil;
	}
	if (EXPECT_NOT(vt != NSNotFound && evt > _texCoordCount))
	{
		[self priv_reportParseError:@"texture coordinates index out of range: %lu out of %lu", (unsigned long)evt, (unsigned long)_texCoordCount];
		return nil;
	}
	if (EXPECT_NOT(vn != NSNotFound && evn > _normalCount))
	{
		[self priv_reportParseError:@"vertex normal index out of range: %lu out of %lu", (unsigned long)evn, (unsigned long)_normalCount];
		return nil;
	}
	
	OOMutableAbstractVertex *vertex = [[OOMutableAbstractVertex alloc] initWithAttribute:[_positions objectAtIndex:ev - 1] forKey:kOOPositionAttributeKey];
	if (vt != NSNotFound)
	{
		[vertex setAttribute:[_texCoords objectAtIndex:evt - 1] forKey:kOOTexCoordsAttributeKey];
	}
	if (vn != NSNotFound)
	{
		[vertex setAttribute:[_normals objectAtIndex:evn - 1] forKey:kOONormalAttributeKey];
	}
	
	OOMutableAbstractVertex *cached = [_vertexCache member:vertex];
	if (cached == nil)
	{
		cached = [vertex copy];
		[_vertexCache addObject:cached];
	}
	// The vertex cache will live long enough to hold on to the vertex for us.
	[vertex release];
	return cached;
}


- (BOOL) priv_readFace
{
	//	Read N-gon and convert to triangle strip.
	NSInteger v, vt, vn;
	
	if (!ReadFaceTriple(self, _lexer, &v, &vt, &vn))  return NO;
	OOAbstractVertex *v0 = [self priv_vertexWithPositionIdx:v
												texCoordIdx:vt
												  normalIdx:vn];
	if (v0 == nil)  return NO;
	BOOL haveTex = vt != NSNotFound, haveNormals = vn != NSNotFound;
	if (!haveTex)  _haveAllTexCoords = NO;
	if (!haveNormals)  _haveAllTexCoords = NO;
	
	if (!ReadFaceTriple(self, _lexer, &v, &vt, &vn))  return NO;
	OOAbstractVertex *v1 = [self priv_vertexWithPositionIdx:v
												texCoordIdx:haveTex ? vt : NSNotFound
												  normalIdx:haveNormals ? vn : NSNotFound];
	if (v1 == nil)  return NO;
	
	while (![_lexer isAtEndOfLine])
	{
		if (!ReadFaceTriple(self, _lexer, &v, &vt, &vn))  return NO;
		OOAbstractVertex *v2 = [self priv_vertexWithPositionIdx:v
													texCoordIdx:haveTex ? vt : NSNotFound
													  normalIdx:haveNormals ? vn : NSNotFound];
		if (v2 == nil)  return NO;
		
		OOAbstractFace *face = [[OOAbstractFace alloc] initWithVertex0:v0 vertex1:v1 vertex2:v2];
		v1 = v2;
		
		[_currentGroup addFace:face];
		[face release];
		_faceCount++;
	}
	
	return YES;
}


- (BOOL) priv_readMaterialLibrary
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSString *name = nil;
	[_lexer readUntilNewline:&name];
	if (name == nil)
	{
		[self priv_reportBasicParseError:@"string"];
		return NO;
	}
	
	OOOBJLexer *mtlLexer = nil;
	NSData *materialLibraryData = [_resolver oo_objReader:self findMaterialLibrary:name];
	if (materialLibraryData != nil)  mtlLexer = [[[OOOBJLexer alloc] initWithData:materialLibraryData issues:_issues] autorelease];
	if (mtlLexer == nil)
	{
		OOReportWarning(_issues, @"Could not read material library \"%@\"", name);
		return YES;	// Not fatal.
	}
	
	OOOBJLexer *savedLexer = _lexer;
	_lexer = mtlLexer;
	_currentMaterialLibraryName = name;
	
	BOOL OK = YES;
	while (OK && ![_lexer isAtEndOfFile])
	{
		NSString *keyword = nil;
		OK = [_lexer readString:&keyword];
		if (!OK)
		{
			[self priv_reportBasicMaterialParseError:@"keyword"];
			break;
		}
		if (EXPECT_NOT([keyword length] == 0))  continue;
		
		if ([keyword isEqualToString:@"newmtl"])  OK = [self priv_readMaterialNewMaterial];
		else if ([keyword isEqualToString:@"Kd"])  OK = [self priv_readMaterialDiffuseColor];
		else if ([keyword isEqualToString:@"Ka"])  OK = [self priv_readMaterialAmbientColor];
		else if ([keyword isEqualToString:@"Ks"])  OK = [self priv_readMaterialSpecularColor];
		else if ([keyword isEqualToString:@"Ke"])  OK = [self priv_readMaterialEmissionColor];
		else if ([keyword isEqualToString:@"map_Kd"])  OK = [self priv_readMaterialDiffuseMap];
		else if ([keyword isEqualToString:@"map_Ks"])  OK = [self priv_readMaterialSpecularMap];
		else if ([keyword isEqualToString:@"map_Ke"])  OK = [self priv_readMaterialEmissionMap];
		else if ([keyword isEqualToString:@"Ns"])  OK = [self priv_readMaterialSpecularExponent];
		else if ([keyword isEqualToString:@"d"] || [keyword isEqualToString:@"Tr"])  OK = [self priv_readMaterialOverallAlpha];
		// illum=1 means no specular highlight, illum=2 means specular highlight with Ks being required. We just use Ks and ignore illum.
		else if ([keyword isEqualToString:@"illum"])  OK = [_lexer skipLine];
		else  OK = [self priv_notifyIgnoredMaterialKeyword:keyword];
		
		if (OK && ![_lexer readNewline])
		{
			[self priv_reportBasicParseError:@"end of line"];
			OK = NO;
		}
	}
	
	_lexer = savedLexer;
	_currentMaterial = nil;
	_currentMaterialLibraryName = nil;
	
	[pool drain];
	return YES;
}


- (BOOL) priv_readUseMaterial
{
	NSString *name = nil;
	[_lexer readUntilNewline:&name];
	if (name == nil)
	{
		[self priv_reportBasicParseError:@"string"];
		return NO;
	}
	
	OOAbstractFaceGroup *group = [_materialGroups objectForKey:name];
	if (group == nil)
	{
		// If necessary, create a group (and perhaps material) for this material key.
		OOMaterialSpecification *material = [_materials objectForKey:name];
		if (material == nil)
		{
			material = [[OOMaterialSpecification alloc] initWithMaterialKey:name];
			[_materials setObject:material forKey:name];
			[material release];
		}
		
		group = [[OOAbstractFaceGroup alloc] init];
		[group setMaterial:material];
		[_materialGroups setObject:group forKey:name];
		[group release];
	}
	
	// Switch current material.
	_currentGroup = group;
	
	return YES;
}


- (BOOL) priv_readObjectName
{
	if (_name != nil)  return [_lexer skipLine];
	
	if (![_lexer readUntilNewline:&_name])
	{
		[self priv_reportBasicParseError:@"string"];
		return NO;
	}
	
	_name = [[_name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] retain];
	return YES;
}


- (BOOL) priv_readSmoothGroup
{
	/*	Strictly speaking, smooth group keys are required to be integers or
		the string "off" (eqivalent to 0). Since we’re using a dictionary
		anyway, enforcing this would be more work than being lax.
	*/
	
	NSString *key = nil;
	if (![_lexer readUntilNewline:&key])
	{
		[self priv_reportBasicParseError:@"string"];
		return NO;
	}
	
	if ([key isEqualToString:@"0"] || [key isEqualToString:@"off"])
	{
		// No smooth group.
		_currentSmoothGroup = nil;
	}
	else
	{
		_currentSmoothGroup = [_smoothGroups objectForKey:key];
		if (_currentSmoothGroup == nil)
		{
			_currentSmoothGroup = [NSArray array];
			[_smoothGroups setObject:_currentSmoothGroup forKey:key];
		}
	}
	
	return YES;
}


- (BOOL) priv_readMaterialNewMaterial
{
	NSString *name = nil;
	[_lexer readUntilNewline:&name];
	if (name == nil)
	{
		[self priv_reportBasicMaterialParseError:@"string"];
		return NO;
	}
	
	/*	NOTE: according to official OBJ semantics, the first material library
		specified takes precendence, and the effect of specifying a material
		library after a material use is unspecified but implicitly should work.
		In this implementation, the last usage seen will apply for new usemtl
		commands. Since deliberate use of conflicting definitions is unlikely,
		this is not a problem, unless there are real-world files where mtllib
		comes after usemtl.
	*/
	_currentMaterial = [[OOMaterialSpecification alloc] initWithMaterialKey:name];
	[_materials setObject:_currentMaterial forKey:name];
	
	//	Set silly OBJ defaults, which will presumably be overriden with sane values.
	[_currentMaterial setAmbientColor:[OOColor colorWithWhite:0.2 alpha:1.0]];
	[_currentMaterial setDiffuseColor:[OOColor colorWithWhite:0.8 alpha:1.0]];
	
	[_currentMaterial setSpecularExponent:0];
	
	[_currentMaterial release];
	
	return YES;
}


- (BOOL) priv_readMaterialDiffuseColor
{
	float r, g, b, a = 1.0f;
	
	if (!([_lexer readReal:&r] && [_lexer readReal:&g] && [_lexer readReal:&b]))
	{
		[self priv_reportBasicMaterialParseError:@"number"];
	}
	
	if (![_lexer isAtEndOfLine])
	{
		// Alpha isn't part of the spec, but a logical extension.
		[_lexer readReal:&a];	// Ignore failure.
	}
	
	[_currentMaterial setDiffuseColor:[OOColor colorWithRed:r green:g blue:b alpha:a]];
	return YES;
}


- (BOOL) priv_readMaterialAmbientColor
{
	float r, g, b, a = 1.0f;
	
	if (!([_lexer readReal:&r] && [_lexer readReal:&g] && [_lexer readReal:&b]))
	{
		[self priv_reportBasicMaterialParseError:@"number"];
	}
	
	if (![_lexer isAtEndOfLine])
	{
		// Alpha isn't part of the spec, but a logical extension.
		[_lexer readReal:&a];	// Ignore failure.
	}
	
	[_currentMaterial setAmbientColor:[OOColor colorWithRed:r green:g blue:b alpha:a]];
	return YES;
}


- (BOOL) priv_readMaterialSpecularColor
{
	float r, g, b, a = 1.0f;
	
	if (!([_lexer readReal:&r] && [_lexer readReal:&g] && [_lexer readReal:&b]))
	{
		[self priv_reportBasicMaterialParseError:@"number"];
	}
	
	if (![_lexer isAtEndOfLine])
	{
		// Alpha isn't part of the spec, but a logical extension.
		[_lexer readReal:&a];	// Ignore failure.
	}
	
	/*	The distinction between specular colour and specular modulate colour
		does not exist in OBJ. It is not clear whether Ks should be used as
		modulate colour when there's a specular map, or ignored.
		
		This interpretation produces default results if Ks = 1,1,1,1.
	 */
	[_currentMaterial setSpecularColor:[OOColor colorWithRed:r * 0.2f green:g * 0.2f blue:b * 0.2f alpha:a]];
	[_currentMaterial setSpecularModulateColor:[OOColor colorWithRed:r green:g blue:b alpha:a]];
	return YES;
}


- (BOOL) priv_readMaterialEmissionColor
{
	float r, g, b, a = 1.0f;
	
	if (!([_lexer readReal:&r] && [_lexer readReal:&g] && [_lexer readReal:&b]))
	{
		[self priv_reportBasicMaterialParseError:@"number"];
	}
	
	if (![_lexer isAtEndOfLine])
	{
		// Alpha isn't part of the spec, but a logical extension.
		[_lexer readReal:&a];	// Ignore failure.
	}
	
	/*	The distinction between emission colour and emission modulate colour
		does not exist in OBJ. It is not clear whether Ks should be used as
		modulate colour when there's a nemission map, or ignored.
		
		This interpretation produces default results if Ks = 0,0,0,1.
	 */
	[_currentMaterial setEmissionColor:[OOColor colorWithRed:r green:g blue:b alpha:a]];
	return YES;
}


- (BOOL) priv_readMaterialDiffuseMap
{
	NSString *name = nil;
	[_lexer readUntilNewline:&name];
	if (name == nil)
	{
		[self priv_reportBasicParseError:@"string"];
		return NO;
	}
	
	[_currentMaterial setDiffuseMap:[OOTextureSpecification textureSpecWithName:name]];
	return YES;
}


- (BOOL) priv_readMaterialSpecularMap
{
	NSString *name = nil;
	[_lexer readUntilNewline:&name];
	if (name == nil)
	{
		[self priv_reportBasicParseError:@"string"];
		return NO;
	}
	
	[_currentMaterial setSpecularMap:[OOTextureSpecification textureSpecWithName:name]];
	return YES;
}


- (BOOL) priv_readMaterialEmissionMap
{
	NSString *name = nil;
	[_lexer readUntilNewline:&name];
	if (name == nil)
	{
		[self priv_reportBasicParseError:@"string"];
		return NO;
	}
	
	[_currentMaterial setEmissionMap:[OOTextureSpecification textureSpecWithName:name]];
	return YES;
}


- (BOOL) priv_readMaterialSpecularExponent
{
	float value;
	[_lexer readReal:&value];
	[_currentMaterial setSpecularExponent:OOClamp_0_max_f(value, 256.0f)];
	return YES;
}


- (BOOL) priv_readMaterialOverallAlpha
{
	float value;
	[_lexer readReal:&value];
	if (value != 1.0f)
	{
		OOReportWarning(_issues, @"Material \"%@\" in material libary \"%@\" specifies an overall alpha of %g. This will be ignored.", [_currentMaterial materialKey], _currentMaterialLibraryName, value);
	}
	
	return YES;
}


- (BOOL) priv_notifyIgnoredKeyword:(NSString *)keyword
{
	//	Set of keywords that are used for curved surfaces, which we don’t support.
	NSSet *curveCommands = $set(@"vp", @"deg", @"bmat", @"step", @"cstype", @"curv", @"curv2", @"surf", @"parm", @"trim", @"hole", @"scrv", @"sp", @"end", @"con");
	
	// Rendering attributes we don’t support.
	NSSet *renderAttribCommands = $set(@"bevel", @"c_interp", @"d_interp", @"lod", @"maplib", @"usemap", @"shadow_obj", @"trace_obj", @"ctech", @"stech");
	
	if ([curveCommands containsObject:keyword])
	{
		if (!_warnedAboutCurves)
		{
			OOReportWarning(_issues, @"\"%@\" contains curve data which will be ignored.", [self priv_displayName]);
			_warnedAboutCurves = YES;
		}
	}
	else if ([renderAttribCommands containsObject:keyword])
	{
		if (!_warnedAboutRenderAttribs)
		{
			OOReportWarning(_issues, @"\"%@\" contains rendering attributes which will be ignored.", [self priv_displayName]);
			_warnedAboutRenderAttribs = YES;
		}
	}
	else if ([keyword isEqual:@"l"] || [keyword isEqual:@"p"])
	{
		if (!_warnedAboutLinesOrPoints)
		{
			OOReportWarning(_issues, @"\"%@\" contains point or line data which will be ignored.", [self priv_displayName]);
			_warnedAboutLinesOrPoints = YES;
		}
	}
	else
	{
		if (!_warnedAboutUnknown)
		{
			OOReportWarning(_issues, @"\"%@\" contains unknown commands such as \"%@\" which will be ignored.", [self priv_displayName], keyword);
			_warnedAboutUnknown = YES;
		}
	}
	
	
	return [_lexer skipLine];
}


- (BOOL) priv_notifyIgnoredMaterialKeyword:(NSString *)keyword
{
	if (!_warnedAboutUnknown)
	{
		OOReportWarning(_issues, @"\"%@\" contains unknown commands such as \"%@\" which will be ignored.", _currentMaterialLibraryName, keyword);
		_warnedAboutUnknown = YES;
	}
	return [_lexer skipLine];
}

@end
