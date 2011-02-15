#import <OoliteGraphics/OoliteGraphics.h>


@interface OOSimpleProgressReporter: NSObject <OOProgressReporting>
@end


static OOAbstractMesh *LoadMesh(NSString *path, id <OOProgressReporting> progressReporter, id <OOProblemReporting> issues);


int main (int argc, const char * argv[])
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
	if (argc < 3)
	{
		fprintf(stderr, "An input file name must be specified.\n");
		return EXIT_FAILURE;
	}
	
	id <OOProgressReporting> progressReporter = [[OOSimpleProgressReporter new] autorelease];
	NSMutableArray *meshes = [NSMutableArray arrayWithCapacity:argc - 1];
	OOSimpleProblemReportManager *issues = nil;
	
	int i;
	for (i = 1; i < argc; i++)
	{
		NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
		
		NSString *path = [NSString stringWithUTF8String:argv[i]];
		char buffer[PATH_MAX];
		realpath([[path stringByExpandingTildeInPath] UTF8String], buffer);
		path = [NSString stringWithUTF8String:buffer];
		
		issues = [[[OOSimpleProblemReportManager alloc] initWithMeshFilePath:path forReading:YES] autorelease];
		OOAbstractMesh *mesh = LoadMesh(path, progressReporter, issues);
		if (mesh == nil)  return EXIT_FAILURE;
		[meshes addObject:mesh];
		
		[innerPool drain];
	}
	
	OOAbstractMesh *mergedMesh = [meshes objectAtIndex:0];
	for (i = 1; i < argc - 1; i++)
	{
		OOAbstractMesh *mesh = [meshes objectAtIndex:i];
		[mergedMesh mergeMesh:mesh];
	}
	
	issues = [[[OOSimpleProblemReportManager alloc] initWithMeshFilePath:@"merged-mesh.oomesh" forReading:NO] autorelease];
	OOWriteOOMesh(mergedMesh, @"merged-mesh.oomesh", issues);
	
	issues = [[[OOSimpleProblemReportManager alloc] initWithMeshFilePath:@"merged-mesh.dat" forReading:NO] autorelease];
	OOWriteDAT(mergedMesh, @"merged-mesh.dat", issues);
	
    [pool drain];
    return 0;
}


static OOAbstractMesh *LoadMesh(NSString *path, id <OOProgressReporting> progressReporter, id <OOProblemReporting> issues)
{
	id <OOMeshReading> reader = nil;
	NSString *ext = [[path pathExtension] lowercaseString];
	
	if ([ext isEqualToString:@"dat"])
	{
		OODATReader *datReader = [[OODATReader alloc] initWithPath:path progressReporter:progressReporter issues:issues];
	//	[datReader setSmoothing:YES];
		[datReader setBrokenSmoothing:YES];
		reader = datReader;
	}
	else if ([ext isEqualToString:@"oomesh"])
	{
		reader = [[OOMeshReader alloc] initWithPath:path progressReporter:progressReporter issues:issues];
	}
	else if ([ext isEqualToString:@"obj"])
	{
		reader = [[OOOBJReader alloc] initWithPath:path progressReporter:progressReporter issues:issues];
	}
	else
	{
		OOReportError(issues, @"%@: unknown mesh type.", [path lastPathComponent]);
		return nil;
	}
	
	return [reader abstractMesh];
}


@implementation  OOSimpleProgressReporter

- (void) task:(id)task reportsProgress:(float)progress
{
	printf("\r%.u %%", (unsigned)(progress * 100.0f));
	if (progress < 1.0)  fflush(stdout);
	else  printf("\n");
}

@end
