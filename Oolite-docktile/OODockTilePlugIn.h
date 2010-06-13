/*

OODockTilePlugIn.h

Dock tile plug-in: manages dock menu when Oolite is docked but not running
under Mac OS X 10.6 and later.


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

#import <Cocoa/Cocoa.h>


@interface OODockTilePlugIn: NSObject <NSDockTilePlugIn>
#if !__OBJC2__
{
@private
	NSDockTile				*_dockTile;
	NSMenu					*_dockMenu;
}
#endif

@property (retain) NSDockTile *dockTile;
@property (assign) IBOutlet NSMenu *dockMenu;


- (IBAction) showScreenShots:(id)sender;
- (IBAction) showExpansionPacks:(id)sender;
- (IBAction) showLatestLog:(id)sender;
- (IBAction) showLogFolder:(id)sender;

@end
