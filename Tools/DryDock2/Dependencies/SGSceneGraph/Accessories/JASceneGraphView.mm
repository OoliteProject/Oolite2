/*
	JASceneGraphView.mm
	Map Viewer for Redline
	Adapted from Dry Dock for Oolite.
	
	Copyright © 2006-2007 Jens Ayton

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

#import "JASceneGraphView.h"
#import "SGSceneGraphUtilities.h"
#import "SGSceneGraph.h"
#import <OpenGL/glu.h>

NSString *kNotificationDDSceneViewSceneChanged = @"se.ayton.jens.SGSceneGraph kNotificationDDSceneViewSceneChanged";
NSString *kNotificationDDSceneViewCameraChanged = @"se.ayton.jens.SGSceneGraph kNotificationDDSceneViewCameraChanged";


#define kButtonZoomRatio		1.2f


#define USE_MULTISAMPLE 1


static const GLuint kAttributes[] =
{
	NSOpenGLPFAWindow,
	NSOpenGLPFANoRecovery,
	NSOpenGLPFAAccelerated,
	NSOpenGLPFADoubleBuffer,
	NSOpenGLPFAColorSize, 24,
	NSOpenGLPFAAlphaSize, 8,
	NSOpenGLPFADepthSize, 24,
	#if USE_MULTISAMPLE
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples,4,
	#endif
	0
};


static const GLuint kFallbackAttributes[] =
{
	NSOpenGLPFAWindow,
	NSOpenGLPFADoubleBuffer,
	NSOpenGLPFAColorSize, 24,
	NSOpenGLPFAAlphaSize, 8,
	NSOpenGLPFADepthSize, 24,
	0
};


@interface JASceneGraphView ()

- (void)beginDragForEvent:(NSEvent *)inEvent;
- (void)endDrag;
- (void)handleDragEvent:(NSEvent *)inEvent;

- (void)handleCameraZoomDragDeltaX:(float)inDeltaX deltaY:(float)inDeltaY;
- (void)handleCameraPanDragDeltaX:(float)inDeltaX deltaY:(float)inDeltaY;

- (SGVector3)virtualTrackballLocationForPoint:(NSPoint)inPoint;

@end


@implementation JASceneGraphView

- (id) initWithFrame:(NSRect)frame
{
	NSOpenGLPixelFormat		*fmt;
	
	fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:(NSOpenGLPixelFormatAttribute *)kAttributes];
	if (nil == fmt) fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:(NSOpenGLPixelFormatAttribute *)kFallbackAttributes];
	
	if (!fmt)
	{
		[self release];
		return nil;
	}
	
	self = [super initWithFrame:frame pixelFormat:[fmt autorelease]];
	
	if (self == nil)  return nil;
	
	_radius = 1.0;
	[self resetCamera:nil];
	self.cameraType = kViewType3D;
	
	return self;
}


- (void)setCameraDistance:(float)inZ
{
	if (-0.5f < inZ) inZ = -0.5f;
	if (inZ < -200000.0f) inZ = -200000.0f;
	if (_cameraDistance != inZ)
	{
	//	LogWithFormat(@"Setting Z to %g", inZ);
		_cameraDistance = inZ;
		[self displaySettingsChanged];
	}
}


- (float)cameraDistance
{
	return _cameraDistance;
}


- (JASceneGraphViewCameraType)cameraType
{
	return _viewType;
}


- (void)setCameraType:(JASceneGraphViewCameraType)inViewType
{
	if (inViewType < kViewTypeCount)
	{
		_viewType = inViewType;
		[self displaySettingsChanged];
	}
}


- (SGVector3)focusPoint
{
	return _focusPoint;
}


- (void)setFocusPoint:(SGVector3)inPoint
{
	_focusPoint = inPoint;
	[self displaySettingsChanged];
}


- (void)moveFocusPointBy:(SGVector3)inDelta
{
	[self setFocusPoint:[self focusPoint] + inDelta];
}


- (float) objectSize
{
	return _radius;
}


- (void)setObjectSize:(float)inRadius
{
	_radius = inRadius;
	if (_radius < 1) _radius = 1;
	[self resetZoom:nil];
}


- (IBAction) resetRotation:(id)sender
{
	_cameraRotation.SetIdentity();
	_cameraRotation.RotateY(-30.0f * M_PI / 180.0f);
	_cameraRotation.RotateX(40.0f * M_PI / 180.0f);
	[self displaySettingsChanged];
}


- (IBAction) resetPan:(id)sender
{
	[self setFocusPoint:kSGVector3Zero];
}


- (IBAction) resetZoom:(id)sender
{
	self.cameraDistance = _radius * -2.5;
}


- (IBAction) resetCamera:(id)sender
{
	[self resetRotation:sender];
	[self resetPan:sender];
	[self resetZoom:sender];
}


- (void)prepareOpenGL
{
	glClearDepth(1.0);
	
	glDepthFunc(GL_LEQUAL);
	glEnable(GL_DEPTH_TEST);
	
	glShadeModel(GL_SMOOTH);
	glEnable(GL_LIGHTING);
	
	glFrontFace(GL_CCW);
	
	#if USE_MULTISAMPLE
		glEnable(GL_MULTISAMPLE_ARB);
	#endif
	
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_RESCALE_NORMAL);
	
	glEnable (GL_POLYGON_OFFSET_FILL);
	glEnable (GL_POLYGON_OFFSET_LINE);
	glEnable (GL_POLYGON_OFFSET_POINT);
	glPolygonOffset(1, 1);
	
	SGLogOpenGLErrors(@"Preparing OpenGL context");
}


- (void)rebuildDisplayList
{
	[self.sceneGraph.rootNode becomeDirtyDownwards];
}


- (void) clearBackground
{
	NSColor *color = [self backgroundColor];
	color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	glClearColor([color redComponent], [color greenComponent], [color blueComponent], [color alphaComponent]);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}


- (void)setUpCamera3DWithRect:(NSRect)inRect
{
	float					near;
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glViewport(0, 0, (GLsizei)inRect.size.width, (GLsizei)inRect.size.height);
	
	near = 0.2f;
	if (near < -3500.0f - _cameraDistance) near = -3500.0f - _cameraDistance;
	gluPerspective(45.0f, inRect.size.width / inRect.size.height, near, 4000.0f - _cameraDistance);
	glMatrixMode(GL_MODELVIEW);
	
	[self clearBackground];
	
	glLoadIdentity();
	
	glTranslatef(0, 0, _cameraDistance);
	_cameraRotation.glMult();
	(-_focusPoint).glTranslate();
}


- (void)setUpCameraOrthoWithRect:(NSRect)inRect direction:(JASceneGraphViewCameraType)inDirection
{
	float					width, height;
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glViewport(0, 0, (GLsizei)inRect.size.width, (GLsizei)inRect.size.height);
	
	height = _cameraDistance / 2.0f;
	width = height * inRect.size.width / inRect.size.height;
	glOrtho(-width, width, -height, height, -2000, 2000);
	
	glMatrixMode(GL_MODELVIEW);
	
	[self clearBackground];
	
	glLoadIdentity();
	
	switch (inDirection)
	{
		case kViewTypeTop:
			glRotatef(90, 1, 0, 0);
			glRotatef(180, 0, 1, 0);
			glTranslatef(-_focusPoint.x, 0, -_focusPoint.z);
			break;
		
		case kViewTypeSouth:
			glRotatef(180, 1, 0, 0);
			glRotatef(180, 0, 1, 0);
			glTranslatef(-_focusPoint.x, -_focusPoint.y, 0);
			break;
		
		case kViewTypeEast:
			glRotatef(180, 1, 0, 0);
			glRotatef(90, 0, 1, 0);
			glTranslatef(0, -_focusPoint.y, -_focusPoint.z);
			break;
		
		default:
			{}
	}
}


- (void)drawRect:(NSRect)inRect
{
	float					scale;
	
	_oldSize = inRect.size;
	_cameraDirty = NO;
	
	scale = [[self window] userSpaceScaleFactor];
	inRect.size.width *= scale;
	inRect.size.height *= scale;
	
	switch (_viewType)
	{
		case kViewType3D:
			[self setUpCamera3DWithRect:inRect];
			break;
		
		default:
			[self setUpCameraOrthoWithRect:inRect direction:_viewType];
	}
	
	@try
	{
		[_sceneGraph render];
	}
	@catch (id ex)
	{
		NSLog(@"Exception \"%@\" rendering.", ex);
	}
	
	glFlush();
	[[self openGLContext] flushBuffer];
	
	SGLogOpenGLErrors(@"End of drawing");
}


- (SGSceneGraph *) sceneGraph
{
	if (_sceneGraph == nil)
	{
		_sceneGraph = [[SGSceneGraph alloc] initWithContext:self.openGLContext];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(sceneGraphChanged:)
													 name:kSGSceneGraphModifiedNotification
												   object:_sceneGraph];
	}
	return _sceneGraph;
}


- (void) sceneGraphChanged:(NSNotification *)n
{
	[self setNeedsDisplay:YES];
}


- (BOOL)isOpaque
{
	return YES;
}


- (void)beginDragForEvent:(NSEvent *)inEvent
{
	NSPoint					where;
	
	where = [inEvent locationInWindow];
	where = [self convertPoint:where fromView:nil];
	
	_dragPoint = [self virtualTrackballLocationForPoint:where];
	_dragAction = [self dragActionForEvent:inEvent];
	
	[self startedDraggingWithAction:_dragAction event:inEvent];
}


- (void)endDrag
{
	[self finishedDraggingWithAction:_dragAction];
	_dragAction = kDragAction_none;
	[self displaySettingsChanged];
}


- (NSUInteger)filterModifiers:(NSUInteger)inModifiers forDragActionForEvent:(NSEvent *)inEvent
{
	return inModifiers;
}


- (unsigned)dragActionForEvent:(NSEvent *)inEvent
{
	return kDragAction_none;
}


- (void)handleDragEvent:(NSEvent *)inEvent
{
	NSPoint					where;
	SGVector3				newDragPoint, delta, axis;
	float					dx, dy;
	
	dx = [inEvent deltaX];
	dy = [inEvent deltaY];
	
	switch (_dragAction)
	{
		case kDragAction_orbitCamera:
			where = [inEvent locationInWindow];
			where = [self convertPoint:where fromView:nil];
			newDragPoint = [self virtualTrackballLocationForPoint:where];
			delta = newDragPoint - _dragPoint;
			if (0.00001f < delta.SquareMagnitude())
			{
				// Rotate about the axis that is perpendicular to the great circle connecting the mouse points.
				axis = _dragPoint % newDragPoint;
				_cameraRotation.RotateAroundAxis(axis, delta.Magnitude());
				[self displaySettingsChanged];
				_dragPoint = newDragPoint;
			}
			break;
		
		case kDragAction_panCamera:
			[self handleCameraPanDragDeltaX:dx deltaY:dy];
			[self displaySettingsChanged];
			break;
		
		case kDragAction_zoomCamera:
			[self handleCameraZoomDragDeltaX:dx deltaY:dy];
			[self displaySettingsChanged];
			break;
		
		default:
			[self handleCustomDragEvent:inEvent];
			return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDSceneViewCameraChanged object:self];
}


- (void)handleCustomDragEvent:(NSEvent *)inEvent
{
	
}


- (void)startedDraggingWithAction:(unsigned)inAction event:(NSEvent *)inEvent
{
	
}


- (void)finishedDraggingWithAction:(unsigned)inAction
{
	
}


- (NSColor *) backgroundColor
{
	return [NSColor blackColor];
}


- (void)mouseDown:(NSEvent *)theEvent
{
	if (NSControlKeyMask == [theEvent modifierFlags]) [super mouseDown:theEvent];	// Pass through for contextual menu handling
	else [self beginDragForEvent:theEvent];
}


- (void)rightMouseDown:(NSEvent *)theEvent
{
	[self beginDragForEvent:theEvent];
}


- (void)otherMouseDown:(NSEvent *)theEvent
{
	[self beginDragForEvent:theEvent];
}


- (void)mouseUp:(NSEvent *)theEvent
{
	[self endDrag];
}


- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self endDrag];
}


- (void)otherMouseUp:(NSEvent *)theEvent
{
	[self endDrag];
}


- (void)mouseDragged:(NSEvent *)theEvent
{
	[self handleDragEvent:theEvent];
}


- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self handleDragEvent:theEvent];
}


- (void)otherMouseDragged:(NSEvent *)theEvent
{
	[self handleDragEvent:theEvent];
}


- (void)scrollWheel:(NSEvent *)theEvent
{
	float				delta;
	
	delta = [theEvent deltaZ];
	if (0.0f == delta) delta = [theEvent deltaY];	// True in approximately 100% of cases
	if (delta != 0.0f)
	{
		// Vertical scroll: zoom.
		[self setCameraDistance:_cameraDistance * (1.0f - (delta * 0.1f))];
	}
	else
	{
		// Horizontal scroll: rotate if in 3D view.
		if (self.cameraType == kViewType3D)
		{
		//	_cameraRotation.RotateY([theEvent deltaX]);
		//	[self displaySettingsChanged];
		}
	}
}


- (void) magnifyWithEvent:(NSEvent *)event
{
	float factor = 1.0 - [event magnification];
	[self setCameraDistance:_cameraDistance * factor];
}


- (void)handleCameraZoomDragDeltaX:(float)inDeltaX deltaY:(float)inDeltaY
{
	[self setCameraDistance:_cameraDistance * (1.0 - (inDeltaY * 0.01f))];
}


- (void)handleCameraPanDragDeltaX:(float)inDeltaX deltaY:(float)inDeltaY
{
	SGVector3				focusPoint;
	float					dX, dY;
	float					scale;
	SGVector3				delta(0);
	
	scale = _cameraDistance / ([self frame].size.height * [[self window] userSpaceScaleFactor]);
	dX = inDeltaX * scale;
	dY = inDeltaY * scale;
	
	switch (_viewType)
	{
		case kViewTypeTop:
			delta.x = dX;
			delta.z = dY;
			break;
		
		case kViewTypeSouth:
			delta.x = dX;
			delta.y = -dY;
			break;
		
		case kViewTypeEast:
			delta.z = -dX;
			delta.y = -dY;
			break;
		
		case kViewType3D:
			delta.x = dX;
			delta.y = -dY;
			delta = _cameraRotation * delta;
			break;
		
		default:
			{}
	}
	
	[self moveFocusPointBy:delta];
}


- (SGVector3)virtualTrackballLocationForPoint:(NSPoint)inPoint
{
	SGVector3				result;
	float					d;
	NSRect					frame;
	
	frame = [self frame];
	
	result.x = (2.0f * inPoint.x - frame.size.width) / frame.size.width;
	result.y = (2.0f * inPoint.y - frame.size.height) / frame.size.height;
	result.z = 0;
	
	d = result.SquareMagnitude();
	if (1.0f < d) d = 1.0f;
	result.z = sqrtf(1.0001 - d);
	result.Normalize();
	
	return result;
}


- (BOOL)shouldBeTreatedAsInkEvent:(NSEvent *)theEvent
{
	// Don’t use write-anywhere (i.e., be an “instant mouser”)
	return NO;
}


- (void)displaySettingsChanged
{
	_cameraDirty = YES;
	[self setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDDSceneViewCameraChanged object:self];
}


- (IBAction)zoomIn:sender
{
	[self setCameraDistance:_cameraDistance / kButtonZoomRatio];
}


- (IBAction)zoomOut:sender
{
	[self setCameraDistance:_cameraDistance * kButtonZoomRatio];
}


- (BOOL) shadersSupported
{
	// FIXME
	return NO;
}

@end
