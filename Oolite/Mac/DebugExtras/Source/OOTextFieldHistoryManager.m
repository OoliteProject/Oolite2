/*
 
 OOTextFieldHistoryManager.m
 
 
 Oolite debug support
 
 Copyright (C) 2007 Jens Ayton
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
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

#import "OOTextFieldHistoryManager.h"
#import "OODebugUtilities.h"


@interface OOTextFieldHistoryManager (Private)

- (void)checkInvariant;
- (void)maintainInvariant;
- (void)moveHistoryCursorTo:(unsigned)newCursor fieldEditor:(NSTextView *)fieldEditor;
- (void)moveHistoryCursorBy:(int)offset fieldEditor:(NSTextView *)fieldEditor;

@end


@implementation OOTextFieldHistoryManager


- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
	if (control == textField)
	{
		if (commandSelector == @selector(moveToBeginningOfParagraph:) ||
			commandSelector == @selector(scrollPageUp:))
		{
			// Option-up arrow or page up. (For just up arrow, use moveUp:.)
			[self moveHistoryCursorBy:1 fieldEditor:textView];
			return YES;
		}
		else if (commandSelector == @selector(moveToEndOfParagraph:) ||
				 commandSelector == @selector(scrollPageDown:))
		{
			// Option-down arrow or page down. (For just down arrow, use moveDown:.)
			[self moveHistoryCursorBy:-1 fieldEditor:textView];
			return YES;
		}
	}
	return NO;
}


- (id)init
{
	self = [super init];
	if (self != nil)
	{
		_historyMaxSize = kDefaultHistorySize;
		_history = [[NSMutableArray alloc] initWithCapacity:kDefaultHistorySize];
		[self checkInvariant];
	}
	return self;
}


- (void)dealloc
{
	[_history release];
	
	[super dealloc];
}


- (NSArray *)history
{
	return [[_history copy] autorelease];
}


- (void)setHistory:(NSArray *)history
{
	if (history == nil)  [_history removeAllObjects];
	else
	{
		_history = [history mutableCopy];
		_historyCursor = 0;
		[self maintainInvariant];
	}
	[self checkInvariant];
}


- (void)addToHistory:(NSString *)string
{
	[self checkInvariant];
	
	if (_historyCurrSize == 0 || ![string isEqual:[_history objectAtIndex:_historyCurrSize - 1]])
	{
		[_history addObject:[[string copy] autorelease]];
	}
	_historyCursor = 0;
	[_latest release];
	_latest = nil;
	
	[self maintainInvariant];
}


- (unsigned)historySize
{
	return _historyMaxSize;
}


- (void)setHistorySize:(unsigned)size
{
	_historyMaxSize = size;
	[self maintainInvariant];
}

@end


@implementation OOTextFieldHistoryManager (Private)

- (void)checkInvariant
{
	NSAssert(_history != nil &&  // History buffer must exist
			 _historyCurrSize == [_history count] &&  // Size must be correct
			 ((_historyCurrSize <= _historyMaxSize) || (_historyMaxSize == 0)) &&  // Size must be in bounds
			 _historyCursor <= _historyCurrSize + 1,  // Cursor must be in bounds
			 @"Invalid history buffer state in OOTextFieldHistoryManager.");
}


- (void)maintainInvariant
{
	_historyCurrSize = [_history count];
	
	if (_historyMaxSize && (_historyMaxSize < _historyCurrSize))
	{
		[_history removeObjectsInRange:NSMakeRange(0, _historyCurrSize - _historyMaxSize)];
		_historyCurrSize = _historyMaxSize;
	}
	
	[self checkInvariant];
}


- (void)moveHistoryCursorTo:(unsigned)newCursor fieldEditor:(NSTextView *)fieldEditor
{
	NSString					*value = nil;
	NSTextStorage				*textStorage = nil;
	
	if (_historyCurrSize < newCursor)
	{
		NSBeep();
		return;
	}
	
	[self checkInvariant];
	textStorage = [fieldEditor textStorage];
	
	if (newCursor > 0)
	{
		unsigned index = _historyCurrSize - newCursor;
		value = [_history objectAtIndex:index];
		if (_historyCursor == 0)  _latest = [[textStorage string] copy];
	}
	else
	{
		value = [_latest autorelease];
		_latest = nil;
	}
	
	_historyCursor = newCursor;
	
	[textStorage setString:value];
	[textField selectText:self];
	
	[self checkInvariant];
}


- (void)moveHistoryCursorBy:(int)offset fieldEditor:(NSTextView *)fieldEditor
{
	// Range check
	if (((offset < 0) && (_historyCursor < (unsigned)-offset))	// Destination < 0
		|| (_historyCurrSize < (offset + _historyCursor)))	// Destination > _historyCurrSize
	{
		NSBeep();
		return;
	}
	[self moveHistoryCursorTo:_historyCursor + offset fieldEditor:fieldEditor];
}

@end