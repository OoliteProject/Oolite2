//
//  OOTRJSGraphViz.h
//  ootranscript
//
//  Created by Jens Ayton on 2010-07-23.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#ifndef NDEBUG

#import "OOTrJSAST.h"

@interface OOTrStatement (GraphViz)

- (NSString *) generateGraphViz;
- (void) writeGraphVizToPath:(NSString *)path;

@end

#endif
