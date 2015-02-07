//
//  MMPLabel.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/31/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//
//  Label is basically just a wrapper around an NSTextView

#import "MMPControl.h"

@interface MMPLabel : MMPControl{
    NSTextView* textView;
}
@property (nonatomic) int textSize;
@property (nonatomic) NSString* stringValue;
@property(nonatomic, readonly)NSString* fontFamily;
@property(nonatomic, readonly) NSString *fontName;
@property(nonatomic, readonly) NSString *androidFontName; //family is always default, this is bold, italic, light/condensed
@property(nonatomic) BOOL isShowingAndroidFonts;

-(void)setFontFamily:(NSString *)fontFamily fontName:(NSString*)fontName;
-(void)setAndroidFontName:(NSString*)fontName;

+ (BOOL)numberIsFloat:(NSNumber*)num;
@end
