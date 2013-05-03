//
//  DocumentModel.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/26/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMPControl.h"
#import "JSONKit.h"

#import "MMPSlider.h"
#import "MMPKnob.h"
#import "MMPButton.h"
#import "MMPToggle.h"
#import "MMPLabel.h"
#import "MMPXYSlider.h"
#import "MMPGrid.h"
#import "MMPPanel.h"
#import "MMPMultiSlider.h"


typedef enum{
    canvasTypeIPhone3p5Inch = 0,
    canvasTypeIPhone4Inch = 1,
    canvasTypeIPad = 2,
} canvasType;

@interface DocumentModel : NSObject

@property int canvasType;
@property BOOL isOrientationLandscape;//default portrait
@property BOOL isPageScrollShortEnd;//default long end
@property NSColor* backgroundColor;
@property NSString* pdFile;
@property int pageCount;//def 1
@property int startPageIndex;//def 0
@property int port;
@property float version;

@property NSMutableArray* controlArray; //of type MMPControl

-(NSString*)modelToString;
+(DocumentModel*)modelFromString:(NSString*)jsonString;
@end
