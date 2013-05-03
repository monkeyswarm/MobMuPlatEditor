//
//  MMPToggle.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/31/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPToggle : MMPControl{
    NSView* innerView;
}

@property (nonatomic) int value;
@property (nonatomic) int borderThickness;
@end
