//
//  MMPTable.m
//  MobMuPlatEditor
//
//  Created by diglesia on 4/27/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPTable.h"

@implementation MMPTable {
  NSUInteger _fillIndex;
  int _tableSize;
  float* _tableData;
  
  CGContextRef _cacheContext;
  CGContextRef _cacheContextSelection;
  float fR,fG,fB,fA;//FRGBA
  float sR,sG,sB,sA;
  
  CGPoint touchDownPoint;
  CGPoint lastPoint;//not normalized
  int lastTableIndex;
  //int touchDownTableIndex;
  //BOOL _tableSeemsBad;
  BOOL loadedTable;
  BOOL _created;
  //debug
  int chunkCount;
  
}

- (id)initWithFrame:(NSRect)frame{
  self = [super initWithFrame:frame];
  if (self) {
    self.address=@"/myTable";
    _created = YES;
    self.layer.backgroundColor=[MMPControl CGColorFromNSColor:self.color];
    self.selectionColor = [NSColor colorWithCalibratedRed:1. green:1. blue:1. alpha:.5];
    
    //self.userInteractionEnabled = NO;//until table load TODO
    // Initialization code
    

      //_tableName = @"dummyName";//todo use init value to protect against nil storage?
    
    
    [self setFrame:frame];//create context
    
    [self addHandles];
    
  }
  return self;
}

-(void)setAddress:(NSString *)address{
  [super setAddress:address];
  if(_created)[self loadTable];
}

-(void)loadTable {
    [self.editingDelegate sendFormattedMessageArray:[NSMutableArray arrayWithObjects:@"/system/requestTable",
                                     [[NSMutableString alloc]initWithString:@"s"],
                                     self.address, nil]];
}


-(void)setFrame:(NSRect)frame{
  [super setFrame:frame];
  
  if(_cacheContext!=nil){//free stuff
    CGContextRelease(_cacheContext);
  }
  if(_cacheContextSelection!=nil){//free stuff
    CGContextRelease(_cacheContextSelection);
  }
  //_cacheContext = [self createBitmapContextW:(int)self.frame.size.width H:(int)self.frame.size.height];
  _cacheContext = CGBitmapContextCreate (nil, (int)frame.size.width, (int)frame.size.height, 8, 0, CGColorSpaceCreateDeviceRGB(),  kCGImageAlphaPremultipliedLast  );
  //CGContextSetRGBFillColor(_cacheContext, 1., 0., 1., 1.);
  
  if(_cacheContext == nil) {//this happens on zero-size frame, during copy/paste initWithCoder:
    return;
  }
  CGContextSetLineWidth(_cacheContext, 2);
  
  _cacheContextSelection = CGBitmapContextCreate (nil, (int)frame.size.width, (int)frame.size.height, 8, 0, CGColorSpaceCreateDeviceRGB(),  kCGImageAlphaPremultipliedLast  );
  //CGContextSetRGBFillColor(_cacheContextSelection, 1., 0., 1., .5);

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

-(void)setSelectionColor:(NSColor *)selectionColor{
  _selectionColor = selectionColor;
  
  sR  = [_selectionColor redComponent];
  sG  = [_selectionColor greenComponent];
  sB  = [_selectionColor blueComponent];
  sA  = [_selectionColor alphaComponent];
  
  
}

-(void)draw{
  [self drawFromIndex:0 toIndex:_tableSize-1];
}

-(void)drawFromIndex:(int)indexA toIndex:(int)indexB {
  CGContextSetRGBStrokeColor(_cacheContext, fR,fG,fB,fA);
  CGContextMoveToPoint(_cacheContext, 0,0);
	int padding = 3;
  int indexDrawPointA = (int)((float)MIN(indexA,indexB)/_tableSize*self.frame.size.width)-padding;
  indexDrawPointA = MIN(MAX(indexDrawPointA,0),self.frame.size.width-1);
  int indexDrawPointB = (int)((float)(MAX(indexA,indexB)+1)/(_tableSize)*self.frame.size.width)+padding;
  indexDrawPointB = MIN(MAX(indexDrawPointB,0),self.frame.size.width-1);
  //NSLog(@"index AB drawpoint AB %d %d %d %d", indexA, indexB, indexDrawPointA, indexDrawPointB);
  CGRect rect = CGRectMake(indexDrawPointA, 0, indexDrawPointB-indexDrawPointA, self.frame.size.height);
  CGContextClearRect(_cacheContext, rect);
  
  
  for(int i=indexDrawPointA; i<=indexDrawPointB; i++){
    float x = (float)i;//(float)i/self.frame.size.width;
    int index = (int)((float)i/self.frame.size.width*_tableSize);
    
    //if touch down one point, make sure that point is represented in redraw and not skipped over
    int prevIndex = (int)((float)(i-1)/self.frame.size.width*_tableSize);
    if(indexA==indexB && indexA<index && indexA>prevIndex) index = indexA;
    
    float y = _tableData[index];
    float unflippedY = (1-((y+1)/2)) *self.frame.size.height;
    //NSLog(@"i %d x %.2f index %d y %.2f unflip %.2f", i,x,index,y, unflippedY);
    if(i==indexDrawPointA){
      CGContextMoveToPoint(_cacheContext, x,unflippedY);
    }
    else {
      CGContextAddLineToPoint(_cacheContext, x, unflippedY);
      CGContextMoveToPoint(_cacheContext, x,unflippedY);
    }
  }
  
  
  
  CGContextStrokePath(_cacheContext);
  /*
   CGRect newRect = CGRectMake(MIN(penPoint.x, x)-penWidth, MIN(penPoint.y, y)-penWidth, fabs(penPoint.x-x)+(2*penWidth), fabs(penPoint.y-y)+(2*penWidth));
   [self setNeedsDisplayInRect:newRect];*/
  [self setNeedsDisplay ];//]InRect:rect];
}

-(void)drawHighlightBetween:(CGPoint)pointA and:(CGPoint)pointB{
  CGContextSetRGBFillColor(_cacheContextSelection, sR,sG,sB,sA);
	CGRect newRect = CGRectMake( MIN(pointA.x,pointB.x), 0, MAX(fabsf(pointB.x-pointA.x),2), self.frame.size.height);
  CGContextClearRect(_cacheContextSelection, self.bounds);
  CGContextFillRect(_cacheContextSelection, newRect);
  [self setNeedsDisplay ];//InRect:newRect];
}

-(void)mouseDown:(NSEvent *)theEvent{
  [super mouseDown:theEvent];
  
  if(![self.editingDelegate isEditing] && loadedTable){
    lastPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    touchDownPoint = lastPoint;
    if(_mode==0) { //select
      [self drawHighlightBetween:lastPoint and:lastPoint];
    
    } else if (_mode == 1) {//draw
      float normalizedX = lastPoint.x/self.frame.size.width;
      int touchDownTableIndex = (int)(normalizedX*_tableSize);
      lastTableIndex = touchDownTableIndex;
      float normalizedY = lastPoint.y/self.frame.size.height;//change to -1 to 1
      float flippedY = (1-normalizedY)*2-1;
      //NSLog(@"touchDownTableIndex %d", touchDownTableIndex);
      
      _tableData[touchDownTableIndex] = flippedY;//check bounds
      [self drawFromIndex:touchDownTableIndex toIndex:touchDownTableIndex];
      
      //make one-element array to send in
      //float* touchValArray = (float*)malloc(1*sizeof(float));
      //touchValArray[0] = flippedY;
      //[PdBase copyArray:touchValArray toArrayNamed:_tableName withOffset:touchDownTableIndex count:1];//put this in draw?
      [self sendSetTableMessageFromIndex:touchDownTableIndex val:flippedY indexB:touchDownTableIndex val:flippedY];
      //free(touchValArray);
   
    }
    
  }
}

-(void)sendSetTableMessageFromIndex:(int)indexA val:(float)valA indexB:(int)indexB val:(float)valB {
  [self.editingDelegate sendFormattedMessageArray:[NSMutableArray arrayWithObjects:@"/system/setTable",
                                                   [[NSMutableString alloc]initWithString:@"sifif"],//startx/y endx/y
                                                   self.address,
                                                   [NSNumber numberWithInt:indexA],
                                                   [NSNumber numberWithFloat:valA],
                                                   [NSNumber numberWithInt:indexB],
                                                   [NSNumber numberWithFloat:valB],
                                                   nil]];
  //look for all other tables with same address, and just refresh
}

-(void)sendRangeMessageFromIndex:(int)indexA toIndex:(int)indexB {
  /*[self.controlDelegate sendGUIMessageArray:[NSArray arrayWithObjects:self.address, @"range", [NSNumber numberWithInt:indexA], [NSNumber numberWithInt:indexB], nil]];*/
  [self.editingDelegate sendFormattedMessageArray:[NSMutableArray arrayWithObjects:self.address,
                                                   [[NSMutableString alloc]initWithString:@"sii"],
                                                   @"range",
                                                   [NSNumber numberWithInt:indexA],
                                                   [NSNumber numberWithInt:indexB], nil]];
}

-(void)mouseDragged:(NSEvent *)theEvent{
  [super mouseDragged:theEvent];
  
  if(![self.editingDelegate isEditing] && loadedTable){
    CGPoint dragPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if(_mode==0) {//select
      float normalizedXA = touchDownPoint.x/self.frame.size.width;
      normalizedXA = MAX(MIN(normalizedXA,1),0);//touch down should always be in bounds
      int dragTableIndexA = (int)(normalizedXA*_tableSize);
      
      float normalizedXB = dragPoint.x/self.frame.size.width;
      normalizedXB = MAX(MIN(normalizedXB,1),0);
      int dragTableIndexB = (int)(normalizedXB*_tableSize);
      
      [self sendRangeMessageFromIndex:MIN(dragTableIndexA,dragTableIndexB) toIndex:MAX(dragTableIndexA,dragTableIndexB)];
      
      [self drawHighlightBetween:touchDownPoint and:dragPoint];
    
    
    } else if (_mode == 1) {//draw
      float normalizedX = dragPoint.x/self.frame.size.width;
      normalizedX = MAX(MIN(normalizedX,1),0);
      int dragTableIndex = (int)(normalizedX*_tableSize);
      float normalizedY = dragPoint.y/self.frame.size.height;//change to -1 to 1
      normalizedY = MAX(MIN(normalizedY,1),0);
      float flippedY = (1-normalizedY)*2-1;
      //NSLog(@"dragTableIndex %d", dragTableIndex);
      
      //compute size, including self but not prev
      int traversedElementCount = abs(dragTableIndex-lastTableIndex);
      if(traversedElementCount==0)traversedElementCount=1;
      //float* touchValArray = (float*)malloc(traversedElementCount*sizeof(float));
      
      _tableData[dragTableIndex] = flippedY;
      //==================just for local representation
      //just one
      if(traversedElementCount==1) {
        
        [self drawFromIndex:dragTableIndex toIndex:dragTableIndex];
        //touchValArray[0] = flippedY;
        //[PdBase copyArray:touchValArray toArrayNamed:_tableName withOffset:dragTableIndex count:1];
      } else {
        //NSLog(@"multi!");
        int minIndex = MIN(lastTableIndex, dragTableIndex);
        int maxIndex = MAX(lastTableIndex, dragTableIndex);
        
        float minValue = _tableData[minIndex];
        float maxValue = _tableData[maxIndex];
        //NSLog(@"skip within %d (%.2f) to %d(%.2f)", minTouchIndex, [[_valueArray objectAtIndex:minTouchIndex] floatValue], maxTouchIndex, [[_valueArray objectAtIndex:maxTouchIndex] floatValue]);
        for(int i=minIndex+1;i<=maxIndex;i++){
          float percent = ((float)(i-minIndex))/(maxIndex-minIndex);
          float interpVal = (maxValue - minValue) * percent  + minValue ;
          //NSLog(@"%d %.2f %.2f", i, percent, interpVal);
          _tableData[i]=interpVal;
          //touchValArray[i-(minIndex+1)]=interpVal;
        }
        [self drawFromIndex:minIndex toIndex:maxIndex];
        //[PdBase copyArray:touchValArray toArrayNamed:_tableName withOffset:minIndex+1 count:traversedElementCount];
      }
      //=======send end points to pd wrapper to do its own interp
      int minIndex = MIN(lastTableIndex, dragTableIndex);
      int maxIndex = MAX(lastTableIndex, dragTableIndex);
      float minValue = _tableData[minIndex];
      float maxValue = _tableData[maxIndex];
      [self sendSetTableMessageFromIndex:minIndex val:minValue indexB:maxIndex val:maxValue];
      //====
      
      lastTableIndex = dragTableIndex;
    }
    lastPoint = dragPoint;
  }
}

-(void)mouseUp:(NSEvent *)theEvent{
  [super mouseUp:theEvent];
  if(![self.editingDelegate isEditing] && loadedTable){
    
    
  }
}

- (void)drawRect:(CGRect)rect
{
  CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort]; //UIGraphicsGetCurrentContext();
  
  CGImageRef cacheImageSelection = CGBitmapContextCreateImage(_cacheContextSelection);
  CGContextDrawImage(context, self.bounds, cacheImageSelection);
  CGImageRelease(cacheImageSelection);
  
  CGImageRef cacheImage = CGBitmapContextCreateImage(_cacheContext);
  CGContextDrawImage(context, self.bounds, cacheImage);
  CGImageRelease(cacheImage);
  
}

-(void)setSelectionColorUndoable:(NSColor*)inColor{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setSelectionColorUndoable:) object:self.selectionColor];
  [self setSelectionColor:inColor];
}

-(void)setModeObjectUndoable:(NSNumber*)number{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setModeObjectUndoable:) object:[NSNumber numberWithInt:self.mode] ];
  [self setMode:(int)[number intValue] ];
}

- (void)setMode:(int)mode {
  _mode = mode;
  //clear selection
  CGContextClearRect(_cacheContextSelection, self.bounds);
  [self setNeedsDisplay];
}

-(void)receiveList:(NSArray *)inArray{
  if ([inArray count]==1 && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"clearSelection"] ){
    CGContextClearRect(_cacheContextSelection, self.bounds);
    [self setNeedsDisplay ];
  }
  else if ([inArray count]==1 && [[inArray objectAtIndex:0] isKindOfClass:[NSString class]] && [[inArray objectAtIndex:0] isEqualToString:@"refresh"] ){
    //NSLog(@"receive refresh on %@", self.address);
    [self loadTable];
  }
  else if([inArray count]==2 && [[inArray objectAtIndex:0] isEqualToString:@"fillTable"] && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
    NSLog(@"%@ filltable %d", self.address, [[inArray objectAtIndex:1]intValue]);
    loadedTable = NO;
    _fillIndex = 0;
    _tableSize = [[inArray objectAtIndex:1]intValue];
    if(_tableData){
      free(_tableData);
    }
    _tableData = (float*)malloc(_tableSize*sizeof(float));
    NSLog(@" alloc table data %p size %d", _tableData, _tableSize);
    chunkCount = 0;
  }
  else if([inArray count]==1 && [[inArray objectAtIndex:0] isEqualToString:@"done"]){
    NSLog(@"%@ filltable DONE chunkcount %d", self.address, chunkCount);
    loadedTable = YES;
    [self draw];
  }
  else if([inArray count]>0 && [[inArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
    //NSLog(@"%@ inarray count %lu fillIndex %lu", self.address, (unsigned long)[inArray count], (unsigned long)_fillIndex);
    //TODO catch array error?
    NSUInteger count = [inArray count];
    for (int i=0;i<count;i++){
      if(_fillIndex+i > _tableSize){
        NSLog(@"error, out of bounds");
        break;
      }
      _tableData[_fillIndex+i] = [[inArray objectAtIndex:i]floatValue];
      //NSLog(@"tableData[%d] = %.2f", _fillIndex+i, _tableData[_fillIndex+i]);
    }
    _fillIndex+=count;
    chunkCount++;
  }
}

//coder for copy/paste

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.selectionColor forKey:@"selectionColor"];
	[coder encodeInt:self.mode forKey:@"mode"];
  
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if(self){
    [self setSelectionColor:[coder decodeObjectForKey:@"selectionColor"]];
    [self setMode:[coder decodeIntForKey:@"mode"]];
  }
  return self;
}

-(void)dealloc {
  if(_tableData)free(_tableData);
}
@end
