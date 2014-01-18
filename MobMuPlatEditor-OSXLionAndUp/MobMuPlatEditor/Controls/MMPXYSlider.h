//
//  MMPXYSlider.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/1/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPXYSlider : MMPControl{
    NSView* borderView;
    NSView* cursorVertView;
    NSView* cursorHorizView;
}

@property float valueX;
@property float valueY;

@end
