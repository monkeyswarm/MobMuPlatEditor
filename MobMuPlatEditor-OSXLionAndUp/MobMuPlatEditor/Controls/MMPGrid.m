//
//  MMPGrid.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/1/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import "MMPGrid.h"

@implementation MMPGrid

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.address=@"/myGrid";
        gridButtons = [[NSMutableArray alloc]init];
        //defaults
        [self setCellPadding:2];
        [self setBorderThickness:3];
        [self setDimX:4];
        [self setDimY:3];
        [self redrawDim];
        
        [self addHandles];
    }
    return self;
}

-(void)setCellPaddingUndoable:(NSNumber*)inVal{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setCellPaddingUndoable:) object:[NSNumber numberWithInt:[self cellPadding]]];
    
    [self setCellPadding:[inVal intValue]];
}

-(void)setCellPadding:(int)cellPadding{
    _cellPadding=cellPadding;
    [self redrawDim];
}

-(void)setBorderThicknessUndoable:(NSNumber*)inVal{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setBorderThicknessUndoable:) object:[NSNumber numberWithInt:[self borderThickness]]];
    
    [self setBorderThickness:[inVal intValue]];
}

-(void)setBorderThickness:(int)borderThickness{
    _borderThickness = borderThickness;
    for(NSControl* button in gridButtons)button.layer.borderWidth=_borderThickness;
}

-(void)hackRefresh{
    [super hackRefresh];
    for(NSControl* button in gridButtons){
        button.layer.borderWidth=_borderThickness;
      if(button.tag==1)button.layer.backgroundColor=self.highlightColor.CGColor;
      else button.layer.backgroundColor=[[NSColor clearColor] CGColor];
    }
}


-(void)setFrame:(NSRect)frameRect{
    [super setFrame:frameRect];
    
    float buttonWidth = self.frame.size.width/_dimX;
    float buttonHeight = self.frame.size.height/_dimY;
    
    for(int j=0;j<_dimY;j++){
        for(int i=0;i<_dimX;i++){
            NSView* buttonView = [gridButtons objectAtIndex:j*_dimX+i ];
            [buttonView setFrame:CGRectMake(i*buttonWidth, j*buttonHeight, buttonWidth-_cellPadding, buttonHeight-_cellPadding)];
        }
    }
}

-(void)setDimXUndoable:(NSNumber*)inVal{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setDimXUndoable:) object:[NSNumber numberWithInt:[self dimX]]];
    
    [self setDimX:[inVal intValue]];
}

-(void)setDimX:(int)inX{
    _dimX=inX;
    [self redrawDim];
}

-(void)setDimYUndoable:(NSNumber*)inVal{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setDimYUndoable:) object:[NSNumber numberWithInt:[self dimY]]];
    
    [self setDimY:[inVal intValue]];
}

-(void)setDimY:(int)inY{
    _dimY=inY;
    [self redrawDim];
}

//whenever dim x or y has changed, redraw everything
-(void)redrawDim{
    
    float buttonWidth = self.frame.size.width/_dimX;
    float buttonHeight = self.frame.size.height/_dimY;
    
    for(NSControl* button in gridButtons){
        [button removeFromSuperview];
    }
    [gridButtons removeAllObjects];
    
    for(int j=0;j<_dimY;j++){
        for(int i=0;i<_dimX;i++){
            
            NSControl* newButtonView = [[NSControl alloc]initWithFrame:CGRectMake(i*buttonWidth, j*buttonHeight, buttonWidth-_cellPadding, buttonHeight-_cellPadding)];
            [newButtonView setWantsLayer:YES];
            newButtonView.layer.cornerRadius=2;
            newButtonView.layer.borderWidth=_borderThickness;
          newButtonView.layer.borderColor=self.color.CGColor;
            [gridButtons addObject:newButtonView];
            [self addSubview:newButtonView];
            
        }
    }
    //bring handle up front
    [self bringUpHandle];
    
}

-(void)mouseDown:(NSEvent *)event
{
    [super mouseDown:event];
    if(![self.editingDelegate isEditing]){
        NSPoint clickLocation = [self convertPoint:[event locationInWindow]fromView:nil];
        //find out which grid element we hit
        for(NSControl* hitView in gridButtons){
            BOOL itemHit = NSPointInRect(clickLocation,[hitView frame]);
            if(itemHit){
                
                [hitView setTag:1-hitView.tag ];
                if(hitView.tag==1)hitView.layer.backgroundColor=self.highlightColor.CGColor;
                else hitView.layer.backgroundColor=[[NSColor clearColor]CGColor];
                
                //get coordinate of cell
                NSInteger hitViewIndex = [gridButtons indexOfObject:hitView];
                
                //send message
                NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
                [formattedMessageArray addObject:self.address];
                //[formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"iii"]];//tags
                [formattedMessageArray addObject:[NSNumber numberWithInt:hitViewIndex%_dimX]];
                [formattedMessageArray addObject:[NSNumber numberWithInt:hitViewIndex/_dimX]];
                [formattedMessageArray addObject:[NSNumber numberWithInt:hitView.tag]];
                [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
                
            }
        }
    }
}


-(void)setColor:(NSColor *)color{
    [super setColor:color];
    for(NSControl* hitView in gridButtons)hitView.layer.borderColor=color.CGColor;
}

-(void)setHighlightColor:(NSColor *)color{
    [super setHighlightColor:color];
    for(NSControl* hitView in gridButtons)if(hitView.tag==1)hitView.layer.backgroundColor=color.CGColor;
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
    
    //if message is three numbers, look at message and set my value, outputting value if required
    if([inArray count]==3 && [[inArray objectAtIndex:0] isKindOfClass:[NSNumber class]] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]] && [[inArray objectAtIndex:2] isKindOfClass:[NSNumber class]]){
        int indexX = (int)[[inArray objectAtIndex:0] floatValue];
        int indexY = (int)[[inArray objectAtIndex:1] floatValue];
        int val = (int)[[inArray objectAtIndex:2] floatValue];
        if(indexX<_dimX && indexY<_dimY){
            
            NSControl* currButton = [gridButtons objectAtIndex:indexX+indexY*_dimX];
            if(val>1)val=1;if(val<0)val=0;
            currButton.tag=val;
            if(val==0)currButton.layer.backgroundColor=[[NSColor clearColor] CGColor];
            else currButton.layer.backgroundColor=self.highlightColor.CGColor;
            
            if(sendVal){
                //NSMutableString* tags = [[NSMutableString alloc]init];
                //[tags appendString:@"iii"];
                NSMutableArray *formattedMessageArray = [NSMutableArray arrayWithObjects:self.address, [NSNumber numberWithInt:indexX], [NSNumber numberWithInt:indexY], [NSNumber numberWithInt:val],  nil];
                [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
            }
        }
    }
    
    //else if message starts with "getColumn", spit out array of that column's values
    else if([inArray count]==2 && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"getcolumn"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        int colIndex = [[inArray objectAtIndex:1] intValue];
        //printf("\n getcol %d", colIndex);
        if(colIndex>=0 && colIndex<_dimX){
            //NSMutableString* tags = [[NSMutableString alloc]init];
            //[tags appendString:@"s"];
            NSMutableArray *formattedMessageArray = [NSMutableArray arrayWithObjects:self.address,@"column", nil];
        
            for(int i=0;i<_dimY;i++){
                int val = (int)[[gridButtons objectAtIndex:(colIndex+_dimX*i)] tag];//0 or 1
                //[tags appendString:@"i"];
                [formattedMessageArray addObject:[NSNumber numberWithInt:val]];
            }
        //[PdBase sendList:msgArray toReceiver:@"fromGUI"];
        [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
        }
    }
    
    //else if message starts with "getRow", spit out array of that row's values
    else if([inArray count]==2 && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"getrow"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        int rowIndex = [[inArray objectAtIndex:1] intValue];
        //printf("\n getrow %d dimX %d: ", rowIndex, _dimX);
        if(rowIndex>=0 && rowIndex<_dimY){
            //NSMutableString* tags = [[NSMutableString alloc]init];
            //[tags appendString:@"s"];
            NSMutableArray *formattedMessageArray = [NSMutableArray arrayWithObjects:self.address, @"row", nil];
        
            for(int i=0;i<_dimX;i++){
                int val = (int)[[gridButtons objectAtIndex:(i+_dimX*rowIndex)] tag];//0 or 1
                //[tags appendString:@"i"];
                [formattedMessageArray addObject:[NSNumber numberWithInt:val]];
            }
            [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
        }
    }
    //clear
    else if([inArray count]==1 && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"clear"]){
        for(NSControl* currButton in gridButtons){
            currButton.tag=0;
            currButton.layer.backgroundColor=[[NSColor clearColor]CGColor];
        }
    }
}

//coder for copy/paste

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeInt:self.dimX forKey:@"dimX"];
    [coder encodeInt:self.dimY forKey:@"dimY"];
    [coder encodeInt:self.borderThickness forKey:@"borderThickness"];
    [coder encodeInt:self.cellPadding forKey:@"cellPadding"];
    
}

- (id)initWithCoder:(NSCoder *)coder {
    
    if(self=[super initWithCoder:coder]){
        [self setDimX:[coder decodeIntForKey:@"dimX"]];
        [self setDimY:[coder decodeIntForKey:@"dimY"]];
        [self setBorderThickness:[coder decodeIntForKey:@"borderThickness"]];
        [self setCellPadding:[coder decodeIntForKey:@"cellPadding"]];
    }
    return self;
}




@end
