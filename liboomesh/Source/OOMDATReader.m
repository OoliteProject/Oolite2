#import "OOMDATReader.h"
#import "OOMProblemReportManager.h"
#import "OOMDATLexer.h"
#import "OOMVertex.h"
#import "CollectionUtils.h"
#import "OOCollectionExtractors.h"


static void CleanVector(Vector *v)
{
	/*	Avoid duplicate vertices that differ only in sign of 0. This happens
		quite easily in practice.
	 */
	if (v->x == -0.0f)  v->x = 0.0f;
	if (v->y == -0.0f)  v->y = 0.0f;
	if (v->z == -0.0f)  v->z = 0.0f;
}


typedef struct RawDATTriangle
{
	OOUInteger			vertex[3];
	Vector				position[3];	// Cache of vertex position, the attribute we use most often.
	OOUInteger			smoothGroupID;
	Vector				normal;
	Vector				tangent;
	Vector2D			texCoords[3];	// Texture coordinates are stored separately because a given file vertex may be used for multiple "real" vertices with different texture coordinates.
	NSString			*materialKey;	// Not retained or released - it's assumed the OODATReader will keep references to the texture names as long as they're relevant.
	float				area;			// Actually twice area.
} RawDATTriangle;


/*	VertexFaceRef
	List of indices of faces used by a given vertex.
	Always access using the provided functions.
*/
enum
{
	kVertexFaceDefInternalCount = 7
};

typedef struct VertexFaceRef
{
	uint16_t			internCount;
	uint16_t			internFaces[kVertexFaceDefInternalCount];
	NSMutableArray		*extra;
} VertexFaceRef;


static void VFRAddFace(VertexFaceRef *vfr, OOUInteger index);
static OOUInteger VFRGetCount(VertexFaceRef *vfr);
static OOUInteger VFRGetFaceAtIndex(VertexFaceRef *vfr, OOUInteger index);
static void VFRRelease(VertexFaceRef *vfr);	// N.b. does not zero out the struct.


@interface OOMDATReader (Private)

- (NSString *) priv_uniqueMaterialKey:(NSString *)name;

- (void) priv_reportParseError:(NSString *)format, ...;
- (void) priv_reportBasicParseError:(NSString *)expected;
- (void) priv_reportMallocFailure;

- (BOOL) priv_checkNormalsAndAdjustWindingWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices;
- (BOOL) priv_generateFaceTangentsWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices;
- (BOOL) priv_calculateVertexNormalsAndTangentsWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices faceRefs:(VertexFaceRef *)vfrs;
- (BOOL) priv_calculateVertexTangentsWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices faceRefs:(VertexFaceRef *)vfrs;

/*	Dump a copy of the file. If smoothing is used, explict normals and
	tangents are used. Currently, this does not take smooth groups into account.
*/
- (void) priv_dumpDATWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices;

@end


@implementation OOMDATReader

- (id) initWithPath:(NSString *)path issues:(id <OOMProblemReportManager>)ioIssues
{
	if ((self = [super init]))
	{
		_issues = [ioIssues retain];
		_path = [path copy];
		_brokenSmoothing = YES;
		
		_lexer = [[OOMDATLexer alloc] initWithPath:_path issues:_issues];
		if (_lexer == nil)  DESTROY(self);
	}
	
	return self;
}


- (void) dealloc
{
	DESTROY(_issues);
	DESTROY(_path);
	DESTROY(_lexer);
	DESTROY(_materialKeys);
	
	[super dealloc];
}


- (void) parse
{
	if (_lexer == nil)  return;
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	BOOL						OK = YES;
	OOMVertex					**fileVertices = NULL;
	RawDATTriangle				*rawTriangles = NULL;
	VertexFaceRef				*vfrs = NULL;
	OOUInteger					vIter, fIter;
	NSString					*secName = nil;
	
	// Get vertex count.
	if (OK)
	{
		OK = [_lexer expectLiteral:"NVERTS"] && [_lexer readInteger:&_fileVertexCount];
		if (!OK)  [self priv_reportBasicParseError:@"\"NVERTS\" and vertex count"];
	}
	
	// Get face count.
	if (OK)
	{
		OK = [_lexer expectLiteral:"NFACES"] && [_lexer readInteger:&_fileFaceCount];
		if (!OK)  [self priv_reportBasicParseError:@"\"NFACES\" and face count"];
	}
	
	// Load VERTEX section.
	if (OK)
	{
		OK = [_lexer expectLiteral:"VERTEX"];
		if (!OK)  [self priv_reportBasicParseError:@"\"VERTEX\""];
	}
	if (OK)
	{
		fileVertices = malloc(sizeof *fileVertices * _fileVertexCount);
		vfrs = calloc(sizeof *vfrs, _fileVertexCount);
		if (fileVertices == NULL || vfrs == NULL)
		{
			OK = NO;
			[self priv_reportMallocFailure];
		}
	}
	if (OK)
	{
		for (vIter = 0; vIter < _fileVertexCount; vIter++)
		{
			// VERTEX entry format: <float v.x> <float v.y> <float v.z>
			
			Vector v;
			OK = [_lexer readReal:&v.x] && [_lexer readReal:&v.y] && [_lexer readReal:&v.z];
			if (!OK)
			{
				[self priv_reportBasicParseError:@"number"];
				break;
			}
			CleanVector(&v);
			
			fileVertices[vIter] = [OOMVertex vertexWithPosition:v];
		}
	}
	
	// Load FACES section.
	if (OK)
	{
		OK = [_lexer expectLiteral:"FACES"];
		if (!OK)  [self priv_reportBasicParseError:@"\"FACES\""];
	}
	if (OK)
	{
		rawTriangles = malloc(sizeof *rawTriangles * _fileFaceCount);
		if (rawTriangles == NULL)
		{
			OK = NO;
			[self priv_reportMallocFailure];
		}
	}
	if (OK)
	{
		for (fIter = 0; fIter != _fileFaceCount; fIter++)
		{
			// FACES entry format: <int smoothGroupID> <int unused1> <int unused2> <float n.x> <float n.y> <float n.z> <int vertexCount = 3> <int v0> <int v1> <int v2>
			
			RawDATTriangle *triangle = &rawTriangles[fIter];
			OOUInteger unused, faceVertexCount;
			OK = [_lexer readInteger:&triangle->smoothGroupID] &&
				 [_lexer readInteger:&unused] &&
				 [_lexer readInteger:&unused];
			if (!OK)
			{
				[self priv_reportBasicParseError:@"integer"];
				break;
			}
			
			OK = [_lexer readReal:&triangle->normal.x] &&
				 [_lexer readReal:&triangle->normal.y] &&
				 [_lexer readReal:&triangle->normal.z];
			if (!OK)
			{
				[self priv_reportBasicParseError:@"number"];
				break;
			}
			CleanVector(&triangle->normal);
			
			/*	Oolite (and Dry Dock) attempt to "support" more than three
				vertices for legacy files by only using the first three and
				then skipping the rest. However, this leaves the texture
				coordinates in the TEXTURES section ill-defined. Without a
				real example of such a file, it's not clear how to implement
				this support in a way that would actually be useful.
			*/
			OK = [_lexer readInteger:&faceVertexCount];
			if (!OK || faceVertexCount != 3)
			{
				[self priv_reportBasicParseError:@"3"];
				break;
			}
			
			OK = [_lexer readInteger:&triangle->vertex[0]] &&
				 [_lexer readInteger:&triangle->vertex[1]] &&
				 [_lexer readInteger:&triangle->vertex[2]];
			if (!OK)
			{
				[self priv_reportBasicParseError:@"integer"];
				break;
			}
			
			for (vIter = 0; vIter < 3; vIter++)
			{
				//	Track vertex->face relationships.
				VFRAddFace(&vfrs[triangle->vertex[vIter]], fIter);
				
				//	Cache vertex positions for post-processing.
				triangle->position[vIter] = [fileVertices[triangle->vertex[vIter]] position];
			}
		}
	}
	
	/*	NOTE: we don't check for errors when reading secName, because this
		would lead to failure for files that don't have an END token, which
		we'd rather just warn about.
	*/
	if (OK)  secName = [_lexer nextToken];
	
	// Load TEXTURES section if present.
	if (OK && [secName isEqualToString:@"TEXTURES"])
	{
		for (fIter = 0; fIter < _fileFaceCount; fIter++)
		{
			// TEXTURES entry format: <string materialName> <float scaleS> <float scaleT> (<float s> <float t>)*3
			
			RawDATTriangle *triangle = &rawTriangles[fIter];
			NSString *materialKey = nil;
			OK = [_lexer readString:&materialKey];
			if (!OK)
			{
				[self priv_reportBasicParseError:@"string"];
				break;
			}
			
			triangle->materialKey = [self priv_uniqueMaterialKey:materialKey];
			
			float scaleS, scaleT;
			OK = [_lexer readReal:&scaleS] && [_lexer readReal:&scaleT];
			
			for (vIter = 0; vIter < 3; vIter++)
			{
				float s, t;
				OK = OK && [_lexer readReal:&s] && [_lexer readReal:&t];
				triangle->texCoords[vIter].x = s / scaleS;
				triangle->texCoords[vIter].y = t / scaleT;
			}
			
			if (!OK)
			{
				[self priv_reportBasicParseError:@"number"];
				OK = NO;
				break;
			}
		}
		
		if (OK)  secName = [_lexer nextToken];
	}
	
	// Load NAMES section if present.
	if (OK && [secName isEqualToString:@"NAMES"])
	{
		OOUInteger nIter, nameCount;
		OK = [_lexer readInteger:&nameCount];
		if (!OK)
		{
			[self priv_reportBasicParseError:@"integer after NAMES"];
			OK = NO;
		}
		if (OK)
		{
			NSMutableDictionary *renameDict = [NSMutableDictionary dictionaryWithCapacity:nameCount];
			NSString *key = nil, *realName = nil;
			
			for (nIter = 0; nIter < nameCount; nIter++)
			{
				// NAMES entry format: <newline-terminated-string>
				
				OK = [_lexer readUntilNewline:&realName];
				if (!OK)
				{
					[self priv_reportBasicParseError:@"string"];
					break;
				}
				
				// Key doesn't strictly need uniquing, but it will allow faster comparisons in the rename pass.
				key = [self priv_uniqueMaterialKey:[NSString stringWithFormat:@"%u", nIter]];
				realName = [self priv_uniqueMaterialKey:realName];
				[renameDict setObject:realName forKey:key];
			}
			
			// Do the renaming.
			for (fIter = 0; fIter < _fileFaceCount; fIter++)
			{
				realName = [renameDict objectForKey:rawTriangles[fIter].materialKey];
				if (realName != nil)  rawTriangles[fIter].materialKey = realName;
			}
		}
		
		if (OK)  secName = [_lexer nextToken];
	}
	
	// Load NORMALS section if present.
	if (OK && [secName isEqualToString:@"NORMALS"])
	{
		_explicitNormals = YES;
		
		for (vIter = 0; vIter < _fileVertexCount; vIter++)
		{
			// NORMALS entry format: <float n.x> <float n.y> <float n.z>
			
			Vector normal;
			OK = [_lexer readReal:&normal.x] &&
				 [_lexer readReal:&normal.y] &&
				 [_lexer readReal:&normal.z];
			if (!OK)
			{
				[self priv_reportBasicParseError:@"number"];
				break;
			}
			
			fileVertices[vIter] = [fileVertices[vIter] vertexByAddingAttribute:OOMArrayFromVector(normal)
																		forKey:kOOMNormalAttributeKey];
		}
		
		if (OK)  secName = [_lexer nextToken];
		
		// TANGENTS is only valid after NORMALS.
		if (OK && [secName isEqualToString:@"TANGENTS"])
		{
			_explicitTangents = YES;
			
			for (vIter = 0; vIter < _fileVertexCount; vIter++)
			{
				// TANGENTS entry format: <float t.x> <float t.y> <float t.z>
				
				Vector tangent;
				OK = [_lexer readReal:&tangent.x] &&
					 [_lexer readReal:&tangent.y] &&
					 [_lexer readReal:&tangent.z];
				if (!OK)
				{
					[self priv_reportBasicParseError:@"number"];
					break;
				}
				
				fileVertices[vIter] = [fileVertices[vIter] vertexByAddingAttribute:OOMArrayFromVector(tangent)
																			forKey:kOOMTangentAttributeKey];
			}
			
			if (OK)  secName = [_lexer nextToken];
		}
	}
	
	//	Check for END.
	if (OK)
	{
		if (![secName isEqualToString:@"END"])
		{
			if (secName == nil)
			{
				OOMReportWarning(_issues, @"missingEnd", @"The document is missing an END line. This may indicate that the file is damaged.");
			}
			else
			{
				OOMReportWarning(_issues, @"missingEnd", @"The document continues beyond where it was expected to end (expected \"END\", found \"%@\"). It may be of a newer format, and important information may be missed.", secName);
			}
		}
	}
	
	
	//	Post-processing.
	//	TODO: cache vertex positions in faces for speed.
	if (OK && !_explicitNormals)
	{
		OK = [self priv_checkNormalsAndAdjustWindingWithTriangles:rawTriangles vertices:fileVertices];
	}
	if (OK && !_explicitTangents)
	{
		OK = [self priv_generateFaceTangentsWithTriangles:rawTriangles vertices:fileVertices];
	}
	if (OK && !_explicitNormals && _smoothing)
	{
		//	Vertex smoothing.
		OK = [self priv_calculateVertexNormalsAndTangentsWithTriangles:rawTriangles vertices:fileVertices faceRefs:vfrs];
	}
	else
	{
		//	Only YES after parsing if actually used, see header.
		_brokenSmoothing = NO;
		if (OK && _explicitNormals && !_explicitTangents)
		{
			OK = [self priv_calculateVertexTangentsWithTriangles:rawTriangles vertices:fileVertices faceRefs:vfrs];
		}
	}
	
	if (OK)  [self priv_dumpDATWithTriangles:rawTriangles vertices:fileVertices];
	
	
	for (vIter = 0; vIter < _fileVertexCount; vIter++)
	{
		VFRRelease(&vfrs[vIter]);
	}
	
	DESTROY(_lexer);
	DESTROY(_materialKeys);
	free(fileVertices);
	free(rawTriangles);
	[pool drain];
}


- (BOOL) smoothing
{
	return _smoothing;
}


- (void) setSmoothing:(BOOL)value
{
	if (_lexer != nil)
	{
		_smoothing = !!value;
	}
}


- (BOOL) brokenSmoothing
{
	return _brokenSmoothing;
}


- (void) setBrokenSmoothing:(BOOL)value
{
	if (_lexer != nil)
	{
		_brokenSmoothing = !!value;
	}
}


- (OOUInteger) fileVertexCount
{
	[self parse];
	return _fileVertexCount;
}


- (OOUInteger) fileFaceCount
{
	[self parse];
	return _fileFaceCount;
}

@end


@implementation OOMDATReader (Private)

- (NSString *) priv_uniqueMaterialKey:(NSString *)name
{
	NSString *result = [_materialKeys member:name];
	if (result == nil)
	{
		if (_materialKeys == nil)  _materialKeys = [NSMutableSet new];
		[_materialKeys addObject:name];
		result = name;
	}
	return result;
}


- (void) priv_reportParseError:(NSString *)format, ...
{
	NSString *base = OOMLocalizeProblemString(_issues, @"Parse error on line %u of %@: %@.");
	format = OOMLocalizeProblemString(_issues, format);
	
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	
	message = [NSString stringWithFormat:base, [_lexer lineNumber], [_path lastPathComponent], message];
	[_issues addProblemOfType:kOOMProblemTypeError key:@"parseError" message:message];
}


- (void) priv_reportBasicParseError:(NSString *)expected
{
	[self priv_reportParseError:@"expected %@, got %@", expected, [_lexer currentTokenString]];
}


- (void) priv_reportMallocFailure
{
	OOMReportError(_issues, @"allocFailed", @"Not enough memory to read %@.", [_path lastPathComponent]);
}


//	NOTE: these methods exactly duplicates Oolite 1.x behaviour, including bugs and slowness.

- (BOOL) priv_checkNormalsAndAdjustWindingWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices
{
	for (OOUInteger fIter = 0; fIter < _fileFaceCount; fIter++)
	{
		RawDATTriangle *triangle = &triangles[fIter];
		Vector v0 = triangle->position[0];
		Vector v1 = triangle->position[1];
		Vector v2 = triangle->position[2];
		Vector normal = triangle->normal;
		
		Vector calculatedNormal = normal_to_surface(v2, v1, v0);
		if (vector_equal(normal, kZeroVector))
		{
			/*	If the existing normal is 0, we want to choose between the
				better of calculatedNormal and -calculatedNormal.
			*/
			normal = vector_flip(calculatedNormal);
			triangle->normal = normal;
		}
		
		/*	This calculation is broken. It should be:
				if (dot_product(normal, calculatedNormal) < 0.0f)
			But see above regarding bugwards-compatibility.
		*/
		if (normal.x * calculatedNormal.x < 0 || normal.y * calculatedNormal.y < 0 || normal.z * calculatedNormal.z < 0)
		{
			//	normal lies in the WRONG direction!
			//	reverse the winding.
			OOUInteger vi0 = triangle->vertex[0];
			triangle->vertex[0] = triangle->vertex[2];
			triangle->vertex[2] = vi0;
			
			//	Don't forget texture coordinates.
			Vector2D t0 = triangle->texCoords[0];
			triangle->texCoords[0] = triangle->texCoords[2];
			triangle->texCoords[2] = t0;
		}
	}
	
	return YES;
}


- (BOOL) priv_generateFaceTangentsWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices
{
	for (OOUInteger fIter = 0; fIter < _fileFaceCount; fIter++)
	{
		RawDATTriangle *triangle = &triangles[fIter];
		
		/*	Generate tangents, i.e. vectors that run in the direction of the s
			texture coordinate. Based on code I found in a forum somewhere and
			then lost track of. Sorry to whomever I should be crediting.
			-- Ahruman 2008-11-23
		*/
		Vector v0 = triangle->position[0];
		Vector v1 = triangle->position[1];
		Vector v2 = triangle->position[2];
		
		Vector vAB = vector_subtract(v1, v0);
		Vector vAC = vector_subtract(v2, v0);
		Vector nA = triangle->normal;
		
		//	projAB = vAB - (nA · vAB) * nA
		Vector vProjAB = vector_subtract(vAB, vector_multiply_scalar(nA, dot_product(nA, vAB)));
		Vector vProjAC = vector_subtract(vAC, vector_multiply_scalar(nA, dot_product(nA, vAC)));
		
		//	delta s/t
		float dsAB = triangle->texCoords[1].x - triangle->texCoords[0].x;
		float dsAC = triangle->texCoords[2].x - triangle->texCoords[0].x;
		float dtAB = triangle->texCoords[1].y - triangle->texCoords[0].y;
		float dtAC = triangle->texCoords[2].y - triangle->texCoords[0].y;
		
		if (dsAC * dtAB > dsAB * dtAC)
		{
			dsAB = -dsAB;
			dsAC = -dsAC;
		}
		
		Vector tangent = vector_subtract(vector_multiply_scalar(vProjAB, dsAC), vector_multiply_scalar(vProjAC, dsAB));
		//	Rotate 90 degrees. Done this way because I'm too lazy to grok the code above.
		triangle->tangent = cross_product(nA, tangent);
	}
	
	return YES;
}


- (void) priv_calculateBrokenTriangleAreasWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices
{
	for (OOUInteger fIter = 0; fIter < _fileFaceCount; fIter++)
	{
		RawDATTriangle *triangle = &triangles[fIter];
		
		Vector v0 = triangle->position[0];
		Vector v1 = triangle->position[1];
		Vector v2 = triangle->position[2];
		
		/*	This is supposed to calculate areas using Heron's formula, but doesn't.
			(The *0.25 is supposed to be outside the sqrt.) Bugwards-compatibility
			is in effect.
		*/
		float a2 = distance2(v0, v1);
		float b2 = distance2(v1, v2);
		float c2 = distance2(v2, v0);
		triangle->area = sqrtf(2.0 * (a2 * b2 + b2 * c2 + c2 * a2) - 0.25 * (a2 * a2 + b2 * b2 +c2 * c2));
	}
}


- (void) priv_calculateCorrectTriangleAreasWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices
{
	for (OOUInteger fIter = 0; fIter < _fileFaceCount; fIter++)
	{
		RawDATTriangle *triangle = &triangles[fIter];
		
		/*	Calculate area of triangle.
			The magnitude of the cross product of two vectors is the area of
			the parallelogram they span. The area of a triangle is half the
			area of a parallelogram sharing two of its sides.
			Since we only use the area of the triangle as a weight factor,
			constant terms are irrelevant, so we don't bother halving the
			value.
		*/
		Vector AB = vector_subtract(triangle->position[1], triangle->position[0]);
		Vector AC = vector_subtract(triangle->position[2], triangle->position[0]);
		triangle->area = magnitude(true_cross_product(AB, AC));
	}
}


- (BOOL) priv_calculateVertexNormalsAndTangentsWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices faceRefs:(VertexFaceRef *)vfrs
{
	if (_brokenSmoothing)
	{
		[self priv_calculateBrokenTriangleAreasWithTriangles:triangles vertices:vertices];
	}
	else
	{
		[self priv_calculateCorrectTriangleAreasWithTriangles:triangles vertices:vertices];
	}

	
	for (OOUInteger vIter = 0; vIter < _fileVertexCount; vIter++)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		Vector normalSum = kZeroVector;
		Vector tangentSum = kZeroVector;
		
		VertexFaceRef *vfr = &vfrs[vIter];
		OOUInteger fIter, fCount = VFRGetCount(vfr);
		for (fIter = 0; fIter < fCount; fIter++)
		{
			RawDATTriangle *triangle = &triangles[VFRGetFaceAtIndex(vfr, fIter)];
			
			normalSum = vector_add(normalSum, vector_multiply_scalar(triangle->normal, triangle->area));
			tangentSum = vector_add(tangentSum, vector_multiply_scalar(triangle->tangent, triangle->area));
		}
		
		normalSum = vector_normal_or_fallback(normalSum, kBasisZVector);
		tangentSum = vector_normal_or_fallback(tangentSum, kBasisXVector);
		NSDictionary *attrs = $dict(kOOMNormalAttributeKey, OOMArrayFromVector(normalSum), kOOMTangentAttributeKey, OOMArrayFromVector(tangentSum));
		vertices[vIter] = [[vertices[vIter] vertexByAddingAttributes:attrs] retain];
		
		[pool drain];
		[vertices[vIter] autorelease];	// Needs to be autoreleased in outer pool.
	}
	
	return YES;
}


/*	This is conceptually broken.
	At the moment, it's calculating one tangent per "input" vertex. It should
	be calculating one tangent per "real" vertex, where a "real" vertex is
	defined as a combination of position, normal, material and texture
	coordinates.
	Currently, we don't have a format with unique "real" vertices.
	This basically means explicit-normal models without explicit tangents
	can't usefully be normal mapped.
*/
- (BOOL) priv_calculateVertexTangentsWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices faceRefs:(VertexFaceRef *)vfrs
{
	//	Oolite gets area calculation right in this case.
	[self priv_calculateCorrectTriangleAreasWithTriangles:triangles vertices:vertices];
	
	for (OOUInteger vIter = 0; vIter < _fileVertexCount; vIter++)
	{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		Vector tangentSum = kZeroVector;
		
		VertexFaceRef *vfr = &vfrs[vIter];
		OOUInteger fIter, fCount = VFRGetCount(vfr);
		for (fIter = 0; fIter < fCount; fIter++)
		{
			RawDATTriangle *triangle = &triangles[VFRGetFaceAtIndex(vfr, fIter)];
			
			tangentSum = vector_add(tangentSum, vector_multiply_scalar(triangle->tangent, triangle->area));
		}
		
		tangentSum = vector_normal_or_fallback(tangentSum, kBasisXVector);
		vertices[vIter] = [[vertices[vIter] vertexByAddingAttribute:OOMArrayFromVector(tangentSum) forKey:kOOMTangentAttributeKey] retain];
		
		[pool drain];
		[vertices[vIter] autorelease];	// Needs to be autoreleased in outer pool.
	}
	
	return YES;
}


- (void) priv_dumpDATWithTriangles:(RawDATTriangle *)triangles vertices:(OOMVertex **)vertices
{
	NSString *path = [[_path stringByDeletingPathExtension] stringByAppendingString:@"_debugdump.dat"];
	FILE *file = fopen([path UTF8String], "w");
	if (file == NULL)
	{
		OOMReportInfo(_issues, @"writeFailed", @"Could not open debug dump file %@", path);
		return;
	}
	
	fprintf(file, "// Debug dump of %s\n\nNVERTS %lu\nNFACES %lu\n\n\nVERTEX\n", [[_path lastPathComponent] UTF8String], (unsigned long)_fileVertexCount, (unsigned long)_fileFaceCount);
	
	for (OOUInteger vIter = 0; vIter < _fileVertexCount; vIter++)
	{
		Vector pos = [vertices[vIter] position];
		fprintf(file, "%g %g %g\n", pos.x, pos.y, pos.z);
	}
	
	BOOL explicitNormals = _explicitNormals || _smoothing;
	
	fprintf(file, "\n\nFACES\n");
	for (OOUInteger fIter = 0; fIter < _fileFaceCount; fIter++)
	{
		RawDATTriangle *triangle = &triangles[fIter];
		Vector normal = explicitNormals ? kZeroVector : triangle->normal;
		OOUInteger smoothGroup = explicitNormals ? 0 : triangle->smoothGroupID;
		fprintf(file, "%lu 0 0 %g %g %g 3 %lu %lu %lu\n", (unsigned long)smoothGroup, normal.x, normal.y, normal.z, (unsigned long)triangle->vertex[0], (unsigned long)triangle->vertex[1], (unsigned long)triangle->vertex[2]);
	}
	
	if (triangles[0].materialKey != nil)
	{
		fprintf(file, "\n\nTEXTURES\n");
		for (OOUInteger fIter = 0; fIter < _fileFaceCount; fIter++)
		{
			RawDATTriangle *triangle = &triangles[fIter];
			fprintf(file, "%s 1 1 %g %g %g %g %g %g\n", [triangle->materialKey UTF8String],
					triangle->texCoords[0].x, triangle->texCoords[0].y,
					triangle->texCoords[1].x, triangle->texCoords[1].y,
					triangle->texCoords[2].x, triangle->texCoords[2].y);
			
		}
	}
	
	if (explicitNormals)
	{
		fprintf(file, "\n\nNORMALS\n");
		for (OOUInteger vIter = 0; vIter < _fileVertexCount; vIter++)
		{
			Vector normal = [vertices[vIter] normal];
			fprintf(file, "%g %g %g\n", normal.x, normal.y, normal.z);
		}
		
		fprintf(file, "\n\nTANGENTS\n");
		for (OOUInteger vIter = 0; vIter < _fileVertexCount; vIter++)
		{
			Vector tangent = [vertices[vIter] tangent];
			fprintf(file, "%g %g %g\n", tangent.x, tangent.y, tangent.z);
		}
	}
	
	fprintf(file, "\nEND\n");
}

@end


static void VFRAddFace(VertexFaceRef *vfr, OOUInteger index)
{
	NSCParameterAssert(vfr != NULL);
	
	if (index < UINT16_MAX && vfr->internCount < kVertexFaceDefInternalCount)
	{
		vfr->internFaces[vfr->internCount++] = index;
	}
	else
	{
		if (vfr->extra == nil)  vfr->extra = [[NSMutableArray alloc] init];
		[vfr->extra addObject:$int(index)];
	}
}


static OOUInteger VFRGetCount(VertexFaceRef *vfr)
{
	NSCParameterAssert(vfr != NULL);
	
	return vfr->internCount + [vfr->extra count];
}


static OOUInteger VFRGetFaceAtIndex(VertexFaceRef *vfr, OOUInteger index)
{
	NSCParameterAssert(vfr != NULL && index < VFRGetCount(vfr));
	
	if (index < vfr->internCount)  return vfr->internFaces[index];
	else  return [vfr->extra oo_unsignedIntegerAtIndex:index - vfr->internCount];
}


static void VFRRelease(VertexFaceRef *vfr)
{
	NSCParameterAssert(vfr != NULL);
	
	[vfr->extra release];
}
