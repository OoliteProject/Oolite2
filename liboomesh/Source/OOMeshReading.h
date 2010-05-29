#import <Foundation/Foundation.h>

@protocol OOProblemReportManager;
@class OOAbstractMesh;


@protocol OOMeshReading <NSObject>

- (id) initWithPath:(NSString *)path issues:(id <OOProblemReportManager>)issues;

- (void) parse;
- (OOAbstractMesh *) abstractMesh;

@end
