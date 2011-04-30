//
//  OOMaterial+DryDockPlaceholder.m
//  DryDock2
//
//  Created by Jens Ayton on 2011-04-30.
//  Copyright 2011 the Oolite team. All rights reserved.
//

#import "OOMaterial+DryDockPlaceholder.h"
#import "DDApplicationDelegate.h"


@implementation OOMaterial (DryDockPlaceholder)

+ (OOMaterial *) fallbackMaterialWithName:(NSString *)name forMesh:(OORenderMesh *)mesh
{
	OOTextureSpecification *texture = [OOTextureSpecification textureSpecWithName:@"Placeholder Texture.png"];
	texture.magFilter = kOOTextureMagFilterNearest;
	
	OOMaterialSpecification *spec = [[OOMaterialSpecification alloc] initWithMaterialKey:name ?: @"<anonymous>"];
	spec.diffuseMap = texture;
	
	return [[OOMaterial alloc] initWithSpecification:spec
												mesh:mesh
											  macros:nil
									   bindingTarget:nil
										fileResolver:[DDApplicationDelegate applicationDelegate].applicationResourceResolver
									 problemReporter:nil];
}

@end
