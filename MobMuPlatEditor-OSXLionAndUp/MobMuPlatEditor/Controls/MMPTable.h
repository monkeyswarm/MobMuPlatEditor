//
//  MMPTable.h
//  MobMuPlatEditor
//
//  Created by diglesia on 4/27/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPTable : MMPControl
@property (nonatomic, copy) NSString *tableName;
@property (nonatomic) int mode;

-(void)loadTable;
@end
