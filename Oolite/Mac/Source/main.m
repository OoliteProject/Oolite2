#import <OoliteBase/OoliteBase.h>
#import "OoliteLogOutputHandler.h"
#import "OOLogHeader.h"


#ifndef NDEBUG
uint32_t gDebugFlags = 0;
#endif


int main(int argc, const char *argv[])
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	OOLoggingInit([OoliteLogOutputHandler sharedLogOutputHandler]);
	OOPrintLogHeader();
	[pool drain];
	
	return NSApplicationMain(argc, argv);
}
