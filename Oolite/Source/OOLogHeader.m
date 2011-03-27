/*

OOLogHeader.m


Copyright (C) 2007-2011 Jens Ayton and contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import "OOLogHeader.h"
#import "Universe.h"
#import "OOStellarBody.h"
#import "OOJavaScriptEngine.h"
#import "OOVersion.h"


static NSString *AdditionalSystemInfo(void);

NSString *OOPlatformDescription(void);


void OOPrintLogHeader(void)
{
	NSArray *featureStrings = [NSArray arrayWithObjects:
	// User features
	#if NEW_PLANETS
		@"new planets",
	#endif
	
	#if OOLITE_MAC_OS_X || defined(HAVE_LIBESPEAK)
		@"spoken messages",
	#endif
	
	#if MASS_DEPENDENT_FUEL_PRICES
		@"mass/fuel pricing",
	#endif
	
	// Debug features
	#if OO_CHECK_GL_HEAVY
		@"heavy OpenGL error checking",
	#endif
	
	#ifndef OO_EXCLUDE_DEBUG_SUPPORT
		@"JavaScript console support",
		#if OOLITE_MAC_OS_X
			// Under Mac OS X, Debug.oxp adds more than console support.
			@"Debug plug-in support",
		#endif
	#endif
	
	#if OO_LOCALIZATION_TOOLS
		@"localization tools",
	#endif
	
	#if DEBUG_GRAPHVIZ
		@"debug GraphViz support",
	#endif
	
	#if OOJS_PROFILE
		#ifdef MOZ_TRACE_JSCALLS
			@"JavaScript profiling",
		#else
			@"JavaScript native callback profiling",
		#endif
	#endif
	
		nil];
	
	
	NSMutableString *headerString = [NSMutableString string];
	[headerString appendFormat:@"Opening log on %@\n", [NSDate date]]; 
	[headerString appendFormat:@"Oolite version: %@ (revision %u built on %@, ID: %@)\n", OoliteVersion(), OoliteRevisionNumber(), OoliteBuildDate(), OoliteRevisionIdentifier()];
	[headerString appendFormat:@"System: %@; %@\n", OolitePlatformDescription(), AdditionalSystemInfo()];
	
	NSString *featureDesc = [featureStrings componentsJoinedByString:@", "];
	if ([featureDesc length] == 0)  featureDesc = @"none";
	[headerString appendFormat:@"\nBuild options: %@.\n", featureDesc];
	
	[headerString appendString:@"\nNote that the contents of the log file can be adjusted by editing logcontrol.plist."];
	
	OOLog(@"log.header", @"%@\n", headerString);
}


// System-specific stuff to append to log header.
#if OOLITE_MAC_OS_X
#include <sys/sysctl.h>


static NSString *GetSysCtlString(const char *name);
static unsigned long long GetSysCtlInt(const char *name);
static NSString *GetCPUDescription(void);

static NSString *AdditionalSystemInfo(void)
{
	NSString				*sysModel = nil;
	unsigned long long		sysPhysMem;
	
	sysModel = GetSysCtlString("hw.model");
	sysPhysMem = GetSysCtlInt("hw.memsize");
	
	return [NSString stringWithFormat:@"%@, %llu MiB memory, %@", sysModel, sysPhysMem >> 20, GetCPUDescription()];
}


static NSString *GetCPUDescription(void)
{
	unsigned long long	sysCPUType, sysCPUSubType, sysCPUFamily,
						sysCPUFrequency, sysCPUCount;
	NSString			*typeStr = nil, *subTypeStr = nil;
	
	sysCPUType = GetSysCtlInt("hw.cputype");
	sysCPUSubType = GetSysCtlInt("hw.cpusubtype");
	sysCPUFamily = GetSysCtlInt("hw.cpufamily");
	sysCPUFrequency = GetSysCtlInt("hw.cpufrequency");
	sysCPUCount = GetSysCtlInt("hw.logicalcpu");
	
	/*	Note: CPU_TYPE_STRING tells us the build architecture. This gets the
		physical CPU type. They may differ, for instance, when running under
		Rosetta. The code is written for flexibility, although ruling out
		x86 code running on PPC would be entirely reasonable.
	*/
	switch (sysCPUType)
	{
		case CPU_TYPE_POWERPC:
			typeStr = @"PowerPC";
			switch (sysCPUSubType)
			{
				case CPU_SUBTYPE_POWERPC_750:
					subTypeStr = @" G3 (750)";
					break;
					
				case CPU_SUBTYPE_POWERPC_7400:
					subTypeStr = @" G4 (7400)";
					break;
					
				case CPU_SUBTYPE_POWERPC_7450:
					subTypeStr = @" G4 (7450)";
					break;
					
				case CPU_SUBTYPE_POWERPC_970:
					subTypeStr = @" G5 (970)";
					break;
				
				default:
					subTypeStr = [NSString stringWithFormat:@":%u", sysCPUSubType];
			}
			break;
			
		case CPU_TYPE_I386:
			typeStr = @"x86";
			switch (sysCPUFamily)
			{
				case CPUFAMILY_INTEL_6_13:
					subTypeStr = @" (Intel 6:13)";
					break;
					
				case CPUFAMILY_INTEL_YONAH:
					subTypeStr = @" (Core/Yonah)";
					break;
					
				case CPUFAMILY_INTEL_MEROM:
					subTypeStr = @" (Core 2/Merom)";
					break;
					
				case CPUFAMILY_INTEL_PENRYN:
					subTypeStr = @" (Penryn)";
					break;
					
				case CPUFAMILY_INTEL_NEHALEM:
					subTypeStr = @" (Nehalem)";
					break;
					
				case CPUFAMILY_INTEL_WESTMERE:
					subTypeStr = @" (Westmere)";
					break;
					
				default:
					subTypeStr = [NSString stringWithFormat:@" (family %x)", sysCPUFamily];
			}
			break;
		
		case CPU_TYPE_ARM:
			typeStr = @"ARM";
			switch (sysCPUSubType)
			{
				case CPU_SUBTYPE_ARM_V4T:
					subTypeStr = @" v4T";
					break;
					
				case CPU_SUBTYPE_ARM_V6:
					subTypeStr = @"v6";		// No space
					break;
			}
			if (subTypeStr == nil)
			{
				switch (sysCPUFamily)
				{
					case CPUFAMILY_ARM_9:
						subTypeStr = @"9";	// No space
						break;
						
					case CPUFAMILY_ARM_11:
						subTypeStr = @"11";	// No space
						break;
						
					case CPUFAMILY_ARM_XSCALE:
						subTypeStr = @" XScale";
						break;
						
					case CPUFAMILY_ARM_13:
						subTypeStr = @"13";	// No such thing?
						break;
					
					default:
						subTypeStr = [NSString stringWithFormat:@" (family %u)", sysCPUFamily];
				}
			}
	}
	
	if (typeStr == nil)  typeStr = [NSString stringWithFormat:@"%u", sysCPUType];
	
	return [NSString stringWithFormat:@"%llu x %@%@ @ %llu MHz", sysCPUCount, typeStr, subTypeStr, (sysCPUFrequency + 500000) / 1000000];
}


static NSString *GetSysCtlString(const char *name)
{
	char					*buffer = NULL;
	size_t					size = 0;
	
	// Get size
	sysctlbyname(name, NULL, &size, NULL, 0);
	if (size == 0)  return nil;
	
	buffer = alloca(size);
	if (sysctlbyname(name, buffer, &size, NULL, 0) != 0)  return nil;
	return [NSString stringWithUTF8String:buffer];
}


static unsigned long long GetSysCtlInt(const char *name)
{
	unsigned long long		llresult = 0;
	unsigned int			intresult = 0;
	size_t					size;
	
	size = sizeof llresult;
	if (sysctlbyname(name, &llresult, &size, NULL, 0) != 0)  return 0;
	if (size == sizeof llresult)  return llresult;
	
	size = sizeof intresult;
	if (sysctlbyname(name, &intresult, &size, NULL, 0) != 0)  return 0;
	if (size == sizeof intresult)  return intresult;
	
	return 0;
}

#else
static NSString *AdditionalSystemInfo(void)
{
	unsigned cpuCount = OOCPUCount();
	return [NSString stringWithFormat:@"%u processor%@", cpuCount, cpuCount != 1 ? @"s" : @""];
}
#endif
