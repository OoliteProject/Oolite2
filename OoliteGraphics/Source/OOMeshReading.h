#import <Foundation/Foundation.h>
#import "OOProblemReporting.h"
#import "OOProgressReporting.h"

@class OOAbstractMesh;
@class OORenderMesh;


@protocol OOMeshReading <NSObject>

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues;

- (void) parse;

#if !OOLITE_LEAN
- (OOAbstractMesh *) abstractMesh;
#endif

- (void) getRenderMesh:(OORenderMesh **)renderMesh andMaterialSpecs:(NSArray **)materialSpecifications;

@end
