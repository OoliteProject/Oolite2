/*

OODockTilePlugIn.m


Oolite
Copyright (C) 2004-2010 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/

#import "OODockTilePlugIn.h"
#import "NSFileManagerOOExtensions.h"


@interface OODockTilePlugIn ()

- (NSString *) screenShotsPath;
- (NSString *) latestLogPath;
- (NSString *) logFolderPath;

@end


static NSString *OOLogHandlerGetLogBasePath(void);
static NSArray *ResourceManagerRootPaths(void);


@implementation OODockTilePlugIn

@synthesize dockTile = _dockTile;
@synthesize dockMenu = _dockMenu;


+ (void) load
{
	NSLog(@"%s called.", __FUNCTION__);
}


+ (void) initialize
{
	NSLog(@"%s called.", __FUNCTION__);
}


- (id) init
{
	NSLog(@"%s called.", __FUNCTION__);
	
	if ((self = [super init]))
	{
		[NSBundle loadNibNamed:@"OODockTilePlugIn" owner:self];
	}
	
	return self;
}


- (void) dealloc
{
	NSLog(@"%s called.", __FUNCTION__);
	
	self.dockTile = nil;
	self.dockMenu = nil;
	
	[super dealloc];
}


- (IBAction) showScreenShots:(id)sender
{
	NSLog(@"%s called.", __FUNCTION__);
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[self screenShotsPath]]];
}


- (IBAction) showExpansionPacks:(id)sender
{
	NSLog(@"%s called.", __FUNCTION__);
	
	// Adapted from -[GameController showAddOnsAction:].
	BOOL			pathIsDirectory;
	NSString		*path = nil;
	NSArray			*rootPaths = ResourceManagerRootPaths();
	NSUInteger		i, count = [rootPaths count];
	
	for (i = 0; i < count; i++)
	{
		path = [rootPaths objectAtIndex:i];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&pathIsDirectory] && pathIsDirectory) break;
	} 
	if (path != nil) [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
}


- (IBAction) showLatestLog:(id)sender
{
	NSLog(@"%s called.", __FUNCTION__);
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[self latestLogPath]]];
}


- (IBAction) showLogFolder:(id)sender
{
	NSLog(@"%s called.", __FUNCTION__);
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[self logFolderPath]]];
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	NSLog(@"%s called.", __FUNCTION__);
	
	SEL action = [menuItem action];
	
	if (action == @selector(showScreenShots:))
	{
		return [[NSFileManager defaultManager] fileExistsAtPath:[self screenShotsPath]];
	}
	if (action == @selector(showLatestLog:))
	{
		return [[NSFileManager defaultManager] fileExistsAtPath:[self latestLogPath]];
	}
	
	return YES;
}


- (NSString *) screenShotsPath
{
	return [NSHomeDirectory() stringByAppendingPathComponent:@SNAPSHOTDIR];
}


- (NSString *) latestLogPath
{
	return [[self logFolderPath] stringByAppendingPathComponent:@"Latest.log"];
}


- (NSString *) logFolderPath
{
	return OOLogHandlerGetLogBasePath();
}

@end


// Adapted from OOLogOutputHandler.m.
static NSString *OOLogHandlerGetLogBasePath(void)
{
	static NSString		*basePath = nil;
	
	if (basePath == nil)
	{
		// ~/Library
		basePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		basePath = [basePath stringByAppendingPathComponent:@"Logs"];
		basePath = [basePath stringByAppendingPathComponent:@"Oolite"];
		
		BOOL				exists, directory;
		NSFileManager		*fmgr =  [NSFileManager defaultManager];
		
		exists = [fmgr fileExistsAtPath:basePath isDirectory:&directory];
		if (exists)
		{
			if (!directory)
			{
				basePath = nil;
			}
		}
		else
		{
			if (![fmgr createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:NULL])
			{
				basePath = nil;
			}
		}
		
		[basePath retain];
	}
	
	return basePath;
}


static NSArray *ResourceManagerRootPaths(void)
{
	// Adapted from -[ResourceManager rootPaths].
	return [[NSArray alloc] initWithObjects:
			[[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
			   stringByAppendingPathComponent:@"Application Support"]
			  stringByAppendingPathComponent:@"Oolite"]
			 stringByAppendingPathComponent:@"AddOns"],
			[[[[NSBundle mainBundle] bundlePath]
			  stringByDeletingLastPathComponent]
			 stringByAppendingPathComponent:@"AddOns"],
			[[NSHomeDirectory()
			  stringByAppendingPathComponent:@".Oolite"]
			 stringByAppendingPathComponent:@"AddOns"],
			nil];
}
