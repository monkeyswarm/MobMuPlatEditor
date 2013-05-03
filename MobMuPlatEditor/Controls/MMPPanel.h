//
//  MMPPanel.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/4/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPPanel : MMPControl{
    NSImageView* imageView;
    NSTextField* textField;
}

@property (nonatomic)NSString* imagePath;
-(void)loadImage;
@end
