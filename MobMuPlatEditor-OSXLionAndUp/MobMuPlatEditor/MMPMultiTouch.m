//
//  MMPMultiTouch.m
//  MobMuPlatEditor
//
//  Created by diglesia on 2/24/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPMultiTouch.h"
#define BORDER_WIDTH 3
#define CURSOR_WIDTH 2
#define TOUCH_VIEW_RADIUS 20


@interface MMPMultiTouch () {
  NSMutableArray* _cursorStack;
  NSMutableArray* _touchStack;
  NSMutableArray* _touchByVoxArray;//add, then hold NSNull values for empty voices
  
  NSView* borderView;
  TouchView* _currTouchView;
  BOOL _createdTouchOnMouseDown;
  MyTouch* _currMyTouch;
}

@end

@implementation MMPMultiTouch

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.address=@"/myMultiTouch";
    //self.backgroundColor = [UIColor purpleColor];
    //[self setMultipleTouchEnabled:YES];
    //self.clipsToBounds = YES;
    borderView = [[NSView alloc]init];
    [borderView setWantsLayer:YES];
    borderView.layer.borderWidth = BORDER_WIDTH;
    borderView.layer.borderColor = [MMPControl CGColorFromNSColor:self.color];
    [self addSubview:borderView];

    
    _cursorStack = [[NSMutableArray alloc] init];
    _touchStack = [[NSMutableArray alloc] init];
    _touchByVoxArray = [[NSMutableArray alloc] init];
    [self setFrame:frame];
    
    [self addHandles];
  }
  return self;
}

-(void)hackRefresh{
  [super hackRefresh];
  borderView.layer.borderWidth = BORDER_WIDTH;
  //todo clear mock touches
}

-(void)setFrame:(NSRect)frameRect{
  [super setFrame:frameRect];
  [borderView setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
  [self removeTouches:[_touchStack copy]];
  
}

-(void)setColor:(NSColor *)inColor{
  [super setColor:inColor];
  borderView.layer.borderColor=[MMPControl CGColorFromNSColor:inColor];

}

//clip touch views to bounds
-(CGPoint)clipPoint:(CGPoint)inPoint{
  CGPoint outPoint;
  outPoint.x = MIN(MAX(0, inPoint.x), self.frame.size.width);
  outPoint.y = MIN(MAX(0, inPoint.y), self.frame.size.height);
  return outPoint;
}

-(CGPoint)normAndClipPoint:(CGPoint)inPoint{
  CGPoint outPoint;
  outPoint.x = inPoint.x/self.frame.size.width;
  outPoint.x = MIN(1, MAX(-1, outPoint.x));
  outPoint.y = 1.0-(inPoint.y/self.frame.size.height);
  outPoint.y = MIN(1, MAX(-1, outPoint.y));
  return outPoint;
}

-(void)mouseDown:(NSEvent *)theEvent{
  [super mouseDown:theEvent];
  //NSLog(@"down view");
  if(![self.editingDelegate isEditing]){
    
    CGPoint hitTestPoint = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
    CGPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    NSView* topView = [self hitTest:hitTestPoint];
    if(topView==borderView || [topView isMemberOfClass:[NSView class]]){//topview or cursors
      //cursor
      Cursor* cursor = [[Cursor alloc]init];
      
      
      cursor.cursorX = [[NSView alloc]initWithFrame:CGRectMake(5, 5, self.frame.size.width, CURSOR_WIDTH)];
      cursor.cursorY = [[NSView alloc]initWithFrame:CGRectMake(5, 5, CURSOR_WIDTH, self.frame.size.height)];
      [cursor.cursorX setWantsLayer:YES];
      [cursor.cursorY setWantsLayer:YES];
      cursor.cursorX.layer.backgroundColor = [self.highlightColor CGColor];
      cursor.cursorY.layer.backgroundColor = [self.highlightColor CGColor];
      //cursor.cursorX.userInteractionEnabled=NO;
      //cursor.cursorY.userInteractionEnabled=NO;
      [self addSubview:cursor.cursorX];
      [self addSubview:cursor.cursorY];
      
      [_cursorStack addObject:cursor];
      
      
      //Touchview
      TouchView* tv = [[TouchView alloc]initAtPoint:[self clipPoint:localPoint]];
      [tv setWantsLayer:YES];
      //tv.layer.backgroundColor = [self.highlightColor CGColor];
      tv.layer.borderColor = [[NSColor blackColor] CGColor];
      tv.layer.borderWidth = CURSOR_WIDTH;
      tv.layer.cornerRadius = TOUCH_VIEW_RADIUS;
      
      tv.editingDelegate = self.editingDelegate;
      tv.parentView = self;
      [self addSubview:tv];
      
      _currTouchView = tv;
      _createdTouchOnMouseDown = YES;
      
      //stack
      MyTouch* myTouch = [[MyTouch alloc]init];
      myTouch.point = [self normAndClipPoint:localPoint];
      //myTouch.origEvent = theEvent;
      //myTouch.state = 1;
      
      myTouch.touchView = tv;
      tv.myTouch = myTouch;
      _currMyTouch = myTouch;
      
      [_touchStack addObject:myTouch];
      
      
      
      
      
      //poly vox
      BOOL added=NO;
      for(id element in _touchByVoxArray){//find NSNull vox slot
        if(element == [NSNull null]){
          int index = [_touchByVoxArray indexOfObject:element];
          myTouch.polyVox = index+1;
          [_touchByVoxArray replaceObjectAtIndex:index withObject:myTouch];
          added=YES;
          break;
        }
      }
      if(!added){
        [_touchByVoxArray addObject:myTouch];//add to end
        int index = [_touchByVoxArray indexOfObject:myTouch];
        myTouch.polyVox = index+1;
      }
      
      
      NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
      [formattedMessageArray addObject:self.address];
      [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"siiff"]];//tags
      [formattedMessageArray addObject:@"touch"];
      [formattedMessageArray addObject:[NSNumber numberWithInt:myTouch.polyVox]];
      [formattedMessageArray addObject:[NSNumber numberWithInt:1]];
      [formattedMessageArray addObject:[NSNumber numberWithFloat:myTouch.point.x]];
      [formattedMessageArray addObject:[NSNumber numberWithFloat:myTouch.point.y]];
      [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
      
      
      [self sendState];
      
      if([_touchStack count]>0) borderView.layer.borderColor=[MMPControl CGColorFromNSColor: self.highlightColor];
      [self redrawCursors];
  
    }
    else if ([topView isKindOfClass:[TouchView class]]){
      _currTouchView = (TouchView*)topView;
      _currMyTouch = _currTouchView.myTouch;
      _createdTouchOnMouseDown=NO;
    }
    else {
      _currTouchView = nil;
      _createdTouchOnMouseDown=NO;
    }
  }
  
}

-(void)mouseDragged:(NSEvent *)theEvent{
  [super mouseDragged:theEvent];
  //NSLog(@"drag view");
  if(![self.editingDelegate isEditing]){
    
    //touchview
    CGPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    CGPoint clipPoint = [self clipPoint:point];
    [_currTouchView setFrame:CGRectMake(clipPoint.x-TOUCH_VIEW_RADIUS, clipPoint.y-TOUCH_VIEW_RADIUS, TOUCH_VIEW_RADIUS*2, TOUCH_VIEW_RADIUS*2)];
    
    
    //for(MyTouch* myTouch in _touchStack){//TODO optimze! just get object by reference somehow? or use "indexOfObject"
      //if(myTouch.origEvent==theEvent){
        _currMyTouch.point = [self normAndClipPoint:point];
      
        //touchview
        //[_currTouchView setFrame:CGRectMake(point.x-TouchViewRadius, point.y-TouchViewRadius, TouchViewRadius*2, TouchViewRadius*2)];
     
        NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
        [formattedMessageArray addObject:self.address];
        [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"siiff"]];//tags
        [formattedMessageArray addObject:@"touch"];
        [formattedMessageArray addObject:[NSNumber numberWithInt:_currMyTouch.polyVox]];
        [formattedMessageArray addObject:[NSNumber numberWithInt:2]];
        [formattedMessageArray addObject:[NSNumber numberWithFloat:_currMyTouch.point.x]];
        [formattedMessageArray addObject:[NSNumber numberWithFloat:_currMyTouch.point.y]];
        [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
     
    //}
  
  [self sendState];
  [self redrawCursors];
  }
}

-(void)mouseUp:(NSEvent *)theEvent{
  [super mouseUp:theEvent];
  if(![self.editingDelegate isEditing]){
    
    //NSLog(@"click count %d", [theEvent clickCount]);
    if([theEvent clickCount]==1 && _createdTouchOnMouseDown==NO){
      //[_currTouchView removeFromSuperview];
    
      NSMutableArray* touchesToRemoveArray = [[NSMutableArray alloc] init];
      //for(MyTouch* myTouch in _touchStack){//TODO optimze! just get object by reference somehow? or use "indexOfObject"!
			//if(myTouch.origEvent==theEvent){
        CGPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        _currMyTouch.point = [self normAndClipPoint:point];//necc??
        [touchesToRemoveArray addObject:_currMyTouch];
        //CGPoint currPoint= [touch locationInView:self];
        //NSLog(@"remove touches : %.2f %.2f", currPoint.x, currPoint.y);
      //}
      //}
      [self removeTouches:touchesToRemoveArray];
  
          }
  }
}

-(void)removeTouches:(NSArray*)touchesToRemoveArray{
  [_touchStack removeObjectsInArray:touchesToRemoveArray];
  //curosrs
  for(Cursor* cursor in [_cursorStack subarrayWithRange:NSMakeRange([_touchStack count], [_cursorStack count]-[_touchStack count])] ){
    [cursor.cursorX removeFromSuperview];
    [cursor.cursorY removeFromSuperview];
  }
  [_cursorStack removeObjectsInRange:NSMakeRange([_touchStack count], [_cursorStack count]-[_touchStack count])];
  
  //
  for(MyTouch* myTouch in touchesToRemoveArray){
    [myTouch.touchView removeFromSuperview];
    
    
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:self.address];
    [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"siiff"]];//tags
    [formattedMessageArray addObject:@"touch"];
    [formattedMessageArray addObject:[NSNumber numberWithInt:myTouch.polyVox]];
    [formattedMessageArray addObject:[NSNumber numberWithInt:0]];
    [formattedMessageArray addObject:[NSNumber numberWithFloat:myTouch.point.x]];
    [formattedMessageArray addObject:[NSNumber numberWithFloat:myTouch.point.y]];
    [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
    
    
    [_touchByVoxArray replaceObjectAtIndex:[_touchByVoxArray indexOfObject:myTouch] withObject:[NSNull null]];
  }
  
  [self sendState];
  if([_touchStack count]==0) borderView.layer.borderColor=[MMPControl CGColorFromNSColor:self.color ];
  [self redrawCursors];

}

/*-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
	[self touchesEnded:touches withEvent:event];
}*/

-(void)sendState{
  //all are triplets
  //send stack as is:"/touchesByTime"
  //send by vox with nulls removed:
  //send prev sorted by x,y
  
  NSMutableArray* valArray = [NSMutableArray arrayWithArray:_touchStack];
  /*for(UITouch* touch in _touchStack){
   CGPoint currPoint= [touch locationInView:self];
   [valArray addObject:[NSNumber numberWithInt:[_touchByVoxArray indexOfObject:touch]+1]];//float or int?
   [valArray addObject:[NSNumber numberWithFloat:currPoint.x]];
   [valArray addObject:[NSNumber numberWithFloat:currPoint.y]];
   }*/
  
  //send as is
  NSMutableArray* msgArray = [[NSMutableArray alloc]init];
  [msgArray addObject:self.address];
  NSMutableString* tags = [[NSMutableString alloc]initWithString:@"s"];
  [msgArray addObject:tags];
  [msgArray addObject:@"touchesByTime"];
  for(MyTouch* myTouch in valArray){
    [tags appendString:@"iff"];
    [msgArray addObject:[NSNumber numberWithInt:myTouch.polyVox]];//float or int?
    [msgArray addObject:[NSNumber numberWithFloat:myTouch.point.x]];
    [msgArray addObject:[NSNumber numberWithFloat:myTouch.point.y]];
  }
  //[self.controlDelegate sendGUIMessageArray:msgArray];
  [self.editingDelegate sendFormattedMessageArray:msgArray];
  
  //sort via vox
  [valArray sortUsingComparator:^NSComparisonResult(MyTouch* myTouch1, MyTouch* myTouch2){
    if(myTouch1.polyVox < myTouch2.polyVox) return NSOrderedAscending;
    else if (myTouch1.polyVox > myTouch2.polyVox) return NSOrderedDescending;
    else return NSOrderedSame;
  }];
  
  [msgArray removeAllObjects];
  [msgArray addObject:self.address];
  [tags setString:@"s"];
  [msgArray addObject:tags];
  [msgArray addObject:@"touchesByVox"];
  for(MyTouch* myTouch in valArray){
    [tags appendString:@"iff"];
    [msgArray addObject:[NSNumber numberWithInt:myTouch.polyVox]];//float or int?
    [msgArray addObject:[NSNumber numberWithFloat:myTouch.point.x]];
    [msgArray addObject:[NSNumber numberWithFloat:myTouch.point.y]];
  }
  //ios [self.controlDelegate sendGUIMessageArray:msgArray];
  [self.editingDelegate sendFormattedMessageArray:msgArray];
  
  //sort via X
  [valArray sortUsingComparator:^NSComparisonResult(MyTouch* myTouch1, MyTouch* myTouch2){
    
    if(myTouch1.point.x < myTouch2.point.x) return NSOrderedAscending;
    else if (myTouch1.point.x > myTouch2.point.x) return NSOrderedDescending;
    else return NSOrderedSame;
  }];
  
  [msgArray removeAllObjects];
  [msgArray addObject:self.address];
  [msgArray addObject:tags];
  [tags setString:@"s"];
  [msgArray addObject:@"touchesByX"];
  
  for(MyTouch* myTouch in valArray){
    [tags appendString:@"iff"];
    [msgArray addObject:[NSNumber numberWithInt:myTouch.polyVox]];//float or int?
    [msgArray addObject:[NSNumber numberWithFloat:myTouch.point.x]];
    [msgArray addObject:[NSNumber numberWithFloat:myTouch.point.y]];
  }
  //ios [self.controlDelegate sendGUIMessageArray:msgArray];
  [self.editingDelegate sendFormattedMessageArray:msgArray];
  
  //sort via Y
  [valArray sortUsingComparator:^NSComparisonResult(MyTouch* myTouch1, MyTouch* myTouch2){
    
    if(myTouch1.point.y < myTouch2.point.y) return NSOrderedAscending;
    else if (myTouch1.point.y > myTouch2.point.y) return NSOrderedDescending;
    else return NSOrderedSame;
  }];
  
  [msgArray removeAllObjects];
  [msgArray addObject:self.address];
  [msgArray addObject:tags];
  [tags setString:@"s"];
  [msgArray addObject:@"touchesByY"];
  for(MyTouch* myTouch in valArray){
    [tags appendString:@"iff"];
    [msgArray addObject:[NSNumber numberWithInt:myTouch.polyVox]];//float or int?
    [msgArray addObject:[NSNumber numberWithFloat:myTouch.point.x]];
    [msgArray addObject:[NSNumber numberWithFloat:myTouch.point.y]];
  }
  //ios [self.controlDelegate sendGUIMessageArray:msgArray];
  [self.editingDelegate sendFormattedMessageArray:msgArray];
  
  
}

-(void)redrawCursors{
	for(MyTouch* myTouch in _touchStack){
    Cursor* currCursor = [_cursorStack objectAtIndex:[_touchStack indexOfObject:myTouch]] ;
    
    /*ios CGPoint HorizCenter=CGPointMake(self.frame.size.width/2, (1.0-myTouch.point.y)*self.frame.size.height);
    CGPoint VertCenter=CGPointMake(myTouch.point.x*self.frame.size.width, self.frame.size.height/2);
		currCursor.cursorX center=HorizCenter;
		currCursor.cursorY.center=VertCenter;
    */
    
    CGRect horizFrame = CGRectMake(0, (1.0-myTouch.point.y)*self.frame.size.height-CURSOR_WIDTH/2, self.frame.size.width, CURSOR_WIDTH);
    [currCursor.cursorX setFrame:horizFrame];
    CGRect vertFrame = CGRectMake(myTouch.point.x*self.frame.size.width-CURSOR_WIDTH/2, 0, CURSOR_WIDTH, self.frame.size.height);
    [currCursor.cursorY setFrame:vertFrame];
    
    
  }
  
}


@end


@implementation Cursor //handle add/remove from view, and color, touch property in main class

@end

@implementation MyTouch

@end


@implementation TouchView

-(id)initAtPoint:(CGPoint)point{
  self = [super initWithFrame:CGRectMake(point.x-TOUCH_VIEW_RADIUS, point.y-TOUCH_VIEW_RADIUS, TOUCH_VIEW_RADIUS*2, TOUCH_VIEW_RADIUS*2)];
  return self;
}

@end