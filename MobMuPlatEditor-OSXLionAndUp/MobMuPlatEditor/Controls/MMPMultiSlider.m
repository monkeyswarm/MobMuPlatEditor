//
//  MMPMultiSlider.m
//  MobMuPlatEditor
//
//  Created by Daniel Iglesia on 3/28/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import "MMPMultiSlider.h"
#define SLIDER_HEIGHT 20
#define CORNER_RADIUS 4

@implementation MMPMultiSlider

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        
        self.address=@"/myMultiSlider";
        
        //create border box
        box = [[NSView alloc] init];
        [box setWantsLayer:YES];
        box.layer.borderWidth=2;
        [self addSubview:box];
        
        [self setRange:8];
        
        [self setColor:self.color];
        [self setFrame:frame];
        [self addHandles];
    }
    return self;
}

-(void)hackRefresh{
    [super hackRefresh];
    for(NSView* head in headViewArray)head.layer.cornerRadius=CORNER_RADIUS;
    box.layer.borderWidth=2;
}

-(void)setFrame:(NSRect)frameRect{
    [super setFrame:frameRect];
    headWidth=frameRect.size.width/_range;
    box.frame=CGRectMake(0, SLIDER_HEIGHT/2, frameRect.size.width, frameRect.size.height-SLIDER_HEIGHT);
    for(int i=0;i<[headViewArray count];i++){
        NSView* head = [headViewArray objectAtIndex:i];
        head.frame =  CGRectMake( i*headWidth, frameRect.size.height-SLIDER_HEIGHT, headWidth, SLIDER_HEIGHT );
    }

}

-(void)setColor:(NSColor *)color{
    [super setColor:color];
    box.layer.borderColor=color.CGColor;
    for(NSView* head in headViewArray)head.layer.backgroundColor = color.CGColor;
}

-(void)setRangeUndoable:(NSNumber*)inVal{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setRangeUndoable:) object:[NSNumber numberWithInt:[self range]]];
    [self setRange:[inVal intValue]];
}

-(void)setRange:(int)inRange{
   
    _range=inRange;
    if(_range<=0)_range=1;
    if(_range>1000)_range=1000;
    
    //remove and remake headViewArray and _valueArray
    if(headViewArray)for(NSView* head in headViewArray)[head removeFromSuperview];
    
    headViewArray = [[NSMutableArray alloc]initWithCapacity:self.range];
    _valueArray = [[NSMutableArray alloc] initWithCapacity:self.range];
    
    headWidth=self.frame.size.width/_range;
    for(int i=0;i<_range;i++){
        [_valueArray addObject:[NSNumber numberWithFloat:0]];
        
        NSView* headView;
        headView = [[NSView alloc]initWithFrame:CGRectMake( i*headWidth, self.frame.size.height-SLIDER_HEIGHT, headWidth, SLIDER_HEIGHT)];
        [headView setWantsLayer:YES];
        //tick = [[UIView alloc]initWithFrame:CGRectMake(6-1+i*((frame.size.width-12)/(range-1)), 6, 2, 8)];
            
        headView.layer.backgroundColor=self.color.CGColor;
        headView.layer.cornerRadius=CORNER_RADIUS;
        [headViewArray addObject:headView];
        [self addSubview:headView];
    }
    
    [self bringUpHandle];
}

//send out OSC message of all values as a list
-(void)sendValue{
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:self.address];
    
    //NSString* formatString=@"";
    //for(int i=0;i<[_valueArray count];i++)formatString = [formatString stringByAppendingString:@"f"];
    //[formattedMessageArray addObject:formatString];//tags string
    for(NSNumber* val in _valueArray)[formattedMessageArray addObject:val];//add values
    [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
}



-(void)mouseDown:(NSEvent *)event{
    [super mouseDown:event];
    if(![self.editingDelegate isEditing]){
        CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
            
        int headIndex = (int)(point.x/headWidth);//find out which slider is touched
        headIndex = MAX(MIN(headIndex, _range-1), 0);//clip to range
    
        float clippedPointY = MAX(MIN(point.y, self.frame.size.height-SLIDER_HEIGHT/2), SLIDER_HEIGHT/2);
        float headVal = 1.0-( (clippedPointY-SLIDER_HEIGHT/2) / (self.frame.size.height - SLIDER_HEIGHT) );
        [_valueArray setObject:[NSNumber numberWithFloat:headVal] atIndexedSubscript:headIndex];
        [self sendValue];
        
        //update position
        NSView* currHead = [headViewArray objectAtIndex:headIndex];
        CGRect newFrame = CGRectMake(headIndex*headWidth, clippedPointY-SLIDER_HEIGHT/2, headWidth, SLIDER_HEIGHT);
        currHead.frame=newFrame;
        //printf("\n%.2f %.2f %.2f %.2f", currHead.frame.origin.x, currHead.frame.origin.y, currHead.frame.size.width, currHead.frame.size.height );
        currHead.layer.backgroundColor=self.highlightColor.CGColor;
        currHeadIndex=headIndex;
    }
}

-(void)mouseDragged:(NSEvent *)event
{
    [super mouseDragged:event];
    if(![self.editingDelegate isEditing]){
        CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
        int headIndex = (int)(point.x/headWidth);
        headIndex = MAX(MIN(headIndex, _range-1), 0);
        
        float clippedPointY = MAX(MIN(point.y, self.frame.size.height-SLIDER_HEIGHT/2), SLIDER_HEIGHT/2);
        float headVal = 1.0-( (clippedPointY-SLIDER_HEIGHT/2) / (self.frame.size.height - SLIDER_HEIGHT) );
        [_valueArray setObject:[NSNumber numberWithFloat:headVal] atIndexedSubscript:headIndex];
        [self sendValue];
        NSView* currHead = [headViewArray objectAtIndex:headIndex];
        CGRect newFrame = CGRectMake(headIndex*headWidth, clippedPointY-SLIDER_HEIGHT/2, headWidth, SLIDER_HEIGHT);
        currHead.frame=newFrame;
      
      //also set elements between prev touch and move, to avoid "skipping" on fast drag
      if(abs(headIndex-currHeadIndex)>1){
        int minTouchIndex = MIN(headIndex, currHeadIndex);
        int maxTouchIndex = MAX(headIndex, currHeadIndex);
        
        float minTouchedValue = [[_valueArray objectAtIndex:minTouchIndex] floatValue];
        float maxTouchedValue = [[_valueArray objectAtIndex:maxTouchIndex] floatValue];
        //NSLog(@"skip within %d (%.2f) to %d(%.2f)", minTouchIndex, [[_valueArray objectAtIndex:minTouchIndex] floatValue], maxTouchIndex, [[_valueArray objectAtIndex:maxTouchIndex] floatValue]);
        for(int i=minTouchIndex+1;i<maxTouchIndex;i++){
          float percent = ((float)(i-minTouchIndex))/(maxTouchIndex-minTouchIndex);
          float interpVal = (maxTouchedValue - minTouchedValue) * percent  + minTouchedValue ;
          //NSLog(@"%d %.2f %.2f", i, percent, interpVal);
          [_valueArray setObject:[NSNumber numberWithFloat:interpVal] atIndexedSubscript:i];
        }
        [self updateThumbsFrom:minTouchIndex+1 to:maxTouchIndex-1];
      }

        
        if(headIndex!=currHeadIndex){//dragged to new head
            NSView* prevHead = [headViewArray objectAtIndex:currHeadIndex];
            prevHead.layer.backgroundColor=self.color.CGColor;//change prev head back
            currHead.layer.backgroundColor=self.highlightColor.CGColor;
            currHeadIndex=headIndex;
        }
    }
}

/*-(void)showVals{
    printf("\n");
    for(NSNumber *num in _valueArray) printf("%.2f ", [num floatValue]);
}*/

-(void)mouseUp:(NSEvent *)event  {
    [super mouseUp:event];
    if(![self.editingDelegate isEditing]){
            for(NSView* head in headViewArray) head.layer.backgroundColor=self.color.CGColor;
    
    }
}

//on receive a new list into valueArray, redraw the slider positions

-(void)updateThumbsFrom:(int)start to:(int)end{
  for(int i=start;i<=end;i++){
    NSNumber* val = [_valueArray objectAtIndex:i];
    NSView* currHead = [headViewArray objectAtIndex:i];
    CGRect newFrame = CGRectMake(i*headWidth, (1.0-[val floatValue])*(self.frame.size.height-SLIDER_HEIGHT), headWidth, SLIDER_HEIGHT);
    currHead.frame=newFrame;
  }
}

-(void)updateThumbs{
  [self updateThumbsFrom:0 to:[_valueArray count]-1];
}

//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
-(void)receiveList:(NSArray *)inArray{
    BOOL sendVal=YES;
    //if message preceded by "set", then set "sendVal" flag to NO, and strip off set and make new messages array without it
    if ([inArray count]>0 && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"set"]){
        NSRange newRange = (NSRange){1, [inArray count]-1};
        inArray = [inArray subarrayWithRange: newRange];
        //printf("\nset!");
        sendVal=NO;
    }
  
  if ([inArray count]>1 && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"allVal"] ){
    
    float val = [[inArray objectAtIndex:1] floatValue];
    for(int i=0;i<[_valueArray count];i++){
      [_valueArray setObject:[NSNumber numberWithFloat:val] atIndexedSubscript:i];
    }
    [self updateThumbs];
    if(sendVal)[self sendValue];
  }
  
  
    //list of values to be interpreted as new slider positions (and new length of multislider)
   else if ([inArray count]>0 ){
        NSMutableArray* newValArray = [[NSMutableArray alloc]init];
        
        for(NSNumber* val in inArray)[newValArray addObject:val];
        
        if([newValArray count] != _range) [self setRange:[newValArray count]];
        [self setValueArray:newValArray];
        for(int i=0;i<[_valueArray count];i++){
            NSNumber* val = [_valueArray objectAtIndex:i];
            if([val floatValue]<0 || [val floatValue]>1 ){
                float newFloat = MAX(MIN([val floatValue], 1), 0);//clip
                [_valueArray setObject:[NSNumber numberWithFloat:newFloat] atIndexedSubscript:i];
            }
            
        }
        [self updateThumbs];
        if(sendVal)[self sendValue];
        
    }
}


//coder for copy/paste

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
	[coder encodeInt:self.range forKey:@"range"];
    
}

- (id)initWithCoder:(NSCoder *)coder {
    
    if(self=[super initWithCoder:coder]){
        [self setRange:[coder decodeIntForKey:@"range"]];
    }
    return self;
}


@end
