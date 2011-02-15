#import <Foundation/Foundation.h>


@protocol OOProgressReporting <NSObject>

- (void) task:(id)task reportsProgress:(float)progress;

@end
