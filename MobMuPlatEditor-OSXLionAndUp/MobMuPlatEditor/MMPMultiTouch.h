//
//  MMPMultiTouch.h
//  MobMuPlatEditor
//
//  Created by diglesia on 2/24/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@class TouchView;

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
//@property (weak, nonatomic) NSEvent* origEvent;
@property (weak, nonatomic) TouchView* touchView;
@end

@interface TouchView : NSView
@property (nonatomic, weak) id<MMPControlEditingDelegate> editingDelegate;
@property (nonatomic, weak) NSView* parentView;
@property (nonatomic, weak) MyTouch* myTouch;
-(id)initAtPoint:(CGPoint)point;
@end