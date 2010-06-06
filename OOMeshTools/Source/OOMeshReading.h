#import <Foundation/Foundation.h>
#import "OOProblemReportManager.h"
#import "OOProgressReporting.h"

@class OOAbstractMesh;


@protocol OOMeshReading <NSObject>

- (id) initWithPath:(NSString *)path
   progressReporter:(id < OOProgressReporting>)progressReporter
			 issues:(id <OOProblemReportManager>)issues;

- (void) parse;
- (OOAbstractMesh *) abstractMesh;

@end
