//
//  MMPTable.h
//  MobMuPlatEditor
//
//  Created by diglesia on 4/27/14.
//  Copyright (c) 2014 Daniel Iglesia. All rights reserved.
//

#import "MMPControl.h"

@interface MMPTable : MMPControl
//@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, strong) NSColor *selectionColor;
@property (nonatomic) int mode;
@property (nonatomic) NSUInteger displayMode;//0=line, 1=fill
@property (nonatomic) CGFloat displayRangeLo;
@property (nonatomic) CGFloat displayRangeHi;
@property (nonatomic) NSUInteger displayRangeConstant;

-(void)loadTable;
@end
