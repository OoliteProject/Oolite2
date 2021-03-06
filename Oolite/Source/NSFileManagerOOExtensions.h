/*

NSFileManagerOOExtensions.h

This extends NSFileManager and adds some methods to insulate the
main oolite code from the gory details of creating/chdiring to the
commander save directory.

Oolite
Copyright (C) 2004-2011 Giles C Williams and contributors

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

#import <OoliteBase/OoliteBase.h>

#define SAVEDIR "oolite-saves"

#if OOLITE_SDL
#define SNAPSHOTDIR "snapshots"
#endif

@interface NSFileManager (OOExtensions)

- (NSArray*) commanderContentsOfPath:(NSString*) savePath;
- (NSString*) defaultCommanderPath;

#if OOLITE_SDL
- (BOOL) chdirToSnapshotPath;
#endif

@end


