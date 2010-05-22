#import <Foundation/Foundation.h>
#import <OOMesh/OOCollectionExtractors.h>


int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	if (argc < 2)
	{
		fprintf(stderr, "An input file name must be specified.\n");
		return EXIT_FAILURE;
	}
	
	NSString *path = [NSString stringWithUTF8String:argv[1]];
	char buffer[PATH_MAX];
	realpath([[path stringByExpandingTildeInPath] UTF8String], buffer);
	path = [NSString stringWithUTF8String:buffer];
	
	id <OOMProblemReportManager> issues = [[OOMSimpleProblemReportManager new] autorelease];
	
	OOMDATReader *reader = [[OOMDATReader alloc] initWithPath:path issues:issues];
	if (reader == nil)  return EXIT_FAILURE;
	
	[reader setSmoothing:YES];
//	[reader setBrokenSmoothing:NO];
	[reader parse];
	
    [pool drain];
    return 0;
}
