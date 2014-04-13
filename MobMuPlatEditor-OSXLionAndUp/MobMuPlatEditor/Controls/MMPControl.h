//
//  MMPControl.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/26/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EditHandle.h"
@class MMPControl;

@protocol MMPControlEditingDelegate <NSObject>

-(void)controlEditClicked:(MMPControl*)control withShift:(BOOL)withShift wasAlreadySelected:(BOOL)wasAlreadySelected;
-(void)controlEditMoved:(MMPControl*)control deltaPoint:(CGPoint)deltaPoint;
-(void)controlEditReleased:(MMPControl*)control withShift:(BOOL)shift hadDrag:(BOOL)hadDrag;
-(void)controlEditDelete;
-(BOOL) isEditing;//edit vs locked mode in document
-(void)sendFormattedMessageArray:(NSMutableArray*) formattedMessageArray;
-(void)canvasClicked;
-(NSURL*)fileURL;//return the fileURL of the document (in order to get relative paths to MMPPanel images)
-(void)updateGuide:(MMPControl*)control;
-(NSColor*)patchBackgroundColor;
-(NSView*)canvasOuterView;
@end

@interface MMPControl : NSControl <NSCoding, NSPasteboardReading, NSPasteboardWriting>{
    BOOL dragging;
    CGPoint clickOffsetInMe;
    CGPoint lastDragLocation;
    BOOL wasSelectedThisCycle;
}

+(CGColorRef) CGColorFromNSColor:(NSColor*)inColor;
-(void)hackRefresh;
-(void) addHandles;
-(void)bringUpHandle;
-(void)receiveList:(NSArray *)inArray;

-(void)setFrameObjectUndoable:(NSValue*)frameObject;
-(void)setFrameOriginObjectUndoable:(NSValue*)pointObject;
-(void)setAddressUndoable:(NSString *)address;
-(void)setColorUndoable:(NSColor *)color;
-(void)setHighlightColorUndoable:(NSColor *)color;

@property (nonatomic) EditHandle* handle;
@property (assign, nonatomic) id<MMPControlEditingDelegate> editingDelegate;
@property (nonatomic) BOOL isSelected;
@property (nonatomic) NSString* address;
@property (nonatomic) NSColor* color;
@property (nonatomic) NSColor* highlightColor;

@end
