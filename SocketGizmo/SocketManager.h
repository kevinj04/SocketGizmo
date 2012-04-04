//
//  SocketManager.h
//  SocketGizmo
//
//  Created by Kevin Jenkins on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const SMSendData;
extern NSString *const SMSendString;
extern NSString *const SMRecData;
extern NSString *const SMRecCmd;
extern NSString *const SMDataKey;
extern NSString *const SMConnectionFail;
extern NSString *const SMConnectionTimeOut;

@interface SocketManager : NSObject<NSStreamDelegate> {
    
    NSString            *serverAddress;
    int                 port;
    
    NSInputStream       *input;
    NSOutputStream      *output;
    
    bool                connected;
    bool                silent;
    
    @private
    NSString            *cr;    
    NSData              *dataToWrite;
}

/** Creation Destruction Methods **/
- (id) init;
+ (id) manager;
- (void) setup;
- (void) dealloc;

/** Socket Setup Methods **/
- (void) setServer:(NSString *) server;
- (void) setPort:(int) p;

/** Socket Interaction Methods **/
- (void) connectToServer;

- (void) sendString:(NSString *) server;
- (void) sendData:(NSData *) data;


@end
