#import "OOVersion.h"
#import "OORevision.h"	// Auto-generated


NSArray *OoliteVersionComponents(void)
{
	static NSArray *versionComponents = nil;
	if (versionComponents == nil)
	{
		versionComponents = [OOComponentsFromVersionString(OoliteVersion()) retain];
	}
	return versionComponents;
}


NSUInteger OoliteRevisionNumber(void)
{
	return REVISION_NUMBER;
}


NSString *OoliteRevisionIdentifier(void)
{
	return @REVISION_IDENTIFIER;
}


NSString *OoliteBuildDate(void)
{
	return @BUILD_DATE;
}


NSString *OolitePlatformDescription(void)
{
	#if defined (__i386__)
		#define CPU_TYPE_STRING "x86-32"
	#elif defined (__x86_64__)
		#define CPU_TYPE_STRING "x86-64"
	#else
		#if OOLITE_BIG_ENDIAN
			#define CPU_TYPE_STRING "<unknown big-endian architecture>"
		#elif OOLITE_LITTLE_ENDIAN
			#define CPU_TYPE_STRING "<unknown little-endian architecture>"
		#else
			#define CPU_TYPE_STRING "<unknown architecture with unknown byte order>"
		#endif
	#endif
	
	#if OOLITE_MAC_OS_X
		#define OS_TYPE_STRING "Mac OS X"
	#elif OOLITE_WINDOWS
		#define OS_TYPE_STRING "Windows"
	#elif OOLITE_LINUX
		#define OS_TYPE_STRING "Linux"	// Hmm, what about other unices?
	#elif OOLITE_SDL
		#define OS_TYPE_STRING "unknown SDL system"
	#elif OOLITE_HAVE_APPKIT
		#define OS_TYPE_STRING "unknown AppKit system"
	#else
		#define OS_TYPE_STRING "unknown system"
	#endif
	
	#if OO_DEBUG
		#define RELEASE_VARIANT_STRING " debug"
	#elif !defined (NDEBUG)
		#define RELEASE_VARIANT_STRING " developer"
	#else
		#define RELEASE_VARIANT_STRING ""
	#endif
	
	#if OOLITE_MAC_OS_X
		NSString *systemString = [NSString stringWithFormat:@OS_TYPE_STRING " %@", [[NSProcessInfo processInfo] operatingSystemVersionString]];
	#else
		#define systemString @OS_TYPE_STRING
	#endif
	
	return [NSString stringWithFormat:@"%@ ("CPU_TYPE_STRING RELEASE_VARIANT_STRING")", systemString];
}


NSArray *OOComponentsFromVersionString(NSString *string)
{
	NSArray				*stringComponents = nil;
	NSMutableArray		*result = nil;
	unsigned			i, count;
	int					value;
	id					component;
	
	stringComponents = [string componentsSeparatedByString:@" "];
	stringComponents = [[stringComponents objectAtIndex:0] componentsSeparatedByString:@"-"];
	stringComponents = [[stringComponents objectAtIndex:0] componentsSeparatedByString:@"."];
	count = [stringComponents count];
	result = [NSMutableArray arrayWithCapacity:count];
	
	for (i = 0; i != count; ++i)
	{
		component = [stringComponents objectAtIndex:i];
		if ([component respondsToSelector:@selector(intValue)])  value = MAX([component intValue], 0);
		else  value = 0;
		
		[result addObject:[NSNumber numberWithUnsignedInt:value]];
	}
	
	return result;
}


NSComparisonResult OOCompareVersions(NSArray *version1, NSArray *version2)
{
	NSEnumerator		*leftEnum = nil,
	*rightEnum = nil;
	NSNumber			*leftComponent = nil,
	*rightComponent = nil;
	unsigned			leftValue,
	rightValue;
	
	leftEnum = [version1 objectEnumerator];
	rightEnum = [version2 objectEnumerator];
	
	for (;;)
	{
		leftComponent = [leftEnum nextObject];
		rightComponent = [rightEnum nextObject];
		
		if (leftComponent == nil && rightComponent == nil)  break;	// End of both versions
		
		// We'll get 0 if the component is nil, which is what we want.
		leftValue = [leftComponent unsignedIntValue];
		rightValue = [rightComponent unsignedIntValue];
		
		if (leftValue < rightValue) return NSOrderedAscending;
		if (leftValue > rightValue) return NSOrderedDescending;
	}
	
	// If there was a difference, we'd have returned already.
	return NSOrderedSame;
}
