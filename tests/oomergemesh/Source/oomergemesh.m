#import <Foundation/Foundation.h>
#import <OOMeshTools/OOMeshTools.h>


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
	id <OOProblemReporting> issues = [[OOSimpleProblemReportManager new] autorelease];
	NSMutableArray *meshes = [NSMutableArray arrayWithCapacity:argc - 1];
	
	unsigned i;
	for (i = 1; i < argc; i++)
	{
		NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
		
		NSString *path = [NSString stringWithUTF8String:argv[i]];
		char buffer[PATH_MAX];
		realpath([[path stringByExpandingTildeInPath] UTF8String], buffer);
		path = [NSString stringWithUTF8String:buffer];
		
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
	
	OOWriteOOMesh(mergedMesh, @"meged-mesh.oomesh", issues);
	OOWriteDAT(mergedMesh, @"meged-mesh.dat", issues);
	
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
