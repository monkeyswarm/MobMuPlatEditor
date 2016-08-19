//
//  DocumentModel.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/26/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMPControl.h"

#import "MMPSlider.h"
#import "MMPKnob.h"
#import "MMPButton.h"
#import "MMPToggle.h"
#import "MMPLabel.h"
#import "MMPXYSlider.h"
#import "MMPGrid.h"
#import "MMPPanel.h"
#import "MMPMultiSlider.h"
#import "MMPLCD.h"
#import "MMPMultiTouch.h"
#import "MMPUnknown.h"
#import "MMPMenu.h"
#import "MMPTable.h"

typedef enum{
    canvasTypeIPhone3p5Inch = 0,
    canvasTypeIPhone4Inch = 1,
    canvasTypeIPad = 2,
    canvasTypeAndroid7Inch = 3,
    canvasTypeWatch
} canvasType;

extern const NSUInteger kMMPDocumentModelCurrentVersion;

@interface DocumentModel : NSObject

@property int canvasType;
@property BOOL isOrientationLandscape;//default portrait
@property BOOL isPageScrollShortEnd;//default long end
@property NSColor* backgroundColor;
@property NSString* pdFile;
@property int pageCount;//def 1
/* wear @property NSUInteger watchPageCount;*/
@property int startPageIndex;//def 0
@property int port;
@property NSUInteger version; //version of opened patch. new patches use kMMPDocumentModelCurrentVersion.
@property BOOL preferAndroidFontDisplay;
@property NSMutableArray* controlArray; //of type MMPControl
/* wear @property NSMutableArray* watchControlDupleArray;*/ //of duple title label, control


-(NSString*)modelToString;
+(DocumentModel*)modelFromString:(NSString*)jsonString;
@end
