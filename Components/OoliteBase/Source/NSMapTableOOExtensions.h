/*
	For Mac OS X 10.5 and later, NSIntMapKeyCallBacks and NSIntMapValueCallBacks
	are deprecated in favour of NSIntegerMapKeyCallBacks and
	NSIntegerMapValueCallBacks, as part of the general NSInteger reform for
	64-bit. However, the documented semantics are 64-bit safe.
	
	GNUstep-base (as of 1.20.1) does not define the new names, so these macros
	use the recommended form for Mac OS X and the available form for GNUstep.
*/


#import "OOCocoa.h"


#if OOLITE_MAC_OS_X
#define OOIntegerMapKeyCallBacks	NSIntegerMapKeyCallBacks
#define OOIntegerMapValueCallBacks	NSIntegerMapValueCallBacks
#define OONotAnIntegerMapKey		NSNotAnIntegerMapKey
#else
#define OOIntegerMapKeyCallBacks	NSIntMapKeyCallBacks
#define OOIntegerMapValueCallBacks	NSIntMapValueCallBacks
#define OONotAnIntegerMapKey		NSNotAnIntMapKey
#endif
