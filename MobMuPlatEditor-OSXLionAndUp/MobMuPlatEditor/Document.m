//
//  Document.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/26/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//
//  Primary object for MobMuPlatEditor, subclass of NSDocument
//

#import "Document.h"

#define CANVAS_LEFT 250
#define CANVAS_TOP 8

@implementation Document {
  BOOL _snapToGridEnabled;
  NSUInteger _snapToGridXVal;
  NSUInteger _snapToGridYVal;
}
@synthesize isEditing;

- (id)init{
    self = [super init];
    if (self) {
        documentModel = [[DocumentModel alloc]init];
        textLineArray = [[NSMutableArray alloc]init];
    }
    return self;
}



- (NSString *)windowNibName
{
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];

  // guides
  _snapToGridXVal = 20;
  _snapToGridYVal = 20;
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSNumber *x = [defaults objectForKey:@"snapToGridXVal"];
  if (x) {
    _snapToGridXVal = [x integerValue];
    _snapToGridXVal = MAX(MIN(_snapToGridXVal,1000),5);
    [_editingGridXTextField setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)_snapToGridXVal]];
  }
  NSNumber *y = [defaults objectForKey:@"snapToGridYVal"];
  if (y) {
    _snapToGridYVal = [y integerValue];
    _snapToGridYVal = MAX(MIN(_snapToGridYVal,1000),5);
    [_editingGridYTextField setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)_snapToGridYVal]];
  }
  NSNumber *en = [defaults objectForKey:@"snapToGridEnabled"];
  if (en){
    _snapToGridEnabled = [en boolValue];
    [_editingGridEnableCheckButton setState:_snapToGridEnabled ? 1 : 0];
  }


  //kick the pd patch to get it to reconnect
  NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
  [formattedMessageArray addObject:@"/system/opened"];
  [formattedMessageArray addObject:[NSNumber numberWithInt:1]];
  [self sendFormattedMessageArray:formattedMessageArray];
  
    [canvasOuterView setWantsLayer:YES];
    canvasOuterView.layer.backgroundColor=CGColorCreateGenericGray(.1, 1);
    
    canvasView.editingDelegate=self;
    [canvasView refreshGuides];
    [[self canvasTypePopButton] selectItemAtIndex:-1];
    [[self canvasTypePopButton] synchronizeTitleAndSelectedItem];//clears check by "iphone" drop down element
    [[self orientationPopButton ] selectItemAtIndex:-1];
    [[self orientationPopButton] synchronizeTitleAndSelectedItem];
    
    [self fillFontPop];//fill the drop-down list of fonts, gotten from the document controller, as defined in uifontlist.txt

    // watch
    /* wear
    _watchCanvasView.buttonBlankView.hidden = YES;
    _watchCanvasView.canvasType = canvasTypeWatch; */

    // load
    [self loadFromModel];
    
    //default values
    [self.propColorWell setColor:[NSColor blueColor]];
    [self.propHighlightColorWell setColor:[NSColor redColor]];
    [self.propKnobIndicatorColorWell setColor:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1]];
    [self.tabView selectFirstTabViewItem:nil];
    [self setIsEditing:YES];

    /* wear _watchWidgetHighlightColorWell.color = [NSColor redColor];
    [self refreshWatchEditorElements]; */
}

+ (BOOL)autosavesInPlace{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSString* zString = [documentModel modelToString];
    NSData * zData = [zString dataUsingEncoding:NSASCIIStringEncoding];
    return zData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] ;
    documentModel = [DocumentModel modelFromString:jsonString];
    return YES;
}



-(void)loadFromModel{
    
  for(MMPControl* control in [documentModel controlArray]){
      control.editingDelegate=self;
      [canvasView addSubview:control];
  }
  /* wear
  for(NSArray* watchControlDuple in [documentModel watchControlDupleArray]){
    MMPControl* control = watchControlDuple[1];
    control.editingDelegate=self;
    [_watchCanvasView addSubview:control];

    NSTextView *controlTitleTextView = watchControlDuple[0];
    [_watchCanvasView addSubview:controlTitleTextView];
  }*/

  NSMutableSet* addedTableNamesSet = [[NSMutableSet alloc] init];
    //LOAD EXTERNAL FILES within docmodel ( panels) that may require a local path name
    for(MMPControl* control in [documentModel controlArray]){
        if([control isKindOfClass:[MMPPanel class]]){
            if([(MMPPanel*)control imagePath] && ![[(MMPPanel*)control imagePath] isEqualToString:@"" ]){
                [(MMPPanel*)control loadImage];
            }
        }
      
        //table stuff
      if([control isKindOfClass:[MMPTable class]]){
        // use set to quash multiple loads of same table/address
        if (![addedTableNamesSet containsObject:control.address]) {
          [(MMPTable*)control loadTable];
          [addedTableNamesSet addObject:control.address];
        }
        
      }
    }
    
    //UPDATE APPLICATION FIELDS
    //pdfile
    if([documentModel pdFile])
        [self.docFileTextField setStringValue:[documentModel pdFile]];
    
    //orient and canvas size
    [self updateWindowAndCanvas];
    [self.canvasTypePopButton selectItemAtIndex:[documentModel canvasType]];
    
    //[[self canvasTypePopButton] synchronizeTitleAndSelectedItem];//looks like not ness
    if(![documentModel isOrientationLandscape])[self.orientationPopButton selectItemAtIndex:0];
    else[self.orientationPopButton selectItemAtIndex:1];
    
    //doc bg color
    [canvasView setBgColor:[documentModel backgroundColor]];
    [self.docBGColorWell setColor:[documentModel backgroundColor]];
    
    //pages
    [self.docPageCountField setIntValue:[documentModel pageCount]];
    [canvasView setPageCount:[documentModel pageCount]];
    [self.docStartPageField setIntValue:[documentModel startPageIndex]+1];
    [self setCurrentPage:[documentModel startPageIndex]];
    

    //watch
  /* wear
    [_watchCanvasView setBgColor:[documentModel backgroundColor]];
    [_watchCanvasView setPageCount:[documentModel watchPageCount]];
    [_watchPageCountPopButton selectItemAtIndex:[[documentModel watchControlDupleArray] count]]; */


}

-(void)pruneControls{
    //check for controls that are out of bounds, add them to this array
    NSMutableArray* toDeleteArray = [[NSMutableArray alloc]init];
    
    for(MMPControl* control in [documentModel controlArray]){
        if(control.frame.origin.x>canvasView.frame.size.width){
            [toDeleteArray addObject:control];
        }
    }
    //and now delete them from view and from control array
    for(MMPControl* control in toDeleteArray){
        printf("\npruned control");
        [control removeFromSuperview];
        [[documentModel controlArray] removeObject:control];
    }
}

/* wear
- (void)pruneWatchControls {
  //check for controls that are out of bounds, add them to this array
  NSMutableArray* toDeleteDupleArray = [[NSMutableArray alloc]init];
  NSUInteger pageCount = documentModel.watchPageCount;

  // remove duples (of index >=pageCount) from control array
  for(NSUInteger i = pageCount;i<[documentModel.watchControlDupleArray count];i++){
    [toDeleteDupleArray addObject:documentModel.watchControlDupleArray[i]];
  }
  //and now delete them from view and from control array
  for(NSArray* controlDuple in toDeleteDupleArray){
    //printf("\npruned watch control");
    [controlDuple[0] removeFromSuperview];// title text view
    [controlDuple[1] removeFromSuperview];// control
    [documentModel.watchControlDupleArray removeObject:controlDuple];
  }
}*/

//called after whenever we change the type of canvas (iphone vs ipad vs iphone 5) or orientation (portrait vs landscape)
// compute new frames for window and scrollviews
-(void)updateWindowAndCanvas{
    
    CGRect screenFrame = [[NSScreen mainScreen] visibleFrame];
    
    if([documentModel canvasType]==canvasTypeIPhone3p5Inch){//iphone 3.5"
        if(![documentModel isOrientationLandscape]){//portrait
            [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+320+CANVAS_TOP, 480+CANVAS_TOP+CANVAS_TOP+20) display:YES animate:NO];
            
            [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
            [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
            [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-480-CANVAS_TOP, 320, 480)];
            
        }
        else{//landscape
            [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+480+CANVAS_TOP, 530) display:YES animate:NO];
            
            [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
            [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
            [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-320-CANVAS_TOP, 480, 320)];
        }
    }
    else if([documentModel canvasType]==canvasTypeIPhone4Inch){//iphone 4"
        if(![documentModel isOrientationLandscape]){//portrait
            [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+320+CANVAS_TOP, 568+CANVAS_TOP+CANVAS_TOP+20) display:YES animate:NO];
            
            [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
            [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
            [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-568-CANVAS_TOP, 320, 568)];
            
        }
        else{//landscape
            [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+568+CANVAS_TOP, 530) display:YES animate:NO];
            
            [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
            [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
            [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-320-CANVAS_TOP, 568, 320)];
        }
    }
    else if ([documentModel canvasType]==canvasTypeIPad){//ipad
        if(![documentModel isOrientationLandscape]){//portrait
            
            [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+768+CANVAS_TOP+10, screenFrame.size.height) display:YES animate:NO];
            [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
            [documentScrollView.documentView setFrameSize:CGSizeMake(CANVAS_LEFT+768+CANVAS_TOP, 1024+CANVAS_TOP+CANVAS_TOP) ];
            
            [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,CANVAS_TOP, /*384, 512*/ 768, 1024)];
            [documentScrollView.documentView scrollPoint:CGPointMake(0, [documentScrollView.documentView frame].size.height)];

        }
        else{//landscape
            [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+1024+CANVAS_TOP, 768+CANVAS_TOP+CANVAS_TOP+20) display:YES animate:NO];
            
            [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
            [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
            [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-768-CANVAS_TOP, 1024, 768)];

        }
    }
    else{//android 7
      if(![documentModel isOrientationLandscape]){//portrait

        [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+600+CANVAS_TOP+10, screenFrame.size.height) display:YES animate:NO];
        [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
        [documentScrollView.documentView setFrameSize:CGSizeMake(CANVAS_LEFT+600+CANVAS_TOP, 960+CANVAS_TOP+CANVAS_TOP) ];

        [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,CANVAS_TOP, 600, 960)];
        [documentScrollView.documentView scrollPoint:CGPointMake(0, [documentScrollView.documentView frame].size.height)];

      }
      else{//landscape
        [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+960+CANVAS_TOP, 600+CANVAS_TOP+CANVAS_TOP+20) display:YES animate:NO];

        [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
        [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
        [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-600-CANVAS_TOP, 960, 600)];

      }
    }
  //TODO srsly make these consants

    //this has to be done after setting outerview, it doesn't move with the change of outerview!
    [canvasView setCanvasType:[documentModel canvasType]];
    [canvasView setIsOrientationLandscape:[documentModel isOrientationLandscape]];
    
    
}


- (IBAction)canvasChanged:(NSPopUpButton *)sender{
    
    if([sender indexOfSelectedItem]==0 && [documentModel canvasType]!=canvasTypeIPhone3p5Inch){//change other to phone
        [documentModel setCanvasType:canvasTypeIPhone3p5Inch];
        [self updateWindowAndCanvas];
    }
    else if ([sender indexOfSelectedItem]==1 && [documentModel canvasType]!=canvasTypeIPhone4Inch){//change other to 4"
        [documentModel setCanvasType:canvasTypeIPhone4Inch];
        [self updateWindowAndCanvas];
    }
    else if ([sender indexOfSelectedItem]==2 && [documentModel canvasType]!=canvasTypeIPad){//change other to pad
        [documentModel setCanvasType:canvasTypeIPad];
        [self updateWindowAndCanvas];
    }
    else if ([sender indexOfSelectedItem]==3 && [documentModel canvasType]!=canvasTypeAndroid7Inch){//change other to android 7"
      [documentModel setCanvasType:canvasTypeAndroid7Inch];
      [self updateWindowAndCanvas];
    }
}

- (IBAction)orientationChanged:(NSPopUpButton *)sender {
    if([sender indexOfSelectedItem]==0 && [documentModel isOrientationLandscape]){//change landscape tp portrait
        [documentModel setIsOrientationLandscape:NO];
        [self updateWindowAndCanvas];
    }
    else if ([sender indexOfSelectedItem]==1 && ![documentModel isOrientationLandscape]){//change portrait to ladscape
        [documentModel setIsOrientationLandscape:YES];
        [self updateWindowAndCanvas];
    }

}

- (IBAction)docBGColorChanged:(NSColorWell *)sender {
    NSColor* noAlphaColor = [[sender color] colorWithAlphaComponent:1];//don't allow transulcency, even if the color picker sends it
    [documentModel setBackgroundColor:noAlphaColor];
    [canvasView setBgColor:noAlphaColor];
    /* wear [_watchCanvasView setBgColor:noAlphaColor]; */
}

- (IBAction)docPageCountChanged:(NSTextField *)sender {
    int oldPageCount = [documentModel pageCount];
    int newPageCount = [sender intValue ];
    //printf("\npre count %d, intended page ount %d",oldPageCount , newPageCount);
    
    if(newPageCount<1){
        newPageCount=1;
        [self.docPageCountField setIntValue:newPageCount];
    }
    
    if(newPageCount>[documentModel pageCount])//add new pages
        documentModel.pageCount = newPageCount;
    
    else if (newPageCount<[documentModel pageCount]){//subtract old pages
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Delete page(s)?"];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            documentModel.pageCount = newPageCount;
            //do we have to change current page?
            if(currentPageIndex>=newPageCount)[self setCurrentPage:newPageCount-1];
            [self pruneControls];
        }
        else{//user hit cancel button
            [self.docPageCountField setIntValue:oldPageCount];
        }
         
        
    }
    //printf("\ndoc page array size %d", [documentModel pageCount]);
    [canvasView setPageCount:[documentModel pageCount]];
    [self.pageIndexLabel setStringValue:[NSString stringWithFormat:@"Page %d/%d", currentPageIndex+1, [documentModel pageCount]]];
}

- (IBAction)docStartPageChanged:(NSTextField *)sender {
    //printf("\nstartpage newval: %d doc pagecount %d", [sender intValue]-1, [documentModel pageCount]);
    int newVal = [sender intValue]-1;
    if(newVal>=[documentModel pageCount]){
        newVal=[documentModel pageCount]-1;
        [self.docStartPageField setIntValue:newVal+1];
    }
    else if(newVal<0){
        newVal=0;
        [self.docStartPageField setIntValue:1];
    }
    [documentModel setStartPageIndex:newVal];
}

//if user wants a file browser for new pd file
- (IBAction)docChooseFile:(NSButton *)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setAllowedFileTypes:[[NSArray alloc] initWithObjects:@"pd",nil]];
    [openDlg setAllowsOtherFileTypes:NO];
  
  
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Enable the selection of directories in the dialog.
    //[openDlg setCanChooseDirectories:YES];
    
    // Display the dialog.  If the OK button was pressed,
    // process the files.
    if ( [openDlg runModal] == NSOKButton ){
        NSString* fileName = [[openDlg URL] absoluteString];
      
        [documentModel setPdFile:[fileName lastPathComponent]];
        [self.docFileTextField setStringValue:[fileName lastPathComponent]];
            
      
    }
}

//if user just typed new PD file name into text field
- (IBAction)docFileFieldChanged:(NSTextField *)sender {
    [documentModel setPdFile:[sender stringValue]];
}

//run after the individual "addSlider", "addPanel", etc methods
-(void)addControlHelper:(MMPControl*)newControl{
    
    newControl.editingDelegate=self;
    [[documentModel controlArray]  addObject:newControl];
    [canvasView addSubview:newControl];
    [newControl setColor:[self.propColorWell color] ];
    [newControl setHighlightColor:[self.propHighlightColorWell color] ];
    
    //just for redo
    //[newControl hackRefresh];
    
    //select
    [newControl setIsSelected:YES];
    [self controlEditClicked:newControl withShift:NO wasAlreadySelected:NO];
    
    [[self undoManager] registerUndoWithTarget:self selector:@selector(deleteControl:) object:newControl ];
    
}

- (IBAction)addSlider:(NSButton*)sender {
    MMPSlider* newControl = [[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
    [self addControlHelper:newControl];
}

- (IBAction)addKnob:(NSButton *)sender {
    MMPKnob* newControl = [[MMPKnob alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0 , 100, 100)];
    [newControl setIndicatorColor:[self.propKnobIndicatorColorWell color]];
    [self addControlHelper:newControl];
}

- (IBAction)addXYSlider:(NSButton *)sender {
    MMPXYSlider* newControl = [[MMPXYSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0,100,100)];
    [self addControlHelper:newControl];
}

- (IBAction)addLabel:(NSButton *)sender {
    MMPLabel* newControl = [[MMPLabel alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0,200,50)];
    [self.propLabelFontType removeAllItems];
    [self addControlHelper:newControl];
}

- (IBAction)addButton:(NSButton *)sender {
    MMPButton* newControl = [[MMPButton alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 100, 100)];
    [self addControlHelper:newControl];
}

- (IBAction)addToggle:(NSButton *)sender {
    MMPToggle* newControl = [[MMPToggle alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 100, 100)];
    [self addControlHelper:newControl];
}

- (IBAction)addGrid:(NSButton *)sender {
    MMPGrid* newControl = [[MMPGrid alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0,100,100)];
    [self addControlHelper:newControl];
}

- (IBAction)addPanel:(NSButton *)sender {
    MMPPanel* newControl = [[MMPPanel alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0,100,100)];
   [self addControlHelper:newControl];
}

- (IBAction)addMultiSlider:(NSButton *)sender {
    MMPMultiSlider* newControl = [[MMPMultiSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0,100,100)];
    [self addControlHelper:newControl];
}

- (IBAction)addMultiTouch:(NSButton *)sender {
  MMPMultiTouch* newControl = [[MMPMultiTouch alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0,100,100)];
  [self addControlHelper:newControl];
}

- (IBAction)addMenu:(NSButton *)sender {
  MMPMenu* newControl = [[MMPMenu alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0,200,40)];
  [self addControlHelper:newControl];
}

- (IBAction)addLCD:(NSButton *)sender {
    MMPLCD* newControl = [[MMPLCD alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0,100,100)];
    [self addControlHelper:newControl];
}

- (IBAction)addTable:(NSButton *)sender {
  MMPTable* newControl = [[MMPTable alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x,0,100,100)];
  [self addControlHelper:newControl];
  [newControl loadTable];//in case there is a pd table named "/myTable"
}



//undoable
-(void)deleteControl:(MMPControl*)control{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(addControlHelper:) object:control ];
    [control removeFromSuperview];
    [[documentModel controlArray] removeObject:control];
    if(control==currentSingleSelection)[self clearSelection];
}

//delete all selected controls
- (IBAction)propDelete:(NSButton *)sender {
    
    NSMutableArray* selectedControls = [[NSMutableArray alloc] init];
    for(MMPControl* control in [documentModel controlArray]){//printf(" %d", currControl);
        if([control isSelected]) [selectedControls addObject:control];
    }

    for(MMPControl* control in selectedControls){
        [self deleteControl:control];
    }
    
    [self clearSelection];//refresh editor properties of single selection
}

-(void)clearSelection{
    currentSingleSelection=nil;
    [self.propVarView setSubviews:[NSArray array]];//clear the control-specific subview
    [self.propAddressTextField setEnabled:NO];
    [self.propAddressTextField setStringValue:@""];
}



- (IBAction)bringForward:(NSButton *)sender {//swap array positions both in subviews and in document controlArray
    NSMutableArray* selectedControls = [[NSMutableArray alloc] init];
    
    for(MMPControl* control in [documentModel controlArray]){
        if([control isSelected]) [selectedControls addObject:control];
    }
    
    for(MMPControl* currControl in selectedControls){
        [[documentModel controlArray] removeObject:currControl];
        [[documentModel controlArray] addObject:currControl];
        [currControl removeFromSuperview];
        [canvasView addSubview:currControl];
        //[currControl hackRefresh];
    }
   
}

- (IBAction)bringBackward:(id)sender {
    NSMutableArray* selectedControls = [[NSMutableArray alloc] init];
 
    for(MMPControl* control in [documentModel controlArray]){//printf(" %d", currControl);
        if([control isSelected]) [selectedControls addObject:control];
    }

    for(MMPControl* currControl in selectedControls){
 
        [[documentModel controlArray] removeObject:currControl];
        [[documentModel controlArray] insertObject:currControl atIndex:0];
    }
    //redraw EVERYTHING?!?!?
    for(MMPControl* control in [documentModel controlArray]){
        [control removeFromSuperview];
        [canvasView addSubview:control];
        //[control hackRefresh];
    }
}


-(void)setIsEditing:(BOOL)inIsEditing{
    isEditing=inIsEditing;
    if(!isEditing){
        for(MMPControl* control in [documentModel controlArray]){
            if ([control isSelected]) [control setIsSelected:NO];
        }
        [self clearSelection];
    }
}

-(void)canvasClicked{//deselect all
    //printf("\ncanvasclicked!");
    [documentWindow makeFirstResponder:canvasView];
    for(MMPControl* currControl in [documentModel controlArray]){
        [currControl setIsSelected:NO];
    }
    [self clearSelection];//lose focus on a control and property tab's class-specific subview
}

//called when a control is clicked (during edit mode); could be part of a group selection
-(void)controlEditClicked:(MMPControl*)control withShift:(BOOL)withShift wasAlreadySelected:(BOOL)wasAlreadySelected{
    //if not a group selection and wasn't selected before, deselect all other controls
    if(!withShift && !wasAlreadySelected){
        for(MMPControl* currControl in [documentModel controlArray]){
            if(currControl!=control) [currControl setIsSelected:NO];
        }
    }
    
    //set color wells to control's color
    [self.propColorWell setColor:[control color]];
    [self.propHighlightColorWell setColor:[control highlightColor]];
    
    //if group selection
    if(withShift) [self clearSelection];
    //single selection
    else{
        //first update the application gui, so that text fields send their values to the previous selection
        
        [documentWindow makeFirstResponder:control];//forces address textfield to lose focus, thus assigning address to whaever was selected before
        
        [self.propVarView setSubviews:[NSArray array]];//clear property tab class-specific subview
        
        //fill in property tab fields (address, class-specific, etc)
        [self.propAddressTextField setEnabled:YES];
        [self.propAddressTextField setStringValue:[control address]];
        
        if([control isKindOfClass:[MMPKnob class]]){
             [self.propVarView addSubview:self.propKnobView];
            [self.propKnobRangeTextField setIntegerValue:[(MMPKnob*)control range]];
            [self.propKnobIndicatorColorWell setColor:[(MMPKnob*) control indicatorColor]];
        }
        else if([control isKindOfClass:[MMPSlider class]]){
            [self.propVarView addSubview:self.propSliderView];
            [self.propSliderRangeTextField setIntegerValue:[(MMPSlider*)control range]];
            if([(MMPSlider*)control isHorizontal])[self.propSliderOrientationPopButton selectItemAtIndex:1];
            else [self.propSliderOrientationPopButton selectItemAtIndex:0];
        }
        else if([control isKindOfClass:[MMPLabel class]]){
            [self.propVarView addSubview:self.propLabelView];
            [self.propLabelTextField setStringValue:[(MMPLabel*)control stringValue ]];
            [self.propLabelSizeTextField setStringValue:[NSString stringWithFormat:@"%d", [(MMPLabel*)control textSize ]]];
            [self.propLabelFontPopButton selectItemWithTitle:[(MMPLabel*)control fontFamily]];
            [self populateFont];
            [self.propLabelFontType selectItemWithTitle:[(MMPLabel*)control fontName]];

            [self.propLabelAndroidFontPopButton selectItemWithTitle:[(MMPLabel*)control androidFontName]];

        }
        else if([control isKindOfClass:[MMPGrid class]]){
            [self.propVarView addSubview:self.propGridView];
            [self.propGridDimXField setStringValue:[NSString stringWithFormat:@"%d", [(MMPGrid*)control dimX ]]];//use setInt
            [self.propGridDimYField setStringValue:[NSString stringWithFormat:@"%d", [(MMPGrid*)control dimY ]]];
            [self.propGridBorderThicknessField setStringValue:[NSString stringWithFormat:@"%d", [(MMPGrid*)control borderThickness ]]];
            [self.propGridPaddingField setStringValue:[NSString stringWithFormat:@"%d", [(MMPGrid*)control cellPadding ]]];
            [self.propGridModePopButton selectItemAtIndex:[(MMPGrid*)control mode]];
        }
        else if([control isKindOfClass:[MMPPanel class]]){
            [self.propVarView addSubview:self.propPanelView];
            if([(MMPPanel*)control imagePath])
                [self.propPanelImagePathTextField setStringValue:[(MMPPanel*)control imagePath]];
            else
              [self.propPanelImagePathTextField setStringValue:@""];
            [self.propPanelPassTouchesButton setState:((MMPPanel*)control).shouldPassTouches];
        }
        else if([control isKindOfClass:[MMPMultiSlider class]]){
            [self.propVarView addSubview:self.propMultiSliderView];
            [self.propMultiSliderRangeField setIntegerValue:[(MMPMultiSlider*)control range]];
            [_propMultiSliderOutputModePopButton selectItemAtIndex:((MMPMultiSlider*)control).outputMode];
        }
        else if([control isKindOfClass:[MMPToggle class]]){
            [self.propVarView addSubview:self.propToggleView];
            [self.propToggleThicknessTextField setIntegerValue:[(MMPToggle*)control borderThickness]];
        }
        else if([control isKindOfClass:[MMPMenu class]]){
          [self.propVarView addSubview:self.propMenuView];
          [self.propMenuTitleTextField setStringValue:[(MMPMenu*)control titleString]];
        }
        else if([control isKindOfClass:[MMPTable class]]){
          MMPTable *table = (MMPTable*)control;
          [self.propVarView addSubview:self.propTableView];
          [self.propTableSelectionColorWell setColor:table.selectionColor];
          [self.propTableModePopButton selectItemAtIndex:table.mode];
          [_propTableDisplayModePopButton selectItemAtIndex:table.displayMode];
          [_propTableDisplayRangeLoTextField setStringValue:[NSString stringWithFormat:@"%.3f", table.displayRangeLo]];
          [_propTableDisplayRangeHiTextField setStringValue:[NSString stringWithFormat:@"%.3f", table.displayRangeHi]];
        }
      
        currentSingleSelection=control;
    }
    
    
}

//one control has moved, move all other selected controls
-(void)controlEditMoved:(MMPControl*)control deltaPoint:(CGPoint)deltaPoint{
    for(MMPControl* currControl in [documentModel controlArray]){
      if([currControl isSelected]) {//&& currControl!=control){ //now handling original control as well here.
            [[self undoManager] registerUndoWithTarget:currControl selector:@selector(setFrameOriginObjectUndoable:) object:[NSValue valueWithPoint:currControl.frame.origin]];
          CGFloat x = currControl.frame.origin.x+deltaPoint.x;
          CGFloat y = currControl.frame.origin.y+deltaPoint.y;

          CGPoint newOrigin = CGPointMake(x,y);
          [currControl setFrameOrigin:newOrigin];
          if(currControl == control) {
            [self updateGuide:currControl];
          }
        }
    }
}

-(void)controlEditReleased:(MMPControl*)control withShift:(BOOL)shift hadDrag:(BOOL)hadDrag{
  //I had dragged, so snap stuff if enabled
  if(hadDrag && _snapToGridEnabled) {
    for(MMPControl* currControl in [documentModel controlArray]){
      if([currControl isSelected]) {
        CGFloat x = currControl.frame.origin.x;
        CGFloat y = currControl.frame.origin.y;
        //NSLog(@"pre %.2f %.2f", x,y);
        x = _snapToGridXVal * floor((x/_snapToGridXVal)+0.5);
        y = _snapToGridYVal * floor((y/_snapToGridYVal)+0.5);
        //NSLog(@"post %.2f %.2f", x,y);
        CGPoint newOrigin = CGPointMake(x,y);
        [currControl setFrameOrigin:newOrigin];
      }
    }
  }


  //I clicked a single control and released it (without drag or shift), deselect everything else
  if(!hadDrag && !shift) {
        for(MMPControl* currControl in [documentModel controlArray]){
            if(currControl!=control) [currControl setIsSelected:NO];
        }
    }
}

//deletion via keyboard, delete all selected
-(void)controlEditDelete{
    [self propDelete:nil];
}

//based on which of the 5 tabs are open, turn editing on/off
-(void)tabView:(NSTabView*)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
  if(tabView == _tabView) {
    if([tabView indexOfTabViewItem:tabViewItem]>=3){//lock
        [self setIsEditing:NO];
    }
    else [self setIsEditing:YES];
  } else if (tabView == _labelTabView) {
    BOOL showAndroid = ([tabView indexOfTabViewItem:tabViewItem] == 1);
    for (MMPControl *control in documentModel.controlArray) {
      if ([control isKindOfClass:[MMPLabel class]])
        ((MMPLabel*)control).isShowingAndroidFonts = showAndroid;
    }
  }
}

- (void)updateGuide:(MMPControl*)control {
  if(!control)_controlGuideLabel.hidden = YES;
  else {
    _controlGuideLabel.hidden = NO;
    [_controlGuideLabel setStringValue:[NSString stringWithFormat:@"x:%.2f y:%.2f w:%.2f h:%.2f", control.frame.origin.x, control.frame.origin.y, control.frame.size.width, control.frame.size.height]];
  }
  
}

//================all the NIB GUI element methods...

//just for proper undo/redo
-(void)setPropColorWellColor:(NSColor*)inColor{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropColorWellColor:) object:[self.propColorWell color]];
    [self.propColorWell setColor:inColor];
}

- (IBAction)propColorWellChanged:(NSColorWell*)sender {
    for(MMPControl* control in [documentModel controlArray]){
        if([control isSelected]){
            [[self undoManager] registerUndoWithTarget:control selector:@selector(setColorUndoable:) object:[control color]];
            [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropColorWellColor:) object:[control color]];
            [control setColor:[sender color]];
        }
    }
}

//just for proper undo/redo
-(void)setPropHighlightColorWellColor:(NSColor*)inColor{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropHighlightColorWellColor:) object:[self.propHighlightColorWell color]];
    [self.propHighlightColorWell setColor:inColor];
}

- (IBAction)propHighlightColorWellChanged:(NSColorWell *)sender {
    for(MMPControl* control in [documentModel controlArray]){
        if([control isSelected]){
            [[self undoManager] registerUndoWithTarget:control selector:@selector(setHighlightColorUndoable:) object:[control highlightColor]];
            [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropHighlightColorWellColor:) object:[control highlightColor]];
            [control setHighlightColor:[sender color]];
        }
    }
}

//just for proper undo/redo
-(void)setPropAddressText:(NSString*)inString{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropAddressText:) object:[self.propAddressTextField stringValue]];
    [self.propAddressTextField setStringValue:inString];
}

- (IBAction)propAddressChanged:(NSTextField*)sender {
  if(currentSingleSelection==nil)return;//fix bug on startup that, on canvas click, calls this with no selection.
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropAddressText:) object:[currentSingleSelection address]];
    [[self undoManager] registerUndoWithTarget:currentSingleSelection selector:@selector(setAddressUndoable:) object:[currentSingleSelection address]];
    if(currentSingleSelection)[currentSingleSelection setAddress:[sender stringValue]];
}

//just for proper undo/redo
-(void)setPropSliderOrientationPopButtonNumber:(NSNumber*)inNumber{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropSliderOrientationPopButtonNumber:) object:[NSNumber numberWithInt:[self.propSliderOrientationPopButton indexOfSelectedItem] ]];
    [self.propSliderOrientationPopButton selectItemAtIndex:[inNumber intValue]];
}

- (IBAction)propSliderOrientationChanged:(NSPopUpButton *)sender {
    MMPSlider *currSlider = (MMPSlider*)currentSingleSelection;
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropSliderOrientationPopButtonNumber:) object:[NSNumber numberWithInt:[currSlider isHorizontal]]];
    [[self undoManager] registerUndoWithTarget:currSlider selector:@selector(setIsHorizontalObjectUndoable:) object:[NSNumber numberWithBool:[currSlider isHorizontal]]];
    
    if([self.propSliderOrientationPopButton indexOfSelectedItem]==0)//vertical
        [currSlider setIsHorizontal:NO];
    else [currSlider setIsHorizontal:YES];
}

//just for proper undo/redo
-(void)setPropSliderRange:(NSNumber*)inNumber{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropSliderRange:) object:[NSNumber numberWithInt:[self.propSliderRangeTextField intValue] ]];
    [self.propSliderRangeTextField setIntValue:[inNumber intValue]];
}


- (IBAction)propSliderRangeChanged:(NSTextField *)sender {
    MMPSlider* currSlider = (MMPSlider*)currentSingleSelection;
    [[self undoManager] registerUndoWithTarget:currSlider selector:@selector(setRangeObjectUndoable:) object:[NSNumber numberWithInt:[currSlider range]]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropSliderRange:) object:[NSNumber numberWithInt:[currSlider range] ]];
    
    NSInteger val = [sender integerValue];
    if(val<2)val=2;
    if(val>128)val=128;
    [(MMPSlider*)currentSingleSelection setRange:(int)val];
}

//just for proper undo/redo
-(void)setPropKnobRange:(NSNumber*)inNumber{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropKnobRange:) object:[NSNumber numberWithInt:[self.propKnobRangeTextField intValue] ]];
    [self.propKnobRangeTextField setIntValue:[inNumber intValue]];
}

- (IBAction)propKnobRangeChanged:(NSTextField *)sender {
   MMPKnob* currKnob = (MMPKnob*)currentSingleSelection;
    [[self undoManager] registerUndoWithTarget:currKnob selector:@selector(setRangeObjectUndoable:) object:[NSNumber numberWithInt:[currKnob range]]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropKnobRange:) object:[NSNumber numberWithInt:[currKnob range] ]];
    NSInteger val = [sender integerValue];
    if(val<2)val=2;
    if(val>128)val=128;
    
    [currKnob setRange:(int)val];
}

//just for proper undo/redo
-(void)setPropKnobIndicatorColorWellColor:(NSColor*)inColor{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropKnobIndicatorColorWellColor:) object:[self.propKnobIndicatorColorWell color]];
    [self.propKnobIndicatorColorWell setColor:inColor];
}

- (IBAction)propKnobIndicatorColorWellChanged:(NSColorWell *)sender {
    for(MMPControl* control in [documentModel controlArray]){
        if([control isKindOfClass:[MMPKnob class]] && [control isSelected]){//ness? change to currentsingle selection?
            MMPKnob* currrKnob=(MMPKnob*)control;
            [[self undoManager] registerUndoWithTarget:currrKnob selector:@selector(setIndicatorColorUndoable:) object:[currrKnob indicatorColor]];
            [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropKnobIndicatorColorWellColor:) object:[currrKnob indicatorColor]];
            
            [currrKnob setIndicatorColor:[sender color]];
        }
    }
}

//just for proper undo/redo
-(void)setPropLabelText:(NSString*)inString{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropLabelText:) object:[self.propLabelTextField stringValue]];
    [self.propLabelTextField setStringValue:inString];
}

- (IBAction)propLabelTextChanged:(NSTextField *)sender {
    MMPLabel* currLabel = (MMPLabel*)currentSingleSelection;
    [[self undoManager] registerUndoWithTarget:currLabel selector:@selector(setStringValueUndoable:) object:[currLabel stringValue]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropLabelText:) object:[currLabel stringValue]];
    
    [currLabel setStringValue:[sender stringValue]];
}

//just for proper undo/redo
-(void)setPropMenuTitleText:(NSString*)inString{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropMenuTitleText:) object:[self.propMenuTitleTextField stringValue]];
  [self.propMenuTitleTextField setStringValue:inString];
}

- (IBAction)propMenuTitleTextChanged:(NSTextField *)sender {
  MMPMenu* currMenu = (MMPMenu*)currentSingleSelection;
  [[self undoManager] registerUndoWithTarget:currMenu selector:@selector(setTitleStringUndoable:) object:[currMenu titleString ]];
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropMenuTitleText:) object:[currMenu titleString]];
  
  [currMenu setTitleString:[sender stringValue]];
}

//just for proper undo/redo
-(void)setPropTableSelectionColorWellColor:(NSColor*)inColor{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableSelectionColorWellColor:) object:[self.propTableSelectionColorWell color]];
  [self.propTableSelectionColorWell setColor:inColor];
}

- (IBAction)propTableSelectionColorWellChanged:(NSColorWell *)sender {
  
      MMPTable* currrTable=(MMPTable*)currentSingleSelection;
      [[self undoManager] registerUndoWithTarget:currrTable selector:@selector(setSelectionColorUndoable:) object:[currrTable selectionColor]];
      [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableSelectionColorWellColor:) object:[currrTable selectionColor]];
      
      [currrTable setSelectionColor:[sender color]];
  

}

//just for proper undo/redo
-(void)setPropTableModePopButtonNumber:(NSNumber*)inNumber{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableModePopButtonNumber:) object:[NSNumber numberWithInt:(int)[self.propTableModePopButton indexOfSelectedItem] ]];
  [self.propTableModePopButton selectItemAtIndex:[inNumber intValue]];
}

- (IBAction)propTableModeChanged:(NSPopUpButton *)sender {
  MMPTable *currTable = (MMPTable*)currentSingleSelection;
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableModePopButtonNumber:) object:[NSNumber numberWithInt:[currTable mode]]];
  [[self undoManager] registerUndoWithTarget:currTable selector:@selector(setModeObjectUndoable:) object:[NSNumber numberWithInt:[currTable mode]]];
  
  [currTable setMode:(int)[self.propTableModePopButton indexOfSelectedItem] ];
}

//just for proper undo/redo
-(void)setPropTableDisplayMode:(NSNumber*)inNumber{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableDisplayMode:) object:[NSNumber numberWithInteger:[_propTableDisplayModePopButton indexOfSelectedItem] ]];
  [_propTableDisplayModePopButton selectItemAtIndex:[inNumber intValue]];
}

- (IBAction)propTableDisplayModeChanged:(NSPopUpButton *)sender {
  MMPTable *currTable = (MMPTable*)currentSingleSelection;
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableDisplayMode:) object:[NSNumber numberWithInteger:currTable.displayMode]];
  [[self undoManager] registerUndoWithTarget:currTable selector:@selector(setDisplayModeUndoable:) object:[NSNumber numberWithInteger:currTable.displayMode]];

  [currTable setDisplayMode:[_propTableDisplayModePopButton indexOfSelectedItem] ];
}

//

-(void)setPropTableDisplayRangeLo:(NSNumber*)inNumber{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableDisplayRangeLo:) object:[NSNumber numberWithFloat:[_propTableDisplayRangeLoTextField floatValue] ]];
  [_propTableDisplayRangeLoTextField setFloatValue:[inNumber floatValue]];
}

- (IBAction)propTableDisplayRangeLoChanged:(NSTextField *)sender {
  MMPTable *currTable = (MMPTable*)currentSingleSelection;
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableDisplayRangeLo:) object:[NSNumber numberWithFloat:currTable.displayRangeLo]];
  [[self undoManager] registerUndoWithTarget:currTable selector:@selector(setDisplayRangeLoObjectUndoable:) object:[NSNumber numberWithFloat:currTable.displayRangeLo]];

  [currTable setDisplayRangeLo:[_propTableDisplayRangeLoTextField floatValue] ];
}

-(void)setPropTableDisplayRangeHi:(NSNumber*)inNumber{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableDisplayRangeHi:) object:[NSNumber numberWithFloat:[_propTableDisplayRangeHiTextField floatValue] ]];
  [_propTableDisplayRangeHiTextField setFloatValue:[inNumber floatValue]];
}

- (IBAction)propTableDisplayRangeHiChanged:(NSTextField *)sender {
  MMPTable *currTable = (MMPTable*)currentSingleSelection;
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropTableDisplayRangeHi:) object:[NSNumber numberWithFloat:currTable.displayRangeHi]];
  [[self undoManager] registerUndoWithTarget:currTable selector:@selector(setDisplayRangeHiObjectUndoable:) object:[NSNumber numberWithFloat:currTable.displayRangeHi]];

  [currTable setDisplayRangeHi:[_propTableDisplayRangeHiTextField floatValue] ];
}

//just for proper undo/redo
-(void)setPropGridModePopButtonNumber:(NSNumber*)inNumber{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridModePopButtonNumber:) object:[NSNumber numberWithInt:(int)[self.propGridModePopButton indexOfSelectedItem] ]];
  [self.propGridModePopButton selectItemAtIndex:[inNumber intValue]];
}

- (IBAction)propGridModeChanged:(NSPopUpButton *)sender {
  MMPGrid *currGrid = (MMPGrid*)currentSingleSelection;
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridModePopButtonNumber:) object:[NSNumber numberWithInt:[currGrid mode]]];
  [[self undoManager] registerUndoWithTarget:currGrid selector:@selector(setModeObjectUndoable:) object:[NSNumber numberWithInt:[currGrid mode]]];
  
  [currGrid setMode:(int)[self.propGridModePopButton indexOfSelectedItem] ];
}



//just for proper undo/redo
-(void)setPropLabelTextSize:(NSNumber*)inNum{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropLabelTextSize:) object:[NSNumber numberWithInt:[self.propLabelSizeTextField intValue]]];
    [self.propLabelSizeTextField setIntValue:[inNum intValue]];
}

- (IBAction)propLabelTextSizeChanged:(NSTextField *)sender {
    MMPLabel* currLabel = (MMPLabel*)currentSingleSelection;
    [[self undoManager] registerUndoWithTarget:currLabel selector:@selector(setTextSizeUndoable:) object:[NSNumber numberWithInt:[currLabel textSize]]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropLabelTextSize:) object:[NSNumber numberWithInt:[currLabel textSize]]];
    [(MMPLabel*)currentSingleSelection setTextSize:[sender intValue]];
}

//just for proper undo/redo
-(void)setPropLabelFont:(NSNumber*)inNum{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropLabelTextSize:) object:[NSNumber numberWithInt:[self.propLabelSizeTextField intValue]]];
    [self.propLabelSizeTextField setIntValue:[inNum intValue]];
}

- (IBAction)propLabelFontChanged:(NSPopUpButton *)sender {
    NSArray* fontArray=[(MMPDocumentController*)[NSDocumentController sharedDocumentController] fontArray];
    
    NSDictionary* currFamilyDict = [fontArray objectAtIndex:[sender indexOfSelectedItem]];
    [self.propLabelFontType removeAllItems];
    for (NSString* fontName in [currFamilyDict objectForKey:@"types"]){
        [self.propLabelFontType addItemWithTitle:fontName];
    }
    
    //set
    if ([[currFamilyDict objectForKey:@"family"] isEqualToString:@"Default"]){
        [(MMPLabel*) currentSingleSelection setFontFamily:@"Default" fontName:@"Default" ];
    }
    
    else{
        NSString* firstFontName = [[currFamilyDict objectForKey:@"types"] objectAtIndex:0];
        if([NSFont fontWithName:firstFontName size:12]){
            [(MMPLabel*) currentSingleSelection setFontFamily:[currFamilyDict objectForKey:@"family"] fontName:firstFontName ];
        }
        else{
            //can't make the font...
        }
    }
}

-(void)populateFont{
     NSArray* fontArray=[(MMPDocumentController*)[NSDocumentController sharedDocumentController] fontArray];
    NSDictionary* currFamilyDict = [fontArray objectAtIndex:[self.propLabelFontPopButton  indexOfSelectedItem]];
    [self.propLabelFontType removeAllItems];
    for (NSString* fontName in [currFamilyDict objectForKey:@"types"]){
        [self.propLabelFontType addItemWithTitle:fontName];
    }
}

- (IBAction)propLabelFontTypeChanged:(NSPopUpButton *)sender {
    NSString* newFontName = [[sender selectedItem] title];
    if([NSFont fontWithName:newFontName size:12]){
        [(MMPLabel*) currentSingleSelection setFontFamily:[[self.propLabelFontPopButton selectedItem] title] fontName:newFontName ];
    }
    else{
        //can't make the font...
    }
}

- (IBAction)propLabelAndroidFontTypeChanged:(NSPopUpButton *)sender {
  NSString* newFontName = [[sender selectedItem] title];
  if([NSFont fontWithName:newFontName size:12]){
    [(MMPLabel*) currentSingleSelection setAndroidFontName:newFontName ];
  }
  else{
    //can't make the font...
  }
}

//just for proper undo/redo
-(void)setPropToggleThickness:(NSNumber*)inNum{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropToggleThickness:) object:[NSNumber numberWithInt:[self.propToggleThicknessTextField intValue]]];
    [self.propToggleThicknessTextField setIntValue:[inNum intValue]];
}

- (IBAction)propToggleThicknessChanged:(NSTextField *)sender {
    MMPToggle* currToggle = (MMPToggle*)currentSingleSelection;
    
    [[self undoManager] registerUndoWithTarget:currToggle selector:@selector(setBorderThicknessUndoable:) object:[NSNumber numberWithInt:[currToggle borderThickness]]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropToggleThickness:) object:[NSNumber numberWithInt:[currToggle borderThickness]]];
    
    NSInteger val = [sender integerValue];
    if(val<1)val=1;
    if(val>1000)val=1000;
    [currToggle setBorderThickness:(int)val];
}

//just for proper undo/redo
-(void)setPropGridDimX:(NSNumber*)inNum{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridDimX:) object:[NSNumber numberWithInt:[self.propGridDimXField intValue]]];
    [self.propGridDimXField setIntValue:[inNum intValue]];
}

- (IBAction)propGridDimXChanged:(NSTextField *)sender {
    MMPGrid* currGrid = (MMPGrid*)currentSingleSelection;
    
    [[self undoManager] registerUndoWithTarget:currGrid selector:@selector(setDimXUndoable:) object:[NSNumber numberWithInt:[currGrid dimX]]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridDimX:) object:[NSNumber numberWithInt:[currGrid dimX]]];
    
    [currGrid setDimX:[sender intValue]];
}

//just for proper undo/redo
-(void)setPropGridDimY:(NSNumber*)inNum{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridDimY:) object:[NSNumber numberWithInt:[self.propGridDimYField intValue]]];
    [self.propGridDimYField setIntValue:[inNum intValue]];
}

- (IBAction)propGridDimYChanged:(NSTextField *)sender {
    MMPGrid* currGrid = (MMPGrid*)currentSingleSelection;
    
    [[self undoManager] registerUndoWithTarget:currGrid selector:@selector(setDimYUndoable:) object:[NSNumber numberWithInt:[currGrid dimY]]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridDimY:) object:[NSNumber numberWithInt:[currGrid dimY]]];
    
    [currGrid setDimY:[sender intValue]];
}

//just for proper undo/redo
-(void)setPropGridBorderThickness:(NSNumber*)inNum{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridBorderThickness:) object:[NSNumber numberWithInt:[self.propGridBorderThicknessField intValue]]];
    [self.propGridBorderThicknessField setIntValue:[inNum intValue]];
}

- (IBAction)propGridBorderThicknessChanged:(NSTextField *)sender {
    MMPGrid* currGrid = (MMPGrid*)currentSingleSelection;
    
    [[self undoManager] registerUndoWithTarget:currGrid selector:@selector(setBorderThicknessUndoable:) object:[NSNumber numberWithInt:[currGrid borderThickness]]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridBorderThickness:) object:[NSNumber numberWithInt:[currGrid borderThickness]]];
    
    [currGrid setBorderThickness:[sender intValue]];
}

//just for proper undo/redo
-(void)setPropGridCellPadding:(NSNumber*)inNum{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridCellPadding:) object:[NSNumber numberWithInt:[self.propGridPaddingField intValue]]];
    [self.propGridPaddingField setIntValue:[inNum intValue]];
}

- (IBAction)propGridCellPaddingChanged:(NSTextField *)sender {
    MMPGrid* currGrid = (MMPGrid*)currentSingleSelection;
    
    [[self undoManager] registerUndoWithTarget:currGrid selector:@selector(setCellPaddingUndoable:) object:[NSNumber numberWithInt:[currGrid cellPadding]]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropGridCellPadding:) object:[NSNumber numberWithInt:[currGrid cellPadding]]];

    
    [(MMPGrid*)currentSingleSelection setCellPadding:[sender intValue]];
}

//TODO: couldn't get undo properly working for this...
- (IBAction)propPanelChooseImage:(NSButton *)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setAllowsMultipleSelection:NO];
    
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton ){
        // Get an array containing the full filenames of all
        // files and directories selected.
        NSArray* files = [openDlg filenames];
        
        // Loop through all the files and process them.
        for( int i = 0; i < [files count]; i++ ){
            NSString* fileName = [files objectAtIndex:i];
            //printf("\nfile %s", [fileName cString]);
            [(MMPPanel*)currentSingleSelection setImagePath:fileName];
            [(MMPPanel*)currentSingleSelection loadImage];
            [self.propPanelImagePathTextField setStringValue:fileName];
        }
    }
}

- (IBAction)propPanelImagePathTextChanged:(NSTextField *)sender {
    NSString* filename = [sender stringValue];
    [(MMPPanel*)currentSingleSelection setImagePath:filename];
    [(MMPPanel*)currentSingleSelection loadImage];
}

//just for undo/red0
-(void)setPropPanelPassTouchesChanged:(NSNumber*)inNum{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropPanelPassTouchesChanged:) object:[NSNumber numberWithBool:(self.propPanelPassTouchesButton.state>0)]];
  self.propPanelPassTouchesButton.state = [inNum boolValue] ? 1 : 0;
  
}

- (IBAction)propPanelPassTouchesChanged:(id)sender{//send can be number.bool or nsbutton
  MMPPanel* currPanel = (MMPPanel*)currentSingleSelection;
  
  [[self undoManager] registerUndoWithTarget:currPanel selector:@selector(setShouldPassTouchesUndoable:) object:[NSNumber numberWithBool:[currPanel shouldPassTouches]]];
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropPanelPassTouchesChanged:) object:[NSNumber numberWithBool:[currPanel shouldPassTouches]]];
  BOOL toSet;
  if([sender isKindOfClass:[NSButton class]]) toSet = [(NSButton*)sender state];
  else toSet = [(NSNumber*)sender boolValue];//nsnumber from redo
  currPanel.shouldPassTouches = toSet;
}

//just for proper undo/redo
-(void)setPropMultiSliderRange:(NSNumber*)inNum{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropMultiSliderRange:) object:[NSNumber numberWithInt:[self.propMultiSliderRangeField intValue]]];
    [self.propMultiSliderRangeField setIntValue:[inNum intValue]];
}

- (IBAction)propMultiSliderRangeChanged:(NSTextField *)sender {
    MMPMultiSlider* currMultiSlider = (MMPMultiSlider*)currentSingleSelection;
    
    [[self undoManager] registerUndoWithTarget:currMultiSlider selector:@selector(setRangeUndoable:) object:[NSNumber numberWithInt:[currMultiSlider range]]];
    [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropMultiSliderRange:) object:[NSNumber numberWithInt:[currMultiSlider range]]];
    
    NSInteger val = [sender integerValue];
    if(val<1)val=1;
    if(val>128)val=128;
    [currMultiSlider setRange:(int)val];
}

//just for proper undo/redo
-(void)setPropMultiSlideroutputMode:(NSNumber*)inNum{
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropMultiSliderOutputMode:) object:[NSNumber numberWithInteger:[_propMultiSliderOutputModePopButton indexOfSelectedItem]]];
  [_propMultiSliderOutputModePopButton selectItemAtIndex:[inNum intValue]];
}

- (IBAction)propMultiSliderOutputModeChanged:(NSPopUpButton *)sender {
  MMPMultiSlider* currMultiSlider = (MMPMultiSlider*)currentSingleSelection;

  [[self undoManager] registerUndoWithTarget:currMultiSlider selector:@selector(setOutputModeUndoable:) object:[NSNumber numberWithInteger:currMultiSlider.outputMode]];
  [[self undoManager] registerUndoWithTarget:self selector:@selector(setPropMultiSliderOutputMode:) object:[NSNumber numberWithInteger:currMultiSlider.outputMode]];

  [currMultiSlider setOutputMode:[sender indexOfSelectedItem]];
}

- (IBAction)lockClearButtonHit:(NSButton *)sender {
    [textLineArray removeAllObjects];
    [self.lockTextView setString:@""];
}

- (IBAction)lockTiltXSliderChanged:(NSSlider *)sender {
    [self sendTilts];
}

- (IBAction)lockTiltYSliderChanged:(NSSlider *)sender {
    [self sendTilts];
}

- (IBAction)lockShakeButtonHit:(NSButton *)sender {
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:@"/system/shake"];
    [formattedMessageArray addObject:[NSNumber numberWithInt:1]];
    [self sendFormattedMessageArray:formattedMessageArray];
}

- (IBAction)pageDownHit:(NSButton *)sender {
    if(currentPageIndex>0)[self setCurrentPage:currentPageIndex-1];
}

- (IBAction)pageUpHit:(NSButton *)sender {
    if(currentPageIndex<[documentModel pageCount]-1)[self setCurrentPage:currentPageIndex+1];
}

#pragma mark - Watch Editor
/* wear
- (IBAction)watchPageCountChanged:(NSPopUpButton *)sender {
  NSUInteger oldPageCount = [documentModel watchPageCount];
  NSUInteger newPageCount = [sender indexOfSelectedItem ];
  //printf("\npre count %d, intended page ount %d",oldPageCount , newPageCount);

  if(newPageCount>oldPageCount) {//add new pages
    // add new control duple for each new page
    for (NSUInteger i=oldPageCount;i<newPageCount;i++) {
      NSString *title = @"page title goes here";
      NSTextView *titleTextView = [[NSTextView alloc] init];
      titleTextView.frame = CGRectMake(i*140, 5, 140,30);
      titleTextView.alignment = NSCenterTextAlignment;
      titleTextView.textColor = _watchWidgetColorWell.color;
      titleTextView.backgroundColor = [NSColor clearColor];
      [titleTextView setString:title];
      [titleTextView setFont:[NSFont fontWithName:@"Roboto-Regular" size:12]];
      // default is grid
      // default frame on canvas - mimic layout in watch (margin 10, title height 60), divided by 2
      CGRect newFrame = CGRectMake(i * 140 + 5, 35, 130, 100);
      MMPGrid* grid = [[MMPGrid alloc] initWithFrame:newFrame];
      grid.color = _watchWidgetColorWell.color;
      grid.highlightColor = _watchWidgetHighlightColorWell.color;
      grid.dimX = 2;
      grid.dimY = 2;
      grid.borderThickness = 2;
      grid.cellPadding = 2;
      grid.editingDelegate = self;
      grid.address = @"/myWatchGrid";

      [documentModel.watchControlDupleArray addObject:
           [NSMutableArray arrayWithObjects: titleTextView, grid, nil]];
      [_watchCanvasView addSubview:titleTextView];
      [_watchCanvasView addSubview:grid];
    }
    //increment watch page count
      documentModel.watchPageCount = newPageCount;
    // if showing initial nothingness and added pages, refresh
    if (oldPageCount==0) [self refreshWatchEditorElements];
  }

  else if (newPageCount<oldPageCount){//subtract old pages

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Delete page(s)?"];
    [alert setAlertStyle:NSWarningAlertStyle];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
      documentModel.watchPageCount = newPageCount;
      //do we have to change current page?
      if(currentWatchPageIndex >= newPageCount) {
        [self setCurrentWatchPage:newPageCount-1];
        [self refreshWatchEditorElements];
      }
      [self pruneWatchControls];
    }
    else{//user hit cancel button
      //[self.docPageCountField setIntValue:oldPageCount];
    }


  }
  //printf("\ndoc page array size %d", [documentModel pageCount]);
  [_watchCanvasView setPageCount:documentModel.watchPageCount];
  [_watchPageIndexLabel setStringValue:[NSString stringWithFormat:@"Page %d/%d", currentWatchPageIndex+1, [documentModel watchPageCount]]];
}

- (IBAction)watchPageUpHit:(NSButton *)sender {
  if(currentWatchPageIndex<documentModel.watchPageCount-1) {
    [documentWindow makeFirstResponder:_watchCanvasView]; //make gui edit elements lose focus, triggereing edit change
    [self setCurrentWatchPage:currentWatchPageIndex+1];
    [self refreshWatchEditorElements];
  }
}

- (IBAction)watchPageDownHit:(NSButton *)sender {
  if(currentWatchPageIndex>0) {
    [documentWindow makeFirstResponder:_watchCanvasView]; //make gui edit elements lose focus, triggering edit change
    [self setCurrentWatchPage:currentWatchPageIndex-1];
    [self refreshWatchEditorElements];
  }
}

- (void)refreshWatchEditorElements {
  if (documentModel.watchControlDupleArray.count == 0)return;

  NSArray *currentWatchControlTuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  NSTextView *currentTextView = ((NSTextView *)currentWatchControlTuple[0]);
  MMPControl *currentControl = ((MMPControl *)currentWatchControlTuple[1]);
  _watchWidgetAddressField.stringValue = currentControl.address;
  _watchWidgetTitleField.stringValue = currentTextView.string;
  _watchWidgetColorWell.color = currentControl.color;
  _watchWidgetHighlightColorWell.color = currentControl.highlightColor;

  [_watchPropVarView setSubviews:[NSArray array]];
  //watch propvarview
  if ([currentControl isKindOfClass:[MMPGrid class]]) {
    [_watchWidgetTypePopButton selectItemAtIndex:0];//make constant
    [_watchPropVarView addSubview:_watchPropGridView];
    MMPGrid *currGrid = (MMPGrid *)currentControl;
    [_watchPropGridDimXField setStringValue:[NSString stringWithFormat:@"%d", currGrid.dimX]];
    [_watchPropGridDimYField setStringValue:[NSString stringWithFormat:@"%d", currGrid.dimY]];
    [_watchPropGridBorderThicknessField setStringValue:
         [NSString stringWithFormat:@"%d", currGrid.borderThickness]];
     [_watchPropGridPaddingField setStringValue:
          [NSString stringWithFormat:@"%d", currGrid.cellPadding]];
     [self.propGridModePopButton selectItemAtIndex:currGrid.mode];
  } else if ([currentControl isKindOfClass:[MMPMultiSlider class]]) {
    [_watchWidgetTypePopButton selectItemAtIndex:1];//make constant
    [_watchPropVarView addSubview:_watchPropMultiSliderView];
    [_watchPropMultiSliderRangeField setIntegerValue:[(MMPMultiSlider*)currentControl range]];
    [_watchPropMultiSliderOutputModePopButton selectItemAtIndex:((MMPMultiSlider*)currentControl).outputMode];
  } else if ([currentControl isKindOfClass:[MMPXYSlider class]]) {
    [_watchWidgetTypePopButton selectItemAtIndex:2];//make constant
  } else if ([currentControl isKindOfClass:[MMPLabel class]]) {
    [_watchWidgetTypePopButton selectItemAtIndex:3];//make constant
    [_watchPropVarView addSubview:_watchPropLabelView];
    [_watchPropLabelTextField setStringValue:[(MMPLabel*)currentControl stringValue ]];
    [_watchPropLabelSizeTextField setStringValue:[NSString stringWithFormat:@"%d", [(MMPLabel*)currentControl textSize ]]];
  }
}

//just for proper undo/redo
-(void)setWatchWidgetColorWellColor:(NSColor*)inColor{
  [[self undoManager] registerUndoWithTarget:self
                                    selector:@selector(setWatchWidgetColorWellColor:)
                                      object:_watchWidgetColorWell.color];
  _watchWidgetColorWell.color = inColor;
}

- (IBAction)watchWidgetColorWellChanged:(NSColorWell *)sender {
  NSArray *currentWatchControlTuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  MMPControl *currControl = currentWatchControlTuple[1];
  NSTextView *currTextView = currentWatchControlTuple[0];

  [[self undoManager] registerUndoWithTarget:currControl
                                    selector:@selector(setColorUndoable:)
                                      object:currControl.color];
  [[self undoManager] registerUndoWithTarget:self
                                    selector:@selector(setWatchWidgetColorWellColor:)
                                      object:currControl.color];
  [[self undoManager] registerUndoWithTarget:currTextView
                                    selector:@selector(setTextColor:)
                                      object:currControl.color];
  NSColor *color = sender.color;
  currTextView.textColor = color;
  currControl.color = color;
}

//just for proper undo/redo
-(void)setWatchWidgetHighlightColorWellColor:(NSColor*)inColor{
  [[self undoManager] registerUndoWithTarget:self
                                    selector:@selector(setWatchWidgetHighlightColorWellColor:)
                                      object:_watchWidgetHighlightColorWell.color];
  _watchWidgetHighlightColorWell.color = inColor;
}

- (IBAction)watchWidgetHighlightColorWellChanged:(NSColorWell *)sender {
  NSArray *currentWatchControlTuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  MMPControl *currControl = currentWatchControlTuple[1];

  [[self undoManager] registerUndoWithTarget:currControl
                                    selector:@selector(setHighlightColorUndoable:)
                                      object:currControl.highlightColor];
  [[self undoManager] registerUndoWithTarget:self
                                    selector:@selector(setWatchWidgetHighlightColorWellColor:)
                                      object:currControl.highlightColor];
  NSColor *color = sender.color;
  currControl.highlightColor = color;
}

//just for proper undo/redo
-(void)setWatchWidgetAddress:(NSString*)inString{
  [[self undoManager] registerUndoWithTarget:self
                                    selector:@selector(setWatchWidgetAddress:)
                                      object:_watchWidgetAddressField.stringValue];
  _watchWidgetAddressField.stringValue = inString;
}

- (IBAction)watchWidgetAddressChanged:(NSTextField *)sender {
  // On initial state, index = 0 but array = 0, so return;
  if (currentWatchPageIndex>=documentModel.watchControlDupleArray.count) return;

  NSArray *currentWatchControlTuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  MMPControl *currControl = currentWatchControlTuple[1];

  [[self undoManager] registerUndoWithTarget:currControl
                                    selector:@selector(setAddressUndoable:)
                                      object:currControl.address];
  [[self undoManager] registerUndoWithTarget:self
                                    selector:@selector(setWatchWidgetAddress:)
                                      object:currControl.address];

  currControl.address = sender.stringValue;
}

//just for proper undo/redo
-(void)setWatchWidgetTitle:(NSString*)inString{
  [[self undoManager] registerUndoWithTarget:self
                                    selector:@selector(setWatchWidgetTitle:)
                                      object:_watchWidgetTitleField.stringValue];
  _watchWidgetTitleField.stringValue = inString;
}

- (IBAction)watchWidgetTitleChanged:(NSTextField *)sender {
  NSArray *currentWatchControlTuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  NSTextView *currTextView = currentWatchControlTuple[0];

  [[self undoManager] registerUndoWithTarget:currTextView
                                    selector:@selector(setString:)
                                      object:currTextView.string];
  [[self undoManager] registerUndoWithTarget:self
                                    selector:@selector(setWatchWidgetTitle:)
                                      object:currTextView.string];

  currTextView.string = sender.stringValue;
}

// not undoable
- (IBAction)watchWidgetTypeChanged:(NSPopUpButton *)sender {

  [documentWindow makeFirstResponder:_watchCanvasView]; //make gui edit elements lose focus, triggering edit change

  NSUInteger popIndex = [_watchWidgetTypePopButton indexOfSelectedItem];
  //fill in property tab fields (address, class-specific, etc)
  //[_watchWidgetAddressField setEnabled:YES]; //necc??
  //[_watchWidgetAddressField setStringValue:[control address]];

  // for replacemnt
  NSMutableArray *currentWatchControlDuple =
      documentModel.watchControlDupleArray[currentWatchPageIndex];
  CGRect newFrame = CGRectMake(currentWatchPageIndex * 140 + 5, 35, 130, 100);

  // show default values
 if(popIndex == 0){ //Grid
   [currentWatchControlDuple[1] removeFromSuperview];

   MMPGrid* grid = [[MMPGrid alloc] initWithFrame:newFrame];
   grid.color = _watchWidgetColorWell.color;
   grid.highlightColor = _watchWidgetHighlightColorWell.color;
   grid.dimX = 2;
   grid.dimY = 2;
   grid.borderThickness = 2;
   grid.cellPadding = 2;
   grid.address = @"/myWatchGrid";
   grid.editingDelegate = self;
   currentWatchControlDuple[1] = grid;
   [_watchCanvasView addSubview:grid];

   [self refreshWatchEditorElements];
  }
  else if(popIndex == 1){ //MultiSlider
    [currentWatchControlDuple[1] removeFromSuperview];

    MMPMultiSlider* multiSlider = [[MMPMultiSlider alloc] initWithFrame:newFrame];
    multiSlider.color = _watchWidgetColorWell.color;
    multiSlider.highlightColor = _watchWidgetHighlightColorWell.color;
    multiSlider.range = 8;
    multiSlider.address = @"/myWatchMultiSlider";
    multiSlider.editingDelegate = self;
    currentWatchControlDuple[1] = multiSlider;
    [_watchCanvasView addSubview:multiSlider];

    [self refreshWatchEditorElements];
  }
  else if(popIndex == 2){ //XY
    [currentWatchControlDuple[1] removeFromSuperview];

    MMPXYSlider* xySlider = [[MMPXYSlider alloc] initWithFrame:newFrame];
    xySlider.color = _watchWidgetColorWell.color;
    xySlider.highlightColor = _watchWidgetHighlightColorWell.color;
    xySlider.address = @"/myWatchXYSlider";
    xySlider.editingDelegate = self;
    currentWatchControlDuple[1] = xySlider;
    [_watchCanvasView addSubview:xySlider];

    [self refreshWatchEditorElements];
  }
  else if(popIndex == 3){ //Label
    [currentWatchControlDuple[1] removeFromSuperview];

    MMPLabel* label = [[MMPLabel alloc] initWithFrame:newFrame];
    label.color = _watchWidgetColorWell.color;
    label.highlightColor = _watchWidgetHighlightColorWell.color;
    label.address = @"/myWatchLabel";
    label.editingDelegate = self;
    currentWatchControlDuple[1] = label;
    [_watchCanvasView addSubview:label];

    [self refreshWatchEditorElements];
  }
}

// TODO MORE UNDO!!!
- (IBAction)watchPropLabelTextChanged:(NSTextField *)sender {
  NSArray *currentWatchControlDuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  ((MMPLabel *)currentWatchControlDuple[1]).stringValue = [sender stringValue];
}

- (IBAction)watchPropLabelTextSizeChanged:(NSTextField *)sender {
  NSArray *currentWatchControlDuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  ((MMPLabel *)currentWatchControlDuple[1]).textSize= [sender intValue];
}

- (IBAction)watchPropGridDimXChanged:(NSTextField *)sender {
  NSArray *currentWatchControlDuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  ((MMPGrid *)currentWatchControlDuple[1]).dimX= [sender intValue];
}

- (IBAction)watchPropGridDimYChanged:(NSTextField *)sender {
  NSArray *currentWatchControlDuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  ((MMPGrid *)currentWatchControlDuple[1]).dimY= [sender intValue];
}

- (IBAction)watchPropGridBorderThicknessChanged:(NSTextField *)sender {
  NSArray *currentWatchControlDuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  ((MMPGrid *)currentWatchControlDuple[1]).borderThickness= [sender intValue];
}

- (IBAction)watchPropGridCellPaddingChanged:(NSTextField *)sender {
  NSArray *currentWatchControlDuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  ((MMPGrid *)currentWatchControlDuple[1]).cellPadding= [sender intValue];
}

- (IBAction)watchPropGridModeChanged:(NSPopUpButton *)sender {
  NSArray *currentWatchControlDuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  ((MMPGrid *)currentWatchControlDuple[1]).mode= [sender intValue];
}

- (IBAction)watchPropMultiSliderRangeChanged:(NSTextField *)sender {
  NSArray *currentWatchControlDuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  ((MMPMultiSlider *)currentWatchControlDuple[1]).range= [sender intValue];
}

- (IBAction)watchPropMultiSliderOutputModeChanged:(NSPopUpButton *)sender {
  NSArray *currentWatchControlDuple = documentModel.watchControlDupleArray[currentWatchPageIndex];
  ((MMPMultiSlider *)currentWatchControlDuple[1]).outputMode = [sender indexOfSelectedItem];
}

// watch action methods
-(void)setCurrentWatchPage:(int)newIndex{
  currentWatchPageIndex = newIndex;
  [ _watchCanvasView setPageViewIndex:currentWatchPageIndex];
  self.watchPageIndexLabel.stringValue = [NSString stringWithFormat:@"Page %d/%d", currentWatchPageIndex+1, documentModel.watchPageCount];
} */

//====end of list of Nib's IBAction methods


//add something to console
-(void)log:(NSString*)logLine{
    [textLineArray addObject:logLine];
    if([textLineArray count]>LOGLINES)
        [textLineArray removeObjectAtIndex:0];
    
    [self.lockTextView setString:@""];

    for(NSString* subString in textLineArray){
        if(subString!=[textLineArray objectAtIndex:0])[[[self.lockTextView textStorage] mutableString] appendString: @"\n"];//ugly hack: after first substring, put \n 
        [[[self.lockTextView textStorage] mutableString] appendString: subString];
    }
    
    //
    NSTextContainer* textContainer = [self.lockTextView textContainer];
    NSLayoutManager* layoutManager = [self.lockTextView layoutManager];
    [layoutManager ensureLayoutForTextContainer: textContainer];
    float intrinsicHeight = [layoutManager usedRectForTextContainer: textContainer].size.height;
    
    NSScrollView* scrollView = self.lockTextScrollView;
    
    if(intrinsicHeight>scrollView.contentSize.height)
        [scrollView.contentView scrollToPoint:NSMakePoint(0, intrinsicHeight - scrollView.contentSize.height)];
}

-(NSColor*)patchBackgroundColor {
  return canvasView.bgColor;
}
-(NSView*)canvasOuterView{
  return canvasOuterView;
}

- (void)sendFormattedMessageArray:(NSArray*)messageArray {
 
  [(MMPDocumentController*)[NSDocumentController sharedDocumentController] sendOSCMessageFromArray:messageArray];
  
  NSMutableString* theString = [[NSMutableString alloc]init];
  [theString appendString:@"[out]"];
  for(NSObject* obj in messageArray){
    [theString appendString:@" "];
    if([obj isKindOfClass:[NSString class]]) {
      [theString appendString:(NSString*)obj];
    } else if ([obj isKindOfClass:[NSNumber class]]) {
      NSNumber* num = (NSNumber*)obj;
      if([MMPDocumentController numberIsFloat:num]){
        [theString appendString:[NSString stringWithFormat:@"%.3f ", [num floatValue]]];
      } else {
        [theString appendString:[NSString stringWithFormat:@"%d ", [num intValue]]];
      }
    }
  }
  
  [self log:theString];
  
}

-(void)receiveOSCHelper:(NSMutableArray*)msgArray{
    // Messages I respond to:
    if([msgArray count]==2 && [[msgArray objectAtIndex:0] isEqualToString:@"/system/setPage"] && [[msgArray objectAtIndex:1] isKindOfClass:[NSNumber class]]){
      int page = [[msgArray objectAtIndex:1] intValue];
      if(page<0)page=0; if (page>documentModel.pageCount-1)page=documentModel.pageCount-1;
      [self setCurrentPage:page];
    }
    else if([msgArray count]>2 && [[msgArray objectAtIndex:0] isEqualToString:@"/system/tableResponse"] && [[msgArray objectAtIndex:1] isKindOfClass:[NSString class]]){
      
        NSString *address =[msgArray objectAtIndex:1];
      for(MMPControl* currControl in [documentModel controlArray]){//TODO HASH TABLE!!! and/or table of MMPTables!
        if([currControl isKindOfClass:[MMPTable class]] && [currControl.address isEqualToString:address]){
          [currControl receiveList: [msgArray subarrayWithRange:NSMakeRange(2, [msgArray count]-2)]];
        }
      }
      
    }
  
    else {
      //otherwise SEND TO OBJECT!!!
      for(MMPControl* currControl in [documentModel controlArray]){//TODO HASH TABLE!!!
        if([currControl.address isEqualToString:[msgArray objectAtIndex:0]]) {
              [currControl receiveList: [msgArray subarrayWithRange:NSMakeRange(1, [msgArray count]-1)]];
        }
      }
      // Watch!
      /* wearfor(NSArray* currControlDuple in [documentModel watchControlDupleArray]){//TODO HASH TABLE!!!
        MMPControl *currControl = currControlDuple[1];
        if([currControl.address isEqualToString:[msgArray objectAtIndex:0]]) {
          [currControl receiveList: [msgArray subarrayWithRange:NSMakeRange(1, [msgArray count]-1)]];
        }
      }*/
    }
}

//-(void)receiveOSCArray:(NSMutableArray*)msgArray asString:(NSString *)string{//from OSC thread!
-(void)receivedOSCMessage:(OSCMessage *)m { //from OSC thread
  
  NSString *address = [m address];
	
  NSMutableArray* msgArray = [[NSMutableArray alloc]init];//create blank message array for sending to pd
  NSMutableArray* tempOSCValueArray = [[NSMutableArray alloc]init];
  NSMutableString *string = [[NSMutableString alloc] init];
  //VV library handles receiving a value confusingly: if just one value, it has a single value in message "m" and no valueArray, if more than one value, it has valuearray. here we just shove either into a temp array to iterate over
  
  if([m valueCount]==1)[tempOSCValueArray addObject:[m value]];
  else for(OSCValue *val in [m valueArray])[tempOSCValueArray addObject:val];
  
  //first element in msgArray is address
  [msgArray addObject:address];
  [string appendString:@"[in] "];
  [string appendString:address];
  
  //then iterate over all values
  for(OSCValue *val in tempOSCValueArray){//unpack OSC value to NSNumber or NSString
    if([val type]==OSCValInt){
      [msgArray addObject:[NSNumber numberWithInt:[val intValue]]];
      [string appendString:[NSString stringWithFormat:@" %d", [val intValue]]];
    }
    else if([val type]==OSCValFloat){
      [msgArray addObject:[NSNumber numberWithFloat:[val floatValue]]];
      [string appendString:[NSString stringWithFormat:@" %f", [val floatValue]]];
    }
    else if([val type]==OSCValString){
      //libpd got _very_ unhappy when it received strings that it couldn't convert to ASCII. Have a check here and convert if needed. This occured when some device user names (coming from LANdini) had odd characters/encodings.
      if ( ![[val stringValue] canBeConvertedToEncoding:NSASCIIStringEncoding] ) {
        NSData *asciiData = [[val stringValue] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *asciiString = [[NSString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding];
        [msgArray addObject:asciiString];
      }
      else{
        [msgArray addObject:[val stringValue]];
      }
      [string appendString:@" "];
      [string appendString:[val stringValue]];
    }
    
  }
  
  [self performSelectorOnMainThread:@selector(log:) withObject:string waitUntilDone:NO];
    
  [self performSelectorOnMainThread:@selector(receiveOSCHelper:) withObject:msgArray waitUntilDone:NO];
    
}

-(void)sendTilts{
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:@"/system/tilts"];
    [formattedMessageArray addObject:[NSNumber numberWithFloat:[self.lockTiltXSlider floatValue]]];
    [formattedMessageArray addObject:[NSNumber numberWithFloat:[self.lockTiltYSlider floatValue]]];
    [self sendFormattedMessageArray:formattedMessageArray];

}

-(void)setCurrentPage:(int)newIndex{    
    currentPageIndex = newIndex;
    [canvasView setPageViewIndex:currentPageIndex];
    self.pageIndexLabel.stringValue = [NSString stringWithFormat:@"Page %d/%d", currentPageIndex+1, [documentModel pageCount]];
  
  NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
  [formattedMessageArray addObject:@"/system/page"];
  [formattedMessageArray addObject:[NSNumber numberWithInt:currentPageIndex]];
  [self sendFormattedMessageArray:formattedMessageArray];
}



-(void)fillFontPop{
    NSArray* fontArray=[(MMPDocumentController*)[NSDocumentController sharedDocumentController] fontArray];
    
    for(NSDictionary* fontDict in fontArray){
        if([fontDict objectForKey:@"family"]){
            NSString* fontName = [fontDict objectForKey:@"family"];
            [self.propLabelFontPopButton addItemWithTitle:fontName];
        
            if([NSFont fontWithName:fontName size:12]){//if font exists when called by family!
                NSMenuItem *menuItem = [self.propLabelFontPopButton itemWithTitle:fontName];
              NSDictionary *attributes = @{
                                         NSFontAttributeName: [NSFont fontWithName:fontName size:12.0],
                                         NSForegroundColorAttributeName: [NSColor blackColor]
                                         };
                NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:fontName attributes:attributes];
                [menuItem setAttributedTitle:attributedTitle];
            }
            
            else if ([[fontDict objectForKey:@"types"] count]>0 &&[NSFont fontWithName:[[fontDict objectForKey:@"types"]objectAtIndex:0] size:12]){//try calling by a type
                NSMenuItem *menuItem = [self.propLabelFontPopButton itemWithTitle:fontName];
                NSDictionary *attributes = @{
                                         NSFontAttributeName: [NSFont fontWithName:[[fontDict objectForKey:@"types"]objectAtIndex:0] size:12],
                                         NSForegroundColorAttributeName: [NSColor blackColor]
                                         };
                NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:fontName attributes:attributes];
                [menuItem setAttributedTitle:attributedTitle];
            }
        
        }
       
    }
    //add this one last
    [self.propLabelFontPopButton addItemWithTitle:@"Default"];

  // android default types
    NSArray* androidFontArray=[(MMPDocumentController*)[NSDocumentController sharedDocumentController] androidFontArray];
  for (NSString *fontName in androidFontArray) {
    [self.propLabelAndroidFontPopButton addItemWithTitle:fontName];

    if([NSFont fontWithName:fontName size:12]){//if font exists when called by family!
      NSMenuItem *menuItem = [self.propLabelAndroidFontPopButton itemWithTitle:fontName];
      NSDictionary *attributes = @{
                                   NSFontAttributeName: [NSFont fontWithName:fontName size:12.0],
                                   NSForegroundColorAttributeName: [NSColor blackColor]
                                   };
      NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:fontName attributes:attributes];
      [menuItem setAttributedTitle:attributedTitle];

    }
    //[self.propLabelAndroidFontPopButton addItem]
  }
}

//=======copy/paste - only allowed while editing, not locked
-(IBAction)copy:(id)sender{
    if(isEditing){
        NSMutableArray* selectedControls = [[NSMutableArray alloc] init];
        for(MMPControl* control in [documentModel controlArray])
            if([control isSelected]) [selectedControls addObject:control];
    
        if(selectedControls!=nil && [selectedControls count]>0){
            NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
            [pasteboard clearContents];
            [pasteboard writeObjects:selectedControls];
        }
    }
}

-(void)undoPasteControl:(MMPControl*)control{
    [[self undoManager] registerUndoWithTarget:self selector:@selector(addControlHelper:) object:control ];
    [control removeFromSuperview];
    [[documentModel controlArray] removeObject:control];
    if(control==currentSingleSelection)[self clearSelection];
}

-(IBAction)paste:(id)sender{
    if(isEditing){
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];;
        NSArray *classes = [[NSArray alloc] initWithObjects:  [MMPControl class], nil];
        NSDictionary *options = [NSDictionary dictionary];
        NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
        if (copiedItems != nil) {
            for(MMPControl* currControl in [documentModel controlArray]) [currControl setIsSelected:NO];
            [self clearSelection];
        
            for(MMPControl* newControl in copiedItems){
                [[self undoManager] registerUndoWithTarget:self selector:@selector(undoPasteControl:) object:newControl ];
                
                newControl.editingDelegate=self;
                [[documentModel controlArray]  addObject:newControl];
                [canvasView addSubview:newControl];
                [newControl setIsSelected:YES];
              
                //class specific post stuff loading/needs delegate
              if ([newControl isKindOfClass:[MMPTable class]]){
                [((MMPTable*)newControl) loadTable];
              }
              
            }
            if([copiedItems count]==1)
                [self controlEditClicked:[copiedItems lastObject] withShift:NO wasAlreadySelected:NO];
        }
    }
}

-(IBAction)delete:(id)sender{
    [self propDelete:nil];
}

-(IBAction)selectAll:(id)sender{
    [self clearSelection];
    for(MMPControl* currControl in [documentModel controlArray]){
       [currControl setIsSelected:YES];
    }
}

- (IBAction)openEditingGridPanel:(id)sender {
  [NSApp beginSheet:_editingGridPanel
     modalForWindow:documentWindow
      modalDelegate:self
     didEndSelector:nil
        contextInfo:nil];
}

-(IBAction)closeEditingGridPanel:(id)sender {
  [NSApp endSheet:_editingGridPanel];
  [_editingGridPanel orderOut:sender];
}

- (IBAction)enableEditingGridChanged:(NSButton *)sender {
  _snapToGridEnabled = [(NSButton*)sender state];
  [canvasView refreshGuides];

  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithBool:_snapToGridEnabled] forKey:@"snapToGridEnabled"];
  [defaults synchronize];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)snapWidgetsToGrid:(NSButton *)sender {
  [[self undoManager] beginUndoGrouping];
  for (MMPControl *control in [documentModel controlArray]) {
    CGFloat originX = control.frame.origin.x;
    CGFloat originY = control.frame.origin.y;
    CGFloat width = control.frame.size.width;
    CGFloat height = control.frame.size.height;

    NSUInteger snapToGridXVal = [control.editingDelegate guidesX];
    NSUInteger snapToGridYVal = [control.editingDelegate guidesY];

    originX = snapToGridXVal * floor((originX/snapToGridXVal)+0.5);
    originY = snapToGridYVal * floor((originY/snapToGridYVal)+0.5);
    width = snapToGridXVal * floor((width/snapToGridXVal)+0.5);
    height = snapToGridYVal * floor((height/snapToGridYVal)+0.5);
    width = MAX(width, 40);
    height = MAX(height, 40);
    CGRect newFrame = CGRectMake(originX, originY, width, height);
    [control setFrameObjectUndoable:[NSValue valueWithRect: newFrame]];
  }
  [[self undoManager] endUndoGrouping];
}

- (IBAction)editingGridXChanged:(NSTextField *)sender {
  _snapToGridXVal = [sender intValue];
  if (_snapToGridXVal < 5) _snapToGridXVal = 5;
  if(_snapToGridEnabled) [canvasView refreshGuides];
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithInteger:_snapToGridXVal] forKey:@"snapToGridXVal"];
  [defaults synchronize];
}

- (IBAction)editingGridYChanged:(NSTextField *)sender {
  _snapToGridYVal = [sender intValue];
  if (_snapToGridYVal < 5) _snapToGridYVal = 5;
  if(_snapToGridEnabled) [canvasView refreshGuides];
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithInteger:_snapToGridYVal] forKey:@"snapToGridYVal"];
  [defaults synchronize];
}

// editing delegate for
-(BOOL)guidesEnabled {
  return _snapToGridEnabled;
}
-(NSUInteger)guidesX {
  return _snapToGridXVal;
}
-(NSUInteger)guidesY {
  return _snapToGridYVal;
}

@end
