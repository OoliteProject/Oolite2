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


typedef enum OutFormat
{
	kFormatAuto,
	kFormatPList,
	kFormatBinaryPList,
	kFormatOOConf,
	kFormatJSON
} Format;


static void PrintUsageAndExit(const char *inCall) __attribute__((noreturn));
static Format FormatForName(NSString *fileName);
static NSString *FormatName(Format format);

static void Convert(NSString *inFile, Format inFormat, NSString *outFile, Format outFormat, BOOL compact) __attribute__((noreturn));
static id Load(NSString *inFile, Format inFormat);
static id Write(NSString *inFile, Format inFormat, id plistValue, BOOL compact) __attribute__((noreturn));

/*	Convert number literal strings to number objects.
	
	This is used for OpenStep format property lists, since they don't have a
	native distinction between strings and numbers.
 */
static id StringsToNumbers(id object);

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
								{ "plist",		no_argument,		NULL, 'P' },
								{ "bplist",		no_argument,		NULL, 'B' },
								{ "ooconf",		no_argument,		NULL, 'O' },
								{ "json",		no_argument,		NULL, 'J' },
								{ "compact",	no_argument,		NULL, 'c' },
								{ "help",		no_argument,		NULL, '?' }
							};
	
	BOOL					help = NO;
	BOOL					compact = NO;
	Format					outFormat = kFormatAuto;
	
	if (argc < 2)  PrintUsageAndExit(argv[0]);
	
	for (;;)
	{
		int option = getopt_long(argc, argv, "PBOJ?", longOpts, NULL);
		if (option == -1)  break;
		
		switch (option)
		{
			case 'P':
				outFormat = kFormatPList;
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
	
	Convert(inFile, inFormat, outFile, outFormat, compact);
	[pool drain];
	
	return EXIT_SUCCESS;
}


static Format FormatForName(NSString *fileName)
{
	NSString *extension = [[fileName pathExtension] lowercaseString];
	
	if ([extension isEqualToString:@"plist"])  return kFormatPList;
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
			
		case kFormatPList:
			return @"plist";
			
		case kFormatBinaryPList:
			return @"binary plist";
			
		case kFormatOOConf:
			return @"OOConf";
			
		case kFormatJSON:
			return @"JSON";
	}
	
	return $sprintf(@"unknown format %i", format);
}


static void Convert(NSString *inFile, Format inFormat, NSString *outFile, Format outFormat, BOOL compact)
{
	id plistValue = nil;
	
	@try
	{
		plistValue = Load(inFile, inFormat);
		if (plistValue == nil)
		{
			Fail(@"Loading failed, but didn't specify why.");
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
	NSData *data = [NSData dataWithContentsOfFile:inFile options:0 error:&error];
	if (data == nil)
	{
		Fail(@"Could not read input file. %@", error);
	}
	
	if (inFormat == kFormatPList || inFormat == kFormatBinaryPList)
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
	else if (inFormat == kFormatOOConf || inFormat == kFormatJSON)
	{
		Fail(@"Reading of %@ files is not yet supported.", FormatName(inFormat));
	}
	else
	{
		Fail(@"Internal error: invalid input format ID %i", inFormat);
	}
}


static id Write(NSString *inFile, Format inFormat, id plistValue, BOOL compact)
{
	NSData *data = nil;
	NSString *errDesc = nil;
	NSError *error = nil;
	
	if (inFormat == kFormatPList || inFormat == kFormatBinaryPList)
	{
		NSPropertyListFormat format = (inFormat == kFormatBinaryPList) ? NSPropertyListBinaryFormat_v1_0 : NSPropertyListXMLFormat_v1_0;
		data = [NSPropertyListSerialization dataFromPropertyList:plistValue format:format errorDescription:&errDesc];
	}
	else if (inFormat == kFormatOOConf || inFormat == kFormatJSON)
	{
		OOConfGenerationOptions options = kOOConfGenerationIgnoreInvalid;
		if (inFormat == kFormatJSON)  options |= kOOConfGenerationJSONCompatible;
		if (compact)  options |= kOOConfGenerationNoPrettyPrint;
		
		data = [plistValue ooConfDataWithOptions:options error:&error];
		if (data == nil)  errDesc = [error description];
	}
	
	if (data == nil)
	{
		Fail(@"Could not convert to %@ format. %@", FormatName(inFormat), errDesc);
	}
	
	if (![data writeToFile:inFile options:NSDataWritingAtomic error:&error])
	{
		Fail(@"Could not write output file. %@", error);
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


static void PrintUsageAndExit(const char *inCall)
{
	Print(@"Usage: %s [--plist|--bplist|--ooconf|--json] inputfile outputfile\n"
		  "%s --help", inCall, inCall);
	
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
	
	exit(EXIT_FAILURE);
}
