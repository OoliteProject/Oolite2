//
//  DDProblemReportManager.h
//  DryDock2
//
//  Created by Jens Ayton on 2010-07-21.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OoliteGraphics/OoliteGraphics.h>


typedef enum
{
	kDDPRContextLoad,
	kDDPRContextSave
} DDProblemReportContext;


typedef void (^DDPRCompletionHandler)(BOOL continueFlag);


@interface DDProblemReportManager: NSObject <OOProblemReporting>
{
@private
	DDProblemReportContext			_context;
	NSURL							*_fileURL;
	NSMutableArray					*_problems;
	OOProblemReportType				_highestType;
	
	IBOutlet NSPanel				*reportDialog;
	IBOutlet __weak NSButton		*continueButton;
	IBOutlet __weak NSButton		*cancelButton;
	IBOutlet __weak NSButton		*cancelButton2;
	IBOutlet __weak NSTextField		*titleField;
	IBOutlet __weak NSTextField		*promptField;
	IBOutlet __weak NSScrollView	*scrollView;
	IBOutlet __weak NSTableView		*tableView;
	IBOutlet __weak NSTextView		*layoutProxyTextView;
	
	__weak NSImage					*_noteIcon;
	__weak NSImage					*_warningIcon;
	__weak NSImage					*_errorIcon;
	
	DDPRCompletionHandler			_completionHandler;
	__strong float					*_heights;
	
	BOOL							_runningModal;
}

- (id) initWithContext:(DDProblemReportContext)context fileURL:(NSURL *)url;

// Reports issues (if any), then calls handler with a flag indiciating whether a “continue” response was given (or YES if there are no issues).
- (void)runReportModalForWindow:(NSWindow *)inWindow completionHandler:(DDPRCompletionHandler)handler;

// Report issues synchronously, then return a flag indicating whether a “continue” response was given (or YES if there are no issues).
- (BOOL)showReportApplicationModal;

@property (readonly) DDProblemReportContext context;
@property (readonly) NSURL *fileURL;
@property (readonly) OOProblemReportType highestProblemType;
@property (readonly) BOOL haveErrors;
@property (readonly) NSUInteger problemCount;
@property (readonly) NSArray *problems;


// Internal.
- (IBAction)continueAction:sender;
- (IBAction)cancelAction:sender;

@end
