#import <OOMeshTools/OOMeshTools.h>


static id <OOMeshReading> NewDATReader(NSString *path, id <OOProblemReportManager> issues);
static id <OOMeshReading> NewOOMeshReader(NSString *path, id <OOProblemReportManager> issues);
static id <OOMeshReading> NewOBJReader(NSString *path, id <OOProblemReportManager> issues);


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
	id <OOMeshReading> reader = nil;
	
	NSString *ext = [[path pathExtension] lowercaseString];
	if ([ext isEqualToString:@"dat"])  reader = NewDATReader(path, issues);
	else if ([ext isEqualToString:@"oomesh"])  reader = NewOOMeshReader(path, issues);
	else if ([ext isEqualToString:@"obj"])  reader = NewOBJReader(path, issues);
	else
	{
		OOReportError(issues, @"unknownType", @"Cannot read %@ because it is of an unknown type.", [path lastPathComponent]);
	}
	
	OOAbstractMesh *mesh = [reader abstractMesh];
	
	if (mesh == nil)
	{
		exit(EXIT_FAILURE);
	}
	
	OOWriteOOMesh(mesh, [[[path stringByDeletingPathExtension] stringByAppendingString:@"-dump"] stringByAppendingPathExtension:@"oomesh"], issues);
	
    [pool drain];
    return 0;
}


static id <OOMeshReading> NewDATReader(NSString *path, id <OOProblemReportManager> issues)
{
	OODATReader *reader = [[OODATReader alloc] initWithPath:path issues:issues];
	if (reader == nil)  return nil;
	
//	[reader setSmoothing:YES];
	[reader setBrokenSmoothing:NO];
	
	return reader;
}


static id <OOMeshReading> NewOOMeshReader(NSString *path, id <OOProblemReportManager> issues)
{
	return [[OOMeshReader alloc] initWithPath:path issues:issues];
}


static id <OOMeshReading> NewOBJReader(NSString *path, id <OOProblemReportManager> issues)
{
	return [[OOOBJReader alloc] initWithPath:path issues:issues];
}
