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
  
    //create temp directory for interacting with PD tables.
  /*NSString *path = nil;
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  if ([paths count])
  {
    NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
  }*/
  
  /*NSError *error;
  NSURL* url = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
  NSLog(@"url: %@", [url absoluteString]);
  */
  
  /*NSURL *cache = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
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
  }*/
  
  //make file
  /*NSString *tempFileTemplate = [path stringByAppendingPathComponent:@"myapptempfile.XXXXXX"];
  const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
  char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
  strcpy(tempFileNameCString, tempFileTemplateCString);
  int fileDescriptor = mkstemp(tempFileNameCString);
  
  if (fileDescriptor == -1)
  {
    // handle file creation failure
  }
  
  // This is the file name if you need to access the file by name, otherwise you can remove
  // this line.
  
  NSString* tempFileName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
  
  free(tempFileNameCString);
  NSFileHandle* tempFileHandle =
  [[NSFileHandle alloc]
   initWithFileDescriptor:fileDescriptor
   closeOnDealloc:NO];*/
  
  
  return self;
}

//OSC manager delegate method: get OSC message, sent it to ALL open documents
- (void)receiveOSCArray:(NSMutableArray *)oscArray asString:(NSString*)string{
    for(Document* doc in [self documents]){
        [doc receiveOSCArray:oscArray asString:string];
    }
}

@end
