/*

OOShipClass+Legacy.h

Support for loading Oolite 1.x shipdata.


Oolite
Copyright © 2004–2011 Giles C Williams and contributors

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

#import "OOShipClass.h"


@interface OOShipClass (Legacy)

/*
	Create an OOShipClass from an Oolite 1.x shipdata.plist entry.
	
	key: the shipdata.plist key.
	legacyPList: the shipdata.plist value, with like_ship stuff folded in.
	legacyShipData: the original shipdata.plist.
*/
- (id) initWithKey:(NSString *)key
	   legacyPList:(NSDictionary *)legacyPList
	legacyShipData:(NSDictionary *)legacyShipData
   problemReporter:(id<OOProblemReporting>)issues;

@end
