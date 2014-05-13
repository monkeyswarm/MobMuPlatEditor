//
//  MMPSlider.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/27/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import "MMPSlider.h"
#define SLIDER_TROUGH_WIDTH 10
#define SLIDER_TROUGH_TOPINSET 10
#define SLIDER_THUMB_HEIGHT 20

@implementation MMPSlider

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self){
       
        self.address=@"/mySlider";
        [self setRange:2];
        
        //the "rail"
        troughView=[[NSView alloc]init ];
        [troughView setWantsLayer:YES];
        troughView.layer.cornerRadius=3;
        [self addSubview:troughView];
        
        //the fader
        thumbView=[[NSView alloc]init];
        [thumbView setWantsLayer:YES];
        thumbView.layer.cornerRadius=5;
        [self addSubview:thumbView];
        
        [self setColor:self.color];
        [self setFrame:frame];
        [self addHandles];
    }
    return self;
}

-(void)hackRefresh{
    [super hackRefresh];
    troughView.layer.cornerRadius=3;
    thumbView.layer.cornerRadius=5;
    [self updateThumb];
}

-(void)setFrame:(NSRect)frameRect{
    
    [super setFrame:frameRect];
    
    if(!_isHorizontal){//vertical
        for(int i=0;i<[tickViewArray count];i++){
            NSView* tick = [tickViewArray objectAtIndex:i];
            [tick setFrame:CGRectMake((self.frame.size.width-10)/4, SLIDER_TROUGH_TOPINSET+i*(frameRect.size.height-SLIDER_TROUGH_TOPINSET*2)/(_range-1)-1, (self.frame.size.width-10)/2+10, 2)];
        }
    
        [troughView setFrame: CGRectMake((frameRect.size.width-10)/2, SLIDER_TROUGH_TOPINSET, SLIDER_TROUGH_WIDTH, frameRect.size.height-(SLIDER_TROUGH_TOPINSET*2))];
    }
    
    else{//horizontal
        for(int i=0;i<[tickViewArray count];i++){
            NSView* tick = [tickViewArray objectAtIndex:i];
            [tick setFrame:CGRectMake(SLIDER_TROUGH_TOPINSET+i*(frameRect.size.width-SLIDER_TROUGH_TOPINSET*2)/(_range-1)-1,  (frameRect.size.height-10)/4, 2, (frameRect.size.height-10)/2+10)];
        }
        [troughView setFrame: CGRectMake(SLIDER_TROUGH_TOPINSET, (frameRect.size.height-10)/2, frameRect.size.width-(SLIDER_TROUGH_TOPINSET*2), SLIDER_TROUGH_WIDTH)];
    }
    
    [self updateThumb];
    
}

-(void)setColor:(NSColor *)color{
    [super setColor:color];
    troughView.layer.backgroundColor=color.CGColor;
    thumbView.layer.backgroundColor=color.CGColor;
    for(NSView* dot in tickViewArray)dot.layer.backgroundColor = color.CGColor;
}

-(void)setRangeObjectUndoable:(NSNumber*)inRangeObject{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setRangeObjectUndoable:) object:[NSNumber numberWithInt:self.range] ];
    [self setRange:[inRangeObject intValue] ];
}

-(void)setRange:(int)range{
    _range=range;
    if(_range<2)_range=2;
    
    if(tickViewArray)for(NSView* tick in tickViewArray)[tick removeFromSuperview];
    tickViewArray = [[NSMutableArray alloc]init];
    if(_range>2){
        for(int i=0;i<_range;i++){
            NSView* tick = [[NSView alloc]init];
            [tick setWantsLayer:YES];
            tick.layer.backgroundColor=self.color.CGColor;
            [tickViewArray addObject:tick];
            [self addSubview:tick];
        }
    }
    [self setFrame:self.frame];
}

-(void)setValue:(float)inVal{
    if(_range==2){//clip 0.-1.
        if(inVal>1)inVal=1;
        if(inVal<0)inVal=0;
    }
    else{
        if(fmod(inVal, 1.0)!=0.0)inVal=(float)(int)inVal;//round down to integer
        if (inVal>=_range) {
            inVal=(float)(_range-1);//clip if necessary
        }
    }
    _value=inVal;
	[self updateThumb];
}

//send OSC message out
-(void)sendValue{
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:self.address];
    [formattedMessageArray addObject:[NSNumber numberWithFloat:self.value]];
    [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
}

-(void)updateThumb{
	CGRect newFrame;
    
    if(!_isHorizontal)
        newFrame = CGRectMake( 0, (1.0-(self.value/(_range-1)))*(self.frame.size.height-(SLIDER_TROUGH_TOPINSET*2)), self.frame.size.width, SLIDER_THUMB_HEIGHT );
    else  newFrame = CGRectMake( (self.value/(_range-1))*(self.frame.size.width-(SLIDER_TROUGH_TOPINSET*2)),0, SLIDER_THUMB_HEIGHT, self.frame.size.height  );
    
	thumbView.frame=newFrame;
}

-(void)setIsHorizontalObjectUndoable:(NSNumber*)isHorizontalObject{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setIsHorizontalObjectUndoable:) object:[NSNumber numberWithBool:self.isHorizontal] ];
    [self setIsHorizontal:[isHorizontalObject boolValue] ];
}

-(void)setIsHorizontal:(BOOL)isHorizontal{
    _isHorizontal=isHorizontal;
    [self setFrame:self.frame];
}

-(void)mouseDown:(NSEvent *)event{
    [super mouseDown:event];
    if(![self.editingDelegate isEditing]){
        CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
        float tempFloatValue;
        if(!_isHorizontal) tempFloatValue=1.0-(float)((point.y-SLIDER_TROUGH_TOPINSET)/(self.frame.size.height-(SLIDER_TROUGH_TOPINSET*2)));//0-1
        else tempFloatValue=(float)((point.x-SLIDER_TROUGH_TOPINSET)/(self.frame.size.width-(SLIDER_TROUGH_TOPINSET*2)));//0-1
        
        if(_range==2 && tempFloatValue<=_range-1 && tempFloatValue>=0  && tempFloatValue!=self.value){
            [self setValue: tempFloatValue ];
            [self sendValue];
        }
        float tempValue = (float)(int)((tempFloatValue*(_range-1))+.5);//round to 0-4
        if(_range>2 && tempValue<=_range-1 && tempValue>=0  && tempValue!=self.value){
            [self setValue: tempValue ];
            [self sendValue];
        }
        
        thumbView.layer.backgroundColor=self.highlightColor.CGColor;
        troughView.layer.backgroundColor= self.highlightColor.CGColor;
        if(tickViewArray)for (NSView* tick in tickViewArray)tick.layer.backgroundColor=self.highlightColor.CGColor;
        
    }
}

-(void)mouseDragged:(NSEvent *)event
{
    [super mouseDragged:event];
    if(![self.editingDelegate isEditing]){
        CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];//CGPoint point = [[touches anyObject] locationInView:self];
        float tempFloatValue;
        if(!_isHorizontal)tempFloatValue=1.0-(float)((point.y-SLIDER_TROUGH_TOPINSET)/(self.frame.size.height-(SLIDER_TROUGH_TOPINSET*2)));
        else tempFloatValue=(float)((point.x-SLIDER_TROUGH_TOPINSET)/(self.frame.size.width-(SLIDER_TROUGH_TOPINSET*2)));
        
        if(_range==2 && tempFloatValue<=_range-1 && tempFloatValue>=0 && tempFloatValue!=self.value){
            [self setValue: tempFloatValue ];
            [self sendValue];
        }
        float tempValue = (float)(int)((tempFloatValue*(_range-1))+.5);
        if(_range>2 && tempValue<=_range-1 && tempValue>=0 && tempValue!=self.value){
            [self setValue: tempValue ];
            [self sendValue];
        }
    }
}

-(void)mouseUp:(NSEvent *)event  {
    [super mouseUp:event];
    if(![self.editingDelegate isEditing]){
        thumbView.layer.backgroundColor=self.color.CGColor;
        troughView.layer.backgroundColor= self.color.CGColor;
        if(tickViewArray)for (NSView* tick in tickViewArray)tick.layer.backgroundColor= self.color.CGColor;
    }
}

//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
-(void)receiveList:(NSArray *)inArray{
    BOOL sendVal=YES;
    //if message preceded by "set", then set "sendVal" flag to NO, and strip off set and make new messages array without it
    if ([inArray count]>0 && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"set"]){
        NSRange newRange = (NSRange){1, [inArray count]-1};
        inArray = [inArray subarrayWithRange: newRange];
        sendVal=NO;
    }
    //set new value
    if ([inArray count]>0 && [[inArray objectAtIndex:0] isKindOfClass:[NSNumber class]]){
        [self setValue:[(NSNumber*)[inArray objectAtIndex:0] floatValue]];
        if(sendVal)[self sendValue];
    }
}

//coder for copy/paste

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeBool:self.isHorizontal forKey:@"isHorizontal"];
	[coder encodeInt:self.range forKey:@"range"];

}

- (id)initWithCoder:(NSCoder *)coder {
    if(self=[super initWithCoder:coder]){
        [self setIsHorizontal:[coder decodeBoolForKey:@"isHorizontal"]];
        [self setRange:[coder decodeIntForKey:@"range"]];
    }
    return self;
}



@end
