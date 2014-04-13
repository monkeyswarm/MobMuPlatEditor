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

#define DEFAULT_PORT_NUMBER 54321
#define CANVAS_LEFT 250
#define CANVAS_TOP 8

@implementation Document
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
    
    [canvasOuterView setWantsLayer:YES];
    canvasOuterView.layer.backgroundColor=CGColorCreateGenericGray(.1, 1);
    
    canvasView.editingDelegate=self;
    [[self canvasTypePopButton] selectItemAtIndex:-1];
    [[self canvasTypePopButton] synchronizeTitleAndSelectedItem];//clears check by "iphone" drop down element
    [[self orientationPopButton ] selectItemAtIndex:-1];
    [[self orientationPopButton] synchronizeTitleAndSelectedItem];
    
    [self fillFontPop];//fill the drop-down list of fonts, gotten from the document controller, as defined in uifontlist.txt
    
    [self loadFromModel];
    
    //default values
    [self.propColorWell setColor:[NSColor blueColor]];
    [self.propHighlightColorWell setColor:[NSColor redColor]];
    [self.propKnobIndicatorColorWell setColor:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1]];
    [self.tabView selectFirstTabViewItem:nil];
    [self setIsEditing:YES];
    
    //kick the pd patch to get it to reconnect 
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:@"/system/opened"];
    [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"i"]];//tags
    [formattedMessageArray addObject:[NSNumber numberWithInt:1]];
    [self sendFormattedMessageArray:formattedMessageArray];
   
    
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
    
    //LOAD EXTERNAL FILES within docmodel ( panels) that may require a local path name
    for(MMPControl* control in [documentModel controlArray]){
        if([control isKindOfClass:[MMPPanel class]]){
            if([(MMPPanel*)control imagePath] && ![[(MMPPanel*)control imagePath] isEqualToString:@"" ]){
                [(MMPPanel*)control loadImage];
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
    
    //port
    [[self.docPortField formatter] setGroupingSeparator:@""];
    [self.docPortField setIntValue:[documentModel port]];
    
    
    
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
            [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+480+CANVAS_TOP, 500) display:YES animate:NO];
            
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
            [documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+568+CANVAS_TOP, 500) display:YES animate:NO];
            
            [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
            [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
            [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-320-CANVAS_TOP, 568, 320)];
        }
    }
    else{//ipad
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

- (IBAction)docPortChanged:(NSTextField *)sender {
    int val = [sender intValue];
    if(val<1000 || val>65535){
        [self.docPortField setIntValue:DEFAULT_PORT_NUMBER];
        val=DEFAULT_PORT_NUMBER;
    }
    
    [documentModel setPort:val];
    
    //send message out in case PD wrapper is listening to update to new port number
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:@"/system/port"];
    [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"i"]];//tags
    [formattedMessageArray addObject:[NSNumber numberWithInt:val]];
    [self sendFormattedMessageArray:formattedMessageArray];
    
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
    [newControl hackRefresh];
    
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
    
    for(MMPControl* control in [documentModel controlArray]){//printf(" %d", currControl);
        if([control isSelected]) [selectedControls addObject:control];
    }
    
    for(MMPControl* currControl in selectedControls){
        [[documentModel controlArray] removeObject:currControl];
        [[documentModel controlArray] addObject:currControl];
        [currControl removeFromSuperview];
        [canvasView addSubview:currControl];
        [currControl hackRefresh];
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
        [control hackRefresh];
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
            
        }
        else if([control isKindOfClass:[MMPGrid class]]){
            [self.propVarView addSubview:self.propGridView];
            [self.propGridDimXField setStringValue:[NSString stringWithFormat:@"%d", [(MMPGrid*)control dimX ]]];//use setInt
            [self.propGridDimYField setStringValue:[NSString stringWithFormat:@"%d", [(MMPGrid*)control dimY ]]];
            [self.propGridBorderThicknessField setStringValue:[NSString stringWithFormat:@"%d", [(MMPGrid*)control borderThickness ]]];
            [self.propGridPaddingField setStringValue:[NSString stringWithFormat:@"%d", [(MMPGrid*)control cellPadding ]]];
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
        }
        else if([control isKindOfClass:[MMPToggle class]]){
            [self.propVarView addSubview:self.propToggleView];
            [self.propToggleThicknessTextField setIntegerValue:[(MMPToggle*)control borderThickness]];
        }
        else if([control isKindOfClass:[MMPMenu class]]){
          [self.propVarView addSubview:self.propMenuView];
          [self.propMenuTitleTextField setStringValue:[(MMPMenu*)control titleString]];
        }
      
        currentSingleSelection=control;
    }
    
    
}

//one control has moved, move all other selected controls
-(void)controlEditMoved:(MMPControl*)control deltaPoint:(CGPoint)deltaPoint{
    for(MMPControl* currControl in [documentModel controlArray]){
        if([currControl isSelected] && currControl!=control){
            [[self undoManager] registerUndoWithTarget:currControl selector:@selector(setFrameOriginObjectUndoable:) object:[NSValue valueWithPoint:currControl.frame.origin]];
            CGPoint newOrigin = CGPointMake(currControl.frame.origin.x+deltaPoint.x, currControl.frame.origin.y+deltaPoint.y);
            [currControl setFrameOrigin:newOrigin];
        }
    }
}

//I clicked a single control and released it (without drag or shift), deselect everything else
-(void)controlEditReleased:(MMPControl*)control withShift:(BOOL)shift hadDrag:(BOOL)hadDrag{
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

//based on which of the 4 tabs are open, turn editing on/off
-(void)tabView:(NSTabView*)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    if([tabView indexOfTabViewItem:tabViewItem]==3){//lock
        [self setIsEditing:NO];
    }
    else [self setIsEditing:YES];
    
   
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
    [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"i"]];//tags
    [formattedMessageArray addObject:[NSNumber numberWithInt:1]];
    [self sendFormattedMessageArray:formattedMessageArray];
}

- (IBAction)pageDownHit:(NSButton *)sender {
    if(currentPageIndex>0)[self setCurrentPage:currentPageIndex-1];
}

- (IBAction)pageUpHit:(NSButton *)sender {
    if(currentPageIndex<[documentModel pageCount]-1)[self setCurrentPage:currentPageIndex+1];
}

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

//send out OSC message, formatted from array of messages
-(void)sendFormattedMessageArray:(NSMutableArray*)formattedMessageArray{
    
    NSMutableString* theString = [[NSMutableString alloc]init];
    [theString appendString:@"[out] "];
    [theString appendString:[formattedMessageArray objectAtIndex:0]];
    [theString appendString:@" "];
    NSString* tagsString = [formattedMessageArray objectAtIndex:1];
    for (int i = 0; i < [tagsString length]; i++){
        unichar c = [tagsString characterAtIndex:i];
        switch(c){
            case 'i':
                [theString appendString:[NSString stringWithFormat:@"%d ", [[formattedMessageArray objectAtIndex:i+2] intValue]]];
                 break;
            case 'f':
                [theString appendString:[NSString stringWithFormat:@"%.3f ", [[formattedMessageArray objectAtIndex:i+2] floatValue]]];
                break;
            case 's':
                [theString appendString:[formattedMessageArray objectAtIndex:i+2]];
                [theString appendString:@" "];
                 break;

        }
    }
    //console
    [self log:theString];
    //send out
    [[(MMPDocumentController*)[NSDocumentController sharedDocumentController] manager] send:formattedMessageArray withDict:nil] ;
    
}

-(void)receiveOSCHelper:(NSMutableArray*)msgArray{
    
    //I respond to this message
    if([[msgArray objectAtIndex:0] isEqualToString:@"/system"] && [[msgArray objectAtIndex:1] isEqualToString:@"requestPort"]){
        printf("\nPD requested port number = %d", [documentModel port]);
        NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
        [formattedMessageArray addObject:@"/system/port"];
        [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"i"]];//tags
        [formattedMessageArray addObject:[NSNumber numberWithInt:[documentModel port]]];
        [self sendFormattedMessageArray:formattedMessageArray];
        
    }
    
    //otherwise SEND TO OBJECT!!!
    for(MMPControl* currControl in [documentModel controlArray]){
        if([currControl.address isEqualToString:[msgArray objectAtIndex:0]])
            [currControl receiveList: [msgArray subarrayWithRange:NSMakeRange(1, [msgArray count]-1)]];
    }
    
}

-(void)receiveOSCArray:(NSMutableArray*)msgArray asString:(NSString *)string{//from OSC thread!
   
    [self performSelectorOnMainThread:@selector(log:) withObject:string waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(receiveOSCHelper:) withObject:msgArray waitUntilDone:NO];
}

-(void)sendTilts{
    NSMutableArray* formattedMessageArray = [[NSMutableArray alloc]init];
    [formattedMessageArray addObject:@"/system/tilts"];
    [formattedMessageArray  addObject:[[NSMutableString alloc]initWithString:@"ff"]];//tags
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
  [formattedMessageArray  addObject:@"i"];//tags
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
                NSMenuItem *menuItem = [self.propLabelFontPopButton itemWithTitle:fontName];//[[NSMenuItem alloc] initWithTitle:@"Hi, how are you?" action:nil  keyEquivalent:@""];
                NSDictionary *attributes = @{
                                         NSFontAttributeName: [NSFont fontWithName:fontName size:12.0],
                                         NSForegroundColorAttributeName: [NSColor blackColor]
                                         };
                NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:fontName attributes:attributes];
                [menuItem setAttributedTitle:attributedTitle];
            }
            
            else if ([[fontDict objectForKey:@"types"] count]>0 &&[NSFont fontWithName:[[fontDict objectForKey:@"types"]objectAtIndex:0] size:12]){//try calling by a type
                NSMenuItem *menuItem = [self.propLabelFontPopButton itemWithTitle:fontName];//[[NSMenuItem alloc] initWithTitle:@"Hi, how are you?" action:nil keyEquivalent:@""];
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


@end
