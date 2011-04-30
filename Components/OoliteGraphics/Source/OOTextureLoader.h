/*

OOTextureLoader.h

Abstract base class for asynchronous texture loaders, which are dispatched by
OOTextureLoadDispatcher. In general, this should be used through OOTexture.

Note: interface is likely to change in future to support other buffer types
(like S3TC/DXT#).


Copyright (C) 2007-2010 Jens Ayton

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

#import "OOTexture.h"
#import "OOPixMap.h"


@interface OOTextureLoader: NSOperation
{
@private
	NSString					*_name;
	
	uint32_t					_options;
	uint8_t						_generateMipMaps: 1,
								_scaleAsNormalMap: 1,
								_avoidShrinking: 1,
								_shrinkIfLarge: 1,
								_noScalingWhatsoever: 1,
								_allowCubeMap: 1,
								_isCubeMap: 1;
	
@protected
	id <OOProblemReporting>		_problemReporter;
	void						*_data;
	uint32_t					_width,
								_height,
								_rowBytes,
								_originalWidth,
								_originalHeight;
	OOTextureDataFormat			_format;
}

+ (id) loaderWithFileData:(NSData *)data
					 name:(NSString *)name
				  options:(OOTextureOptionFlags)options
		  problemReporter:(id <OOProblemReporting>)problemReporter;

/*	Return value indicates success. This may only be called once (subsequent
	attempts will return failure), and only on the main thread.
*/
- (BOOL) getResult:(OOPixMap *)result
			format:(OOTextureDataFormat *)outFormat
	 originalWidth:(uint32_t *)outWidth
	originalHeight:(uint32_t *)outHeight;

/*	Hopefully-unique string for texture loader; analagous, but not identical,
	to corresponding texture cacheKey.
*/
- (NSString *) cacheKey;

- (NSString *) name;



/*** Subclass interface; do not use on pain of pain. Unless you're subclassing. ***/

// Content sniffing.
+ (BOOL) canLoadData:(NSData *)data;

// Subclasses shouldn't do much on init, because of the whole asynchronous thing.
- (id) initWithData:(NSData *)data
			   name:(NSString *)name
			options:(OOTextureOptionFlags)options
	problemReporter:(id <OOProblemReporting>)problemReporter;


/*	Load data, setting up _data, _format, _width, and _height; also _rowBytes
	if it's not _width * OOTextureComponentsForFormat(_format), and
	_originalWidth/_originalHeight if _width and _height for some reason aren't
	the original pixel dimensions.
	
	Thread-safety concerns: this will be called in a worker thread, and there
	may be several worker threads. The caller takes responsibility for
	autorelease pools and exception safety.
	
	Superclass will handle scaling and mip-map generation. Data must be
	allocated with malloc() family.
*/
- (void) loadTexture;

@end
