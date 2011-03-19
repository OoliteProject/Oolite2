/*
	ooconftool
	
	Tool to test OOConf import/export. It can read any plist format, and write
	OOConf, JSON, XML plists or binary plists.
	
	Note that not all data is portable between formats: plists don’t
	(officially) support nulls, and OOConf/JSON doesn’t support dates or
	binary data. Unsupported plist types will cause an error, and unsupported
	JSON types will be encoded as nulls.
*/

#import <OoliteBase/OoliteBase.h>
#import <getopt.h>
#import "OldSchoolPropertyListWriting.h"


typedef enum OutFormat
{
	kFormatAuto,
	kFormatAnyPList,
	kFormatOpenStepPList,
	kFormatXMLPList,
	kFormatBinaryPList,
	kFormatOOConf,
	kFormatJSON
} Format;


static void PrintUsageAndExit(const char *inCall) __attribute__((noreturn));
static Format FormatForName(NSString *fileName);
static NSString *FormatName(Format format);
static BOOL IsPListFormat(Format format);

static void Convert(NSString *inFile, Format inFormat, NSString *outFile, Format outFormat, BOOL compact, BOOL nullToString) __attribute__((noreturn));
static id Load(NSString *inFile, Format inFormat);
static void Write(NSString *inFile, Format inFormat, id plistValue, BOOL compact) __attribute__((noreturn));


/*	Convert number literal strings to number objects.
	
	This is used for OpenStep format property lists, since they don't have a
	native distinction between strings and numbers.
 */
static id StringsToNumbers(id object);


/*	Convert NSNulls to @"null".
*/
static id NullsToStrings(id object);

static void Print(NSString *format, ...);
static void Printv(NSString *format, va_list inArgs);
static void EPrint(NSString *format, ...) __attribute__((unused));
static void EPrintv(NSString *format, va_list inArgs);
static void Fail(NSString *format, ...) __attribute__((noreturn));


int main (int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	const struct option		longOpts[] =
							{
								{ "plist",			no_argument,	NULL, 'P' },
								{ "openstep-plist",	no_argument,	NULL, 'T' },
								{ "xml-plist",		no_argument,	NULL, 'X' },
								{ "binary-plist",	no_argument,	NULL, 'B' },
								{ "ooconf",			no_argument,	NULL, 'O' },
								{ "json",			no_argument,	NULL, 'J' },
								{ "compact",		no_argument,	NULL, 'c' },
								{ "null-to-string",	no_argument,	NULL, 'n' },
								{ "help",			no_argument,	NULL, '?' }
							};
	
	BOOL					help = NO;
	BOOL					compact = NO;
	BOOL					nullToString = NO;
	Format					outFormat = kFormatAuto;
	
	if (argc < 2)  PrintUsageAndExit(argv[0]);
	
	for (;;)
	{
		int option = getopt_long(argc, argv, "PTXBOJcn?", longOpts, NULL);
		if (option == -1)  break;
		
		switch (option)
		{
			case 'P':
				outFormat = kFormatAnyPList;
				break;
				
			case 'T':
				outFormat = kFormatOpenStepPList;
				break;
				
			case 'X':
				outFormat = kFormatXMLPList;
				break;
				
			case 'B':
				outFormat = kFormatBinaryPList;
				break;
				
			case 'O':
				outFormat = kFormatOOConf;
				break;
				
			case 'J':
				outFormat = kFormatJSON;
				break;
				
			case 'c':
				compact = YES;
				break;
				
			case 'n':
				nullToString = YES;
				break;
				
			case '?':
				help = YES;
				break;
		}
	}
	
	if (argc != optind + 2)  PrintUsageAndExit(argv[0]);
	
	NSString *inFile = [NSString stringWithUTF8String:argv[optind]];
	Format inFormat = FormatForName(inFile);
	if (inFormat == kFormatAuto)
	{
		Fail(@"Cannot determine type for input file %@.", inFile);
	}
	
	NSString *outFile = [NSString stringWithUTF8String:argv[optind + 1]];
	if (outFormat == kFormatAuto)
	{
		outFormat = FormatForName(outFile);
		if (outFormat == kFormatAuto)
		{
			Fail(@"Cannot determine type for output file %@.", outFile);
		}
	}
	
	inFile = [[[inFile stringByStandardizingPath] stringByExpandingTildeInPath] stringByResolvingSymlinksInPath];
	outFile = [[[outFile stringByStandardizingPath] stringByExpandingTildeInPath] stringByResolvingSymlinksInPath];
	
	Convert(inFile, inFormat, outFile, outFormat, compact, nullToString);
	[pool drain];
	
	return EXIT_SUCCESS;
}


static Format FormatForName(NSString *fileName)
{
	NSString *extension = [[fileName pathExtension] lowercaseString];
	
	if ([extension isEqualToString:@"plist"])  return kFormatAnyPList;
	if ([extension isEqualToString:@"ooconf"])  return kFormatOOConf;
	if ([extension isEqualToString:@"oomesh"])  return kFormatOOConf;
	if ([extension isEqualToString:@"json"])  return kFormatJSON;
	
	return kFormatAuto;
}


static NSString *FormatName(Format format)
{
	switch (format)
	{
		case kFormatAuto:
			return @"auto";
			
		case kFormatAnyPList:
			return @"plist";
			
		case kFormatOpenStepPList:
			return @"OpenStep plist";
			
		case kFormatXMLPList:
			return @"XML plist";
			
		case kFormatBinaryPList:
			return @"binary plist";
			
		case kFormatOOConf:
			return @"OOConf";
			
		case kFormatJSON:
			return @"JSON";
	}
	
	return $sprintf(@"unknown format %i", format);
}


static BOOL IsPListFormat(Format format)
{
	switch (format)
	{
		case kFormatAnyPList:
		case kFormatOpenStepPList:
		case kFormatXMLPList:
		case kFormatBinaryPList:
			return YES;
			
		case kFormatAuto:
		case kFormatOOConf:
		case kFormatJSON:
			break;
	}
	return NO;
}


static void Convert(NSString *inFile, Format inFormat, NSString *outFile, Format outFormat, BOOL compact, BOOL nullToString)
{
	id plistValue = nil;
	
	@try
	{
		plistValue = Load(inFile, inFormat);
		if (plistValue == nil)
		{
			Fail(@"Loading failed, but didn't specify why.");
		}
		
		if (nullToString)
		{
			plistValue = NullsToStrings(plistValue);
		}
		
		Write(outFile, outFormat, plistValue, compact);
	}
	@catch (NSException *exception)
	{
		Fail(@"Conversion failed due to an unhandled exception: %@", [exception reason]);
	}
}


static id Load(NSString *inFile, Format inFormat)
{
	NSError *error = nil;
	NSData *data = [NSData oo_dataWithContentsOfFile:inFile options:0 error:&error];
	if (data == nil)
	{
		Fail(@"Could not read input file. %@", error);
	}
	
	if (IsPListFormat(inFormat))
	{
		NSString *errDesc = nil;
		// This method is discouraged in Mac OS X and will probably be deprecated in 10.7, but the replacement isn't in GNUstep 1.20.1.
		NSPropertyListFormat format;
		id result = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainers format:&format errorDescription:&errDesc];
		if (result == nil)
		{
			Fail(@"Input file could not be interpreted as a property list file. %@", errDesc);
		}
		
		if (format == NSPropertyListOpenStepFormat)
		{
			result = StringsToNumbers(result);
		}
		
		return result;
	}
	else if (inFormat == kFormatOOConf)
	{
		OOSimpleProblemReportManager *issues = [[OOSimpleProblemReportManager alloc] initWithContextString:$sprintf(@"Loading %@:", inFile) messageClassPrefix:@""];
		
		id result = [NSObject objectWithContentsOfOOConfURL:[NSURL fileURLWithPath:inFile] problemReporter:issues];
		if (result == nil)  exit(EXIT_FAILURE);
		
		[issues release];
		
		return result;
	}
	else if (inFormat == kFormatJSON)
	{
		NSString *string = [NSString oo_stringWithContentsOfUnicodeFile:inFile];
		if (string == nil)
		{
			Fail(@"Could not read input file.");
		}
		
		OOSimpleProblemReportManager *issues = [[OOSimpleProblemReportManager alloc] initWithContextString:$sprintf(@"Loading %@:", inFile) messageClassPrefix:@""];
		
		id result = [NSObject objectFromOOConfString:string problemReporter:issues];
		if (result == nil)  exit(EXIT_FAILURE);
		
		[issues release];
		
		return result;
	}
	else
	{
		Fail(@"Internal error: invalid input format ID %i", inFormat);
	}
}


static NSData *ConvertToOpenStepPList(id plistValue, NSString **errDesc)
{
	return [plistValue oldSchoolPListFormatWithErrorDescription:errDesc];
}


static NSData *ConvertToXMLPList(id plistValue, NSString **errDesc)
{
	return [NSPropertyListSerialization dataFromPropertyList:plistValue format:NSPropertyListXMLFormat_v1_0 errorDescription:errDesc];
}


static NSData *ConvertToBinaryPList(id plistValue, NSString **errDesc)
{
	return [NSPropertyListSerialization dataFromPropertyList:plistValue format:NSPropertyListBinaryFormat_v1_0 errorDescription:errDesc];
}


static NSData *ConvertToAnyPList(id plistValue, NSString **errDesc)
{
	NSData *result = ConvertToOpenStepPList(plistValue, errDesc);
	if (result == nil)  result = ConvertToXMLPList(plistValue, errDesc);
	if (result == nil)  result = ConvertToBinaryPList(plistValue, errDesc);
	return result;
}



static void Write(NSString *inFile, Format inFormat, id plistValue, BOOL compact)
{
	NSData *data = nil;
	NSError *error = nil;
	NSString *errDesc = nil;
	
	
	OOConfGenerationOptions options = kOOConfGenerationIgnoreInvalid;
	if (compact)  options |= kOOConfGenerationNoPrettyPrint;
	
	switch (inFormat)
	{
		case kFormatAuto:
			break;
			
		case kFormatAnyPList:
			data = ConvertToAnyPList(plistValue, &errDesc);
			break;
			
		case kFormatOpenStepPList:
			data = ConvertToOpenStepPList(plistValue, &errDesc);
			break;
			
		case kFormatXMLPList:
			data = ConvertToXMLPList(plistValue, &errDesc);
			break;
			
		case kFormatBinaryPList:
			data = ConvertToBinaryPList(plistValue, &errDesc);
			break;
			
		case kFormatJSON:
			options |= kOOConfGenerationJSONCompatible;
			// Fall through.
			
		case kFormatOOConf:
		{
			data = [plistValue ooConfDataWithOptions:options error:&error];
			if (data == nil)
			{
				errDesc = [error localizedFailureReason];
				if (errDesc == nil)  errDesc = [error localizedDescription];
			}
		}
	}
	
	if (data == nil)
	{
		Fail(@"Could not convert to %@ format. %@", FormatName(inFormat), errDesc);
	}
	
	if (![data writeToFile:inFile options:NSDataWritingAtomic error:&error])
	{
		Fail(@"Could not write output file. %@", [error localizedFailureReason] ?: [error localizedDescription]);
	}
	
	exit(EXIT_SUCCESS);
}


static id StringsToNumbers(id object)
{
	if ([object isKindOfClass:[NSDictionary class]])
	{
		NSArray *keys = [object allKeys];
		id key = nil;
		foreach (key, keys)
		{
			id oldValue = [object objectForKey:key];
			id newValue = StringsToNumbers(oldValue);
			if (newValue != oldValue)  [object setObject:newValue forKey:key];
		}
	}
	else if ([object isKindOfClass:[NSArray class]])
	{
		NSUInteger i, count = [object count];
		for (i = 0; i < count; i++)
		{
			id oldValue = [object objectAtIndex:i];
			id newValue = StringsToNumbers(oldValue);
			if (newValue != oldValue)  [object replaceObjectAtIndex:i withObject:newValue];
		}
	}
	else if ([object isKindOfClass:[NSString class]])
	{
		if (OOIsNumberLiteral(object, NO))
		{
			if ([object rangeOfString:@"."].location == NSNotFound)
			{
				object = [NSNumber numberWithLongLong:[object longLongValue]];
			}
			else
			{
				object = [NSNumber numberWithDouble:[object doubleValue]];
			}

		}
	}
	return object;
}


static id NullsToStrings(id object)
{
	if ([object isKindOfClass:[NSDictionary class]])
	{
		NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[object count]];
		id key = nil;
		foreachkey (key, object)
		{
			id oldValue = [object objectForKey:key];
			id newValue = NullsToStrings(oldValue);
			[result setObject:newValue forKey:key];
		}
		object = result;
	}
	else if ([object isKindOfClass:[NSArray class]])
	{
		NSMutableArray *result = [NSMutableArray arrayWithCapacity:[object count]];
		id oldValue = nil;
		foreach (oldValue, object)
		{
			id newValue = NullsToStrings(oldValue);
			[result addObject:newValue];
		}
		object = result;
	}
	else if (object == [NSNull null])
	{
		object = @"null";
	}
	return object;
}


static void PrintUsageAndExit(const char *inCall)
{
	Print(@"Usage: %s [--plist|--bplist|--ooconf|--json] inputfile outputfile\n"
		  "%s --help\n", inCall, inCall);
	
	exit(EXIT_SUCCESS);
}


void Print(NSString *format, ...)
{
	va_list				args;
	
	va_start(args, format);
	Printv(format, args);
	va_end(args);
}


void Printv(NSString *format, va_list inArgs)
{
	NSString			*string;
	NSData				*data;
	
	string = [[NSString alloc] initWithFormat:format arguments:inArgs];
	data = [string dataUsingEncoding:NSUTF8StringEncoding];
	fwrite([data bytes], 1, [data length], stdout);
	[string release];
}



void EPrint(NSString *format, ...)
{
	va_list				args;
	
	va_start(args, format);
	EPrintv(format, args);
	va_end(args);
}


void EPrintv(NSString *format, va_list inArgs)
{
	NSString			*string;
	NSData				*data;
	
	string = [[NSString alloc] initWithFormat:format arguments:inArgs];
	data = [string dataUsingEncoding:NSUTF8StringEncoding];
	fwrite([data bytes], 1, [data length], stderr);
	[string release];
}


static void Fail(NSString *format, ...)
{
	va_list				args;
	
	va_start(args, format);
	EPrintv(format, args);
	va_end(args);
	EPrint(@"\n");
	
	exit(EXIT_FAILURE);
}
