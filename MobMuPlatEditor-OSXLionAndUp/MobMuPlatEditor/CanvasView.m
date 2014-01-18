//
//  CanvasView.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/26/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import "CanvasView.h"
#import "MMPControl.h"
@implementation CanvasView
@synthesize bgColor;

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _pageCount=1;
        _pageViewIndex=0;
        [self setWantsLayer:YES];
        [self setBgColor:[NSColor colorWithCalibratedRed:.5 green:.5 blue:.5 alpha:1]];
        
        buttonBlankView = [[NSImageView alloc]initWithFrame:CGRectMake(10, 10, 30, 30)];
        [buttonBlankView setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"infoicon_100x100.png"]]];
        [self addSubview:buttonBlankView];
    }
    
    return self;
}

-(BOOL) isFlipped{
    return YES;
}
-(void)setBgColor:(NSColor *)inbgColor{
    bgColor = inbgColor;
    self.layer.backgroundColor = [MMPControl CGColorFromNSColor:inbgColor];
}

-(void)mouseDown:(NSEvent *)theEvent{
    [super mouseDown:theEvent];
    if(_editingDelegate && [_editingDelegate respondsToSelector:@selector(canvasClicked)]){
        [self.editingDelegate canvasClicked];
    }
}

-(void)setPageViewIndex:(int)inIndex{
    _pageViewIndex=inIndex;
    int offset;
    switch(_canvasType){
        case (canvasTypeIPhone3p5Inch):
            offset = (_isOrientationLandscape ? 480:320);
            break;
        case (canvasTypeIPhone4Inch):
            offset = (_isOrientationLandscape ? 568:320);
            break;
        case (canvasTypeIPad):
            offset = (_isOrientationLandscape ? 1024:768);
            break;
    }
    //slide to new offset to show the page of controls
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.3f]; // However long you want the slide to take
    
    [[self animator] setFrameOrigin:CGPointMake(-1.0*offset*_pageViewIndex, 0)];
    
    [NSAnimationContext endGrouping];
    
    
}

-(void)refresh{//called on changing pagecount, canvas, orientation
    int width; int height;
    switch(_canvasType){
        case (canvasTypeIPhone3p5Inch):
            width = (_isOrientationLandscape ? 480:320);
            height = (_isOrientationLandscape ? 320:480);
            [buttonBlankView setFrame:CGRectMake(10, 10, 30, 30)];
            break;
        case (canvasTypeIPhone4Inch):
            width = (_isOrientationLandscape ? 568:320);
            height = (_isOrientationLandscape ? 320:568);
             [buttonBlankView setFrame:CGRectMake(10, 10, 30, 30)];
            break;
        case (canvasTypeIPad):
            width = (_isOrientationLandscape ? 1024:768);
            height = (_isOrientationLandscape ? 768:1024);
             [buttonBlankView setFrame:CGRectMake(20, 20, 40, 40)];
            break;
    }
    [self setFrame:CGRectMake(0, 0, width*_pageCount, height)];
    [self setPageViewIndex:_pageViewIndex];
}

-(void)setPageCount:(int)pageCount{
    _pageCount=pageCount;
    [self refresh];
}

-(void)setCanvasType:(int)canvasType{
    _canvasType=canvasType;
    [self refresh];
}

-(void)setIsOrientationLandscape:(BOOL)isOrientationLandscape{
    _isOrientationLandscape=isOrientationLandscape;
    [self refresh];
}

-(BOOL)canBecomeFirstResponder{
    return YES;
}

-(void)keyDown:(NSEvent*)event{//this is for keyboard-delete after "select all" which switches responder to canvas view isntead of a (nonexistant) mmpcontrol
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

-(IBAction)deleteBackward:(id)sender{
    [self.editingDelegate controlEditDelete];
}


@end
