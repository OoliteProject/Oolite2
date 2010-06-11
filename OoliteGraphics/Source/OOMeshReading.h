#import <Foundation/Foundation.h>
#import "OOProblemReporting.h"
#import "OOProgressReporting.h"

@class OOAbstractMesh;


@protocol OOMeshReading <NSObject>

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReporting>)issues;

- (void) parse;
- (OOAbstractMesh *) abstractMesh;

@end
