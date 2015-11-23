//
//  MMPControl.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/26/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//
//  Abstract superclass of all gui control widget classes.


#import "MMPControl.h"
#define HANDLE_SIZE 20 //size of the EditHandle in the lower right corner
#define PASTE_OFFSET 20 //when a MMPControl gets copeid and pasted, offset it it this much (to the right and down)
#define BORDER_WIDTH 5 //editing border
#import "CanvasView.h"

@implementation MMPControl
@synthesize isSelected, editingDelegate;

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];
        //default colors!
        [self setColor:[NSColor blueColor]];
        [self setHighlightColor:[NSColor redColor]];
    }
    return self;
}

//coordinate system is flipped upside down, so that it matches the coordinate system of iOS
-(BOOL) isFlipped{
  return YES;
}

//put the EditHandle on the lower right when editing
-(void)addHandles{
  _handle = [[EditHandle alloc]initWithFrame:CGRectMake(self.frame.size.width-HANDLE_SIZE, self.frame.size.height-HANDLE_SIZE, HANDLE_SIZE, HANDLE_SIZE) ];

  _handle.hidden=YES;
  [self addSubview:_handle];
}

-(void)hackRefresh{
 if(isSelected){
   [self.layer setBorderWidth:BORDER_WIDTH];
 }
 [self setColor:[self color]];
 [self bringUpHandle];
 }

-(void)bringUpHandle{//bringSubviewToFront doesn't seem to work?
  [_handle removeFromSuperview];
  [self addSubview:_handle];
  _handle.layer.borderWidth=BORDER_WIDTH;
}

-(void)mouseDown:(NSEvent *)event{

  if([editingDelegate isEditing]){

    //SELECTION
    wasSelectedThisCycle=NO;
    BOOL wasAlreadySelected = isSelected;
    if(!isSelected){
      [self setIsSelected:YES];//toggle
      wasSelectedThisCycle=YES;
    }

    [editingDelegate controlEditClicked:self withShift:([event modifierFlags] & NSShiftKeyMask)!=0 wasAlreadySelected:wasAlreadySelected ];//poll objects for selection state

    //MOVEMENT
    lastDragLocation=[[self superview] convertPoint:[event locationInWindow]fromView:nil];
    clickOffsetInMe=[self convertPoint:[event locationInWindow] fromView:nil];

    [self.editingDelegate updateGuide:self]; //TODO move to delegate controlEditClicked
  }
}

-(void)setFrameObjectUndoable:(NSValue*)frameObject{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setFrameObjectUndoable:) object:[NSValue valueWithRect:self.frame]];
  [self setFrame:[frameObject rectValue]];
}

-(void)setFrame:(NSRect)frameRect{
  [super setFrame:frameRect];
  if(_handle){
    [_handle setFrameOrigin:CGPointMake(frameRect.size.width-HANDLE_SIZE,self.frame.size.height-HANDLE_SIZE)];
  }
}

-(void)setFrameOriginObjectUndoable:(NSValue*)pointObject{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setFrameOriginObjectUndoable:) object:[NSValue valueWithPoint:self.frame.origin]];
  [self setFrameOrigin:[pointObject pointValue]];
}

-(void)mouseDragged:(NSEvent *)event{

  if([self.editingDelegate isEditing]){
    if(dragging==NO){//first drag
      [[self undoManager] beginUndoGrouping];
    }
    dragging=YES;

    [[NSCursor closedHandCursor] push];
    NSPoint newDragLocation=[[self superview] convertPoint:[event locationInWindow] fromView:nil];
    //CGPoint newOrigin = CGPointMake(newDragLocation.x-clickOffsetInMe.x, newDragLocation.y-clickOffsetInMe.y);

    //[self setFrameOriginObjectUndoable:[NSValue valueWithPoint:newOrigin]]; //move movement to delegate
    [self autoscroll:event];
    [self.editingDelegate controlEditMoved:self deltaPoint:CGPointMake(newDragLocation.x-lastDragLocation.x, newDragLocation.y-lastDragLocation.y)];
    //[self.editingDelegate updateGuide:self];
    lastDragLocation=newDragLocation;
  }
}

-(void)mouseUp:(NSEvent *)theEvent  {

  if([self.editingDelegate isEditing]){
    //if end of dragging
    if(dragging){
      [[self  undoManager] endUndoGrouping];
      [[NSCursor closedHandCursor] pop];
      dragging=NO;
      [self.editingDelegate controlEditReleased:self withShift:([theEvent modifierFlags] & NSShiftKeyMask)!=0 hadDrag:YES];//don't think we need this for anything...
    }
    //wasn't a drag, just a click+release, and if has shift
    else{
      if(([theEvent modifierFlags] & NSShiftKeyMask)!=0 && isSelected && !wasSelectedThisCycle) [self setIsSelected:NO];//allow shift toggle off
      [self.editingDelegate controlEditReleased:self withShift:([theEvent modifierFlags] & NSShiftKeyMask)!=0 hadDrag:NO];
    }
    [self.editingDelegate updateGuide:nil];
  }
}



-(void)setIsSelected:(BOOL)newSelected{

  isSelected=newSelected;
  if(isSelected){
    [self.layer setBorderWidth:BORDER_WIDTH];
    [_handle setHidden:NO];
  }
  else{
    [self.layer setBorderWidth:0];
    [_handle setHidden:YES];
  }
}

/*+(CGColorRef) CGColorFromNSColor:(NSColor*)inColor{

 CGFloat components[4];
 [inColor getComponents:components];
 return CGColorCreateGenericRGB(components[0], components[1], components[2], components[3]);
 }*/

//====copy/paste
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:NSStringFromRect(CGRectMake(self.frame.origin.x+PASTE_OFFSET, self.frame.origin.y+PASTE_OFFSET, self.frame.size.width, self.frame.size.height)) forKey:@"frame"];//string->rect
  [coder encodeObject:self.address forKey:@"address"];//string
  [coder encodeObject:self.color forKey:@"color"];//color
  [coder encodeObject:self.highlightColor forKey:@"highlightColor"];//color
  //[coder encodeObject:self.handle forKey:@"handle"];

}

- (id)initWithCoder:(NSCoder *)coder {
  CGRect frame = NSRectFromString([coder decodeObjectForKey:@"frame"]);
  self = [[[self class] alloc] initWithFrame:frame];
  if(self){//=[super initWithCoder:coder]){
    //[self setWantsLayer:YES];
    //[self setFrame:NSRectFromString([coder decodeObjectForKey:@"frame"])];
    self.address = [coder decodeObjectForKey:@"address"];
    [self setColor:[coder decodeObjectForKey:@"color"]];
    [self setHighlightColor:[coder decodeObjectForKey:@"highlightColor"]];
  }
  return self;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
  return [NSArray arrayWithObject:@"com.iglesiaintermedia.mobmuplat.mmpcontrol"];
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
  return [NSArray arrayWithObject:@"com.iglesiaintermedia.mobmuplat.mmpcontrol"];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pboard {
  return NSPasteboardReadingAsKeyedArchive;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
  return [NSKeyedArchiver archivedDataWithRootObject:self];
}


-(BOOL)canBecomeFirstResponder{
  return YES;
}

-(void)keyDown:(NSEvent*)event{
  [self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

//responder chain for keyboard "delete" hit
-(IBAction)deleteBackward:(id)sender{
  //printf("\ndel!");
  [self.editingDelegate controlEditDelete];
}

//more undoables

-(void)setAddressUndoable:(NSString *)address{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setAddressUndoable:)  object:self.address];
  [self setAddress:address];
}

-(void)setColorUndoable:(NSColor *)color{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setColorUndoable:) object:self.color];
  [self setColor:color];
}

-(void)setHighlightColorUndoable:(NSColor *)color{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setHighlightColorUndoable:) object:self.highlightColor];
  [self setHighlightColor:color];
}

//all subclasses override this when receiveing a message
-(void)receiveList:(NSArray *)inArray{
  if ([inArray count] >= 2 &&
      [inArray[0] isKindOfClass:[NSString class]] &&
      [inArray[0] isEqualToString:@"enable"] &&
      [inArray[1] isKindOfClass:[NSNumber class]]) {
    self.enabled = ([inArray[1] floatValue] > 0);
  }
}

- (void)setEnabled:(BOOL)enabled {
  [super setEnabled:enabled];
  self.alphaValue = enabled ? 1 : .2;
}

@end
