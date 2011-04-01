//
//  OOTRJSGraphViz.m
//  ootranscript
//
//  Created by Jens Ayton on 2010-07-23.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#ifndef NDEBUG

#import "OOTRJSGraphViz.h"
#import "NSString+OOJavaScriptLiteral.h"
#import <OoliteBase/OoliteBase.h>


@interface OOTrStatement (GraphVizInternal)

- (void) appendGraphVizRecursively:(NSMutableString *)ioString
							parent:(NSString *)parentName
						 nodeIndex:(NSUInteger *)ioIndex;

- (NSString *) completeLabelForGraphViz;
- (NSString *) descriptionForGraphViz;
- (NSArray *) childrenForGraphViz;

- (NSString *) shapeForGraphViz;

@end


@implementation OOTrStatement (GraphViz)

- (NSString *) generateGraphViz
{
	NSMutableString *result = [NSMutableString string];
	
	[result appendString:@"digraph ootranscriptAST\n{\n"];
	
	NSUInteger nodeIndex = 0;
	[self appendGraphVizRecursively:result parent:nil nodeIndex:&nodeIndex];
	
	[result appendString:@"}\n"];
	return result;
}


- (void) writeGraphVizToPath:(NSString *)path
{
	NSString *graphViz = [self generateGraphViz];
	NSData *data = [graphViz dataUsingEncoding:NSUTF8StringEncoding];
	
	if (data != nil)
	{
		path = [path stringByExpandingTildeInPath];
		[data writeToFile:path atomically:YES];
	}
}



- (void) appendGraphVizRecursively:(NSMutableString *)ioString
							parent:(NSString *)parentName
						 nodeIndex:(NSUInteger *)ioIndex
{
	NSString *myName = $sprintf(@"node_%u", (*ioIndex)++);
	
	[ioString appendFormat:@"\t%@ [label=\"%@\" shape=\"%@\"];\n", myName, [[self completeLabelForGraphViz] oo_escapedForJavaScriptLiteral], [self shapeForGraphViz]];
	if (parentName != nil)
	{
		[ioString appendFormat:@"\t%@ -> %@\n", parentName, myName];
	}
	[ioString appendString:@"\n"];
	
	OOTrStatement *child = nil;
	foreach (child, [self childrenForGraphViz])
	{
		[child appendGraphVizRecursively:ioString parent:myName nodeIndex:ioIndex];
	}
}


- (NSString *) completeLabelForGraphViz
{
	return $sprintf(@"%@\n%@", [self class], [self descriptionForGraphViz]);
}


- (NSString *) descriptionForGraphViz
{
	return [self descriptionComponents];
}


- (NSArray *) childrenForGraphViz
{
	return nil;
}


- (NSString *) shapeForGraphViz
{
	return @"box";
}

@end


@implementation OOTrExpression (GraphViz)

- (NSString *) shapeForGraphViz
{
	return @"ellipse";
}

@end



@implementation OOTrArrayDeclaration (GraphViz)

- (NSArray *) childrenForGraphViz
{
	return [self array];
}

@end


@implementation OOTrUnaryOperator (GraphViz)

- (NSArray *) childrenForGraphViz
{
	return $array([self argument]);
}

@end


@implementation OOTrBinaryOperator (GraphViz)

- (NSArray *) childrenForGraphViz
{
	return $array([self leftArgument], [self rightArgument]);
}

@end


@implementation OOTrConditionalOperator (GraphViz)

- (NSArray *) childrenForGraphViz
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:3];
	if (_condition != nil)  [result addObject:_condition];
	if (_trueValue != nil)  [result addObject:_trueValue];
	if (_falseValue != nil)  [result addObject:_falseValue];
	return result;
}

@end


@implementation OOTrConditionalStatement (GraphViz)

- (NSArray *) childrenForGraphViz
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:3];
	if (_condition != nil)  [result addObject:_condition];
	if (_trueStatement != nil)
	{
		NSArray *statements = [_trueStatement statements];
		if ([statements count] == 1)  [result addObject:[statements objectAtIndex:0]];
		else  [result addObject:_trueStatement];
	}
	if (_falseStatement != nil)
	{
		NSArray *statements = [_falseStatement statements];
		if ([statements count] == 1)  [result addObject:[statements objectAtIndex:0]];
		else  [result addObject:_falseStatement];
	}
	return result;
}


- (NSString *) shapeForGraphViz
{
	return @"diamond";
}

@end


@implementation OOTrFunctionCallOperator (GraphViz)

- (NSArray *) childrenForGraphViz
{
//	return [$array([self callee]) arrayByAddingObjectsFromArray:[self arguments]];
	
	NSArray *calleeArray = $array([self callee]);
	NSArray *args = [self arguments];
	NSArray *result = [calleeArray arrayByAddingObjectsFromArray:args];
	return result;
}


- (NSString *) shapeForGraphViz
{
	return @"invhouse";
}

@end


@implementation OOTrReturnStatement (GraphViz)

- (NSArray *) childrenForGraphViz
{
	OOTrExpression *expr = [self expression];
	if (expr != nil)  return $array([self expression]);
	return nil;
}

@end


@implementation OOTrCompoundStatement (GraphViz)

- (NSArray *) childrenForGraphViz
{
	return [self statements];
}


- (NSString *) shapeForGraphViz
{
	return @"trapezium";
}

@end


@implementation OOTrFunctionDeclaration (GraphViz)

- (NSArray *) childrenForGraphViz
{
	// Skip the OOTrCompoundStatement for simplicity.
	return [[self body] statements];
}


- (NSString *) shapeForGraphViz
{
	return @"house";
}

@end


@implementation OOTrVarStatement (GraphViz)

- (NSArray *) childrenForGraphViz
{
	id initializer = [self initializer];
	return (initializer == nil) ? nil : $array(initializer);
}

@end

#endif // NDEBUG
