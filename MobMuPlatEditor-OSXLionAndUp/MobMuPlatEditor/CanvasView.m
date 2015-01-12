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
        
        _buttonBlankView = [[NSImageView alloc]initWithFrame:CGRectMake(10, 10, 30, 30)];
        [_buttonBlankView setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"infoicon_100x100.png"]]];
        [self addSubview:_buttonBlankView];
    }
    
    return self;
}

-(BOOL) isFlipped{
    return YES;
}
-(void)setBgColor:(NSColor *)inbgColor{
    bgColor = inbgColor;
  self.layer.backgroundColor = inbgColor.CGColor;
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
        case (canvasTypeAndroid7Inch):
            offset = (_isOrientationLandscape ? 960:600); //different
            break;
        case(canvasTypeWatch):
          offset = 140;
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
            [_buttonBlankView setFrame:CGRectMake(10, 10, 30, 30)];
            break;
        case (canvasTypeIPhone4Inch):
            width = (_isOrientationLandscape ? 568:320);
            height = (_isOrientationLandscape ? 320:568);
             [_buttonBlankView setFrame:CGRectMake(10, 10, 30, 30)];
            break;
        case (canvasTypeIPad):
            width = (_isOrientationLandscape ? 1024:768);
            height = (_isOrientationLandscape ? 768:1024);
             [_buttonBlankView setFrame:CGRectMake(20, 20, 40, 40)];
            break;
      case (canvasTypeAndroid7Inch):
        width = (_isOrientationLandscape ? 960:600);
        height = (_isOrientationLandscape ? 552:912);
        [_buttonBlankView setFrame:CGRectMake(20, 20, 40, 40)];
        break;
      case (canvasTypeWatch):
        width = 140;
        height = 140;
        break;
    }
    [self setFrame:CGRectMake(0, 0, width*_pageCount, height)];
    [self setPageViewIndex:_pageViewIndex];
}

-(void)refreshGuides; {
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
  if(![_editingDelegate guidesEnabled]) return;
  NSBezierPath *line = [NSBezierPath bezierPath];
  [line setLineWidth:1.0];
  NSColor * white = [NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:.2];
  [white set];

  for (int i = 0; i <self.frame.size.width; i+=[_editingDelegate guidesX]) {
    [line moveToPoint:NSMakePoint(i, NSMinY([self bounds]))];
    [line lineToPoint:NSMakePoint(i, NSMaxY([self bounds]))];
  }

  for (int i = 0; i <self.frame.size.height; i+=[_editingDelegate guidesY]) {
    [line moveToPoint:NSMakePoint(NSMinX([self bounds]), i)];
    [line lineToPoint:NSMakePoint(NSMaxX([self bounds]), i)];
  }
  
  [line stroke];
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
