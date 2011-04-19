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


/*
	OOErrorDetectingProblemReporter wraps a “real” problem reporter and keeps
	track of whether any errors have been reported.
*/
@interface OOErrorDetectingProblemReporter: NSObject <OOProblemReporting>
{
@private
	id <OOProblemReporting>			_underlyingProblemReporter;
	BOOL							_hadError;
}

- (id) initWithProblemReporter:(id <OOProblemReporting>)problemReporter;
- (BOOL) hadError;

@end


NSData *OOLoadFile(NSString *folder, NSString *name, id <OOFileResolving> resolver, id <OOProblemReporting> problemReporter)
{
	NSCParameterAssert(name != nil && resolver != nil);
	
	OOErrorDetectingProblemReporter *problemReporterWrapper = [[OOErrorDetectingProblemReporter alloc] initWithProblemReporter:problemReporter];
	
	NSData *data = [resolver contentsOfFileFileNamed:name inFolder:folder problemReporter:problemReporterWrapper];
	
	if (data == nil && ![problemReporterWrapper hadError])
	{
		OOReportError(problemReporter, $sprintf(OOLocalizeProblemString(problemReporter, @"Could not load file %@"), OODisplayFileName(folder, name)));
	}
	
	return data;
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


- (NSData *) contentsOfFileFileNamed:(NSString *)name
							inFolder:(NSString *)folder
					 problemReporter:(id <OOProblemReporting>)problemReporter
{
	NSString *path = nil;
	if (name != nil)
	{
		NSFileManager *fmgr = [NSFileManager defaultManager];
		
		if (folder != nil)
		{
			path = [[_basePath stringByAppendingPathComponent:folder] stringByAppendingPathComponent:name];
			if (![fmgr fileExistsAtPath:path])  path = nil;
		}
		if (path == nil)
		{
			path = [_basePath stringByAppendingPathComponent:name];
			if (![fmgr fileExistsAtPath:path])  path = nil;
		}
	}
	
	if (path == nil)  return nil;
	
	NSError *error = nil;
	NSData *result = [NSData oo_dataWithContentsOfFile:path options:NSDataReadingMapped error:&error];
	if (result == nil)
	{
		OOReportNSError(problemReporter, $sprintf(OOLocalizeProblemString(problemReporter, @"Could not load file %@"), OODisplayFileName(folder, name)), error);
	}
	
	return result;
}

@end


@implementation OOErrorDetectingProblemReporter

- (id) initWithProblemReporter:(id <OOProblemReporting>)problemReporter
{
	if ((self = [super init]))
	{
		_underlyingProblemReporter = [problemReporter retain];
	}
	
	return self;
}


- (void) dealloc
{
	[_underlyingProblemReporter release];
	
	[super dealloc];
}


- (BOOL) hadError
{
	return _hadError;
}


- (void) addProblemOfType:(OOProblemReportType)type message:(NSString *)message
{
	if (type == kOOProblemTypeError)  _hadError = YES;
	return [_underlyingProblemReporter addProblemOfType:type message:message];
}


- (NSString *) localizedProblemStringForKey:(NSString *)string
{
	return [_underlyingProblemReporter localizedProblemStringForKey:string];
}

@end


NSString *OODisplayFileName(NSString *folder, NSString *name)
{
	if (folder == nil)  return name;
	return $sprintf(@"%@/%@", folder, name);
}
