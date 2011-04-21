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
#import "OOTexture.h"
#import "OORenderMesh.h"


static NSString *MacrosToString(NSDictionary *macros);


@interface OOMaterial (OOPrivate)

- (BOOL) doApply;
- (void) unapplyWithNext:(OOMaterial *)next;

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
	OOSynthesizeMaterialShader(specification, mesh, &vertexShader, &fragmentShader, nil);
	
	OOLog(@"materials.synthesize.dump", @"Sythesized shaders for material \"%@\" of mesh \"%@\":\n// Vertex shader:\n%@\n\n// Fragment shader:\n%@", [specification materialKey], [mesh name], vertexShader, fragmentShader);
	
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
	
	// FIXME: uniforms and textures.
	
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
		if (_textureCount > 1)  OOGL(glActiveTexture(0));
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
