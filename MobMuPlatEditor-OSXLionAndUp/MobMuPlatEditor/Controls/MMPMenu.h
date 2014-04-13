//
//  MMPMenu.h
//  MobMuPlatEditor
//
//  Created by diglesia on 4/9/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPMenu : MMPControl <NSTableViewDataSource, NSTableViewDelegate>
@property (strong, nonatomic) NSString* titleString;
//@property (nonatomic) int textSize; //TODO
@end

@interface MiddleAlignedTextFieldCell : NSTextFieldCell

@end