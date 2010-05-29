#import <Foundation/Foundation.h>
#import <OOMesh/CollectionUtils.h>


static OOAbstractMesh *ReadDAT(NSString *path, id <OOProblemReportManager> issues);
static OOAbstractMesh *ReadOOMesh(NSString *path, id <OOProblemReportManager> issues);


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
	
	id <OOProblemReportManager> issues = [[OOSimpleProblemReportManager new] autorelease];
	OOAbstractMesh *mesh = nil;
	
	NSString *ext = [[path pathExtension] lowercaseString];
	if ([ext isEqualToString:@"dat"])  mesh = ReadDAT(path, issues);
	else if ([ext isEqualToString:@"oomesh"])  mesh = ReadOOMesh(path, issues);
	else
	{
		OOReportError(issues, @"unknownType", @"Cannot read %@ because it is of an unknown type.", [path lastPathComponent]);
	}
	
	if (mesh != nil)
	{
		OOWriteOOMesh(mesh, [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"oomesh"], issues);
	}

	
    [pool drain];
    return 0;
}


static OOAbstractMesh *ReadDAT(NSString *path, id <OOProblemReportManager> issues)
{
	OODATReader *reader = [[OODATReader alloc] initWithPath:path issues:issues];
	if (reader == nil)  return nil;
	
//	[reader setSmoothing:YES];
	[reader setBrokenSmoothing:NO];
	
	OOAbstractMesh *result = [reader mesh];
	[reader release];
	
	return result;
}


static OOAbstractMesh *ReadOOMesh(NSString *path, id <OOProblemReportManager> issues)
{
	OOMeshReader *reader = [[OOMeshReader alloc] initWithPath:path issues:issues];
	if (reader == nil)  return nil;
	
	OOAbstractMesh *result = [reader mesh];
	[reader release];
	
	return result;
}
