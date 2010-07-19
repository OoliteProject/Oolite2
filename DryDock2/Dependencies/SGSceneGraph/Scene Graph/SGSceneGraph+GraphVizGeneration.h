/*
	SGSceneGraph+GraphVizGeneration.h
	
	Categories for generating GraphViz data for a scene graph.
	
	
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

#import "SGSceneGraph.h"

@interface SGSceneGraph (GraphVizGeneration)

- (NSString *) generateGraphViz;
- (void) writeGraphVizToPath:(NSString *)path;

@end


@interface SGSceneNode (GraphVizGeneration)

// Inward interface for subclasses
@property (readonly) NSString *graphVizLabel;

@end


@interface SGSceneTag (GraphVizGeneration)

// Inward interface for subclasses
@property (readonly) NSString *graphVizLabel;	// default: "nameForGraphViz: graphVizExtra", "nameForGraphViz" or "graphVizExtra" as appropriate.
@property (readonly) NSString *nameForGraphViz;	// default: self.name
@property (readonly) NSString *graphVizExtra;	// default: nil

@end


// Tag to supress display of children in GraphViz
@interface SGSupressChildrenInGraphVizTag: SGSceneTag
@end
