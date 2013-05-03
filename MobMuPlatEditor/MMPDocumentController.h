//
//  MMPDocumentController.h
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/1/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OSCManager.h"
#import "Document.h"
#import "JSONKit.h"

@interface MMPDocumentController : NSDocumentController<OSCManagerDelegate>{}

@property(retain)OSCManager* manager;
@property(retain)NSMutableArray* fontArray;
@end
