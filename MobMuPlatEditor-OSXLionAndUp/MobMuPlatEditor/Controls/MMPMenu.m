//
//  MMPMenu.m
//  MobMuPlatEditor
//
//  Created by Daniel Iglesia on 4/9/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPMenu.h"
#import "MMPLabel.h"
#define EDGE_RADIUS 5
#define DEFAULT_FONT @"HelveticaNeue"
#define DEFAULT_FONTSIZE 18
#define TAB_WIDTH 30


@interface MMPMenu () {
  NSMutableArray* _dataArray;
  
  NSView* downView;
  NSTextField* textField;
  NSView *innerView;
  
  NSScrollView * tableContainer;
  //NSButton *doneButton;
  NSView* topView;
  NSTableView* theTableView;
  //BOOL _hasSelectedElement;
}

@end

@implementation MMPMenu

- (id)initWithFrame:(NSRect)frame{
  self = [super initWithFrame:frame];
  if (self) {
    self.address=@"/myMenu";
    //self.layer.backgroundColor=[NSColor clearColor]];
    //self.layer.cornerRadius=EDGE_RADIUS;
    
    
    innerView = [[NSView alloc]init];
    [innerView setWantsLayer:YES];
    innerView.layer.borderColor = self.color.CGColor;
    innerView.layer.cornerRadius=EDGE_RADIUS;
    innerView.layer.borderWidth = 2;
    innerView.layer.backgroundColor=[[NSColor clearColor]CGColor];
    [self addSubview:innerView];
    
    textField = [[NSTextField alloc]initWithFrame:CGRectMake(TAB_WIDTH, 0, frame.size.width-TAB_WIDTH, frame.size.height)];
    textField.bezeled         = NO;
    textField.editable        = NO;
    textField.drawsBackground = NO;
    [textField setTextColor:self.color];
    textField.alignment = NSCenterTextAlignment;
    textField.font = [NSFont fontWithName:DEFAULT_FONT size:DEFAULT_FONTSIZE];
    
    _titleString = @"Menu";
    [self setTitleString:_titleString];
    [self addSubview:textField];
    [textField sizeToFit];
    
    downView = [[NSView alloc] initWithFrame:CGRectMake(0, 0, TAB_WIDTH, self.frame.size.height) ];
    [downView setWantsLayer:YES];
    downView.layer.borderColor = self.color.CGColor;
    downView.layer.borderWidth = 2;
    downView.layer.cornerRadius=EDGE_RADIUS;
    //downView.layer.backgroundColor=[NSColor clearColor]];
    [self addSubview:downView];
   
    //self.layer.backgroundColor = [NSColor clearColor]];
    
    [self setFrame:frame];
    [self addHandles];
  }
  return self;
}

-(void)setFrame:(NSRect)frameRect{
  [super setFrame:frameRect];
  [innerView setFrame:CGRectMake(0,0, frameRect.size.width, frameRect.size.height)];
  [downView setFrame:CGRectMake(0, 0, TAB_WIDTH, self.frame.size.height) ];
  
  [textField setFrame:CGRectMake(frameRect.size.width/2-textField.frame.size.width/2, frameRect.size.height/2-textField.frame.size.height/2, textField.frame.size.width, textField.frame.size.height )];
}

-(void)hackRefresh{
  [super hackRefresh];
  self.layer.cornerRadius=EDGE_RADIUS;
}

-(void)showTable{
  NSView* canvas = self.editingDelegate.canvasOuterView;
 
  topView = [[NSView alloc] initWithFrame:NSMakeRect(0, canvas.frame.size.height-40, canvas.frame.size.width, 40)];
  [topView setWantsLayer:YES];
  topView.layer.backgroundColor = [[NSColor darkGrayColor] CGColor];//self.color.CGColor;
  [canvas addSubview:topView];
  
  NSTextField* titleField = [[NSTextField alloc]initWithFrame:NSMakeRect(80, 10, topView.frame.size.width-80, topView.frame.size.height-20)];
  titleField.alignment = NSCenterTextAlignment;
  titleField.bezeled         = NO;
  titleField.editable        = NO;
  titleField.drawsBackground = NO;
  titleField.font = [NSFont systemFontOfSize:16];
  [titleField setTextColor:[NSColor whiteColor]];
  //titleField.backgroundColor=[NSColor clearColor];
  [titleField setStringValue:_titleString];
  
  [topView addSubview:titleField];
  
  NSButton *doneButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 80, 40)];
  [doneButton setAction:@selector(doneButtonHit)];
  [doneButton setTarget:self];
  [[doneButton cell] setBackgroundColor:[NSColor darkGrayColor]];
  [doneButton setTitle:@"Done"];
  
  NSColor *color = [NSColor colorWithCalibratedRed:.2 green:.4 blue:1. alpha:1.0];
  NSMutableAttributedString *colorTitle =
  [[NSMutableAttributedString alloc] initWithAttributedString:[doneButton attributedTitle]];
  NSRange titleRange = NSMakeRange(0, [colorTitle length]);
  [colorTitle addAttribute:NSForegroundColorAttributeName
                     value:color
                     range:titleRange];
  [colorTitle addAttribute:NSFontAttributeName
                     value:[NSFont systemFontOfSize:16]
                     range:titleRange];
  [doneButton setAttributedTitle:colorTitle];
  
  [topView addSubview:doneButton];
  
  tableContainer = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, canvas.frame.size.width, canvas.frame.size.height-40)];
  theTableView = [[NSTableView alloc] initWithFrame:tableContainer.bounds];
  [theTableView setHeaderView:nil];
  // create columns for our table
  NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"Col1"];
  [column1 setWidth:canvas.frame.size.width];
  // generally you want to add at least one column to the table view.
  [theTableView addTableColumn:column1];
  [theTableView setDelegate:self];
  [theTableView setDataSource:self];
  [theTableView setBackgroundColor:self.editingDelegate.patchBackgroundColor];
  [theTableView reloadData];//necc?

  //theTableView.intercellSpacing = CGSizeMake(10, 80);
  // embed the table view in the scroll view, and add the scroll view
  // to our window.
  [tableContainer setDocumentView:theTableView];
  [tableContainer setHasVerticalScroller:YES];
  [canvas addSubview:tableContainer];
}

- (void)doneButtonHit{
  [topView removeFromSuperview];
  [tableContainer removeFromSuperview];
}

-(void)mouseDown:(NSEvent *)event{
  [super mouseDown:event];
  if(![self.editingDelegate isEditing]){
    //[self setValue:1];
    [self showTable];
  }
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
  return 44;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return _dataArray.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
  
  // Get an existing cell with the MyView identifier if it exists
  NSTextField *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
  
  // There is no existing cell to reuse so create a new one
  if (result == nil) {
    
    // Create the new NSTextField with a frame of the {0,0} with the width of the table.
    // Note that the height of the frame is not really relevant, because the row height will modify the height.
    result = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 40, 10)];
    //result.backgroundColor = [NSColor clearColor];
    result.cell = [[MiddleAlignedTextFieldCell alloc]init ];
    result.bezeled         = NO;
    result.editable        = NO;
    result.drawsBackground = NO;
    result.alignment = NSCenterTextAlignment;
    result.bordered = YES;
    result.textColor = self.color;
    result.font = [NSFont systemFontOfSize:16];
    result.identifier = @"MyView";
  }
  
  result.stringValue = [_dataArray objectAtIndex:row];
  
  return result;
  
}

//hack:this also fires when table selection is set programatically...
-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
  //send
  [self sendValueAt:row];
  //clear
  [topView removeFromSuperview];
  [tableContainer removeFromSuperview];
  //display
  //[textField setStringValue:[_dataArray objectAtIndex:row]];
  //mark
  //_hasSelectedElement = YES;
  return YES;
}

//send out OSC message
-(void)sendValueAt:(NSInteger)index{
  NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
  [formattedMessageArray addObject:self.address];
  [formattedMessageArray addObject:[NSNumber numberWithInt:(int)index]];
  [formattedMessageArray addObject:[_dataArray objectAtIndex:index]];
  [self.editingDelegate sendFormattedMessageArray:formattedMessageArray];
}

//ugly hack so that textview doesn't take touches, but passes to controls underneath
//TODO something like userInteractionEnabled = NO to fix?
- (NSView *)hitTest:(NSPoint)aPoint{
  //if I am editing, behave nomrally like any other MMPControl
  if([self.editingDelegate isEditing]){
    NSPoint convPoint = [self convertPoint:aPoint fromView:[self superview]];
    if(NSPointInRect(convPoint, [[self handle] frame]))
      return [self handle];
    else if(NSPointInRect(aPoint, [self frame])){
      return self;
    }
    else return nil;
  }
  
  //but if not editing, return me if touched in bounds
  if(NSPointInRect(aPoint, [self frame]))return self;
  else return nil;
}

-(void)setColor:(NSColor *)color{
  [super setColor:color];
  innerView.layer.borderColor = self.color.CGColor;
  downView.layer.borderColor = self.color.CGColor;
  [textField setTextColor:self.color];
  
}

-(void)setTitleStringUndoable:(NSString*)inString{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setTitleStringUndoable:) object:[self titleString]];
  [self setTitleString:inString];
}

-(void)setTitleString:(NSString *)titleString{
  _titleString = titleString;
  //if(!_hasSelectedElement){
    [self setStringValue:_titleString];
  //}
}

-(void)setStringValue:(NSString *)aString{
  [textField setStringValue:aString];
 [textField setFrame: CGRectMake(TAB_WIDTH, 0, self.frame.size.width-TAB_WIDTH, self.frame.size.height)];
  [textField sizeToFit];
  [textField setFrame:CGRectMake(self.frame.size.width/2-textField.frame.size.width/2, self.frame.size.height/2-textField.frame.size.height/2, textField.frame.size.width, textField.frame.size.height )];
}

//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object

-(void)receiveList:(NSArray *)inArray{
  NSMutableArray* dataArray = [[NSMutableArray alloc] init];
  
  for(id thing in inArray){
    if([thing isKindOfClass:[NSString class]]){
      [dataArray addObject:(NSString*)thing];
    }
    else if ([thing isKindOfClass:[NSNumber class]]){
      NSNumber* thingNumber = (NSNumber*)thing;
      if ([MMPLabel numberIsFloat:thingNumber] ){ //todo put in separate class
        //pd sends floats :(
        if(fmod([thingNumber floatValue],1)==0) {
          [dataArray addObject:[NSString stringWithFormat:@"%d", (int)[thingNumber floatValue]]];//print whole numbers as ints
        } else {
          [dataArray addObject:[NSString stringWithFormat:@"%.3f", [thingNumber floatValue]]];
        }
      }
      else {
        [dataArray addObject:[NSString stringWithFormat:@"%d", [thingNumber intValue]]];
      }
    }
  }
  _dataArray=dataArray;
  
  if(theTableView){
    [theTableView reloadData];
  }
}

//coder for copy/paste

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:self.titleString forKey:@"titleString"];
}

- (id)initWithCoder:(NSCoder *)coder {
  
  if(self=[super initWithCoder:coder]){
    [self setTitleString:[coder decodeObjectForKey:@"titleString"]];
  }
  return self;
}

@end

@implementation MiddleAlignedTextFieldCell

- (NSRect)titleRectForBounds:(NSRect)theRect {
  NSRect titleFrame = [super titleRectForBounds:theRect];
  NSSize titleSize = [[self attributedStringValue] size];
  titleFrame.origin.y = theRect.origin.y - .5 + (theRect.size.height - titleSize.height) / 2.0;
  return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  NSRect titleRect = [self titleRectForBounds:cellFrame];
  [[self attributedStringValue] drawInRect:titleRect];
}

@end