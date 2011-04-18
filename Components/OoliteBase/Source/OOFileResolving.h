/*
	OOFileResolving.h
	
	Abstraction of the process of looking up files.
	
	Objects which implement <OOFileResolving> provide an absolute path for a
	given file name and expected containing folder. The folder name may be nil.
	
	OOLoadFile() looks up a file with a given resolver, and attempts to read it.
	
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

- (NSString *) pathForFileNamed:(NSString *)name inFolder:(NSString *)folder;

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
