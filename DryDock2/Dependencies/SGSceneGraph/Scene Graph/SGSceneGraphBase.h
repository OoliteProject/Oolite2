#ifndef SCENGRAPH_LIGHTING
#define SCENGRAPH_LIGHTING 1
#endif

#import <Foundation/Foundation.h>
#import <OpenGL/gl.h>
#import "SGVectorTypes.h"
#import "SGMatrixTypes.h"


@class SGSceneGraph;
@class SGSceneNode;
@class SGSceneTag;

#if SCENGRAPH_LIGHTING
@class SGLight;
@class SGLightManager;
#endif


#if __cplusplus
#define SG_BEGIN_EXTERN_C	extern "C" {
#define SG_END_EXTERN_C		}
#define SG_INLINE			inline
#else
#define SG_BEGIN_EXTERN_C
#define SG_END_EXTERN_C
#define SG_INLINE			static inline
#endif
