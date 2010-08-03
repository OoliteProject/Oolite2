/*
	SGSceneGraph+GraphVizGeneration.m
	
	
	Copyright © 2007-2009 Jens Ayton
	
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

#import "SGSceneGraph+GraphVizGeneration.h"
#import "CollectionUtils.h"


@interface SGSceneNode (GraphVizGenerationInternal)

- (void) appendGraphVizRecursively:(NSMutableString *)ioString
							parent:(NSString *)parentName
						 nodeIndex:(unsigned *)ioIndex;
- (NSString *) completeLabelForGraphViz;

@end


@interface SGSceneTag (GraphVizGenerationInternal)

- (NSString *) completeLabelForGraphViz;

@end


#if SCENGRAPH_LIGHTING
@interface SGLight (GraphVizGenerationInternal)

- (void) appendGraphViz:(NSMutableString *)ioString
				  index:(unsigned)index;

@end
#endif


static NSString *EscapedString(NSString *string);


@implementation SGSceneGraph (GraphVizGeneration)

- (NSString *) generateGraphViz
{
	NSMutableString *result = [NSMutableString string];
	
	[result appendString:@"digraph sceneGraph\n{\n\trankdir=LR\n\tnode [shape=box]\n\t\n\troot [shape=diamond]\n"];
	
#if SCENGRAPH_LIGHTING
	if (self.lightManager != nil)
	{
		[result appendString:@"\t\n\tlights [shape=ellipse]\n\t\n"];
		unsigned index = 0;
		for (SGLight *light in self.lightManager)
		{
			[light appendGraphViz:result index:index++];
		}
	}
#endif
	
	if (self.rootNode != nil)
	{
		[result appendString:@"\troot->node_0\n"];
		unsigned index = 0;
		[self.rootNode appendGraphVizRecursively:result parent:nil nodeIndex:&index];
	}
	
	[result appendString:@"}\n"];
	return result;
}


- (void) writeGraphVizToPath:(NSString *)path
{
	NSString *graphViz = [self generateGraphViz];
	NSData *data = [graphViz dataUsingEncoding:NSUTF8StringEncoding];
	
	if (data != nil)
	{
		path = path.stringByExpandingTildeInPath;
		[data writeToFile:path atomically:YES];
	}
}

@end


@implementation SGSceneNode (GraphVizGeneration)

- (void) appendGraphVizRecursively:(NSMutableString *)ioString
							parent:(NSString *)parentName
						 nodeIndex:(unsigned *)ioIndex
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL supressChildren = NO;
	
	@try
	{
		[ioString appendString:@"\t\n"];
		
		// This node
		unsigned myID = *ioIndex;
		*ioIndex = myID + 1;
		[ioString appendFormat:@"\t// Node %@ %@\n", [self className], [self graphVizLabel]];
		NSString *myName = $sprintf(@"node_%u", myID);
		[ioString appendFormat:@"\tsubgraph cluster_%u\n\t{\n\t\tshape=box\n\t\tbgcolor=lightgrey\n\t\t\n", myID];
		[ioString appendFormat:@"\t\t%@ [label=\"%@\" style=filled]\n", myName, [self completeLabelForGraphViz]];
		
		// Tags
		size_t i, count = self.tagCount;
		if (count != 0)
		{
			[ioString appendString:@"\t\t\n\t\t// Tags\n\t\tnode [shape=none]\n"];
			for (i = 0; i != count; ++i)
			{
				SGSceneTag *tag = [self tagAtIndex:i];
				NSString *tagName = $sprintf(@"tag_%u_%zu", myID, i);
				[ioString appendFormat:@"\t\t%@ [label=\"%@\"]\n", tagName, [tag completeLabelForGraphViz]];
				
				if ([tag isKindOfClass:[SGSupressChildrenInGraphVizTag class]])  supressChildren = YES;
			}
		}
		[ioString appendString:@"\t}\n"]; // End subgraph
		if (parentName != nil) [ioString appendFormat:@"\t%@ -> %@\n", parentName, myName];
		
		// Children
		if (!supressChildren)
		{
			SGSceneNode *child = [self firstChild];
			while (child != nil)
			{
				[child appendGraphVizRecursively:ioString parent:myName nodeIndex:ioIndex];
				child = [child nextSibling];
			}
		}
		else if ([self firstChild] != nil)
		{
			[ioString appendFormat:@"\t%@_suppressedChildren [label=\"%d hidden children\" shape=ellipse style=filled]\n\t%@ -> %@_suppressedChildren\n", myName, self.childCount, myName, myName];
		}
	}
	@finally
	{
		[pool release];
	}
}


- (NSString *) graphVizLabel
{
	NSString *nodeName = self.name;
	NSString *extra = self.itemDescription;
	
	if (nodeName == nil)  return extra;
	else if (extra == nil)
	{
		if (nodeName != nil)  return $sprintf(@"\"%@\"", nodeName);
		else return @"unnamed";
	}
	return $sprintf(@"\"%@\": %@", nodeName, extra);
}


- (NSString *) completeLabelForGraphViz
{
	NSString *result = self.className;
	NSString *label = self.graphVizLabel;
	if (label != nil)
	{
		result = [result stringByAppendingFormat:@"\n%@", label];
	}
	return EscapedString(result);
}

@end


@implementation SGSceneTag (GraphVizGeneration)

- (NSString *) graphVizLabel
{
	NSString *name = self.nameForGraphViz;
	NSString *extra = self.graphVizExtra;
	
	if (name == nil)  return extra;
	else if (extra == nil)
	{
		if (name != nil)  return $sprintf(@"\"%@\"", name);
		else return @"unnamed";
	}
	return $sprintf(@"\"%@\": %@", name, extra);
}


- (NSString *)nameForGraphViz
{
	return self.name;
}


- (NSString *) graphVizExtra
{
	return nil;
}


- (NSString *) completeLabelForGraphViz
{
	NSString *result = [self className];
	NSString *label = [self graphVizLabel];
	if (label != nil)
	{
		result = [result stringByAppendingFormat:@"\n%@", label];
	}
	return EscapedString(result);
}

@end


@implementation SGSimpleTag (GraphVizGeneration)

- (NSString *)nameForGraphViz
{
	// nil if no name specified, instead of falling back to key
	return _name;
}


static NSString *VarName(NSString *name)
{
	if ([name rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound)
	{
		return $sprintf(@"$%@", name);
	}
	else
	{
		return $sprintf(@"$\"%@\"", name);
	}
}


static NSString *Description(id value)
{
	// NSNumber booleans return 1 and 0 as descriptions; I prefer true and false.
	if (value == $true)  return @"true";
	if (value == $false)  return @"false";
	if ([value isKindOfClass:[NSString class]])  return $sprintf(@"\"%@\"", value);
	if (value == nil)  return @"nil";
	return [value description];
}


- (NSString *) graphVizExtra
{
	return $sprintf(@"%@ = %@", VarName(self.key), Description(self.value));
}

@end


@implementation SGConditionalTag (GraphVizGeneration)

- (NSString *) graphVizLabel
{
	// Name is based on result key and therefore redundant.
	return [self expressionDescription];
}

@end


// Workaround for Xcode auto-indent bug
static NSString * const kQuotationMark = @"\"";
static NSString * const kEscapedQuotationMark = @"\\\"";


static NSString *EscapedString(NSString *string)
{
	const NSString			*srcStrings[] =
	{
		//Note: backslash must be first.
		@"\\", @"\"", @"\'", @"\r", @"\n", @"\t", nil
	};
	const NSString			*subStrings[] =
	{
		//Note: must be same order.
		@"\\\\", @"\\\"", @"\\\'", @"\\r", @"\\n", @"\\t", nil
	};
	
	NSString				**src = srcStrings, **sub = subStrings;
	NSMutableString			*mutableStr = nil;
	NSString				*result = nil;
	
	mutableStr = [string mutableCopy];
	while (*src != nil)
	{
		[mutableStr replaceOccurrencesOfString:*src++
								 withString:*sub++
									options:0
									  range:NSMakeRange(0, [mutableStr length])];
	}
	
	if ([mutableStr length] == [string length])
	{
		result = string;
	}
	else
	{
		result = [[mutableStr copy] autorelease];
	}
	[mutableStr release];
	return result;
}


@implementation SGSupressChildrenInGraphVizTag: SGSceneTag

- (NSString *)name
{
	return @"supress children in GraphViz";
}


- (NSString *)nameForGraphViz
{
	return nil;
}

@end


#if SCENGRAPH_LIGHTING
@implementation SGLight (GraphVizGenerationInternal)

- (void) appendGraphViz:(NSMutableString *)ioString
				  index:(unsigned)index
{
	NSString		*desc = nil;
	
	if (self.spotCutoff != 180.0f)  desc = @"Spotlight";
	else  if (self.positional)  desc = @"Positional light";
	else  desc = @"Directional light";
	
	if (self.name != nil)
	{
		desc = $sprintf(@"%@\n\"%@\"", desc, self.name);
	}
	
	[ioString appendFormat:@"\t\n\tlight_%u [label=\"%@\"]\n\tlights -> light_%u", index, EscapedString(desc), index];
}

@end
#endif
