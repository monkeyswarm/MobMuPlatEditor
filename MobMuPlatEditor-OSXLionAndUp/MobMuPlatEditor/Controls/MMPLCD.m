//
//  MMPLCD.m
//  MobMuPlatEditor
//
//  Created by Daniel Iglesia on 1/9/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPLCD.h"

@interface MMPLCD () {
    
    CGContextRef _cacheContext;

    float fR,fG,fB,fA;//FRGBA
    //float bR,bG,bB,bA;//BRGBA
    CGPoint penPoint;
    float penWidth;
    
    
}

@end

@implementation MMPLCD

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.address=@"/myLCD";
        self.layer.backgroundColor=[MMPControl CGColorFromNSColor:self.color];
        
        penPoint = CGPointMake(0, 0);
      
      
        [self setFrame:frame];//create context
        [self setPenWidth:1];
        //
        [self addHandles];
        
    }
    return self;
}

-(void)setFrame:(NSRect)frameRect{
    [super setFrame:frameRect];
    if(_cacheContext!=nil){//free stuff
        CGContextRelease(_cacheContext);
    }
  _cacheContext = [self createBitmapContextW:(int)self.frame.size.width H:(int)self.frame.size.height];//createBitmapContext((int)self.frame.size.width, (int)self.frame.size.height);
    CGContextSetLineWidth(_cacheContext, penWidth);
}


-(CGContextRef) createBitmapContextW:(int) pixelsWide H:(int) pixelsHigh {
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    //void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    bitmapBytesPerRow   = (pixelsWide * 4);// 1
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);// 2
    /*bitmapData = malloc( bitmapByteCount );// 3
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }*/
    context = CGBitmapContextCreate (nil,// 4
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     0,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedLast);
    if (context== NULL)
    {
        //free (bitmapData);// 5
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease( colorSpace );// 6
    
    return context;// 7
}

-(void)setColor:(NSColor *)color{
    [super setColor:color];
    self.layer.backgroundColor=[MMPControl CGColorFromNSColor:color];
    
}

-(void)setHighlightColor:(NSColor *)highlightColor{
    [super setHighlightColor:highlightColor];
    
    fR  = [highlightColor redComponent];
    fG  = [highlightColor greenComponent];
    fB  = [highlightColor blueComponent];
    fA  = [highlightColor alphaComponent];
}
//

-(void)clear{
    CGContextClearRect(_cacheContext, self.bounds);
    [self setNeedsDisplayInRect:self.bounds];
}

-(void)paintRectX:(float)x Y:(float)y X2:(float)x2 Y2:(float)y2 R:(float)r G:(float)g B:(float)b A:(float)a{
    CGContextSetRGBFillColor(_cacheContext, r,g,b,a);
	CGRect newRect = CGRectMake( MIN(x,x2)*self.frame.size.width, MIN(y,y2)*self.frame.size.height, fabsf(x2-x)*self.frame.size.width, fabs(y2-y)*self.frame.size.height);
    CGContextFillRect(_cacheContext, newRect);
    [self setNeedsDisplayInRect:newRect];
}

-(void)paintRectX:(float)x Y:(float)y X2:(float)x2 Y2:(float)y2{
    [self paintRectX:x Y:y X2:x2 Y2:y2 R:fR G:fG B:fB A:fA];
}

-(void)frameRectX:(float)x Y:(float)y X2:(float)x2 Y2:(float)y2 R:(float)r G:(float)g B:(float)b A:(float)a{
    //NSLog(@"frameRect rgba %.2f %.2f %.2f - %.2f %.2f %.2f %.2f", x,y,x2,y2,r, g, b, a);
    CGContextSetRGBStrokeColor(_cacheContext, r,g,b,a);
	CGRect newRect = CGRectMake( MIN(x,x2)*self.frame.size.width, MIN(y,y2)*self.frame.size.height, fabsf(x2-x)*self.frame.size.width, fabs(y2-y)*self.frame.size.height);
    CGContextStrokeRect(_cacheContext, newRect);
    
    newRect = CGRectMake( newRect.origin.x-penWidth, newRect.origin.y-penWidth, newRect.size.width+(2*penWidth), newRect.size.height+(2*penWidth));
    [self setNeedsDisplayInRect:newRect];
}

-(void)frameRectX:(float)x Y:(float)y X2:(float)x2 Y2:(float)y2{
    [self frameRectX:x Y:y X2:x2 Y2:y2 R:fR G:fG B:fB A:fA];
}

-(void)frameOvalX:(float)x Y:(float)y X2:(float)x2 Y2:(float)y2 R:(float)r G:(float)g B:(float)b A:(float)a{
    CGContextSetRGBStrokeColor(_cacheContext, r,g,b,a);
	CGRect newRect = CGRectMake( MIN(x,x2)*self.frame.size.width, MIN(y,y2)*self.frame.size.height, fabsf(x2-x)*self.frame.size.width, fabs(y2-y)*self.frame.size.height);
    CGContextStrokeEllipseInRect(_cacheContext, newRect);
    
    newRect = CGRectMake( newRect.origin.x-penWidth, newRect.origin.y-penWidth, newRect.size.width+(2*penWidth), newRect.size.height+(2*penWidth));

    [self setNeedsDisplayInRect:newRect];
}

-(void)frameOvalX:(float)x Y:(float)y X2:(float)x2 Y2:(float)y2{
    [self frameOvalX:x Y:y X2:x2 Y2:y2 R:fR G:fG B:fB A:fA];
}

-(void)paintOvalX:(float)x Y:(float)y X2:(float)x2 Y2:(float)y2 R:(float)r G:(float)g B:(float)b A:(float)a{
    CGContextSetRGBFillColor(_cacheContext, r,g,b,a);
	CGRect newRect = CGRectMake( MIN(x,x2)*self.frame.size.width, MIN(y,y2)*self.frame.size.height, fabsf(x2-x)*self.frame.size.width, fabs(y2-y)*self.frame.size.height);
    CGContextFillEllipseInRect(_cacheContext, newRect);
    [self setNeedsDisplayInRect:newRect];
}

-(void)paintOvalX:(float)x Y:(float)y X2:(float)x2 Y2:(float)y2{
    [self paintOvalX:x Y:y X2:x2 Y2:y2 R:fR G:fG B:fB A:fA];
}

-(void)moveToX:(float)x Y:(float)y {
    penPoint.x = x*self.frame.size.width;
    penPoint.y = y*self.frame.size.height;
    
}

-(void)lineToX:(float)x Y:(float)y R:(float)r G:(float)g B:(float)b A:(float)a{
    //convert to coords
    x = x*self.frame.size.width;
    y = y*self.frame.size.height;
    
    //NSLog(@"pen x %.2f y %.2f TO x %.2f y %.2f ", penPoint.x, penPoint.y, x, y);
    CGContextSetRGBStrokeColor(_cacheContext, r,g,b,a);
    CGContextMoveToPoint(_cacheContext, penPoint.x,penPoint.y);
	CGContextAddLineToPoint(_cacheContext, x, y);
	CGContextStrokePath(_cacheContext);
    CGRect newRect = CGRectMake(MIN(penPoint.x, x)-penWidth, MIN(penPoint.y, y)-penWidth, fabs(penPoint.x-x)+(2*penWidth), fabs(penPoint.y-y)+(2*penWidth));
    [self setNeedsDisplayInRect:newRect];
    //[self setNeedsDisplay];
    
    CGContextMoveToPoint(_cacheContext, x,y);//not really ness
    penPoint.x = x;
    penPoint.y = y;
    
}

-(void)lineToX:(float)x Y:(float)y{
    [self lineToX:x Y:y R:fR G:fG B:fB A:fA];
}

-(void)setPenWidth:(float)w{
    penWidth = w;
    CGContextSetLineWidth(_cacheContext, w);
}


-(void)framePolyRGBA:(NSArray*)pointArray R:(float)r G:(float)g B:(float)b A:(float)a {
    //points are normalized, NSNumber floats
    if([pointArray count]<4)return;
    
    float  minX=self.frame.size.width, minY = self.frame.size.height, maxX =0, maxY = 0;
    
    CGContextSetRGBStrokeColor(_cacheContext, r,g,b,a);
    
    float x = [[pointArray objectAtIndex:0] floatValue]*self.frame.size.width;
    float y = [[pointArray objectAtIndex:1] floatValue]*self.frame.size.height;
    CGContextMoveToPoint(_cacheContext, x,y );
	
    if(x<minX)minX=x; if(y<minY)minY=y; if(x>maxX)maxX=x; if(y>maxY)maxY=y;
	
    for(int i = 2; i < [pointArray count]; i+=2)
	{
        x = [[pointArray objectAtIndex:i] floatValue]*self.frame.size.width;
        y = [[pointArray objectAtIndex:i+1] floatValue]*self.frame.size.height;
		CGContextAddLineToPoint(_cacheContext, x,y);
        if(x<minX)minX=x; if(y<minY)minY=y; if(x>maxX)maxX=x; if(y>maxY)maxY=y;
	}
	
	CGContextClosePath(_cacheContext);
    
    CGContextDrawPath(_cacheContext, kCGPathStroke);
    
    CGRect newRect = CGRectMake(minX-penWidth, minY-penWidth, maxX-minX+(2*penWidth), maxY-minY+(2*penWidth));
    [self setNeedsDisplayInRect:newRect];
}

-(void)framePoly:(NSArray*)pointArray{
    [self framePolyRGBA:pointArray R:fR G:fG B:fB A:fA];
}

-(void)paintPolyRGBA:(NSArray*)pointArray R:(float)r G:(float)g B:(float)b A:(float)a {
    //points are normalized, NSNumber floats
    if([pointArray count]<4)return;
    
    float  minX=self.frame.size.width, minY = self.frame.size.height, maxX =0, maxY = 0;
    
    CGContextSetRGBFillColor(_cacheContext, r,g,b,a);
    float x = [[pointArray objectAtIndex:0] floatValue]*self.frame.size.width;
    float y = [[pointArray objectAtIndex:1] floatValue]*self.frame.size.height;
    
    CGContextMoveToPoint(_cacheContext, x,y);
    
    if(x<minX)minX=x; if(y<minY)minY=y; if(x>maxX)maxX=x; if(y>maxY)maxY=y;
	
    for(int i = 2; i < [pointArray count]; i+=2)
	{
         x = [[pointArray objectAtIndex:i] floatValue]*self.frame.size.width;
         y = [[pointArray objectAtIndex:i+1] floatValue]*self.frame.size.height;
		CGContextAddLineToPoint(_cacheContext, x,y);
        if(x<minX)minX=x; if(y<minY)minY=y; if(x>maxX)maxX=x; if(y>maxY)maxY=y;
	}
	
	CGContextClosePath(_cacheContext);
    
    CGContextDrawPath(_cacheContext, kCGPathFill);
    
    //
    CGRect newRect = CGRectMake(minX, minY, maxX-minX, maxY-minY);
    [self setNeedsDisplayInRect:newRect];
}

-(void)paintPoly:(NSArray*)pointArray{
    [self paintPolyRGBA:pointArray R:fR G:fG B:fB A:fA];
}

//

-(void)mouseDown:(NSEvent *)theEvent{
    [super mouseDown:theEvent];
    
    if(![self.editingDelegate isEditing]){
        
        CGPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];//[[touches anyObject] locationInView:self];
        float valX = point.x/self.frame.size.width;
        float valY = point.y/self.frame.size.height;
        if(valX>1)valX=1; if(valX<0)valX=0;
        if(valY>1)valY=1; if(valY<0)valY=0;
        
        [self sendValueState:1.f X:valX Y:valY];
        

    }
}

-(void)mouseDragged:(NSEvent *)theEvent{
    [super mouseDragged:theEvent];
    
    if(![self.editingDelegate isEditing]){
        
        CGPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];//[[touches anyObject] locationInView:self];
        float valX = point.x/self.frame.size.width;
        float valY = point.y/self.frame.size.height;
        if(valX>1)valX=1; if(valX<0)valX=0;
        if(valY>1)valY=1; if(valY<0)valY=0;
        
        [self sendValueState:2.f X:valX Y:valY];
    }
}

-(void)mouseUp:(NSEvent *)theEvent{
    [super mouseUp:theEvent];
    if(![self.editingDelegate isEditing]){
        
        CGPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];//[[touches anyObject] locationInView:self];
        float valX = point.x/self.frame.size.width;
        float valY = point.y/self.frame.size.height;
        if(valX>1)valX=1; if(valX<0)valX=0;
        if(valY>1)valY=1; if(valY<0)valY=0;
        
        [self sendValueState:0.f X:valX Y:valY];    }
    
}



//send out OSC message - state is 1 on touch down, 2 on drag, 0 on touch up
-(void)sendValueState:(float)state X:(float)x Y:(float)y{
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:self.address];
    
    [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"fff"]];//tags
    [formattedMessageArray addObject:[NSNumber numberWithFloat:state]];
    [formattedMessageArray addObject:[NSNumber numberWithFloat:x]];
    [formattedMessageArray addObject:[NSNumber numberWithFloat:y]];
    [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
}

//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object

-(void)receiveList:(NSArray *)inArray{
    if([inArray count]==5 && [[inArray objectAtIndex:0] isEqualToString:@"paintrect"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self paintRectX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue] X2:[[inArray objectAtIndex:3] floatValue] Y2:[[inArray objectAtIndex:4] floatValue]];
    }
    else if([inArray count]==9 && [[inArray objectAtIndex:0] isEqualToString:@"paintrect"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self paintRectX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue] X2:[[inArray objectAtIndex:3] floatValue] Y2:[[inArray objectAtIndex:4] floatValue] R:[[inArray objectAtIndex:5] floatValue] G:[[inArray objectAtIndex:6] floatValue] B:[[inArray objectAtIndex:7] floatValue] A:[[inArray objectAtIndex:8] floatValue]];
    }
    else if([inArray count]==5 && [[inArray objectAtIndex:0] isEqualToString:@"framerect"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self frameRectX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue] X2:[[inArray objectAtIndex:3] floatValue] Y2:[[inArray objectAtIndex:4] floatValue]];
    }
    else if([inArray count]==9 && [[inArray objectAtIndex:0] isEqualToString:@"framerect"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self frameRectX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue] X2:[[inArray objectAtIndex:3] floatValue] Y2:[[inArray objectAtIndex:4] floatValue] R:[[inArray objectAtIndex:5] floatValue] G:[[inArray objectAtIndex:6] floatValue] B:[[inArray objectAtIndex:7] floatValue] A:[[inArray objectAtIndex:8] floatValue]];
    }
    else if([inArray count]==5 && [[inArray objectAtIndex:0] isEqualToString:@"paintoval"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self paintOvalX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue] X2:[[inArray objectAtIndex:3] floatValue] Y2:[[inArray objectAtIndex:4] floatValue]];
    }
    else if([inArray count]==9 && [[inArray objectAtIndex:0] isEqualToString:@"paintoval"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self paintOvalX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue] X2:[[inArray objectAtIndex:3] floatValue] Y2:[[inArray objectAtIndex:4] floatValue] R:[[inArray objectAtIndex:5] floatValue] G:[[inArray objectAtIndex:6] floatValue] B:[[inArray objectAtIndex:7] floatValue] A:[[inArray objectAtIndex:8] floatValue]];
    }
    else if([inArray count]==5 && [[inArray objectAtIndex:0] isEqualToString:@"frameoval"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self frameOvalX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue] X2:[[inArray objectAtIndex:3] floatValue] Y2:[[inArray objectAtIndex:4] floatValue]];
    }
    else if([inArray count]==9 && [[inArray objectAtIndex:0] isEqualToString:@"frameoval"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self frameOvalX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue] X2:[[inArray objectAtIndex:3] floatValue] Y2:[[inArray objectAtIndex:4] floatValue] R:[[inArray objectAtIndex:5] floatValue] G:[[inArray objectAtIndex:6] floatValue] B:[[inArray objectAtIndex:7] floatValue] A:[[inArray objectAtIndex:8] floatValue]];
    }
    else if([inArray count]%2==1 && [[inArray objectAtIndex:0] isEqualToString:@"framepoly"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        NSArray* pointArray = [inArray subarrayWithRange:NSMakeRange(1, [inArray count]-1) ];//strip off "framepoly"
        
        [self framePoly:pointArray];
    }
    else if([inArray count]>0 && [inArray count]%2==1 && [[inArray objectAtIndex:0] isEqualToString:@"framepolyRGBA"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        NSArray* pointArray = [inArray subarrayWithRange:NSMakeRange(1, [inArray count]-5) ];//strip off "framepolyRGBA"
        NSInteger RGBAStartIndex = [inArray count]-4;
        
        [self framePolyRGBA:pointArray R:[[inArray objectAtIndex:RGBAStartIndex] floatValue] G:[[inArray objectAtIndex:RGBAStartIndex+1] floatValue] B:[[inArray objectAtIndex:RGBAStartIndex+2] floatValue] A:[[inArray objectAtIndex:RGBAStartIndex+3] floatValue] ];
    }
    else if([inArray count]%2==1 && [[inArray objectAtIndex:0] isEqualToString:@"paintpoly"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        NSArray* pointArray = [inArray subarrayWithRange:NSMakeRange(1, [inArray count]-1) ];//strip off "paintpoly"
        
        [self paintPoly:pointArray];
    }
    else if([inArray count]>0 && [inArray count]%2==1 && [[inArray objectAtIndex:0] isEqualToString:@"paintpolyRGBA"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        NSArray* pointArray = [inArray subarrayWithRange:NSMakeRange(1, [inArray count]-5) ];//strip off "paintpolyRGBA"
        NSInteger RGBAStartIndex = [inArray count]-4;
        
        [self paintPolyRGBA:pointArray R:[[inArray objectAtIndex:RGBAStartIndex] floatValue] G:[[inArray objectAtIndex:RGBAStartIndex+1] floatValue] B:[[inArray objectAtIndex:RGBAStartIndex+2] floatValue] A:[[inArray objectAtIndex:RGBAStartIndex+3] floatValue] ];
    }
    else if([inArray count]==3 && [[inArray objectAtIndex:0] isEqualToString:@"lineto"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self lineToX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue]  ];
    }
    else if([inArray count]==7 && [[inArray objectAtIndex:0] isEqualToString:@"lineto"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self lineToX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue] R:[[inArray objectAtIndex:3] floatValue] G:[[inArray objectAtIndex:4] floatValue] B:[[inArray objectAtIndex:5] floatValue] A:[[inArray objectAtIndex:6] floatValue] ];
    }
    else if([inArray count]==3 && [[inArray objectAtIndex:0] isEqualToString:@"moveto"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self moveToX:[[inArray objectAtIndex:1] floatValue] Y:[[inArray objectAtIndex:2] floatValue]  ];
    }
    else if([inArray count]==2 && [[inArray objectAtIndex:0] isEqualToString:@"penwidth"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
        [self setPenWidth: [[inArray objectAtIndex:1] floatValue]  ];
    }
    else if ([inArray count]==1 && [[inArray objectAtIndex:0] isEqualToString:@"clear"]){
        [self clear];
    }
}


//

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    //NSLog(@"draw==== %.2f %.2f", self.bounds.size.width, self.bounds.size.height);
    // Drawing code
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort]; //UIGraphicsGetCurrentContext();
    
    CGImageRef cacheImage = CGBitmapContextCreateImage(_cacheContext);
    CGContextDrawImage(context, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height), cacheImage);
    CGImageRelease(cacheImage);

/*    CGContextSetRGBFillColor (context, 1, 0, 0, 1);// 3
    CGContextFillRect (context, CGRectMake (0, 0, 200, 100 ));// 4
    CGContextSetRGBFillColor (context, 0, 0, 1, .5);// 5
    CGContextFillRect (context, CGRectMake (0, 0, 100, 200));
*/
 }


@end
