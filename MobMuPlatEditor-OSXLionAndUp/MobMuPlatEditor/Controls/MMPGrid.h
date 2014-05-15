//
//  MMPGrid.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/1/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPGrid : MMPControl{
    NSMutableArray* gridButtons;
}

@property (nonatomic) int dimX;
@property (nonatomic) int dimY;
@property (nonatomic) int borderThickness;
@property (nonatomic) int cellPadding;
@property (nonatomic) int mode;



@end

