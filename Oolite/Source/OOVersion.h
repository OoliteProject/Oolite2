#import <OoliteBase/OoliteBase.h>


OOINLINE NSString *OoliteVersion(void) INLINE_PURE_FUNC;
OOINLINE NSString *OoliteVersion(void)
{
	return @OOLITE_VERSION;
}

NSArray *OoliteVersionComponents(void);


NSUInteger OoliteRevisionNumber(void);
NSString *OoliteRevisionIdentifier(void);	// Currently, Git revision hash.
NSString *OoliteBuildDate(void);
NSString *OolitePlatformDescription(void);


// Version handling utilities, should probably be moved to Base.

// Given a string of the form 1.2.3.4 (with arbitrarily many components), return an array of unsigned ints.
NSArray *OOComponentsFromVersionString(NSString *string);

/*	Compare two arrays of unsigned int NSNumbers, as returned by
	OOComponentsFromVersionString().
	
	Components are ordered from most to least significant, and a missing
	component is treated as 0. Thus "1.7" < "1.60", and "1.2.3.0" == "1.2.3".
*/
NSComparisonResult OOCompareVersions(NSArray *version1, NSArray *version2);

