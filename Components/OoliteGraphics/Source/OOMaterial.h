/*

OOMaterial.h

A collection of drawing state that affects the appearance of subsequently-
drawn geometry, comprising a shader program, a set of textures and a set of
uniforms.


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

#import <OoliteBase/OoliteBase.h>

@class OOMaterialSpecification, OORenderMesh, OOShaderProgram, OOTexture;


@interface OOMaterial: NSObject
{
@private
	NSString					*_name;
	
	OOShaderProgram				*_shaderProgram;
	NSMutableDictionary			*_uniforms;
	
	NSUInteger					_textureCount;
	OOTexture					**_textures;
	
	OOWeakReference				*_bindingTarget;
}

- (id)initWithSpecification:(OOMaterialSpecification *)specification
					   mesh:(OORenderMesh *)mesh
					 macros:(NSDictionary *)macros
			  bindingTarget:(id <OOWeakReferenceSupport>)target
			   fileResolver:(id <OOFileResolving>)resolver
			problemReporter:(id <OOProblemReporting>)problemReporter;

- (NSString *) name;

// Make this the current material.
- (void) apply;

/*	Make no material the current material, tearing down anything set up by the
	current material.
*/
+ (void) applyNone;

/*	Get current material.
*/
+ (OOMaterial *) current;

/*	Ensure material is ready to be used in a display list. This is not
	required before using a material directly.
*/
- (void) ensureFinishedLoading;
- (BOOL) isFinishedLoading;

// Only used by shader material, but defined for all materials for convenience.
- (void) setBindingTarget:(id <OOWeakReferenceSupport>)target;

#ifndef NDEBUG
- (NSSet *) allTextures;
#endif

@end
