#import <OoliteGraphics/OoliteGraphics.h>


@interface OOSimpleProgressReporter: NSObject <OOProgressReporting>
@end


static OOAbstractMesh *LoadMesh(NSString *path, id <OOProgressReporting> progressReporter, id <OOProblemReporting> issues);


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
	
	id <OOProgressReporting> progressReporter = [[OOSimpleProgressReporter new] autorelease];
	OOSimpleProblemReportManager *issues = [[[OOSimpleProblemReportManager alloc] initWithMeshFilePath:path forReading:YES] autorelease];
	
	OOAbstractMesh *mesh = LoadMesh(path, progressReporter, issues);
	if (mesh == nil)  exit(EXIT_FAILURE);
	
	path = [[[path stringByDeletingPathExtension] stringByAppendingString:@"-dump"] stringByAppendingPathExtension:@"oomesh"];
	issues = [[[OOSimpleProblemReportManager alloc] initWithMeshFilePath:path forReading:NO] autorelease];
	OOWriteOOMesh(mesh, path, issues);
	
    [pool drain];
    return 0;
}


static OOAbstractMesh *LoadMesh(NSString *path, id <OOProgressReporting> progressReporter, id <OOProblemReporting> issues)
{
	id <OOMeshReading> reader = OOReadMeshFromFile(path, progressReporter, issues);
	
#if 1
	return [reader abstractMesh];
#else
	OORenderMesh *mesh = nil;
	NSArray *materials = nil;
	[reader getRenderMesh:&mesh andMaterialSpecs:&materials];
	return nil;
#endif
}


@implementation  OOSimpleProgressReporter

- (void) task:(id)task reportsProgress:(float)progress
{
	printf("\r%.u %%", (unsigned)(progress * 100.0f));
	if (progress < 1.0)  fflush(stdout);
	else  printf("\n");
}

@end
