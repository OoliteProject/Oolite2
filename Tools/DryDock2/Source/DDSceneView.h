//
//  DDSceneView.h
//  DryDock2
//
//  Created by Jens Ayton on 2010-06-10.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "JASceneGraphView.h"

@class OOGraphicsContext;


@interface DDSceneView: JASceneGraphView
{
@private
	OOGraphicsContext			*_context;
}

@property (nonatomic, readonly) OOGraphicsContext *graphicsContext;

@end
