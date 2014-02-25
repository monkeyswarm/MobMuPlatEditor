//
//  MMPMultiTouch.h
//  MobMuPlatEditor
//
//  Created by diglesia on 2/24/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPMultiTouch : MMPControl

@end

@interface Cursor : NSObject
@property (strong, nonatomic) NSView* cursorX;
@property (strong, nonatomic) NSView* cursorY;

@end

@interface MyTouch : NSObject
@property (nonatomic) CGPoint point;
@property (nonatomic) int state;//0,1,2
@property (nonatomic) int polyVox;
@property (weak, nonatomic) NSEvent* origEvent;
@end