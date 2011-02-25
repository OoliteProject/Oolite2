#import <OoliteBase/OoliteBase.h>
#import "OoliteLogOutputHandler.h"


#ifndef NDEBUG
uint32_t gDebugFlags = 0;
#endif


int main(int argc, const char *argv[])
{
	OOLoggingInit([OoliteLogOutputHandler sharedLogOutputHandler]);
	return NSApplicationMain(argc, argv);
}
