//
//  MMPSlider.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/27/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPSlider : MMPControl{
    NSView* troughView;
    NSView* thumbView;
    NSMutableArray* tickViewArray;
    
}
@property (nonatomic) BOOL isHorizontal;
@property (nonatomic) float value;
@property (nonatomic) int range;

@end
