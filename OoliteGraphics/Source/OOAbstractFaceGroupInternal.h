/*
	OOAbstractFaceGroupInternal.h
	
	Internal, abstraction-breaking methods.
	
	
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

#import "OOAbstractFaceGroup.h"


// Bitmask of effects a change to an abstract face group or mesh can have.
enum
{
	kOOChangeInvalidatesUniqueness			= 0x0001,	// True if change may de-unique vertices.
	kOOChangeInvalidatesSchema				= 0x0002,	// True if change may affect vertex schema.
	kOOChangeInvalidatesRenderMesh			= 0x0004,	// True if change may affect render mesh or materials.
	kOOChangeInvalidatesBoundingBox			= 0x0008,	// True if change may remove or reposition vertices.
	kOOChangeGuaranteesUniqueness			= 0x0010,
	
	kOOChangeInvalidatesEverything			= kOOChangeInvalidatesUniqueness | kOOChangeInvalidatesSchema | kOOChangeInvalidatesRenderMesh | kOOChangeInvalidatesBoundingBox
};
typedef uint32_t OOAbstractMeshEffectMask;


@interface OOAbstractFaceGroup (Internal)

// Must be called whenever face group is mutated.
- (void) internal_becomeDirtyWithEffects:(OOAbstractMeshEffectMask)effects;

- (void) internal_replaceAllFaces:(NSMutableArray *)faces
					  withEffects:(OOAbstractMeshEffectMask)effects;

@end

#endif


extern NSString * const kOOAbstractFaceGroupEffectMask;
