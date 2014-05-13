//
//  MMPDocumentController.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 1/1/13.
//  Copyright (c) 2013 Daniel Iglesia. All rights reserved.
//


#import "MMPDocumentController.h"

@implementation MMPDocumentController {
  OSCInPort *inPort;
	OSCOutPort *outPort;
}

-(id)init{
    self = [super init];
  
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(appWillTerminate:)
             name:NSApplicationWillTerminateNotification
           object:nil];
  
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    
    //set up one OSC manager for all open documents
   /* _manager = [[OSCManager alloc]init];
    [_manager setOSCReceivePort:[NSMutableArray arrayWithObjects:[NSNumber numberWithInt:54310], nil] withDict:nil];
    [_manager setIPAddressAndPort:[NSMutableArray arrayWithObjects:@"localhost", [NSNumber numberWithInt:54300], nil] withDict:nil];
    _manager.delegate=self;
    */
  _manager = [[OSCManager alloc] init];
	[_manager setDelegate:self];
  outPort = [_manager createNewOutputToAddress:@"127.0.0.1" atPort:54300];
  inPort = [_manager createNewInputForPort:54310];

    NSString* fontnamesjson = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"uifontlist" ofType:@"txt"]];
    //_fontArray = [[fontnamesjson objectFromJSONString] mutableCopy];//array of dictionaries
    NSData *data = [fontnamesjson dataUsingEncoding:NSUTF8StringEncoding];
    _fontArray = [[NSJSONSerialization JSONObjectWithData:data options:nil error:nil] mutableCopy];
  

  
  //printf("\ncontroller font array %d", [_fontArray count]);
    [_fontArray sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"family" ascending:YES], nil]];
    //create an extra font list element called "default"
    NSMutableDictionary* defaultDict = [[NSMutableDictionary alloc]init];
    [defaultDict setObject:@"Default" forKey:@"family"];
    [defaultDict setObject:[NSArray array] forKey:@"types"];
    [_fontArray addObject:defaultDict];
  
  return self;
}

+ (NSString*)cachePathWithAddress:(NSString *)address {
  NSURL *cache = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                        inDomain:NSUserDomainMask
                                               appropriateForURL:nil
                                                          create:YES
                                                           error:nil];
  NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
  NSURL *scratchFolder = [cache URLByAppendingPathComponent:bundleName];
  if(![[NSFileManager defaultManager] fileExistsAtPath:[scratchFolder absoluteString]]) {
    [[NSFileManager defaultManager] createDirectoryAtURL:scratchFolder
                             withIntermediateDirectories:YES
                                              attributes:@{}
                                                   error:nil];
  }
  
  if(address == nil){//just want folder
    return [scratchFolder path];
  }
  
  //strip off slash :(
  if([address hasPrefix:@"/"])
    address = [address substringFromIndex:1];
  
  NSURL *scratchFile = [scratchFolder URLByAppendingPathComponent:address];
  return [scratchFile path] ;
}

//OSC manager delegate method: get OSC message, sent it to ALL open documents
- (void) receivedOSCMessage:(OSCMessage *)m {
  for(Document* doc in [self documents]){
        //[doc receiveOSCArray:oscArray asString:string];
    [doc receivedOSCMessage:m];
    }
}

+ (OSCMessage*) oscMessageFromList:(NSArray*)list{
  OSCMessage *msg = [OSCMessage createWithAddress:[list objectAtIndex:0]];
  for(id item in [list subarrayWithRange:NSMakeRange(1, [list count]-1)]){
    if([item isKindOfClass:[NSString class]]) [msg addString:item];
    else if([item isKindOfClass:[NSNumber class]]){
      NSNumber* itemNumber = (NSNumber*)item;
      if([MMPDocumentController numberIsFloat:itemNumber]) {
        [msg addFloat:[item floatValue]];
      }
      else {
        [msg addInt:[item intValue]];
      }
    }
  }
  return msg;
}

+ (BOOL)numberIsFloat:(NSNumber*)num {
  if(strcmp([num objCType], @encode(float)) == 0 || strcmp([num objCType], @encode(double)) == 0) {
    return YES;
  }
  else return NO;
}

-(void)sendOSCMessageFromArray:(NSArray*) list {
  [outPort sendThisPacket:[OSCPacket createWithContent:[MMPDocumentController oscMessageFromList:list]]];
}

-(void)appWillTerminate:(NSNotification*)notif{ //clear cache!
  
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *directory = [MMPDocumentController cachePathWithAddress:nil];
  NSError *error = nil;
  for (NSString *file in [fm contentsOfDirectoryAtPath:directory error:&error]) {
    BOOL success = [fm removeItemAtPath:[directory stringByAppendingPathComponent:file] error:&error];
    if (!success || error) {
      // it failed.
    }
  }
}

@end
