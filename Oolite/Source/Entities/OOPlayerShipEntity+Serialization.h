/*

OOPlayerShipEntity+Serialization.h

Methods for converting OOPlayerShipEntity to/from property list for saving.


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

#import "OOPlayerShipEntity.h"


@interface OOPlayerShipEntity (Serialization)

+ (NSString *) savedPathGameForName:(NSString *)name directoryPath:(NSString *)directoryPath;

- (BOOL) writeSavedGameToPath:(NSString *)path error:(NSError **)error;

- (NSDictionary *) legacyCommanderDataDictionary;
- (BOOL)setCommanderDataFromLegacyDictionary:(NSDictionary *) dict;

@end
