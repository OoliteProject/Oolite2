#import <Foundation/Foundation.h>
#import <OOMesh/CollectionUtils.h>


static OOMMesh *ReadDAT(NSString *path, id <OOMProblemReportManager> issues);


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
	OOMMesh *mesh = nil;
	
	NSString *ext = [[path pathExtension] lowercaseString];
	if ([ext isEqualToString:@"dat"])  mesh = ReadDAT(path, issues);
	else
	{
		OOMReportError(issues, @"unknownType", @"Cannot read %@ because it is of an unknown type.", [path lastPathComponent]);
	}
	
	if (mesh != nil)
	{
		OOMWriteOOMesh(mesh, [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"oomesh"], issues);
	}
	
    [pool drain];
    return 0;
}


static OOMMesh *ReadDAT(NSString *path, id <OOMProblemReportManager> issues)
{
	OOMDATReader *reader = [[OOMDATReader alloc] initWithPath:path issues:issues];
	if (reader == nil)  return nil;
	
	[reader setSmoothing:YES];
//	[reader setBrokenSmoothing:NO];
	
	OOMMesh *result = [reader mesh];
	[reader release];
	
	return result;
}
