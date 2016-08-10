//
//  MMPKnob.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/30/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPKnob : MMPControl{
    NSView* knobView;
    NSView* indicatorView;
	id targetObject;
	SEL targetSelector;
	float dim; //diameter
	float radius;
	float indicatorDim;
	CGPoint centerPoint;
    int indicatorThickness;
    NSMutableArray *tickViewArray;
}
@property(nonatomic) float value;
@property(nonatomic) int range;
@property(nonatomic) NSColor* indicatorColor;

//get which osx version is runnning (returns 7 for 10.7, 8 for 10.8). Lion and Mountain Lion handle angles/rotation differently
+(int)osxMinorVersion;

- (void)setLegacyRange:(int)range;

@end
