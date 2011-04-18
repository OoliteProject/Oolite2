/*
	OOFileResolving.m
	
	
	Copyright © 2011 Jens Ayton
	
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

#import "OOFileResolving.h"
#import "OOProblemReporting.h"
#import "NSDataOOExtensions.h"
#import "MYCollectionUtilities.h"


static NSString *FileName(NSString *folder, NSString *name)
{
	if (folder == nil)  return name;
	return $sprintf(@"%@/%@", folder, name);
}


NSData *OOLoadFile(NSString *folder, NSString *name, id <OOFileResolving> resolver, id <OOProblemReporting> problemReporter)
{
	NSString *path = [resolver pathForFileNamed:name inFolder:folder];
	if (path == nil)
	{
		OOReportError(problemReporter, @"Could not find file %@.", FileName(folder, name));
		return nil;
	}
	
	NSError *error = nil;
	NSData *result = [NSData oo_dataWithContentsOfFile:path options:NSDataReadingMapped error:&error];
	if (result == nil)
	{
		OOReportNSError(problemReporter, $sprintf(OOLocalizeProblemString(problemReporter, @"Could not load file %@"), FileName(folder, name)), error);
	}
	
	return result;
}


@implementation OOSimpleFileResolver

- (id) initWithBasePath:(NSString *)basePath
{
    if ((self = [super init]))
	{
		_basePath = [basePath copy];
		if (_basePath == nil)  DESTROY(self);
    }
    
    return self;
}


- (void) dealloc
{
	DESTROY(_basePath);
	
    [super dealloc];
}


- (NSString *) descriptionComponents
{
	return _basePath;
}


- (NSString *) basePath
{
	return _basePath;
}


- (NSString *) pathForFileNamed:(NSString *)name inFolder:(NSString *)folder
{
	NSString *result = nil;
	if (name != nil)
	{
		NSFileManager *fmgr = [NSFileManager defaultManager];
		
		if (folder != nil)
		{
			result = [[_basePath stringByAppendingPathComponent:folder] stringByAppendingPathComponent:name];
			if (![fmgr fileExistsAtPath:result])  result = nil;
		}
		if (result == nil)
		{
			result = [_basePath stringByAppendingPathComponent:name];
			if (![fmgr fileExistsAtPath:result])  result = nil;
		}
	}
	
	return result;
}

@end
