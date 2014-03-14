//
//  EditHandle.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/28/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//
// This object is the little square on the lower left when you select a GUI control while in edit mode. When you drag on it, it resizes the control

#import "EditHandle.h"
#import "MMPControl.h"

@implementation EditHandle

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];
        [self.layer setBorderColor:CGColorCreateGenericGray(0, 1)];
        [self.layer setBorderWidth:5];
    }
    return self;
}

-(void)mouseDown:(NSEvent *)event
{
    [[self undoManager] beginUndoGrouping];
    startDragPoint=[[[self superview] superview] convertPoint:[event locationInWindow] fromView:nil];
    MMPControl* control = (MMPControl*)[self superview];
    [control.editingDelegate updateGuide:control];
}

-(void)mouseDragged:(NSEvent *)event{
    NSPoint newDragLocation=[[[self superview] superview] convertPoint:[event locationInWindow] fromView:nil];
   
    CGFloat newWidth = [self superview].frame.size.width+(newDragLocation.x-startDragPoint.x);
    CGFloat newHeight = [self superview].frame.size.height+(newDragLocation.y-startDragPoint.y);
    CGRect newFrame = CGRectMake([self superview].frame.origin.x, [self superview].frame.origin.y, newWidth, newHeight);
    
    //keep it from getting too small
    if(newWidth>40 && newHeight>40){
      MMPControl* control = (MMPControl*)[self superview];
      [control setFrameObjectUndoable:[NSValue valueWithRect: newFrame]];
      [control.editingDelegate updateGuide:control];
    }
    startDragPoint=newDragLocation;
}

-(void)mouseUp:(NSEvent *)theEvent{
    [[self undoManager] endUndoGrouping];
    MMPControl* control = (MMPControl*)[self superview];
    [control.editingDelegate updateGuide:nil];
}

@end
