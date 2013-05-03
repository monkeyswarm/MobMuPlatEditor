//
//  MMPXYSlider.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/1/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import "MMPXYSlider.h"

@implementation MMPXYSlider
#define LINE_WIDTH 4

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.address=@"/myXYSlider";
        
        borderView = [[NSView alloc]init];
        [borderView setWantsLayer:YES];
        borderView.layer.borderWidth = LINE_WIDTH;
        [self addSubview:borderView];
        
        cursorHorizView = [[NSView alloc]init];
        cursorVertView = [[NSView alloc]init];
        [cursorHorizView setWantsLayer:YES];
        [cursorVertView setWantsLayer:YES];
        
        [self addSubview:cursorHorizView];
        [self addSubview: cursorVertView];
        [self setColor:self.color];
        [self setFrame:frame];
        [self setValueX:.5 Y:.5];//set initial val, but don't send it out as message
        
        [self addHandles];
        
    }
    
    return self;
}

-(void)hackRefresh{
    [super hackRefresh];
     borderView.layer.borderWidth = LINE_WIDTH;
    [self setValueX:_valueX Y:_valueY];
}

-(void)setFrame:(NSRect)frameRect{
    [super setFrame:frameRect];
    [borderView setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    CGRect horizFrame = CGRectMake(0, _valueY*self.frame.size.height-LINE_WIDTH/2, self.frame.size.width, LINE_WIDTH);
    [cursorHorizView setFrame:horizFrame];
    CGRect vertFrame = CGRectMake(_valueX*self.frame.size.width-LINE_WIDTH/2, 0, LINE_WIDTH, self.frame.size.height);
    [cursorVertView setFrame:vertFrame];
}

-(void)setColor:(NSColor *)color{
    [super setColor:color];
    borderView.layer.borderColor = [MMPControl CGColorFromNSColor:color];
    cursorVertView.layer.backgroundColor = [MMPControl CGColorFromNSColor:color];
    cursorHorizView.layer.backgroundColor = [MMPControl CGColorFromNSColor:color];
}


-(void)setValueX:(float)valX Y:(float)valY{
    _valueX = valX;
    _valueY = valY;
    
    CGRect horizFrame = CGRectMake(0, (1.0-_valueY)*self.frame.size.height-LINE_WIDTH/2, self.frame.size.width, LINE_WIDTH);
    [cursorHorizView setFrame:horizFrame];
    CGRect vertFrame = CGRectMake(_valueX*self.frame.size.width-LINE_WIDTH/2, 0, LINE_WIDTH, self.frame.size.height);
    [cursorVertView setFrame:vertFrame];
}

//send out OSC message
-(void)sendValue{
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:self.address];
    
    [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"ff"]];//tags
    [formattedMessageArray addObject:[NSNumber numberWithFloat:self.valueX]];
    [formattedMessageArray addObject:[NSNumber numberWithFloat:self.valueY]];
    [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
}

-(void)mouseDown:(NSEvent *)theEvent{
    [super mouseDown:theEvent];
    
    if(![self.editingDelegate isEditing]){
        cursorHorizView.layer.backgroundColor=[MMPControl CGColorFromNSColor:self.highlightColor];
        cursorVertView.layer.backgroundColor=[MMPControl CGColorFromNSColor:self.highlightColor];
        borderView.layer.borderColor=[MMPControl CGColorFromNSColor:self.highlightColor];
        [self mouseDragged:theEvent];
    }
}

-(void)mouseDragged:(NSEvent *)theEvent{
    [super mouseDragged:theEvent];
    if(![self.editingDelegate isEditing]){
        CGPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];//[[touches anyObject] locationInView:self];
        float valX = point.x/self.frame.size.width;
        float valY = 1.0-(point.y/self.frame.size.height);
        if(valX>1)valX=1; if(valX<0)valX=0;
        if(valY>1)valY=1; if(valY<0)valY=0;
        //printf("\n%.2f %.2f %.2f %.2f", touchX, touchY, centerPoint.x, centerPoint.y);
        [self setValueX:valX Y:valY];
        [self sendValue];
    }
    
    
}

-(void)mouseUp:(NSEvent *)theEvent{
    [super mouseUp:theEvent];
    if(![self.editingDelegate isEditing]){
        cursorHorizView.layer.backgroundColor=[MMPControl CGColorFromNSColor:self.color];
        cursorVertView.layer.backgroundColor=[MMPControl CGColorFromNSColor:self.color];
        borderView.layer.borderColor=[MMPControl CGColorFromNSColor:self.color];
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
    //set position and send
    if([inArray count]==2 && [[inArray objectAtIndex:0] isKindOfClass:[NSNumber class]] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self setValueX:[(NSNumber*)[inArray objectAtIndex:0] floatValue]  Y:[(NSNumber*)[inArray objectAtIndex:1] floatValue]];
        if(sendVal)[self sendValue];
    }
}

@end
