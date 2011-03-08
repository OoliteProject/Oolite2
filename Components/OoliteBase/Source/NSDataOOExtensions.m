/*

NSDataOOExtensions.m


Copyright © 2011 Jens Ayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#import "NSDataOOExtensions.h"
#import "MYCollectionUtilities.h"
#import "OOBaseErrors.h"


@implementation NSData (OOExtensions)

+ (id) oo_dataWithContentsOfURL:(NSURL *)url options:(NSUInteger)readOptionsMask error:(NSError **)errorPtr
{
#if OOLITE_MAC_OS_X
	return [self dataWithContentsOfURL:url options:readOptionsMask error:errorPtr];
#else
	NSData *result = nil;
	if ((readOptionsMask & NSDataReadingMapped) && [url isFileURL])
	{
		result = [self dataWithContentsOfMappedFile:[url path]];
	}
	else
	{
		result = [self dataWithContentsOfURL:url];
	}
	
	if (result == nil && errorPtr != NULL)
	{
		*errorPtr = [NSError errorWithDomain:kOoliteBaseErrorDomain code:kOOBaseReadError userInfo:$dict(NSLocalizedFailureReasonErrorKey, $sprintf(@"Could not read file %@", [url path]))];
	}
	
	return result;
#endif
}

@end
