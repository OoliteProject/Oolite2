#import <Foundation/Foundation.h>


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
	
	OOMMesh *mesh = [reader mesh];
	if (mesh != nil)
	{
		OOMWriteOOMesh(mesh, [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"oomesh"], issues);
	}
	
    [pool drain];
    return 0;
}
