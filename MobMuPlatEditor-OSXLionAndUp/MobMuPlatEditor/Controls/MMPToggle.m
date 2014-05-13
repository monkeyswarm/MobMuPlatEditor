//
//  MMPToggle.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/31/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import "MMPToggle.h"
#define EDGE_RADIUS 5

@implementation MMPToggle

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.address=@"/myToggle";
        
        innerView = [[NSView alloc]init];
        [innerView setWantsLayer:YES];
        innerView.layer.borderColor = self.color.CGColor;
        innerView.layer.cornerRadius=EDGE_RADIUS;
        [self addSubview:innerView];
        [self setBorderThickness:4];
        
        [self setFrame:frame];
        [self addHandles];
        
    }
    return self;
}

-(void)setFrame:(NSRect)frameRect{
    [super setFrame:frameRect];
    [innerView setFrame:CGRectMake(0,0, frameRect.size.width, frameRect.size.height)];
}

-(void)setBorderThicknessUndoable:(NSNumber*)inNum{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setBorderThicknessUndoable:) object:[NSNumber numberWithInt:[self borderThickness]]];
    [self setBorderThickness:[inNum intValue]];
}

-(void)setBorderThickness:(int)borderThickness{
    _borderThickness = borderThickness;
    innerView.layer.borderWidth = _borderThickness;
}

-(void)hackRefresh{
    [super hackRefresh];
    innerView.layer.cornerRadius=EDGE_RADIUS;
    innerView.layer.borderWidth = _borderThickness;
    if(self.value==1)innerView.layer.backgroundColor=self.highlightColor.CGColor;
    
}

-(void)mouseDown:(NSEvent *)event{
    [super mouseDown:event];
   if(![self.editingDelegate isEditing]){
        [self setValue:1-self.value];
       [self sendValue];
    }
}

-(void)setColor:(NSColor *)color{
    [super setColor:color];
    innerView.layer.borderColor=color.CGColor;
}

-(void)setHighlightColor:(NSColor *)color{
    [super setHighlightColor:color];
    if(self.value==1)innerView.layer.backgroundColor=color.CGColor;
}


-(void)setValue:(int)inVal{
	_value=inVal;
    
    if(self.value==1)innerView.layer.backgroundColor=self.highlightColor.CGColor;
    else innerView.layer.backgroundColor=[[NSColor clearColor]CGColor];
	
}

//send out OSC message
-(void)sendValue{
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:self.address];
    [formattedMessageArray addObject:[NSNumber numberWithInt:self.value]];
    [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
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
    //set on/off
    if ([inArray count]>0 && [[inArray objectAtIndex:0] isKindOfClass:[NSNumber class]]){
        [self setValue:(int)[(NSNumber*)[inArray objectAtIndex:0] floatValue]];
        if(sendVal)[self sendValue];
    }
}

//coder for copy/paste

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeInt:self.borderThickness forKey:@"borderThickness"];
    
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self=[super initWithCoder:coder]){
        [self setBorderThickness:[coder decodeIntForKey:@"borderThickness"]];
    }
    return self;
}

@end
