//
//  CanvasView.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/26/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//
//  The gray view on which MMPControls are placed

#import <Cocoa/Cocoa.h>
#import "MMPControl.h"
#import "DocumentModel.h"

@interface CanvasView : NSView{
    NSImageView* buttonBlankView;
}

@property (nonatomic) NSColor* bgColor;
@property (nonatomic) id<MMPControlEditingDelegate> editingDelegate;
@property (nonatomic) int pageCount;
@property (nonatomic) int pageViewIndex;
@property  (nonatomic) int canvasType;
@property (nonatomic) BOOL isOrientationLandscape;

- (void)refreshGuides;

@end
