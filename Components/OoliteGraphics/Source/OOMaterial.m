/*

OOMaterial.m


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


#import "OOMaterial.h"
#import "OOMaterialSpecification.h"
#import "OODefaultShaderSynthesizer.h"

#import "OOOpenGL.h"
#import "OOMacroOpenGL.h"
#import "OOOpenGLUtilities.h"

#import "OOGraphicsContextInternal.h"
#import "OOShaderProgram.h"
#import "OOShaderUniform.h"
#import "OOTexture.h"
#import "OORenderMesh.h"


static NSString *MacrosToString(NSDictionary *macros);


@interface OOMaterial (OOPrivate)

- (BOOL) doApply;
- (void) unapplyWithNext:(OOMaterial *)next;

-(void) addUniformsFromDictionary:(NSDictionary *)uniformDefs withBindingTarget:(id<OOWeakReferenceSupport>)target;

@end


@implementation OOMaterial


- (id)initWithSpecification:(OOMaterialSpecification *)specification
					   mesh:(OORenderMesh *)mesh
					 macros:(NSDictionary *)macros
			  bindingTarget:(id <OOWeakReferenceSupport>)target
			   fileResolver:(id <OOFileResolving>)resolver
			problemReporter:(id <OOProblemReporting>)problemReporter
{
	NSParameterAssert(specification != nil && mesh != nil);
	
	OOGraphicsContext		*context = OOCurrentGraphicsContext();
	NSAssert(context != nil, @"Can't create material with no graphics context.");
#ifndef NDEBUG
	_context = [context retain];
#endif
	
	BOOL					OK = YES;
	NSString				*macroString = nil;
	GLint					textureUnits = [context textureImageUnitCount];
	NSMutableDictionary		*modifiedMacros = nil;
	
	self = [super init];
	if (self == nil)  return NO;
	
	if (OK)
	{
		// Set up name.
		_name = [[specification materialKey] retain];
	}
	
	if (OK)
	{
		// Set up macros.
		modifiedMacros = macros ? [macros mutableCopy] : [[NSMutableDictionary alloc] init];
		[modifiedMacros autorelease];
		
		[modifiedMacros setObject:[NSNumber numberWithUnsignedInt:textureUnits]
						   forKey:@"OO_TEXTURE_UNIT_COUNT"];
		
		macroString = MacrosToString(modifiedMacros);
	}
	
	// Synthesize material. FIXME: support custom shaders.
	NSString *vertexShader = nil, *fragmentShader = nil;
	NSArray *textures = nil;
	NSDictionary *uniformSpecs = nil;
	OOSynthesizeMaterialShader(specification, mesh, &vertexShader, &fragmentShader, &textures, &uniformSpecs, nil);
	
	OOLog(@"materials.synthesize.dump", @"Sythesized shaders for material \"%@\" of mesh \"%@\":\n// Vertex shader:\n%@\n\n// Fragment shader:\n%@\n\n// Uniforms:\n%@", [specification materialKey], [mesh name], vertexShader, fragmentShader, uniformSpecs);
	
	NSDictionary *attributeBindings = [mesh prefixedAttributeIndices];
	
	if (OK)
	{
		_shaderProgram = [OOShaderProgram shaderProgramWithVertexShader:vertexShader
														 fragmentShader:fragmentShader
													   vertexShaderName:@".synthesized.vs"
													 fragmentShaderName:@".synthesized.fs"
																 prefix:macroString
													  attributeBindings:attributeBindings];
		OK = (_shaderProgram != nil);
		[_shaderProgram retain];
	}
	
	NSUInteger textureIter, textureCount = [textures count];
	if (OK && textureCount > 0)
	{
		_textureCount = textureCount;
		_textures = OOAllocObjectArray(textureCount);
		if (_textures == NULL)  OK = NO;
		
		if (OK)
		{
			for (textureIter = 0; textureIter < textureCount; textureIter++)
			{
				OOTextureSpecification *spec = [textures objectAtIndex:textureIter];
				_textures[textureIter] = [[OOTexture textureWithSpecification:spec
																 fileResolver:resolver
															  problemReporter:problemReporter] retain];
				
				if (_textures[textureIter] == nil)
				{
					OK = NO;
					_textureCount = textureIter;	// For safe cleanup.
					break;
				}
			}
		}
	}
	
	// FIXME: uniforms.
	
	if (!OK)  DESTROY(self);
	return self;
}


- (void) dealloc
{
#ifndef NDEBUG
	OOAssertGraphicsContext(_context);
	
	if ([OOCurrentGraphicsContext() currentMaterial] == self)
	{
		OOLogERR(@"material.dealloc.imbalance", @"Material deallocated while active, indicating a retain/release imbalance.");
		[[self class] applyNone];
	}
	
	DESTROY(_context);
#endif
	
	DESTROY(_name);
	DESTROY(_shaderProgram);
	DESTROY(_uniforms);
	
	if (_textures != NULL)
	{
		for (NSUInteger i = 0; i != _textureCount; ++i)
		{
			[_textures[i] release];
		}
		free(_textures);
		_textures = NULL;
	}
	
	[super dealloc];
}


+ (OOMaterial *) fallbackMaterialWithName:(NSString *)name forMesh:(OORenderMesh *)mesh
{
	OOMaterialSpecification *spec = [[[OOMaterialSpecification alloc] initWithMaterialKey:name ?: @"<anonymous>"] autorelease];
	
	[spec setDiffuseColor:[OOColor colorWithRed:1 green:0 blue:0 alpha:1]];
	
	return [[[OOMaterial alloc] initWithSpecification:spec
												 mesh:mesh
											   macros:nil
										bindingTarget:nil
										 fileResolver:nil
									  problemReporter:nil] autorelease];
}


- (NSString *)descriptionComponents
{
	return [NSString stringWithFormat:@"\"%@\"", [self name]];
}


- (NSString *)name
{
	return _name;
}


- (void) apply
{
	OOAssertGraphicsContext(_context);
	
	OOGraphicsContext *context = OOCurrentGraphicsContext();
	OOMaterial *current = [context currentMaterial];
	if (current != self)
	{
		[current unapplyWithNext:self];
		if ([self doApply])
		{
			[context setCurrentMaterial:self];
		}
		else
		{
			[context setCurrentMaterial:nil];
		}
	}
}


+ (void) applyNone
{
	OOGraphicsContext *context = OOCurrentGraphicsContext();
	[[context currentMaterial] unapplyWithNext:nil];
	[context setCurrentMaterial:nil];
	[OOShaderProgram applyNone];
}


- (BOOL) doApply
{
	OOAssertGraphicsContext(_context);
	
	[_shaderProgram apply];
	
	if (_textures != NULL)
	{
		OO_ENTER_OPENGL();
		for (NSUInteger i = 0; i != _textureCount; ++i)
		{
			OOGL(glActiveTexture(GL_TEXTURE0 + i));
			[_textures[i] apply];
		}
		if (_textureCount > 1)  OOGL(glActiveTexture(GL_TEXTURE0));
	}
	
	@try
	{
		id key = nil;
		foreachkey (key, _uniforms)
		{
			OOShaderUniform *uniform = [_uniforms objectForKey:key];
			[uniform apply];
		}
	}
	@catch (...)
	{
		// Supress exceptions during application of bound uniforms.
	}
	
	return YES;
}


- (void)unapplyWithNext:(OOMaterial *)next
{
	OOAssertGraphicsContext(_context);
	
	// Probably not needed now with all materials being shader materials.
}


+ (OOMaterial *) current
{
	return [[[OOCurrentGraphicsContext() currentMaterial] retain] autorelease];
}


- (void) ensureFinishedLoading
{
	if (_textures != NULL)
	{
		for (NSUInteger i = 0; i != _textureCount; ++i)
		{
			[_textures[i] ensureFinishedLoading];
		}
	}
}


- (BOOL) isFinishedLoading
{
	if (_textures != NULL)
	{
		for (NSUInteger i = 0; i != _textureCount; ++i)
		{
			if (![_textures[i] isFinishedLoading])  return NO;
		}
	}
	
	return YES;
}


- (void) setBindingTarget:(id <OOWeakReferenceSupport>)target
{
	[[_uniforms allValues] makeObjectsPerformSelector:@selector(setBindingTarget:) withObject:target];
	[_bindingTarget release];
	_bindingTarget = [target weakRetain];
}


#ifndef NDEBUG
- (NSSet *) allTextures
{
	return [NSSet setWithObjects:_textures count:_textureCount];
}
#endif


- (BOOL)bindUniform:(NSString *)uniformName
		   toObject:(id<OOWeakReferenceSupport>)source
		   property:(SEL)selector
	 convertOptions:(OOUniformConvertOptions)options
{
	OOShaderUniform			*uniform = nil;
	
	if (uniformName == nil) return NO;
	
	uniform = [[OOShaderUniform alloc] initWithName:uniformName
									  shaderProgram:_shaderProgram
									  boundToObject:source
										   property:selector
									 convertOptions:options];
	if (uniform != nil)
	{
		[_uniforms setObject:uniform forKey:uniformName];
		[uniform release];
		return YES;
	}
	else
	{
		[_uniforms removeObjectForKey:uniformName];
		return NO;
	}
}


OOINLINE BOOL UniformBindingPermitted(NSString *property, SEL selector, id <OOWeakReferenceSupport> target)
{
	if (property == nil || selector == NULL || target == nil)  return NO;
	if (![target respondsToSelector:selector])  return NO;
	if (![target respondsToSelector:@selector(allowBindingMethodAsShaderUniform:)])  return NO;
	if (![(id)target allowBindingMethodAsShaderUniform:property])  return NO;
	
	return YES;
}


- (BOOL) bindSafeUniform:(NSString *)uniformName
				toObject:(id <OOWeakReferenceSupport>)target
		   propertyNamed:(NSString *)property
		  convertOptions:(OOUniformConvertOptions)options
{
	SEL selector = NSSelectorFromString(property);
	if (UniformBindingPermitted(property, selector, target))
	{
		return [self bindUniform:uniformName
						toObject:target
						property:selector
				  convertOptions:options];
	}
	else
	{
		OOLog(@"shader.uniform.unpermittedMethod", @"Did not bind uniform \"%@\" to property -[%@ %@] - unpermitted method.", uniformName, [target class], property);
	}
	
	return NO;
}


- (void) setUniform:(NSString *)uniformName intValue:(int)value
{
	OOShaderUniform			*uniform = nil;
	
	if (uniformName == nil) return;
	
	uniform = [[OOShaderUniform alloc] initWithName:uniformName
									  shaderProgram:_shaderProgram
										   intValue:value];
	if (uniform != nil)
	{
		[_uniforms setObject:uniform forKey:uniformName];
		[uniform release];
	}
	else
	{
		[_uniforms removeObjectForKey:uniformName];
	}
}


- (void) setUniform:(NSString *)uniformName floatValue:(float)value
{
	OOShaderUniform			*uniform = nil;
	
	if (uniformName == nil) return;
	
	uniform = [[OOShaderUniform alloc] initWithName:uniformName
									  shaderProgram:_shaderProgram
										 floatValue:value];
	if (uniform != nil)
	{
		[_uniforms setObject:uniform forKey:uniformName];
		[uniform release];
	}
	else
	{
		[_uniforms removeObjectForKey:uniformName];
	}
}


- (void) setUniform:(NSString *)uniformName vectorValue:(Vector)value
{
	OOShaderUniform			*uniform = nil;
	
	if (uniformName == nil) return;
	
	uniform = [[OOShaderUniform alloc] initWithName:uniformName
									  shaderProgram:_shaderProgram
										vectorValue:value];
	if (uniform != nil)
	{
		[_uniforms setObject:uniform forKey:uniformName];
		[uniform release];
	}
	else
	{
		[_uniforms removeObjectForKey:uniformName];
	}
}


- (void) setUniform:(NSString *)uniformName quaternionValue:(Quaternion)value asMatrix:(BOOL)asMatrix
{
	OOShaderUniform			*uniform = nil;
	
	if (uniformName == nil) return;
	
	uniform = [[OOShaderUniform alloc] initWithName:uniformName
									  shaderProgram:_shaderProgram
									quaternionValue:value
										   asMatrix:asMatrix];
	if (uniform != nil)
	{
		[_uniforms setObject:uniform forKey:uniformName];
		[uniform release];
	}
	else
	{
		[_uniforms removeObjectForKey:uniformName];
	}
}


-(void) addUniformsFromDictionary:(NSDictionary *)uniformDefs withBindingTarget:(id<OOWeakReferenceSupport>)target
{
	NSEnumerator			*uniformEnum = nil;
	NSString				*name = nil;
	id						definition = nil;
	id						value = nil;
	NSString				*binding = nil;
	NSString				*type = nil;
	GLfloat					floatValue;
	BOOL					gotValue;
	OOUniformConvertOptions	convertOptions;
	BOOL					quatAsMatrix = YES;
	GLfloat					scale = 1.0;
	unsigned				randomSeed;
	RANROTSeed				savedSeed;
	NSArray					*keys = nil;
	
	if ([target respondsToSelector:@selector(randomSeedForShaders)])
	{
		randomSeed = [(id)target randomSeedForShaders];
	}
	else
	{
		randomSeed = (unsigned int)(uintptr_t)self;
	}
	savedSeed = RANROTGetFullSeed();
	ranrot_srand(randomSeed);
	
	keys = [[uniformDefs allKeys] sortedArrayUsingSelector:@selector(compare:)];
	for (uniformEnum = [keys objectEnumerator]; (name = [uniformEnum nextObject]); )
	{
		gotValue = NO;
		definition = [uniformDefs objectForKey:name];
		
		type = nil;
		value = nil;
		binding = nil;
		
		if ([definition isKindOfClass:[NSDictionary class]])
		{
			value = [(NSDictionary *)definition objectForKey:@"value"];
			binding = [(NSDictionary *)definition oo_stringForKey:@"binding"];
			type = [(NSDictionary *)definition oo_stringForKey:@"type"];
			scale = [(NSDictionary *)definition oo_floatForKey:@"scale" defaultValue:1.0];
			if (type == nil)
			{
				if (value == nil && binding != nil)  type = @"binding";
				else  type = @"float";
			}
		}
		else if ([definition isKindOfClass:[NSNumber class]])
		{
			value = definition;
			type = @"float";
		}
		else if ([definition isKindOfClass:[NSString class]])
		{
			if (OOIsNumberLiteral(definition, NO))
			{
				value = definition;
				type = @"float";
			}
			else
			{
				binding = definition;
				type = @"binding";
			}
		}
		else if ([definition isKindOfClass:[NSArray class]])
		{
			binding = definition;
			type = @"vector";
		}
		
		// Transform random values to concrete values
		if ([type isEqualToString:@"randomFloat"])
		{
			type = @"float";
			value = [NSNumber numberWithFloat:randf() * scale];
		}
		else if ([type isEqualToString:@"randomUnitVector"])
		{
			type = @"vector";
			value = OOPropertyListFromVector(vector_multiply_scalar(OORandomUnitVector(), scale));
		}
		else if ([type isEqualToString:@"randomVectorSpatial"])
		{
			type = @"vector";
			value = OOPropertyListFromVector(OOVectorRandomSpatial(scale));
		}
		else if ([type isEqualToString:@"randomVectorRadial"])
		{
			type = @"vector";
			value = OOPropertyListFromVector(OOVectorRandomRadial(scale));
		}
		else if ([type isEqualToString:@"randomQuaternion"])
		{
			type = @"quaternion";
			value = OOPropertyListFromQuaternion(OORandomQuaternion());
		}
		
		if ([type isEqualToString:@"float"] || [type isEqualToString:@"real"])
		{
			gotValue = YES;
			if ([value respondsToSelector:@selector(floatValue)])  floatValue = [value floatValue];
			else if ([value respondsToSelector:@selector(doubleValue)])  floatValue = [value doubleValue];
			else if ([value respondsToSelector:@selector(intValue)])  floatValue = [value intValue];
			else gotValue = NO;
			
			if (gotValue)
			{
				[self setUniform:name floatValue:floatValue];
			}
		}
		else if ([type isEqualToString:@"int"] || [type isEqualToString:@"integer"] || [type isEqualToString:@"texture"])
		{
			/*	"texture" is allowed as a synonym for "int" because shader
				uniforms are mapped to texture units by specifying an integer
				index.
				uniforms = { diffuseMap = { type = texture; value = 0; }; };
				means "bind uniform diffuseMap to texture unit 0" (which will
				have the first texture in the textures array).
			*/
			if ([value respondsToSelector:@selector(intValue)])
			{
				[self setUniform:name intValue:[value intValue]];
				gotValue = YES;
			}
		}
		else if ([type isEqualToString:@"vector"])
		{
			[self setUniform:name vectorValue:OOVectorFromObject(value, kZeroVector)];
			gotValue = YES;
		}
		else if ([type isEqualToString:@"quaternion"])
		{
			if ([definition isKindOfClass:[NSDictionary class]])
			{
				quatAsMatrix = [definition oo_boolForKey:@"asMatrix" defaultValue:quatAsMatrix];
			}
			[self setUniform:name
			 quaternionValue:OOQuaternionFromObject(value, kIdentityQuaternion)
					asMatrix:quatAsMatrix];
			gotValue = YES;
		}
		else if (target != nil && [type isEqualToString:@"binding"])
		{
			if ([definition isKindOfClass:[NSDictionary class]])
			{
				convertOptions = 0;
				if ([definition oo_boolForKey:@"clamped" defaultValue:NO])  convertOptions |= kOOUniformConvertClamp;
				if ([definition oo_boolForKey:@"normalized" defaultValue:[definition oo_boolForKey:@"normalised" defaultValue:NO]])
				{
					convertOptions |= kOOUniformConvertNormalize;
				}
				if ([definition oo_boolForKey:@"asMatrix" defaultValue:YES])  convertOptions |= kOOUniformConvertToMatrix;
				if (![definition oo_boolForKey:@"bindToSubentity" defaultValue:NO])  convertOptions |= kOOUniformBindToSuperTarget;
			}
			else
			{
				convertOptions = kOOUniformConvertDefaults;
			}
			
			[self bindSafeUniform:name toObject:target propertyNamed:binding convertOptions:convertOptions];
			gotValue = YES;
		}
		
		if (!gotValue)
		{
			OOLog(@"shader.uniform.badDescription", @"----- Warning: could not bind uniform \"%@\" for target %@ -- could not interpret definition:\n%@", name, target, definition);
		}
	}
	
	RANROTSetFullSeed(savedSeed);
}

@end


static NSString *MacrosToString(NSDictionary *macros)
{
	if (macros == nil)  return nil;
	
	NSMutableString *result = [NSMutableString string];
	id key = nil;
	foreachkey(key, macros)
	{
		if (![key isKindOfClass:[NSString class]]) continue;
		id value = [macros objectForKey:key];
		
		[result appendFormat:@"#define %@  %@\n", key, value];
	}
	
	if ([result length] == 0) return nil;
	[result appendString:@"\n\n"];
	return result;
}
