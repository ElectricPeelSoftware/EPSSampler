//
//  EPSSampler.h
//
//  Created by Peter Stuart on 02/10/13.
//  Copyright (c) 2013 Electric Peel Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPSSampler : NSObject

- (id)initWithPresetURL:(NSURL *)url;

- (void)startPlayingNote:(UInt32)note withVelocity:(double)velocity;
- (void)stopPlayingNote:(UInt32)note;

- (AUGraph)processingGraph;

@end
