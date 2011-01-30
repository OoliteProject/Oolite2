/*
	OOMeshReading.m
	
	
	Copyright © 2010 Jens Ayton.
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#import "OOMeshReading.h"

#import "OOMeshReader.h"
#import "OOJMeshReader.h"
#import "OODATReader.h"
#import "OOOBJReader.h"
#import "OOCTMReader.h"


Class OOSelectMeshReaderForExtension(NSString *fileNameExtension)
{
	if ([fileNameExtension isEqualToString:@"oomesh"])
	{
		return [OOMeshReader class];
	}
	else if ([fileNameExtension isEqualToString:@"oojmesh"])
	{
		return [OOJMeshReader class];
	}
#if !OOLITE_LEAN
	else if ([fileNameExtension isEqualToString:@"dat"])
	{
		return [OODATReader class];
	}
	else if ([fileNameExtension isEqualToString:@"obj"])
	{
		return [OOOBJReader class];
	}
	else if ([fileNameExtension isEqualToString:@"ctm"])
	{
		return [OOCTMReader class];
	}
#endif
	
	return Nil;
}


#if !OOLITE_LEAN
Class OOSelectMeshReaderForUTI(NSString *uti)
{
	if ([uti isEqualToString:@"org.oolite.oomesh"])
	{
		return [OOMeshReader class];
	}
	else if ([uti isEqualToString:@"org.oolite.oojmesh"])
	{
		return [OOJMeshReader class];
	}
	else if ([uti isEqualToString:@"org.aegidian.oolite.mesh"])
	{
		return [OODATReader class];
	}
	else if ([uti isEqualToString:@"com.newtek.lightwave.obj"])
	{
		return [OOOBJReader class];
	}
	else if ([uti isEqualToString:@"net.sf.openctm"])
	{
		return [OOCTMReader class];
	}
	
	return Nil;
}
#endif


id <OOMeshReading> OOReadMeshFromFile(NSString *path, id < OOProgressReporting> progressReporter, id <OOProblemReporting> issues)
{
	Class readerClass = OOSelectMeshReaderForExtension([[path pathExtension] lowercaseString]);
	return [[[readerClass alloc] initWithPath:path progressReporter:progressReporter issues:issues] autorelease];
}
