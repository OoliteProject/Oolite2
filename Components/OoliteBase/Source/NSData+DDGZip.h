/*
	NSData+DDGZip.h
	
	From http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html
	(with namespacing changes). No license specified, but trivial.
*/

#import <Foundation/Foundation.h>


@interface NSData (DDGZip)

// gzip compression utilities
- (NSData *) dd_gzipInflate;
- (NSData *) dd_gzipDeflate;

@end
