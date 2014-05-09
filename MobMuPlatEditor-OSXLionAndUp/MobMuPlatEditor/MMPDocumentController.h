//
//  MMPDocumentController.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/1/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "OSCManager.h"

#import <VVOSC/VVOSC.h>
#import "Document.h"

@interface MMPDocumentController : NSDocumentController<OSCDelegateProtocol>{}

@property(retain)OSCManager* manager;
@property(retain)NSMutableArray* fontArray;

-(void)sendOSCMessageFromArray:(NSArray*) list;
+ (BOOL)numberIsFloat:(NSNumber*)num;
+ (NSString*)cachePathWithAddress:(NSString*)address;
@end
