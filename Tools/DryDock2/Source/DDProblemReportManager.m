//
//  DDProblemReportManager.m
//  DryDock2
//
//  Created by Jens Ayton on 2010-07-21.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "DDProblemReportManager.h"
#import "IconFamily.h"

enum
{
	kMinHeight = 42,
	kMaxHeight = 480,
	kHeightPadding = 8
};


// Immutable container for an issue.
@interface DDProblemReportIssue: NSObject
{
@private
	OOProblemReportType		_type;
	NSString				*_message;
}

- (id) initWithType:(OOProblemReportType)type message:(NSString *)message;

@property (readonly) OOProblemReportType type;
@property (readonly, copy) NSString *message;

@end


@interface DDProblemReportManager ()

// If preparing dialog fails or problem count is 0, -priv_prepareDialog returns NO and default result is used.
- (BOOL) priv_prepareDialog;
- (BOOL) priv_defaultResult;
- (void) priv_teardownDialog;

- (NSImage *) priv_noteIcon;
- (NSImage *) priv_warningIcon;
- (NSImage *) priv_errorIcon;

@end


@implementation DDProblemReportManager

@synthesize context = _context;
@synthesize fileURL = _fileURL;
@synthesize highestProblemType = _highestType;
@synthesize problems = _problems;


- (id) initWithContext:(DDProblemReportContext)context fileURL:(NSURL *)url
{
	if ((self = [super init]))
	{
		_context = context;
		_fileURL = url;
	}
	return self;
}


- (NSUInteger) problemCount
{
	return [_problems count];
}


- (BOOL) haveErrors
{
	return self.problemCount > 0 && self.highestProblemType >= kOOProblemTypeError;
}


#pragma mark OOProblemReporting

- (void) addProblemOfType:(OOProblemReportType)type message:(NSString *)message
{
	if (_problems == nil)  _problems = [NSMutableArray array];
	[_problems addObject:[[DDProblemReportIssue alloc] initWithType:type message:message]];
	if (_highestType < type)  _highestType = type;
}


- (NSString *) localizedProblemStringForKey:(NSString *)string
{
	return [[NSBundle mainBundle] localizedStringForKey:string value:string table:nil];
}


#pragma mark Dialog handling


- (void)runReportModalForWindow:(NSWindow *)inWindow completionHandler:(DDPRCompletionHandler)handler
{
	if (handler == NULL)  handler = ^(BOOL flag) {};
	
#if 0
	if (!self.haveErrors)
	{
		handler(YES);
		return;
	}
	
	if (![self priv_prepareDialog])
	{
		if (handler != NULL)  handler([self priv_defaultResult]);
		return;
	}
#else
	handler([self showReportApplicationModal]);
#endif
}


- (BOOL)showReportApplicationModal
{
//	if (!self.haveErrors)  return YES;
	if (![self priv_prepareDialog])  return [self priv_defaultResult];
	
	_runningModal = YES;
	BOOL result = [NSApp runModalForWindow:reportDialog];
	[reportDialog orderOut:nil];
	[self priv_teardownDialog];
	
	return result;
}


- (BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	SEL						action;
	
	action = [inItem action];
	if (action == @selector(copy:))
	{
		return 0 != [tableView numberOfSelectedRows];
	}
	
	return [super validateMenuItem:inItem];
}


- (IBAction)continueAction:sender
{
	if (_runningModal)  [NSApp stopModalWithCode:YES];
}


- (IBAction)cancelAction:sender
{
	if (_runningModal)  [NSApp stopModalWithCode:NO];
}


#pragma mark NSTableViewDataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
	return self.problemCount;
}


- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *identifier = tableColumn.identifier;
	DDProblemReportIssue *problem = [self.problems objectAtIndex:row];
	
	if ([identifier isEqualToString:@"icon"])
	{
		switch (problem.type)
		{
			case kOOProblemTypeInformative:	return [self priv_noteIcon];
			case kOOProblemTypeWarning:		return [self priv_warningIcon];
			case kOOProblemTypeError:		return [self priv_errorIcon];
		}
		return nil;
	}
	else if ([identifier isEqualToString:@"description"])
	{
		return problem.message;
	}
	else
	{
		OOLog(@"dryDock.problemReportManager.tableView.unknownColumn", @"Unknown table column identifer %@", identifier);
		return nil;	
	}
}


- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	float result = 0;
	if (_heights != NULL)
	{
		result = _heights[row];
		if (result == 0)
		{
			// Calculate and cache value.
			DDProblemReportIssue *problem = [self.problems objectAtIndex:row];
			NSString *message = problem.message;
			if (message == nil)  message = @"";
			[layoutProxyTextView setString:message];
			[layoutProxyTextView sizeToFit];
			result = layoutProxyTextView.frame.size.height;
			_heights[row] = result;
		}
	}
	
	if (result < kMinHeight) result = kMinHeight;
	
	return result + kHeightPadding;
}


#pragma mark Private

- (BOOL) priv_prepareDialog
{
	NSArray *problems = self.problems;
	NSUInteger /*iter,*/ count = problems.count;
	if (count == 0)  return NO;
	
	_heights = NSAllocateCollectable(sizeof *_heights * count, 0);
	if (_heights != NULL)  memset(_heights, 0, sizeof *_heights * count);
	
	if (![NSBundle loadNibNamed:@"DDProblemReportManager" owner:self])  return NO;
	
	// Set up strings in dialog.
	NSString *titleContextString = nil, *promptContextString = nil;
	switch (self.context)
	{
		case kDDPRContextLoad:
			titleContextString = NSLocalizedString(@"open the document", NULL);
			promptContextString = NSLocalizedString(@"opening", NULL);
			break;
			
		case kDDPRContextSave:
			titleContextString = NSLocalizedString(@"save the document", NULL);
			promptContextString = NSLocalizedString(@"saving", NULL);
			break;
	}
	
	// Set title.
	NSString *title = nil;
	if (count == 1)  title = NSLocalizedString(@"An issue arose while attempting to %@:", NULL);
	else  title = NSLocalizedString(@"Some issues arose while attempting to %@:", NULL);
	titleField.objectValue = $sprintf(title, titleContextString);
	
	// Set prompt.
	NSString *prompt = nil;
	if (self.haveErrors)  prompt = NSLocalizedString(@"Dry Dock cannot continue %@, because errors occurred.", NULL);
	else  prompt = NSLocalizedString(@"Do you wish to continue %@?", NULL);
	promptField.objectValue = $sprintf(prompt, promptContextString);
	
	// Select the buttons to show.
	if (self.haveErrors)
	{
		// Show cancelButton2 only
		[cancelButton removeFromSuperview];
		[continueButton removeFromSuperview];
	}
	else
	{
		// Show cancelButton and continueButton.
		[cancelButton2 removeFromSuperview];
	}
	
	// Fiddle with the view used to lay out text.
	NSSize size = layoutProxyTextView.frame.size;
	size.height = kMinHeight;
	layoutProxyTextView.minSize = size;
	size.height = kMaxHeight;
	layoutProxyTextView.maxSize = size;
	[layoutProxyTextView setVerticallyResizable:YES];
	layoutProxyTextView.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
	
	[tableView reloadData];
	
	return YES;
}


- (BOOL) priv_defaultResult
{
	return !self.haveErrors;
}


- (void) priv_teardownDialog
{
	reportDialog = nil;
	_heights = NULL;
	_completionHandler = nil;
	_runningModal = NO;
}


- (NSImage *) priv_noteIcon
{
	NSImage *result = _noteIcon;
	if (result == nil)
	{
		_noteIcon = result = [[IconFamily iconFamilyWithSystemIcon:kAlertNoteIcon] imageWithAllReps];
	}
	return result;
}


- (NSImage *) priv_warningIcon
{
	NSImage *result = _warningIcon;
	if (result == nil)
	{
		_warningIcon = result = [[IconFamily iconFamilyWithSystemIcon:kAlertCautionIcon] imageWithAllReps];
	}
	return result;
}


- (NSImage *) priv_errorIcon
{
	NSImage *result = _errorIcon;
	if (result == nil)
	{
		_errorIcon = result = [[IconFamily iconFamilyWithSystemIcon:kAlertStopIcon] imageWithAllReps];
	}
	return result;
}

@end


@implementation DDProblemReportIssue: NSObject

@synthesize type = _type, message = _message;

- (id) initWithType:(OOProblemReportType)type message:(NSString *)message
{
//	if (message == nil)  return nil;
	
	if ((self = [super init]))
	{
		_type = type;
		_message = [message copy];
	}
	return self;
}


- (NSString *) description
{
	NSString *type = @"<unknown type>";
	switch (self.type)
	{
		case kOOProblemTypeInformative:
			type = @"note";
			break;
			
		case kOOProblemTypeWarning:
			type = @"warning";
			break;
			
		case kOOProblemTypeError:
			type = @"error";
			break;
	}
	
	return $sprintf(@"<%@ %p>{%@: %@}", self.class, self, type, self.message);
}

@end
