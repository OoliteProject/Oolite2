/*
	OOGarbageCollectionSupport.h
	
	Oolite does not use garbage collection, because:
	* It wasn’t available in Mac OS X when Oolite was first written.
	* Garbage collection semantics are different between Mac OS X and GNUstep.
	* Converting a large code base to use garbage collection is a pretty big
	  job anyway, and managing code with two different garbage collectors (the
	  Objective-C one and the JavaScript one) sounds like... fun.
	
	However, some Mac-specific tools which share code with Oolite do use
	garbage collection, and the shared code needs to be written to support
	this.
	
	Other than the attributes and functions in this file, the main artefact of
	garbage collection is the -finalize method in some classes. This is the GC
	equivalent of -dealloc, but does less work since most of the work in
	-dealloc is freeing object ivars that are themselves garbage collected.
	
	
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

#import "OOCocoa.h"
#import "OOFunctionAttributes.h"


/*	Memory management attributes for garbage-collected Objective-C. Currently
	only used in Mac-only tools.
*/
#if OOLITE_MAC_OS_X

#define OO_STRONG	__strong
#define OO_WEAK		__weak

/*	Memory allocated with malloc() is not scanned, so it can’t be used for
	arrays of pointers to objects (or other GC memory).
	OOAllocScanned() allocates scanned memory under GC and calls malloc()
	without GC. OOFreeScanned() frees an allocation made with OOAllocScanned().
*/

void *OOAllocScanned(size_t size);

#else
#define OO_STRONG
#define OO_WEAK

OOINLINE void *OOAllocScanned(size_t size) { return malloc(size); }

#endif


#define OOFreeScanned free

OOINLINE id *OOAllocObjectArray(size_t count) { return (id *)OOAllocScanned(count * sizeof (id)); }
