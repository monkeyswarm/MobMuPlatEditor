//
//  OSCManager.h
//  PhoneGap
//
//  Created by thecharlie on 5/17/10.
//  Copyright 2010 One More Muse. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "PhoneGapCommand.h"
#include "OscReceivedElements.h"
#include "OscPacketListener.h"
#include "UdpSocket.h"
#include "IpEndpointName.h"
#include "OscOutboundPacketStream.h"

@protocol OSCManagerDelegate
- (void)receiveOSCArray:(NSMutableArray *)oscArray asString:(NSString*)string;
@end

class ExamplePacketListener;
@interface OSCManager : NSObject {
    BOOL shouldPoll;
	ExamplePacketListener  * listener;
	UdpListeningReceiveSocket * s;
	//NSMutableDictionary * addresses;
	
	IpEndpointName    * destinationAddress;
	UdpTransmitSocket * output;
	int receivePort;
}

//@property (retain) NSMutableDictionary * addresses;
@property (nonatomic) int receivePort;
@property id<OSCManagerDelegate> delegate;

- (void)oscThread;
//- (void)pushInterface:(NSValue *)msgPointer;
//- (void)pushDestination:(NSValue *) msgPointer;

- (void)setOSCReceivePort:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)setIPAddressAndPort:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)startReceiveThread:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)send:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)startPolling:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)stopPolling:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

//edit
-(void)killReceiveSocket;
    

@end


