//
//  DDDocument.m
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-10.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDDocument.h"
#import "DDDocumentWindowController.h"
#import "DDMesh.h"

#import <OoliteGraphics/OoliteGraphics.h>


@interface DDDocument ()

@property (readwrite) float loadingProgress;

@end


@implementation DDDocument

@synthesize loadingProgress = _loadingProgress;


+ (BOOL) accessInstanceVariablesDirectly
{
	return NO;
}


- (id) init
{
    self = [super init];
    if ((self = [super init]))
	{
		
    }
    return self;
}


- (void) makeWindowControllers
{
	[self addWindowController:[[DDDocumentWindowController alloc] init]];
}


- (void) windowControllerDidLoadNib:(NSWindowController *) aController
{
	NSLog(@"%s called", __FUNCTION__);
    [super windowControllerDidLoadNib:aController];
}


- (NSData *) dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL )
	{
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL) readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if (![absoluteURL isFileURL])  return NO;
	
	NSString *path = [absoluteURL path];
	
	// FIXME: better error reporter.
	OOSimpleProblemReportManager *issues = [[OOSimpleProblemReportManager alloc] initWithMeshFilePath:path forReading:YES];
	id <OOProgressReporting> progressReporter = nil;
	
	Class readerClass = OOSelectMeshReaderForUTI(typeName);
	id <OOMeshReading> reader = [[readerClass alloc] initWithPath:path progressReporter:progressReporter issues:issues];
	
	DDMesh *mesh = [[DDMesh alloc] initWithReader:reader issues:issues];
	if (mesh != nil)  [self addMesh:mesh];
	
    return mesh != nil;
}


- (void) performSimpleUndoWithMeshes:(NSArray *)meshes
{
	NSMutableArray *redoMeshes = [NSMutableArray arrayWithCapacity:self.meshes.count];
	for (DDMesh *mesh in self.meshes)
	{
		[redoMeshes addObject:mesh.abstractMesh];
	}
	
	[[self.undoManager prepareWithInvocationTarget:self] performSimpleUndoWithMeshes:redoMeshes];
	
	NSUInteger idx = 0;
	for (DDMesh *mesh in self.meshes)
	{
		mesh.abstractMesh = [meshes objectAtIndex:idx++];
	}
}


- (void) prepareSimpleUndoWithName:(NSString *)actionName
{
	NSMutableArray *meshes = [NSMutableArray arrayWithCapacity:self.meshes.count];
	for (DDMesh *mesh in self.meshes)
	{
		[meshes addObject:[mesh.abstractMesh copy]];
	}
	
	[self.undoManager setActionName:actionName];
	[[self.undoManager prepareWithInvocationTarget:self] performSimpleUndoWithMeshes:meshes];
}


#pragma mark -
#pragma mark Actions

- (IBAction) generateNormalsSmooth:(id)sender
{
	[self prepareSimpleUndoWithName:NSLocalizedString(@"Generate Smooth Normals", NULL)];
	
	// TODO: deal with selections.
	for (DDMesh *mesh in self.meshes)
	{
		[mesh generateNormalsSmooth:YES];
	}
}


- (IBAction) generateNormalsFlat:(id)sender
{
	[self prepareSimpleUndoWithName:NSLocalizedString(@"Generate Flat Normals", NULL)];
	
	// TODO: deal with selections.
	for (DDMesh *mesh in self.meshes)
	{
		[mesh generateNormalsSmooth:NO];
	}
}


- (IBAction) flipNormals:(id)sender
{
	[self.undoManager setActionName:NSLocalizedString(@"Flip Normals", NULL)];
	[[self.undoManager prepareWithInvocationTarget:self] flipNormals:nil];
	
	// TODO: deal with selections.
	for (DDMesh *mesh in self.meshes)
	{
		[mesh flipNormals];
	}
}


- (IBAction) reverseWinding:(id)sender
{
	[self.undoManager setActionName:NSLocalizedString(@"Reverse Winding", NULL)];
	[[self.undoManager prepareWithInvocationTarget:self] reverseWinding:nil];
	
	// TODO: deal with selections.
	for (DDMesh *mesh in self.meshes)
	{
		[mesh reverseWinding];
	}
}


#pragma mark -
#pragma mark Properties

- (NSArray *) meshes
{
	return [NSArray arrayWithArray:_meshes];
}


- (void) addMesh:(DDMesh *)mesh
{
	if (mesh != nil)
	{
		[self willChangeValueForKey:@"meshes"];
		if (_meshes == nil)  _meshes = [NSMutableArray new];
		[_meshes addObject:mesh];
		[self didChangeValueForKey:@"meshes"];
	}
}


- (void) removeMesh:(DDMesh *)mesh
{
	if (mesh != nil)
	{
		[self willChangeValueForKey:@"meshes"];
		[_meshes removeObject:mesh];
		[self didChangeValueForKey:@"meshes"];
	}
}


// KVC accessors
- (void) insertObject:(DDMesh *)mesh inMeshesAtIndex:(NSUInteger)index
{
	[self willChangeValueForKey:@"meshes"];
	[_meshes insertObject:mesh atIndex:index];
	[self didChangeValueForKey:@"meshes"];
}


- (void) removeObjectFromMeshesAtIndex:(NSUInteger)index
{
	[self willChangeValueForKey:@"meshes"];
	[_meshes removeObjectAtIndex:index];
	[self didChangeValueForKey:@"meshes"];
}

@end
