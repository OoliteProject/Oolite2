/*

GetMetadataForFile.m

Spotlight metadata importer for Oolite
Copyright (C) 2005-2010 Jens Ayton

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

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <stdarg.h>
#import "NSScannerOOExtensions.h"
#import "OOCollectionExtractors.h"


#define kShipIDs			@"org_aegidian_oolite_shipids"
#define kShipClassNames		@"org_aegidian_oolite_shipclassnames"
#define kShipRoles			@"org_aegidian_oolite_shiproles"
#define kShipModels			@"org_aegidian_oolite_shipmodels"
#define kCombatRating		@"org_aegidian_oolite_combatrating"
#define kSystemName			@"org_aegidian_oolite_systemname"
#define kMinVersion			@"org_aegidian_oolite_minversion"
#define kMaxVersion			@"org_aegidian_oolite_maxversion"

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1050
#define kMDItemURL			@"kMDItemURL"
#define kMDItemSupportFileType	@"kMDItemSupportFileType"
#endif


static BOOL GetMetadataForSaveFile(void* thisInterface, NSMutableDictionary *attributes, NSString *pathToFile);
static BOOL GetMetadataForOXP(void* thisInterface, NSMutableDictionary *attributes, NSString *pathToFile);

static id GetBundlePropertyList(NSString *inPListName);
static NSDictionary *ConfigDictionary(NSString *basePath, NSString *name);
static NSDictionary *MergeShipData(NSDictionary *shipData, NSDictionary *shipDataOverrides);
static NSDictionary *MergeShipDataEntry(NSDictionary *baseDict, NSDictionary *overrideDict);

static NSDictionary *OOParseRolesFromString(NSString *string);
static NSMutableArray *ScanTokensFromString(NSString *values);


/*
	NOTE: this prototype differs from the one declared in main.c (which is mostly unmodified
	Apple boilerplate code), but the types are entirely compatible.
*/
BOOL GetMetadataForFile(void* thisInterface, 
			   NSMutableDictionary *attributes, 
			   NSString *contentTypeUTI,
			   NSString *pathToFile)
{
	NSAutoreleasePool		*pool;
	BOOL					result = NO;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	@try
	{
		if ([contentTypeUTI isEqual:@"org.aegidian.oolite.save"])
		{
			result = GetMetadataForSaveFile(thisInterface, attributes, pathToFile);
		}
		else if ([contentTypeUTI isEqual:@"org.aegidian.oolite.oxp"])
		{
			result = GetMetadataForOXP(thisInterface, attributes, pathToFile);
		}
	}
	@catch (id any) {}
	
	[pool release];
	return result;
}

static BOOL GetMetadataForSaveFile(void* thisInterface, NSMutableDictionary *attributes, NSString *pathToFile)
{
	BOOL					ok = NO;
	NSDictionary			*content;
	id						value;
	OOInteger				killCount;
	
	content = [NSDictionary dictionaryWithContentsOfFile:pathToFile];			
	if (nil != content)
	{
		ok = YES;
		
		value = [content oo_stringForKey:@"player_name"];
		if (nil != value)  [attributes setObject:value forKey:(NSString *)kMDItemTitle];
		
		value = [content oo_stringForKey:@"ship_desc"];
		if (nil != value)  [attributes setObject:[NSArray arrayWithObject:value] forKey:kShipIDs];
		
		value = [content oo_stringForKey:@"ship_name"];
		if (nil != value)  [attributes setObject:[NSArray arrayWithObject:value] forKey:kShipClassNames];
		
		value = [content oo_stringForKey:@"current_system_name"];
		if (nil != value)  [attributes setObject:value forKey:kSystemName];
		
		value = [content oo_arrayForKey:@"comm_log"];
		if (0 != [value count])  [attributes setObject:[value componentsJoinedByString:@"\n"] forKey:(NSString *)kMDItemTextContent];
		
		killCount = [content oo_integerForKey:@"ship_kills"];
		if (killCount > 0)
		{
			NSArray					*ratings;
			int						rating = 0;
			int						kills[8] = { 0x0008,  0x0010,  0x0020,  0x0040,  0x0080,  0x0200,  0x0A00,  0x1900 };
			
			ratings = [GetBundlePropertyList(@"Values") objectForKey:@"ratings"];
			if (nil != ratings)
			{
				while ((rating < 8) && (kills[rating] <= killCount))
				{
					rating ++;
				}
				
				[attributes setObject:[ratings oo_stringAtIndex:rating] forKey:kCombatRating];
			}
		}
	}
	
	return ok;
}


static BOOL GetMetadataForOXP(void* thisInterface, NSMutableDictionary *attributes, NSString *pathToFile)
{
	NSDictionary			*requires = nil;
	NSDictionary			*shipData = nil;
	NSDictionary			*shipDataOverrides = nil;
	NSDictionary			*manifest = nil;
	NSEnumerator			*shipEnum = nil;
	NSDictionary			*ship = nil;
	NSString				*string = nil;
	NSMutableSet			*names = nil, *models = nil, *roles = nil;
	CFIndex					count;
	id						object = nil;
	
	requires = ConfigDictionary(pathToFile, @"requires.plist");
	if (requires != nil)
	{
		string = [requires objectForKey:@"version"];
		if (string != nil) [attributes setObject:string forKey:kMinVersion];
		
		string = [requires objectForKey:@"max_version"];
		if (string != nil) [attributes setObject:string forKey:kMaxVersion];
	}
	
	shipData = ConfigDictionary(pathToFile, @"shipdata.plist");
	shipDataOverrides = ConfigDictionary(pathToFile, @"shipdata-overrides.plist");
	shipData = MergeShipData(shipData, shipDataOverrides);
	
	count = [shipData count];
	if (count != 0)
	{
		names = [NSMutableSet setWithCapacity:count];
		models = [NSMutableSet setWithCapacity:count];
		roles = [NSMutableSet set];
		
		[attributes setObject:[shipData allKeys] forKey:kShipIDs];
		
		for (shipEnum = [shipData objectEnumerator]; (ship = [shipEnum nextObject]); )
		{
			if (![ship isKindOfClass:[NSDictionary class]])  continue;
			
			string = [ship oo_stringForKey:@"name"];
			if (string != nil)  [names addObject:string];
			
			string = [ship oo_stringForKey:@"model"];
			if (string != nil)  [models addObject:string];
			
			string = [ship oo_stringForKey:@"roles"];
			if (string != nil)  [roles addObjectsFromArray:[OOParseRolesFromString(string) allKeys]];
		}
		
		if (0 != [names count]) [attributes setObject:[names allObjects] forKey:kShipClassNames];
		if (0 != [models count]) [attributes setObject:[models allObjects] forKey:kShipModels];
		if (0 != [roles count]) [attributes setObject:[roles allObjects] forKey:kShipRoles];
	}
	
	// Semi-official metadata file, spec in progress.
	manifest = ConfigDictionary(pathToFile, @"manifest.plist");
	string = [manifest oo_stringForKey:@"version"];
	if (string == nil)
	{
		// Not "officially" supported, but exists in some OXPs.
		manifest = ConfigDictionary(pathToFile, @"Info.plist");
		string = [manifest oo_stringForKey:@"CFBundleVersion"];
	}
	if (string != nil)
	{
		[attributes setObject:string forKey:(NSString *)kMDItemVersion];
	}
	
	if (manifest != nil)
	{
		// Author: Spotlight wants array, we accept array or string.
		object = [manifest objectForKey:@"author"];
		if ([object isKindOfClass:[NSString class]])  object = [NSArray arrayWithObject:object];
		if ([object isKindOfClass:[NSArray class]])  [attributes setObject:object forKey:(NSString *)kMDItemAuthors];
		
		string = [manifest oo_stringForKey:@"name"];
		if (string != nil)  [attributes setObject:string forKey:(NSString *)kMDItemTitle];
		
		string = [manifest oo_stringForKey:@"copyright"];
		if (string != nil)  [attributes setObject:string forKey:(NSString *)kMDItemCopyright];
		
		string = [manifest oo_stringForKey:@"identifier"];
		if (string != nil)  [attributes setObject:string forKey:(NSString *)kMDItemIdentifier];
		
		string = [manifest oo_stringForKey:@"description"];
		if (string != nil)  [attributes setObject:string forKey:(NSString *)kMDItemDescription];
		
		string = [manifest oo_stringForKey:@"info_url"];
		if (string == nil)  string = [manifest oo_stringForKey:@"download_url"];
		if (string != nil)  [attributes setObject:string forKey:(NSString *)kMDItemURL];
	}
	
	// Attempt to make OXPs searchable even if they're in ~/Library.
	[attributes setObject:[NSArray arrayWithObject:@""] forKey:(NSString *)kMDItemSupportFileType];
	
	return YES;
}


#pragma mark -
#pragma mark Helper functions

static id GetBundlePropertyList(NSString *inPListName)
{
	NSBundle				*bundle;
	NSString				*path;
	NSData					*data;
	
	bundle = [NSBundle bundleWithIdentifier:@"org.aegidian.oolite.md-importer"];
	path = [bundle pathForResource:inPListName ofType:@"plist"];
	data = [NSData dataWithContentsOfFile:path];
	return [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
}


static NSDictionary *ConfigDictionary(NSString *basePath, NSString *name)
{
	NSDictionary *content = [NSDictionary dictionaryWithContentsOfFile:[[basePath stringByAppendingPathComponent:@"Config"] stringByAppendingPathComponent:name]];
	if (content == nil)  content = [NSDictionary dictionaryWithContentsOfFile:[basePath stringByAppendingPathComponent:name]];
	return content;
}


static NSDictionary *MergeShipData(NSDictionary *shipData, NSDictionary *shipDataOverrides)
{
	NSMutableDictionary		*mutableShipData = nil;
	NSEnumerator			*keyEnum = nil;
	NSString				*key = nil;
	NSDictionary			*baseDict = nil;
	NSDictionary			*overrideDict = nil;
	
	if (shipDataOverrides == nil)  return shipData;
	if (shipData == nil)  return shipDataOverrides;
	
	mutableShipData = [NSMutableDictionary dictionaryWithDictionary:shipData];
	for (keyEnum = [shipDataOverrides keyEnumerator]; key != nil; (key = [keyEnum nextObject]))
	{
		baseDict = [shipData objectForKey:key];
		overrideDict = [shipDataOverrides objectForKey:key];
		[mutableShipData setObject:MergeShipDataEntry(baseDict, overrideDict) forKey:key];
	}
	
	return mutableShipData;
}


static NSDictionary *MergeShipDataEntry(NSDictionary *baseDict, NSDictionary *overrideDict)
{
	NSMutableDictionary		*mutableEntry = nil;
	
	if (baseDict == nil)  return overrideDict;
	
	mutableEntry = [NSMutableDictionary dictionaryWithDictionary:baseDict];
	[mutableEntry addEntriesFromDictionary:overrideDict];
	
	return mutableEntry;
}


// Stuff lifted from messy files in Oolite

static NSDictionary *OOParseRolesFromString(NSString *string)
{
	NSMutableDictionary		*result = nil;
	NSArray					*tokens = nil;
	unsigned				i, count;
	NSString				*role = nil;
	float					probability;
	NSScanner				*scanner = nil;
	
	// Split string at spaces, sanity checks, set-up.
	if (string == nil)  return nil;
	
	tokens = ScanTokensFromString(string);
	count = [tokens count];
	if (count == 0)  return nil;
	
	result = [NSMutableDictionary dictionaryWithCapacity:count];
	
	// Scan tokens, looking for probabilities.
	for (i = 0; i != count; ++i)
	{
		role = [tokens objectAtIndex:i];
		
		probability = 1.0f;
		if ([role rangeOfString:@"("].location != NSNotFound)
		{
			scanner = [[NSScanner alloc] initWithString:role];
			[scanner scanUpToString:@"(" intoString:&role];
			[scanner scanString:@"(" intoString:NULL];
			if (![scanner scanFloat:&probability])	probability = 1.0f;
			// Ignore rest of string
			
			[scanner release];
		}
		
		if (0 <= probability)
		{
			[result setObject:[NSNumber numberWithFloat:probability] forKey:role];
		}
	}
	
	if ([result count] == 0)  result = nil;
	return result;
}


static NSMutableArray *ScanTokensFromString(NSString *values)
{
	NSMutableArray			*result = nil;
	NSScanner				*scanner = nil;
	NSString				*token = nil;
	static NSCharacterSet	*space_set = nil;
	
	if (values == nil)  return [NSArray array];
	if (space_set == nil) space_set = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
	
	result = [NSMutableArray array];
	scanner = [NSScanner scannerWithString:values];
	
	while (![scanner isAtEnd])
	{
		[scanner ooliteScanCharactersFromSet:space_set intoString:NULL];
		if ([scanner ooliteScanUpToCharactersFromSet:space_set intoString:&token])
		{
			[result addObject:token];
		}
	}
	
	return result;
}
