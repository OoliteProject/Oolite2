/*
	OOFileResolving.h
	
	Abstraction of the process of looking up and loading files.
	
	Objects which implement <OOFileResolving> can find and open a file with a
	given name and expected containing folder. The folder name may be nil.
	
	Because we will need to create aggregate resolvers to check multiple
	locations, the core contentsOfFile... method does not report “file not
	found” errors. The function OOLoadFile() attempts to load a file with a
	resolver, and if it fails and no messages have been added to the problem
	reporter, it adds a file not found message.
	
	OOSimpleFileResolver implements <OOFileResolving> by looking up the
	requested file within a base directory. The file may be found either in
	a subdirectory with the specified folder name, or in the root of the base
	directory.
	
	
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

#import "OOCocoa.h"

@protocol OOProblemReporting;


@protocol OOFileResolving <NSObject>

- (NSData *) contentsOfFileFileNamed:(NSString *)name
							inFolder:(NSString *)folder
					 problemReporter:(id <OOProblemReporting>)problemReporter;

@end


NSData *OOLoadFile(NSString *folder, NSString *name, id <OOFileResolving> fileResolver, id <OOProblemReporting> problemReporter);


@interface OOSimpleFileResolver: NSObject <OOFileResolving>
{
@private
    NSString				*_basePath;
}

- (id) initWithBasePath:(NSString *)basePath;

- (NSString *) basePath;

@end


/*
	OODisplayFileName()
	
	Returns a string of the form folder/file, or just file if folder is nil.
*/
NSString *OODisplayFileName(NSString *folder, NSString *name);
