/*
	JASceneGraphView.h
	
	
	Copyright © 2006–2008 Jens Ayton
	
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

#import <Cocoa/Cocoa.h>
#import "SGMatrixTypes.h"

@class SGSceneGraph;

enum
{
	kDragAction_none = 0UL,
	kDragAction_currentTool,
	kDragAction_orbitCamera,
	kDragAction_panCamera,
	kDragAction_zoomCamera,
	
	// first ID for subclasses to use for their own drag actions
	kDragAction_customBase
};


typedef enum
{
	//NOTE: order is significant.
	kViewTypeSouth = 0UL,
	kViewTypeEast,
	kViewTypeTop,
	kViewType3D,
	
	kViewTypeCount
} JASceneGraphViewCameraType;


@interface JASceneGraphView: NSOpenGLView
{
	SGSceneGraph				*_sceneGraph;
	
	NSSize						_oldSize;
	
	unsigned					_dragAction;
	SGVector3					_dragPoint;
	
	SGVector3					_focusPoint;
	float						_cameraDistance;
	float						_radius;
	
	SGMatrix4x4					_cameraRotation;
	
	JASceneGraphViewCameraType	_viewType;
	
	BOOL						_cameraDirty;
}

// Note: scene graph is read-only as it is tied to view's NSOpenGLContext, but it is mutable.
@property (nonatomic, readonly) SGSceneGraph *sceneGraph;

@property (nonatomic) SGVector3 focusPoint;
- (void)moveFocusPointBy:(SGVector3)inDelta;

@property (nonatomic) float cameraDistance;
@property (nonatomic) float objectSize;

@property (nonatomic) JASceneGraphViewCameraType cameraType;

- (void) resetRotation;
- (void) resetPan;
- (void) resetZoom;
- (void) resetCamera;

// Subclass stuff
- (unsigned) dragActionForEvent:(NSEvent *)inEvent;
- (NSUInteger) filterModifiers:(NSUInteger)inModifiers forDragActionForEvent:(NSEvent *)inEvent;
- (void) handleCustomDragEvent:(NSEvent *)inEvent;	// Called for drags where action is not none, rotateObject, rotateLight or moveCamera

- (void) startedDraggingWithAction:(unsigned)inAction event:(NSEvent *)inEvent;
- (void) finishedDraggingWithAction:(unsigned)inAction;

- (NSColor *) backgroundColor;	// Default: blackColor

- (void) displaySettingsChanged;

- (IBAction) zoomInAction:sender;
- (IBAction) zoomOutAction:sender;

@property (readonly) BOOL shadersSupported;

@end


extern NSString *kNotificationDDSceneViewSceneChanged;
extern NSString *kNotificationDDSceneViewCameraChanged;
