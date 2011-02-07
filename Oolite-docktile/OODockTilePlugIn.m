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
#import "JAPersistentFileReference.h"


#define OOLITE_LEOPARD 1


@interface OODockTilePlugIn ()

- (NSURL *) snapshotsURLCreatingIfNeeded:(BOOL)create;
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
	
	[[NSWorkspace sharedWorkspace] openURL:[self snapshotsURLCreatingIfNeeded:NO]];
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
		return [[NSFileManager defaultManager] fileExistsAtPath:[[self snapshotsURLCreatingIfNeeded:NO] path]];
	}
	if (action == @selector(showLatestLog:))
	{
		return [[NSFileManager defaultManager] fileExistsAtPath:[self latestLogPath]];
	}
	
	return YES;
}


static id GetPreference(NSString *key, Class expectedClass)
{
	// Use CFPreferences instead of NSDefaults so we can specify the app ID.
	CFPropertyListRef value = CFPreferencesCopyAppValue((CFStringRef)key, CFSTR("org.aegidian.oolite"));
	id result = [NSMakeCollectable(value) autorelease];
	if (expectedClass != Nil && ![result isKindOfClass:expectedClass])  result = nil;
	
	return result;
}


static void SetPreference(NSString *key, id value)
{
	CFPreferencesSetAppValue((CFStringRef)key, value, CFSTR("org.aegidian.oolite"));
}


static void RemovePreference(NSString *key)
{
	SetPreference(key, nil);
}


static NSString *DESC(NSString *key)
{
	static NSDictionary *descs = nil;
	if (descs == nil)
	{
		// Get default description.plist from Oolite.
		NSURL *url = [[NSBundle mainBundle] bundleURL];
		url = [NSURL URLWithString:@"../Resources/Config/description.plist" relativeToURL:url];
		NSLog(@"description.plist URL: %@ = %@", url, [[url absoluteURL] path]);
		
		descs = [NSDictionary dictionaryWithContentsOfURL:url];
		if (descs == nil)  descs = [NSDictionary dictionary];
		[descs retain];
	}
	
	NSString *result = [descs objectForKey:key];
	if (![result isKindOfClass:[NSString class]])  result = nil;	// We don't need to deal with arrays.
	return result;
}


#define kSnapshotsDirRefKey		@"snapshots-directory-reference"
#define kSnapshotsDirNameKey	@"snapshots-directory-name"

- (NSURL *) snapshotsURLCreatingIfNeeded:(BOOL)create
{
	BOOL			stale = NO;
	NSDictionary	*snapshotDirDict = GetPreference(kSnapshotsDirRefKey, [NSDictionary class]);
	NSURL			*url = nil;
	NSString		*name = DESC(@"snapshots-directory-name-mac");
	
	if (snapshotDirDict != nil)
	{
		url = JAURLFromPersistentFileReference(snapshotDirDict, kJAPersistentFileReferenceWithoutUI | kJAPersistentFileReferenceWithoutMounting, &stale);
		if (url != nil)
		{
			NSString *existingName = [[url path] lastPathComponent];
			if ([existingName compare:name options:NSCaseInsensitiveSearch] != 0)
			{
				// Check name from previous access, because we might have changed localizations.
				NSString *originalOldName = GetPreference(kSnapshotsDirNameKey, [NSString class]);
				if ([existingName compare:originalOldName options:NSCaseInsensitiveSearch] != 0)
				{
					url = nil;
				}
			}
			
			// did we put the old directory in the trash?
			Boolean inTrash = false;
			const UInt8* utfPath = (UInt8*)[[url path] UTF8String];
			
			OSStatus err = DetermineIfPathIsEnclosedByFolder(kOnAppropriateDisk, kTrashFolderType, utfPath, false, &inTrash);
			// if so, create a new directory.
			if (err == noErr && inTrash == true) url = nil;
		}
	}
	
	if (url == nil)
	{
		NSString *path = nil;
		NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
		if ([searchPaths count] > 0)
		{
			path = [[searchPaths objectAtIndex:0] stringByAppendingPathComponent:name];
		}
		url = [NSURL fileURLWithPath:path];
		
		if (url != nil)
		{
			stale = YES;
			if (create)
			{
				NSFileManager *fmgr = [NSFileManager defaultManager];
				if (![fmgr fileExistsAtPath:path])
				{
#if OOLITE_LEOPARD
					[fmgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
#else
					[fmgr createDirectoryAtPath:path attributes:nil];
#endif
				}
			}
		}
	}
	
	if (stale)
	{
		snapshotDirDict = JAPersistentFileReferenceFromURL(url);
		if (snapshotDirDict != nil)
		{
			SetPreference(kSnapshotsDirRefKey, snapshotDirDict);
			SetPreference(kSnapshotsDirNameKey, [[url path] lastPathComponent]);
		}
		else
		{
			RemovePreference(kSnapshotsDirRefKey);
		}
	}
	
	return url;
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
