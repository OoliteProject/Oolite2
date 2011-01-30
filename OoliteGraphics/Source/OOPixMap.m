/*

OOPixMap.c


Copyright (C) 2010 Jens Ayton

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

#import "OOPixMap.h"


const OOPixMap kOONullPixMap =
{
	.pixels = NULL,
	.width = 0,
	.height = 0,
	.format = kOOPixMapInvalidFormat,
	.rowBytes = 0,
	.bufferSize = 0
};


BOOL OOIsValidPixMap(OOPixMap pixMap)
{
	return	pixMap.pixels != NULL &&
			pixMap.width > 0 &&
			pixMap.height > 0 &&
			OOIsValidPixMapFormat(pixMap.format) &&
			pixMap.rowBytes >= pixMap.width * OOPixMapBytesPerPixelForFormat(pixMap.format) &&
			pixMap.bufferSize >= pixMap.rowBytes * pixMap.height;
}


OOPixMap OOMakePixMap(void *pixels, OOPixMapDimension width, OOPixMapDimension height, OOPixMapFormat format, size_t rowBytes, size_t bufferSize)
{
	if (rowBytes == 0)  rowBytes = width * OOPixMapBytesPerPixelForFormat(format);
	if (bufferSize == 0)  bufferSize = rowBytes * height;
	
	OOPixMap result =
	{
		.pixels = pixels,
		.width = width,
		.height = height,
		.format = format,
		.rowBytes = rowBytes,
		.bufferSize = bufferSize
	};
	
	if (OOIsValidPixMap(result))  return result;
	else  return kOONullPixMap;
}


OOPixMap OOAllocatePixMap(OOPixMapDimension width, OOPixMapDimension height, OOPixMapFormat format, size_t rowBytes, size_t bufferSize)
{
	// Create pixmap struct with dummy pixel pointer to test validity.
	OOPixMap pixMap = OOMakePixMap((void *)-1, width, height, format, rowBytes, bufferSize);
	if (EXPECT_NOT(!OOIsValidPixMap(pixMap)))  return kOONullPixMap;
	
	pixMap.pixels = malloc(pixMap.bufferSize);
	if (EXPECT_NOT(pixMap.pixels == NULL))  return kOONullPixMap;
	
	return pixMap;
}


void OOFreePixMap(OOPixMap *ioPixMap)
{
	if (EXPECT_NOT(ioPixMap == NULL))  return;
	
	free(ioPixMap->pixels);
	*ioPixMap = kOONullPixMap;
}


OOPixMap OODuplicatePixMap(OOPixMap srcPixMap, size_t desiredSize)
{
	if (EXPECT_NOT(!OOIsValidPixMap(srcPixMap)))  return kOONullPixMap;
	
	size_t minSize = OOMinimumPixMapBufferSize(srcPixMap);
	if (desiredSize < minSize)  desiredSize = minSize;
	
	OOPixMap result = OOAllocatePixMap(srcPixMap.width, srcPixMap.width, srcPixMap.format, srcPixMap.rowBytes, desiredSize);
	if (EXPECT_NOT(!OOIsValidPixMap(result)))  return kOONullPixMap;
	
	memcpy(result.pixels, srcPixMap.pixels, minSize);
	return result;
}


BOOL OOResizePixMap(OOPixMap *ioPixMap, size_t desiredSize)
{
	if (EXPECT_NOT(ioPixMap == NULL || !OOIsValidPixMap(*ioPixMap)))  return NO;
	if (desiredSize == ioPixMap->bufferSize)  return YES;
	if (desiredSize < OOMinimumPixMapBufferSize(*ioPixMap))  return NO;
	
	void *newPixels = realloc(ioPixMap->pixels, desiredSize);
	if (newPixels != NULL)
	{
		ioPixMap->pixels = newPixels;
		ioPixMap->bufferSize = desiredSize;
		return YES;
	}
	else
	{
		return NO;
	}
}


BOOL OOExpandPixMap(OOPixMap *ioPixMap, size_t desiredSize)
{
	if (EXPECT_NOT(ioPixMap == NULL || !OOIsValidPixMap(*ioPixMap)))  return NO;
	if (desiredSize <= ioPixMap->bufferSize)  return YES;
	
	return OOResizePixMap(ioPixMap, desiredSize);
}


#ifndef NDEBUG

#import "png.h"


static NSString *DefaultResolver(NSString *name, OOPixMap *pixMap)
{
	if (name == nil)  return nil;
	if (![[[name pathExtension] lowercaseString] isEqualToString:@"png"])  name = [name stringByAppendingPathExtension:@"png"];
	return [NSHomeDirectory() stringByAppendingPathComponent:name];
}


static NSString *(*sResolver)(NSString *name, OOPixMap *pixMap) = DefaultResolver;


void OOSetPixMapDumpPathResolver(NSString *(*resolver)(NSString *name, OOPixMap *pixMap))
{
	if (resolver != NULL)  sResolver = resolver;
	else  sResolver = DefaultResolver;
}


static void PNGError(png_structp png, png_const_charp message)
{
	NSString *name = png_get_io_ptr(png);
	OOLog(@"pixmap.dump.error", @"***** A PNG writing error occurred for %@: %s.", name, message);
}


static void PNGWarning(png_structp png, png_const_charp message)
{
	NSString *name = png_get_io_ptr(png);
	OOLog(@"pixmap.dump.warning", @"----- A PNG writing warning occurred for %@: %s.", name, message);
}


void OODumpPixMap(OOPixMap pixMap, NSString *name)
{
	if (!OOIsValidPixMap(pixMap))  return;
	name = sResolver(name, &pixMap);
	if (name == nil)  return;
	
	FILE *file = fopen([name UTF8String], "wb");
	if (file == NULL)
	{
		OOLog(@"pixmap.dump.error", @"***** Could not open file %@.", name);
		goto FAIL;
	}
	
	png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, name, PNGError, PNGWarning);
	png_infop pngInfo = NULL;
	if (png != NULL)  pngInfo = png_create_info_struct(png);
	if (pngInfo == NULL)
	{
		OOLog(@"pixmap.dump.error", @"***** Error preparing to write %@.", name);		
	}
	
	if (EXPECT_NOT(setjmp(png_jmpbuf(png))))
	{
		// libpng will jump here on error.
		goto FAIL;
	}
	
	png_init_io(png, file);
	
	int colorType;
	switch (pixMap.format)
	{
		case kOOPixMapGrayscale:
			colorType = PNG_COLOR_TYPE_GRAY;
			break;
			
		case kOOPixMapGrayscaleAlpha:
			colorType = PNG_COLOR_TYPE_GRAY_ALPHA;
			break;
			
		case kOOPixMapRGBA:
			colorType = PNG_COLOR_TYPE_RGB_ALPHA;
			break;
			
		default:
			OOLog(@"pixmap.dump.error", @"***** Can't write %@ from pixmap with unsupported colour format %@.", name, OOPixMapFormatName(pixMap.format));
			goto FAIL;
	}
	
	png_set_IHDR(png, pngInfo, pixMap.width, pixMap.height, 8, colorType, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
	png_write_info(png, pngInfo);
	
	for (OOPixMapDimension y = 0; y < pixMap.height; y++)
	{
		png_bytep row = (png_bytep)pixMap.pixels + pixMap.rowBytes * y;
		png_write_row(png, row);
	}
	
	png_write_end(png, pngInfo);
	
FAIL:
	png_destroy_write_struct(&png, &pngInfo);
	if (file != NULL)  fclose(file);
}

#endif


BOOL OOIsValidPixMapFormat(OOPixMapFormat format)
{
	switch (format)
	{
		case kOOPixMapInvalidFormat: return NO;
		case kOOPixMapGrayscale:
		case kOOPixMapGrayscaleAlpha:
		case kOOPixMapRGBA:
			return YES;
	}
	
	return NO;
}


#ifndef NDEBUG
size_t OOPixMapBytesPerPixelForFormat(OOPixMapFormat format)
{
	switch (format)
	{
		case kOOPixMapInvalidFormat: return 0;
		case kOOPixMapGrayscale: return 1;
		case kOOPixMapGrayscaleAlpha: return 2;
		case kOOPixMapRGBA: return 4;
	}
	
	[NSException raise:NSInvalidArgumentException format:@"Invalid pixel format %li.", (long)format];
	OO_UNREACHABLE();
	return -1;
}
#endif


NSString *OOPixMapFormatName(OOPixMapFormat format)
{
	switch (format)
	{
		case kOOPixMapInvalidFormat: return @"invalid";
		case kOOPixMapGrayscale: return @"grayscale";
		case kOOPixMapGrayscaleAlpha: return @"grayscale+alpha";
		case kOOPixMapRGBA: return @"RGBA";
	}
	
	return [NSString stringWithFormat:@"invalid<%i>", (int)format];
}



BOOL OOPixMapFormatHasAlpha(OOPixMapFormat format)
{
	switch (format)
	{
		case kOOPixMapInvalidFormat: return NO;
		case kOOPixMapGrayscale: return NO;
		case kOOPixMapGrayscaleAlpha: return YES;
		case kOOPixMapRGBA: return YES;
	}
	
	return NO;
}
