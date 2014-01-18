    //
//  OSCManager.m
//  PhoneGap
//
//  Created by thecharlie on 5/17/10.
//  Copyright 2010 One More Muse. All rights reserved.
//

#import "OSCManager.h"
//#import "PhoneGapDelegate.h"
//#import "PdBase.h"

//#define OSC_RECEIVE_PORT 8080
#define OSC_POLLING_RATE .003
#define OUTPUT_BUFFER_SIZE 1024

OSCManager *_oscManager;


class ExamplePacketListener : public osc::OscPacketListener {
protected:

    virtual void ProcessMessage( const osc::ReceivedMessage& m, const IpEndpointName& remoteEndpoint ) {
	
        osc::ReceivedMessage::const_iterator arg = m.ArgumentsBegin();
			
        NSMutableArray* msgArray = [[NSMutableArray alloc]init];//for pd
        NSMutableString *jsString = [[NSMutableString alloc]init];//for printing, 
        [jsString appendString:@"[in] "];
        [jsString appendString:[NSMutableString stringWithFormat:@"%s", m.AddressPattern()]];
        [msgArray addObject:[NSMutableString stringWithFormat:@"%s", m.AddressPattern()]];
        
        
			const char * tags = m.TypeTags();

			for(int i = 0; i < m.ArgumentCount(); i++) {
					switch(tags[i]) {
                    case 'f':
                            [msgArray addObject:[NSNumber numberWithFloat:(arg)->AsFloat()]];
                        [jsString appendString:[NSString stringWithFormat:@" %f", (arg++)->AsFloat()]];
                        
						break;
					case 'i':
                        [msgArray addObject:[NSNumber numberWithInt:(arg)->AsInt32()]];
						[jsString appendString:[NSString stringWithFormat:@" %i", (arg++)->AsInt32()]];						
						break;
					case 's':
                        [msgArray addObject:[NSString stringWithFormat:@"%s", (arg)->AsString()]]; 
						[jsString appendString:[NSString stringWithFormat:@" %s", (arg++)->AsString()]];
						break;
					default:
						break;
				}
				//if(i != m.ArgumentCount() - 1) [jsString appendString:@","];
			}
			
			//[jsString appendString:@"\n"];
		//	[_oscManager.webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsString waitUntilDone:NO];
            //NSLog(@"%@", jsString);
		//}
		//[pool drain];
        
        [_oscManager.delegate receiveOSCArray:msgArray asString:jsString];
        //[PdBase sendList:msgArray toReceiver:@"fromNetwork"];
        //performSelectorOnMainThread:@selector(receivedOSCArray:) withObject:msgArray waitUntilDone:NO]; //receiveOSCArray:msgArray];

	}
};

@implementation OSCManager
@synthesize receivePort, delegate;

- (id) init{

	if(self = (OSCManager *)[super init]) {
        shouldPoll = NO;
		listener = new ExamplePacketListener();
		[NSThread detachNewThreadSelector:@selector(pollJavascriptStart:) toTarget:self withObject:nil];
	}
	_oscManager = self;
	return self;
}



- (void)oscThread {
	s = new UdpListeningReceiveSocket( IpEndpointName( IpEndpointName::ANY_ADDRESS, self.receivePort ),listener );
	s->RunUntilSigInt();
}

- (void)setOSCReceivePort:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    //NSLog(@"CALLED %d %d", self.receivePort, [[arguments objectAtIndex:0] intValue]);
	if([[arguments objectAtIndex:0] intValue] != self.receivePort) {
        if (s != NULL) {
            //NSLog(@"deleting socket");
            s->AsynchronousBreak();
            //delete(s);   // causes error for some reason...
        }
        //NSLog(@"started with %d",[[arguments objectAtIndex:0] intValue]);
		self.receivePort = [[arguments objectAtIndex:0] intValue];
		[NSThread detachNewThreadSelector:@selector(oscThread) toTarget:self withObject:nil];
	}
}
//edit
-(void)killReceiveSocket{
    s->Break();
    s->AsynchronousBreak();
}



- (void)startPolling:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    shouldPoll = YES;
    [NSThread detachNewThreadSelector:@selector(pollJavascriptStart:) toTarget:self withObject:nil];
}
- (void)stopPolling:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    shouldPoll = NO;
}
- (void)startReceiveThread:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
	// this can be (and is) blank... it will still force the command object to be created which will start the OSC thread
}

- (void)setIPAddressAndPort:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
	char * dest_ip = (char *)[[arguments objectAtIndex:0] UTF8String];
	int dest_port  = (int)[[arguments objectAtIndex:1] intValue];

	delete(destinationAddress);
	destinationAddress = new IpEndpointName( dest_ip, dest_port );
	
	delete(output);
	output = new UdpTransmitSocket(*destinationAddress);
	
//    [self startPolling:nil withDict:nil];
}


- (void) pollJavascriptStart:(id)obj {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	while(shouldPoll) {
		[self performSelectorOnMainThread:@selector(pollJavascript:) withObject:nil waitUntilDone:NO];
		[NSThread sleepForTimeInterval:OSC_POLLING_RATE];
	}
	
	//[pool drain];
}

// form is objectName:paramNumber,val1,val2,val3|objectName:paramNumber,val1,val2,val3|objectName:paramNumber,val1,val2,val3
/*- (void) pollJavascript:(id)obj {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *cmdString = [webView stringByEvaluatingJavaScriptFromString:@"control.getValues()"];
	if([cmdString length] == 0) return;
	
	char buffer[OUTPUT_BUFFER_SIZE];
    osc::OutboundPacketStream p( buffer, OUTPUT_BUFFER_SIZE );		
	p << osc::BeginBundleImmediate;
	
	[webView stringByEvaluatingJavaScriptFromString:@"control.clearValuesString()"];
	NSArray *objects = [cmdString componentsSeparatedByString:@"|"];

	for(int i = 0; i < [objects count]; i++) {
		NSString *str = [objects objectAtIndex:i];
		NSArray  *nameValues = [str componentsSeparatedByString:@":"];
		
		if([nameValues count] < 2) continue; // avoids problem caused by starting polling before JavaScript state is ready
		
		NSString *oscAddress = [nameValues objectAtIndex:0];
		NSString *allvalues  = [nameValues objectAtIndex:1];
		
		p << osc::BeginMessage( [oscAddress UTF8String] );

		NSArray *strValues = [allvalues componentsSeparatedByString:@","];
		for(int j = 0; j < [strValues count]; j++) {
			NSString * value = [strValues objectAtIndex:j];
			p << [value floatValue];
		}
		p << osc::EndMessage;
	}
	
	p << osc::EndBundle;
	output->Send(p.Data(), p.Size());
	
//	[pool drain];
//  [pool release];
}*/

- (void)send:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
	char buffer[OUTPUT_BUFFER_SIZE];
    osc::OutboundPacketStream p( buffer, OUTPUT_BUFFER_SIZE );		
	p << osc::BeginBundleImmediate << osc::BeginMessage( [[arguments objectAtIndex:0] UTF8String] );
	
	NSString *typetags= [arguments objectAtIndex:1];
	for(int i = 0; i < [typetags length]; i++) {	
		char c = [typetags characterAtIndex:i];
		switch(c) {
			case 'i':
				p << [[arguments objectAtIndex:i+2] intValue];
				break;
			case 'f':
				p << [[arguments objectAtIndex:i+2] floatValue];
				break;
			case 's':
				p << [[arguments objectAtIndex:i+2] UTF8String];
				break;
		 }
	}
	p << osc::EndMessage << osc::EndBundle;
	if(output != NULL) output->Send(p.Data(), p.Size());
}

- (void) dealloc {
	s->Break();
	delete(s);

	delete(listener); 	
	delete(destinationAddress);
	delete(output);
//	[super dealloc];
}

@end
