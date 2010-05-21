#import <Foundation/Foundation.h>

#define OOMATHS_STANDALONE 1
#define OOCOLLECTIONEXTRACTORS_SIMPLE

#import "OOMaths.h"


#ifndef DESTROY
	#define DESTROY(x) do { id x_ = x; x = nil; [x_ release]; } while (0)
#endif


#ifndef OO_NUMBER_TYPES_DEFINED
	#if NSINTEGER_DEFINED
		typedef NSInteger OOInteger;
		typedef NSUInteger OOUInteger;
		typedef CGFloat OOCGFloat;
	#else
		typedef int OOInteger;
		typedef unsigned int OOUInteger;
		typedef float OOCGFloat;
	#endif
	
	#define OO_NUMBER_TYPES_DEFINED	1
#endif
