//
//  MMPDocumentController.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/1/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//


#import "MMPDocumentController.h"

@implementation MMPDocumentController

-(id)init{
    self = [super init];
    
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    
    //set up one OSC manager for all open documents
    _manager = [[OSCManager alloc]init];
    [_manager setOSCReceivePort:[NSMutableArray arrayWithObjects:[NSNumber numberWithInt:54310], nil] withDict:nil];
    [_manager setIPAddressAndPort:[NSMutableArray arrayWithObjects:@"localhost", [NSNumber numberWithInt:54300], nil] withDict:nil];
    _manager.delegate=self;
    
    NSString* fontnamesjson = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"uifontlist" ofType:@"txt"]];
    _fontArray = [[fontnamesjson objectFromJSONString] mutableCopy];//array of dictionaries
    //printf("\ncontroller font array %d", [_fontArray count]);
    [_fontArray sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"family" ascending:YES], nil]];
    //create an extra font list element called "default"
    NSMutableDictionary* defaultDict = [[NSMutableDictionary alloc]init];
    [defaultDict setObject:@"Default" forKey:@"family"];
    [defaultDict setObject:[NSArray array] forKey:@"types"];
    [_fontArray addObject:defaultDict];
    
    return self;
}

//OSC manager delegate method: get OSC message, sent it to ALL open documents
- (void)receiveOSCArray:(NSMutableArray *)oscArray asString:(NSString*)string{
    for(Document* doc in [self documents]){
        [doc receiveOSCArray:oscArray asString:string];
    }
}

@end
