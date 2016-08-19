//
//  MMPKnob.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/30/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import "MMPKnob.h"
#define ROTATION_PAD_RAD .7 //angle of the non-scrollable part at the bottom of the knob
#define EXTRA_RADIUS 10 //how many pixels from the edge of the knob are the tick marks
#define TICK_DIM 10 //size of tick marks

@implementation MMPKnob

int osxMinorVersion=-1;

//OSX 10.7 and 10.8 handle angles, rotation differently, so I need to know what version we are running.
+(int)osxMinorVersion{
    
    if(osxMinorVersion!=-1) return osxMinorVersion;//if we have already found it, send it out
    //otherwise, find it!
    else{
        osxMinorVersion=8;//assume 8;
   
        NSString* versionString = [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"];
        NSArray* versions = [versionString componentsSeparatedByString:@"."];
        //check( versions.count >= 2 );
        
        if ( versions.count >= 2 ) {
            osxMinorVersion = (int)[versions[1] integerValue];
            NSLog(@"OSX minor version:%d", osxMinorVersion);
            return osxMinorVersion;
        }
        else return osxMinorVersion;
    }
}

- (id)initWithFrame:(NSRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        self.address=@"/myKnob";
        
        [self setRange:1];//default
        
        knobView = [[NSView alloc]init];//create, don't set frame until setFrame
        [knobView setWantsLayer:YES];
        knobView.layer.backgroundColor=self.color.CGColor;
        [self addSubview:knobView];
        
        indicatorView=[[NSView alloc]init ];//create, don't set frame until setFrame
        [indicatorView setWantsLayer:YES];
    	indicatorView.layer.cornerRadius=3;
        [self addSubview:indicatorView];
        
		[self setColor:self.color];
        //[self setFrame:frame];
		[self addHandles];
      [self resizeSubviewsWithOldSize:self.frame.size];
        
        _value=0;
        [self updateIndicator];
        
    }
    
    return self;
}


-(void)setIndicatorColorUndoable:(NSColor*)inColor{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setIndicatorColorUndoable:) object:self.indicatorColor];
    [self setIndicatorColor:inColor];
}

-(void)setIndicatorColor:(NSColor*)inColor{
    _indicatorColor = inColor;
    indicatorView.layer.backgroundColor=inColor.CGColor;
}

-(void)hackRefresh{
    [super hackRefresh];
    knobView.layer.cornerRadius=radius;
    indicatorView.layer.cornerRadius=3;
    indicatorView.layer.backgroundColor=_indicatorColor.CGColor;
    for(NSView* dot in tickViewArray)dot.layer.cornerRadius=TICK_DIM/2;
    [self updateIndicator];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize{ //TODO use layoutSubviews.
  [super resizeSubviewsWithOldSize:oldBoundsSize];


  dim = self.frame.size.width-((EXTRA_RADIUS+TICK_DIM)*2);//diameter of circle

  //rounded up to nearest int - for corner radius
  radius = (float)(int)(dim/2+.5);

  [knobView setFrame:CGRectMake(EXTRA_RADIUS+TICK_DIM, EXTRA_RADIUS+TICK_DIM, dim, dim)];
  knobView.layer.cornerRadius = radius;

  indicatorDim=dim/2+2;
  indicatorThickness = dim/8;

  centerPoint=CGPointMake(dim/2+EXTRA_RADIUS+TICK_DIM, dim/2+EXTRA_RADIUS+TICK_DIM);
  [indicatorView setFrame:CGRectMake(centerPoint.x-indicatorThickness/2,centerPoint.y-indicatorThickness/2, indicatorThickness, indicatorDim)];
  [self updateIndicator];

  //tickmarks
  for(NSView* dot in tickViewArray){
    float angle= /*M_PI/2+M_PI-*/((float)[tickViewArray indexOfObject:dot]/(tickViewArray.count - 1) * (M_PI*2-ROTATION_PAD_RAD*2)+ROTATION_PAD_RAD+M_PI/2);/**/
    float xPos=(dim/2+EXTRA_RADIUS+TICK_DIM/2)*cos(angle);
    float yPos=(dim/2+EXTRA_RADIUS+TICK_DIM/2)*sin(angle);
    [dot setFrame:CGRectMake(centerPoint.x+xPos-(TICK_DIM/2),centerPoint.y+yPos-(TICK_DIM/2), TICK_DIM, TICK_DIM)];
  }
}

-(void)setFrame:(NSRect)frameRect{
    //unlike other MMPControls, we always keep this frame square
    
    //get larger of the dragged width and height to make a square
    int newDim = (frameRect.size.width>frameRect.size.height) ? frameRect.size.width : frameRect.size.height;
    CGRect squareFrame = CGRectMake(frameRect.origin.x, frameRect.origin.y, newDim, newDim);
    [super setFrame:squareFrame];
}

-(void)setColor:(NSColor *)color{
    [super setColor:color];
    knobView.layer.backgroundColor=color.CGColor;
    for(NSView* dot in tickViewArray)dot.layer.backgroundColor = color.CGColor;
}

-(void)setRangeObjectUndoable:(NSNumber*)inRangeObject{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setRangeObjectUndoable:) object:[NSNumber numberWithInt:self.range] ];
    [self setRange:[inRangeObject intValue] ];
}

-(void)setLegacyRange:(int)range {
  // old mode, default range is 2, which is range 0 to 1 float. translate that to new range of "1".
  if (range == 2) range = 1;
  [self setRange:range];
}

-(void)setRange:(int)inRange{
    
    _range=inRange;
    if(_range<1)_range=1;
    if(_range>1000)_range=1000;
    
    //remove and remake the tickViewArray
    for(NSView* dot in tickViewArray){
        [dot removeFromSuperview];
    }
    tickViewArray = [[NSMutableArray alloc]init];

    NSUInteger tickRange = _range == 1 ? 2 : _range;
    for(int i=0;i<tickRange;i++){
        NSView* dot = [[NSView alloc]init];
        [dot setWantsLayer:YES];
        dot.layer.backgroundColor=self.color.CGColor;
        dot.layer.cornerRadius=TICK_DIM/2;
        //printf("\n%.2f, %.2f", dot.center.x, dot.center.y);
        [self addSubview:dot];
        [tickViewArray addObject:dot];
    }
  //[self setNeedsLayout:YES];
  [self resizeSubviewsWithOldSize:self.frame.size];
  [self bringUpHandle]; // keep new view from being on top of edithandle, which can cause undo issues.
}

-(void)setValue:(float)inVal{
    if(inVal!=_value){//only on change

        if(_range==1){//if range is 1, clip value to 0.-1.
            if(inVal>1)inVal=1;
            if(inVal<0)inVal=0;
        }
        else{
            if(fmod(inVal, 1.0)!=0.0)inVal=(float)(int)inVal;//round inVal down to nearest integer
            if (inVal>=_range) {
                inVal=(float)(_range-1);//and clip if necessary
            }
        }

        _value=inVal;
        
        [self updateIndicator];
    }
}

//send out OSC message with value
-(void)sendValue{
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:self.address];
    if(_range>1){
        [formattedMessageArray addObject:[NSNumber numberWithInt:(int)self.value]];
    }
    else{
        [formattedMessageArray addObject:[NSNumber numberWithFloat:self.value]];
    }
    [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
}

// we have a new value, set the knob's indicator
//plenty of ugly math in this one...
-(void)updateIndicator{
	float newRad=0; //the angle of the indicatorView's rotation
    CGPoint newOrigin;

    if(_range==1){
        if ([MMPKnob osxMinorVersion]>=8) newRad= M_PI-((1.0-_value)*(M_PI*2-ROTATION_PAD_RAD*2)+ROTATION_PAD_RAD+M_PI/2);
        else newRad= M_PI-(_value*(M_PI*2-ROTATION_PAD_RAD*2)+ROTATION_PAD_RAD+M_PI/2);
    }
    
    else if (_range>1){
        if ([MMPKnob osxMinorVersion]>=8) newRad= M_PI-(((_range-_value-1)/(_range-1))*(M_PI*2-ROTATION_PAD_RAD*2)+ROTATION_PAD_RAD+M_PI/2);
        else newRad= M_PI-((_value/(_range-1))*(M_PI*2-ROTATION_PAD_RAD*2)+ROTATION_PAD_RAD+M_PI/2);
    }
    
    //set origin
    if ([MMPKnob osxMinorVersion]>=8) newOrigin = CGPointMake(centerPoint.x+sin(newRad)*(-indicatorThickness/2), centerPoint.y-cos(newRad)*(-indicatorThickness/2));
    else newOrigin = CGPointMake(centerPoint.x+sin(newRad)*(-indicatorThickness/2), centerPoint.y+cos(newRad)*(-indicatorThickness/2));
   
    [indicatorView setFrameOrigin:newOrigin];
    
    float newRad2 = (newRad-M_PI/2)/6.282*360.0;//offset and convert to degrees
        [indicatorView setFrameRotation:newRad2];
}


-(void)mouseDown:(NSEvent *)event{
    [super mouseDown:event];
    
   if(![self.editingDelegate isEditing] && self.enabled){
       knobView.layer.backgroundColor = self.highlightColor.CGColor;
     for(NSView* dot in tickViewArray)dot.layer.backgroundColor = self.highlightColor.CGColor;
       [self mouseDragged:event];
    }
}

//compute the value based on where I am touching
-(void)mouseDragged:(NSEvent *)event{	
	[super mouseDragged:event];
    if(![self.editingDelegate isEditing] && self.enabled){
        
        CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];//[[touches anyObject] locationInView:self];
    
        float touchX = point.x-centerPoint.x;
        float touchY = point.y-centerPoint.y;
        double theta = atan2(touchY, touchX);//raw theta =0 starting at 3 o'clock and going potive counterclockwise
    
        double updatedTheta = fmod( theta+M_PI/2+M_PI, (M_PI*2) );//theta =0 at 6pm going positive clockwise
   
        if(_range==1){
            if(updatedTheta<ROTATION_PAD_RAD)[self setValue:0];
            else if(updatedTheta>(M_PI*2-ROTATION_PAD_RAD)) [self setValue:1];
            else [self setValue:(updatedTheta-ROTATION_PAD_RAD)/(M_PI*2-2*ROTATION_PAD_RAD) ];
        
        }
        else if (_range>1){
            if(updatedTheta<ROTATION_PAD_RAD)[self setValue:0];
            else if(updatedTheta>(M_PI*2-ROTATION_PAD_RAD)) [self setValue:_range-1];
            else [self setValue:(float) (  (int)((updatedTheta-ROTATION_PAD_RAD)/(M_PI*2-2*ROTATION_PAD_RAD)*(_range-1)+.5)  ) ];//round to nearest tick!
        }
        [self sendValue];
    }
}

-(void)mouseUp:(NSEvent *)event{
    [super mouseUp:event];
    if(![self.editingDelegate isEditing] && self.enabled){
        knobView.layer.backgroundColor = self.color.CGColor;
      for(NSView* dot in tickViewArray)dot.layer.backgroundColor = self.color.CGColor;

    }
}

//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
-(void)receiveList:(NSArray *)inArray{
  [super receiveList:inArray];
    BOOL sendVal=YES;
    //if message preceded by "set", then set "sendVal" flag to NO, and strip off set and make new messages array without it
    if ([inArray count]>0 && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"set"]){
        NSRange newRange = (NSRange){1, [inArray count]-1};
        inArray = [inArray subarrayWithRange: newRange];
        //printf("\nset!");
        sendVal=NO;
    }
    //set new value, send it out 
    if ([inArray count]>0 && [[inArray objectAtIndex:0] isKindOfClass:[NSNumber class]]){
        [self setValue:[(NSNumber*)[inArray objectAtIndex:0] floatValue]];
        if(sendVal)[self sendValue];
    }
}

//coder for copy/paste

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.indicatorColor forKey:@"indicatorColor"];
	[coder encodeInt:self.range forKey:@"range"];
    
}

- (id)initWithCoder:(NSCoder *)coder {
    
    if(self=[super initWithCoder:coder]){
        [self setIndicatorColor:[coder decodeObjectForKey:@"indicatorColor"]];
        [self setRange:[coder decodeIntForKey:@"range"]];
    }
    return self;
}


@end
