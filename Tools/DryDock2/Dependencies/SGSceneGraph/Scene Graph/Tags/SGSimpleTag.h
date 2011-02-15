/*
	SGSimpleTag.h
	
	Simple key-value implementation of SGSceneTag.
	
	
	Copyright © 2005-2008 Jens Ayton
	
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

#import "SGSceneTag.h"


@interface SGSimpleTag: SGSceneTag
{
	NSString				*_name;
	NSString				*_key;
	id						_value;
}

- (id)initWithKey:(NSString *)inKey andName:(NSString *)inName;
- (id)initWithKey:(NSString *)inKey;		// Name will be Localizable.strings version of key

@property (retain, nonatomic) id value;

// Conveniences
+ (id)tagWithKey:(NSString *)inKey value:(id)inValue;
+ (id)tagWithKey:(NSString *)inKey integerValue:(NSInteger)inValue;
+ (id)tagWithKey:(NSString *)inKey doubleValue:(double)inValue;
+ (id)tagWithKey:(NSString *)inKey boolValue:(bool)inValue;
- (id)initWithKey:(NSString *)inKey value:(id)inValue;
- (id)initWithKey:(NSString *)inKey integerValue:(NSInteger)inValue;
- (id)initWithKey:(NSString *)inKey doubleValue:(double)inValue;
- (id)initWithKey:(NSString *)inKey boolValue:(bool)inValue;

@property (nonatomic) NSInteger integerValue;
@property (nonatomic) double doubleValue;
@property (nonatomic) BOOL boolValue;

@end
