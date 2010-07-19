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

#import "OOOBJReader.h"
#import "OOOBJLexer.h"

#import "OOAbstractMesh.h"


#define kAnonymousMaterialName @"<unnamed>"


@interface OOOBJReader (Private) <OOOBJMaterialLibraryResolving>

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)expected;
- (void) priv_reportMaterialParseError:(NSString *)format, ...;
- (void) priv_reportBasicMaterialParseError:(NSString *)expected;
- (void) priv_reportMallocFailure;

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


@interface OOOBJVertexCacheKey: NSObject <NSCopying>
{
@private
	NSUInteger			_v, _vn, _vt;
}

- (id) initWithV:(NSInteger)v vn:(NSInteger)vn vt:(NSInteger)vt;

@end


@implementation OOOBJReader

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues
{
	return [self initWithPath:path progressReporter:progressReporter issues:issues resolver:nil];
}


- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues
		   resolver:(id <OOOBJMaterialLibraryResolving>)resolver
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
	DESTROY(_progressReporter);
	DESTROY(_path);
	DESTROY(_resolver);
	DESTROY(_lexer);
	DESTROY(_abstractMesh);
	
	[super dealloc];
}


- (void) setProgressReporter:(id <OOProgressReporting>)progressReporter
{
	if (progressReporter != _progressReporter)
	{
		[_progressReporter release];
		_progressReporter = [progressReporter retain];
	}
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
	_vertexCache = [NSMutableDictionary dictionary];
	_haveAllTexCoords = YES;
	_haveAllNormals = YES;
	_currentGroup = [[[OOAbstractFaceGroup alloc] init] autorelease];
	
	OOMaterialSpecification *anonMaterial = [[OOMaterialSpecification alloc] initWithMaterialKey:kAnonymousMaterialName];
	[_currentGroup setMaterial:anonMaterial];
	[_materials setObject:anonMaterial forKey:kAnonymousMaterialName];
	[_materialGroups setObject:_currentGroup forKey:kAnonymousMaterialName];
	[anonMaterial release];
	
	NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
	NSUInteger iterCount = 0;
	
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
		
		/*	Drain pool every 16 lines.
			This value has been tweaked with a large model and is slightly
			better than every 8 or 32 times.
		*/
		iterCount++;
		if ((iterCount & 0xF) == 0)
		{
			/*	Every 256 lines, update the progress reporter if at least 1 %
				change.
			*/
			if ((iterCount & 0xFF) == 0)
			{
				if (_progressReporter != nil)
				{
					float progress = [_lexer progressEstimate];
					if (progress > _lastProgress + 0.01f)
					{
						[_progressReporter task:self reportsProgress:progress];
						_lastProgress = progress;
					}
				}
				iterCount = 0;
			}
			
			[innerPool drain];
			innerPool = [NSAutoreleasePool new];
		}
	}
	
	[_progressReporter task:self reportsProgress:1.0f];
	[innerPool drain];
	DESTROY(_lexer);
	
	/*	TODO: track whether we have nonzero tex coords and avoid adding all-
		zero ones to the list. To support this, add special handling of all-
		zero OOFloatArrays, and treat them as equivalent to non-existent ones
		for OOAbstractVertex. (Ideally, trailing zeroes should be equivalent
		to holes, too.)
	*/
	_abstractMesh = [[OOAbstractMesh alloc] init];
	[_abstractMesh setName:[self meshName]];
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


- (void) getRenderMesh:(OORenderMesh **)renderMesh andMaterialSpecs:(NSArray **)materialSpecifications
{
	[[self abstractMesh] getRenderMesh:renderMesh andMaterialSpecs:materialSpecifications];
}


- (NSString *) meshName
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


- (NSString *) meshDescription
{
	return [[self abstractMesh] modelDescription];
}


- (BOOL) prefersAbstractMesh
{
	return YES;
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
	NSString *base = OOLocalizeProblemString(_issues, @"Parse error on line %u: %@.");
	format = OOLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [_lexer lineNumber], message];
	[_issues addProblemOfType:kOOProblemTypeError message:message];
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
	[_issues addProblemOfType:kOOProblemTypeWarning message:message];
}


- (void) priv_reportBasicMaterialParseError:(NSString *)expected
{
	[self priv_reportParseError:@"expected %@, got \"%@\"", expected, [_lexer currentTokenString]];
}


- (void) priv_reportMallocFailure
{
	OOReportError(_issues, @"Not enough memory to read %@.", [[NSFileManager defaultManager] displayNameAtPath:_path]);
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
	float x, y, z;
	BOOL OK = [_lexer readReal:&x] &&
			  [_lexer readReal:&y];
	if (!OK)
	{
		[self priv_reportBasicParseError:@"number"];
		return NO;
	}
	
	/*	vt is defined to take two parameters, but I've seen one with three
		in the wild - probably a mistake, since it was only one set of tex
		coords for the whole file, but since we conceptually support 3D tex
		coords we might as well parse it.
	*/
	BOOL is3D = [_lexer readReal:&z];
	if (!is3D || z == 0.0f)
	{
		[_texCoords addObject:OOFloatArrayFromVector2D(clean_vector2D((Vector2D){x, y}))];
	}
	else
	{
		[_texCoords addObject:OOFloatArrayFromVector(clean_vector((Vector){x, y, z}))];
	}

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

	OOOBJVertexCacheKey *cacheKey = [[OOOBJVertexCacheKey alloc] initWithV:ev vn:evn vt:evt];
	OOMutableAbstractVertex *vertex = [_vertexCache objectForKey:cacheKey];
	if (vertex == nil)
	{
		/*	Create a vertex object.
			This is ugly, but several times faster than using a mutable vertex.
		*/
		OOFloatArray *vAttr = [_positions objectAtIndex:ev - 1], *vtAttr = nil, *vnAttr = nil;
		if (vt != NSNotFound)
		{
			vtAttr = [_texCoords objectAtIndex:evt - 1];
			if (vn != NSNotFound)
			{
				vnAttr = [_normals objectAtIndex:evn - 1];
				vertex = [OOAbstractVertex vertexWithAttributes:$dict(kOOPositionAttributeKey, vAttr, kOONormalAttributeKey, vnAttr, kOOTexCoordsAttributeKey, vtAttr)];
			}
			else
			{
				vertex = [OOAbstractVertex vertexWithAttributes:$dict(kOOPositionAttributeKey, vAttr, kOOTexCoordsAttributeKey, vtAttr)];
			}
		}
		else
		{
			if (vn != NSNotFound)
			{
				vnAttr = [_normals objectAtIndex:evn - 1];
				vertex = [OOAbstractVertex vertexWithAttributes:$dict(kOOPositionAttributeKey, vAttr, kOONormalAttributeKey, vnAttr)];
			}
			else
			{
				vertex = [OOAbstractVertex vertexWithAttribute:vAttr forKey:kOOPositionAttributeKey];
			}
		}
		
		[_vertexCache setObject:vertex forKey:cacheKey];
	}
	[cacheKey release];
	return vertex;
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
												texCoordIdx:haveTex ? vt : (NSInteger)NSNotFound
												  normalIdx:haveNormals ? vn : (NSInteger)NSNotFound];
	if (v1 == nil)  return NO;
	
	while (![_lexer isAtEndOfLine])
	{
		if (!ReadFaceTriple(self, _lexer, &v, &vt, &vn))  return NO;
		OOAbstractVertex *v2 = [self priv_vertexWithPositionIdx:v
													texCoordIdx:haveTex ? vt : (NSInteger)NSNotFound
													  normalIdx:haveNormals ? vn : (NSInteger)NSNotFound];
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
			OOReportWarning(_issues, @"The document contains curve data which will be ignored.");
			_warnedAboutCurves = YES;
		}
	}
	else if ([renderAttribCommands containsObject:keyword])
	{
		if (!_warnedAboutRenderAttribs)
		{
			OOReportWarning(_issues, @"The document contains rendering attributes which will be ignored.");
			_warnedAboutRenderAttribs = YES;
		}
	}
	else if ([keyword isEqual:@"l"] || [keyword isEqual:@"p"])
	{
		if (!_warnedAboutLinesOrPoints)
		{
			OOReportWarning(_issues, @"The document contains point or line data which will be ignored.");
			_warnedAboutLinesOrPoints = YES;
		}
	}
	else
	{
		if (!_warnedAboutUnknown)
		{
			OOReportWarning(_issues, @"The document contains unknown commands such as \"%@\" (line %lu) which will be ignored.", keyword, (unsigned long)[_lexer lineNumber]);
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


@implementation OOOBJVertexCacheKey

- (id) initWithV:(NSInteger)v vn:(NSInteger)vn vt:(NSInteger)vt
{
	if ((self = [super init]))
	{
		_v = v;
		_vn = vn;
		_vt = vt;
	}
	return self;
}


- (BOOL) isEqual:(id)other
{
	NSParameterAssert([other isKindOfClass:[OOOBJVertexCacheKey class]]);
	OOOBJVertexCacheKey *otherKey = other;
	return _v == otherKey->_v && _vn == otherKey->_vn && _vt == otherKey->_vt;
}


- (NSUInteger) hash
{
	return (_v * 1089) ^ (_vn * 33) ^ _vt;
}


- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}

@end

#endif	// OOLITE_LEAN
