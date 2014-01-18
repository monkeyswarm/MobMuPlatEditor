//
//  MMPMultiSlider.h
//  MobMuPlatEditor
//
//  Created by Daniel Iglesia on 3/28/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPMultiSlider : MMPControl{
    NSView* box;
    NSMutableArray* headViewArray;
    float headWidth;
    int currHeadIndex;
}

@property(nonatomic) int range;
@property(nonatomic) NSMutableArray* valueArray;
@end


