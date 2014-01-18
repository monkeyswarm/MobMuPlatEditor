//
//  MMPUnknown.h
//  MobMuPlatEditor
//
//  Created by Daniel Iglesia on 1/12/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPUnknown : MMPControl {
    NSTextField* warningLabel;
}

//-(void)setWarning:(NSString*)badName;
@property (nonatomic, strong) NSString* badName;
@end
