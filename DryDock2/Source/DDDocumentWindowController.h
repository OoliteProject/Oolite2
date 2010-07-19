//
//  DDDocumentWindowController.h
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-10.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DDMainDocumentView, SGSceneNode;


@interface DDDocumentWindowController: NSWindowController
{
@private
	NSArray								*_meshes;
	SGSceneNode							*_rootNode;
	SGSceneNode							*_contentNode;
	
#if !__OBJC2__
	DDMainDocumentView					*_mainView;
#endif
}

- (id) init;


@property IBOutlet DDMainDocumentView *mainView;

@property (readonly, copy) NSArray *meshes;

- (IBAction) takeViewFromTag:(NSMenuItem *)sender;

@end
