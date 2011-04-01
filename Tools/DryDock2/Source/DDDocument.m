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
#import "DDProblemReportManager.h"


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


- (BOOL) writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	DDProblemReportManager *issues = [[DDProblemReportManager alloc] initWithContext:kDDPRContextSave fileURL:absoluteURL];
	NSData *data = nil;
	
	if ([typeName isEqualToString:@"org.oolite.oomesh"])
	{
		data = OOMeshDataFromMesh([[self.meshes objectAtIndex:0] abstractMesh], kOOMeshWriteWithAnnotations | kOOMeshWriteWithExtendedAnnotations /*| kOOMeshWriteJSONCompatible*/, issues);
	}
	else if ([typeName isEqualToString:@"org.aegidian.oolite.mesh"])
	{
		data = OODATDataFromMesh([[self.meshes objectAtIndex:0] abstractMesh], issues);
	}
	else
	{
		OOReportError(issues, @"The file format \"%@\" is currently not supported for saving.", [[NSWorkspace sharedWorkspace] localizedDescriptionForType:typeName]);
	}
	
	[issues runReportModalForWindow:[self windowForSheet] completionHandler:^(BOOL continueFlag){
		if (continueFlag)
		{
			NSError *error = nil;
			BOOL OK = [data writeToURL:absoluteURL options:NSDataWritingAtomic error:&error];
			if (!OK)
			{
				[self presentError:error];
			}
		}
	}];
	
	return YES;	// Don’t want NSDocument’s error messages.
}


- (BOOL) readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if (![absoluteURL isFileURL])  return NO;
	
	NSString *path = [absoluteURL path];
	
	DDProblemReportManager *issues = [[DDProblemReportManager alloc] initWithContext:kDDPRContextLoad fileURL:absoluteURL];
	id <OOProgressReporting> progressReporter = nil;
	
	Class readerClass = OOSelectMeshReaderForUTI(typeName);
	id <OOMeshReading> reader = [[readerClass alloc] initWithPath:path progressReporter:progressReporter issues:issues];
	
	DDMesh *mesh = [[DDMesh alloc] initWithReader:reader issues:issues];
	if (mesh != nil)  [self addMesh:mesh];
	
	BOOL success = [issues showReportApplicationModal] && mesh != nil;
	if (!success && outError != NULL)
	{
		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
	}
	return success;
}


// Simple undo: just replace entire mesh[es].
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


- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(deleteSmoothGroups:))
	{
		for (DDMesh *mesh in self.meshes)
		{
			if (mesh.hasSmoothGroups)  return YES;
		}
		return NO;
	}
	
	return YES;
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


- (IBAction) deleteSmoothGroups:(id)sender
{
	[self prepareSimpleUndoWithName:NSLocalizedString(@"Delete Smooth Groups", NULL)];
	
	// TODO: deal with selections.
	for (DDMesh *mesh in self.meshes)
	{
		[mesh deleteSmoothGroups];
		[mesh generateNormalsSmooth:YES];
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
