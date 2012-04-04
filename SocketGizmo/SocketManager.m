//
//  SocketManager.m
//  SocketGizmo
//
//  Created by Kevin Jenkins on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SocketManager.h"

NSString *const SMSendData = @"SocketManagerSendDataNotificationRequest";
NSString *const SMSendString = @"SocketManagerSendStringNotification";
NSString *const SMRecCmd = @"SocketManagerRecievedCommandNotification";
NSString *const SMRecData = @"SocketManagerRecievedDataNotification";
NSString *const SMDataKey = @"SocketManagerNotificationDataKey";
NSString *const SMConnectionFail = @"SocketManagerConnectionFailNotification";
NSString *const SMConnectionTimeOut = @"SocketManagerConnectionTimeOutNotification";


@interface SocketManager (hidden)
- (void) registerNotifications;
- (void) handleData:(NSData *) data;
- (void) handleInputData:(NSData *) data;
- (void) postSocketStringNotification:(NSString *) str;
- (void) stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent;
- (void) handleSendDataNotification:(NSNotification *) notification;
- (void) handleSendStringNotification:(NSNotification *) notification;

@end

@implementation SocketManager (hidden)
- (void) registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSendDataNotification:) name:SMSendData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSendStringNotification:) name:SMSendString object:nil];
}
- (void) handleInputData:(NSData *) data {
    int pointer = 0;
    uint8_t bytes[1024];
    [data getBytes:bytes length:[data length]];
    int len = [data length];
    
    while (pointer < len) {
        
        if (bytes[pointer] == 0x00) {
            
            // first command might null, ignore and advance
            // post the command, in case we care...
            unsigned char* d = &bytes[pointer];
            //NSString *str = [[NSString alloc] initWithBytes:d length:4 encoding:NSASCIIStringEncoding];
            NSData *dataCommand = [NSData dataWithBytes:d length:1];
            //NSLog(@"CMD: %c%c%c", bytes[pointer], bytes[pointer+1], bytes[pointer+2])
            NSLog(@"CMD: %@", dataCommand);
            [[NSNotificationCenter defaultCenter] postNotificationName:SMRecCmd object:self userInfo:[NSDictionary dictionaryWithObject:dataCommand forKey:SMDataKey]];
            //[str release];
            pointer += 1;
            
        } else if (bytes[pointer] == 0xFF) {
            
            // tcp/ip command is probably 3 bytes, ignore it.
            unsigned char* d = &bytes[pointer];
            //NSString *str = [[NSString alloc] initWithBytes:d length:3 encoding:NSASCIIStringEncoding];
            NSData *dataCommand = [NSData dataWithBytes:d length:3];
            NSLog(@"CMD: %@", dataCommand);
            [[NSNotificationCenter defaultCenter] postNotificationName:SMRecCmd 
                                                                object:self 
                                                              userInfo:[NSDictionary dictionaryWithObject:dataCommand forKey:SMDataKey]];            
            pointer += 3;
                
        } else {

            // encode as ascii?
            unsigned char* dData = &bytes[pointer];
            NSData *d2 = [NSData dataWithBytes:dData length:len-pointer];
            
            //NSLog(@"Data Length: %i", len-pointer);
            
            NSString *str = [[NSString alloc] initWithBytes:d2 length:[d2 length] encoding:NSASCIIStringEncoding];
            NSString *str2 = [[NSString alloc] initWithBytes:[d2 bytes] length:[d2 length] encoding:NSASCIIStringEncoding];
            //NSLog(@"Data(length: %i): %@", len-pointer, d2);
            //NSLog(@"Bytes: %@", d);
            //NSLog(@"String: %@", str2);
            [self postSocketStringNotification:str2];
            //[str release];
            pointer += len-pointer;
            [str release];
            [str2 release];
            //[d2 release];
        }
        
    }

}
- (void) handleData:(NSData *) data {
    
    int pointer = 0;
    uint8_t bytes[1024];
    [data getBytes:bytes length:[data length]];
    int len = [data length];
    
    NSLog(@"Handling %i bytes :: %@", len, data);
    
    while (pointer < len) {
        
        if (bytes[pointer] == 0xFF) {
            
            NSLog(@"CMD: %c%c%c", bytes[pointer], bytes[pointer+1], bytes[pointer+2]);
            // commands are 3 bytes, ignore and advance
            pointer += 3;
            connected = YES;
            
        } else {
            NSLog(@"WE HAVE DATA!");
            // encode as ascii?
            unsigned char* data = &bytes[pointer];
            //NSData *d = [NSData dataWithBytes:data length:len-pointer];
            NSString *str = [[NSString alloc] initWithBytes:data length:len-pointer encoding:NSASCIIStringEncoding];
            //NSLog(@"Data(length: %i): %@", len-pointer, str);
            //NSLog(@"Bytes: %@", d);
            [str release];
            pointer += len-pointer;
        }
        
    }
        

    
}
- (void) postSocketStringNotification:(NSString *) str {
    
    NSDictionary *info = [NSDictionary dictionaryWithObject:str forKey:SMDataKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:SMRecData object:self userInfo:info];
}

/** Major Stream Update Method **/
- (void) stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
	if (theStream == input)
        if (!silent) NSLog(@"input stream event %i", streamEvent);
    else
        if (!silent) NSLog(@"output stream event %i", streamEvent);
    
    switch (streamEvent) {
            
		case NSStreamEventOpenCompleted:
			if (!silent) NSLog(@"Stream opened");
			break;
            
		case NSStreamEventHasBytesAvailable:
            
            if (!silent) NSLog(@"Stream[%@] has bytes!", theStream);
            
            if (theStream == input) {
                
                uint8_t buffer[1024];
                int len;
                    
                /*
                if (![input hasBytesAvailable]) {
                    
                    // we were sent a null byte!
                    len = [input read:buffer maxLength:sizeof(buffer)];
                    NSData *d = [NSData dataWithBytes:buffer length:len];
                    if (!silent) NSLog(@"Recieved...: %@", d);
                    [self handleInputData:d];
                }
                 */
                
                while ([input hasBytesAvailable]) {
                    len = [input read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSData *d = [NSData dataWithBytes:buffer length:len];
                        if (!silent) NSLog(@"Recieved: %@", d);
                        [self handleInputData:d];
                        
                        
                    }
                }
            }
            
			break;		
            
            
        case NSStreamEventHasSpaceAvailable:
            
            if (theStream == output) {
                
                NSStreamStatus s = [output streamStatus];
                if (!silent) NSLog(@"Status Before Send: %d", s);
                
                if (dataToWrite != nil) {
                    int status = (NSInteger)[output write:[dataToWrite bytes] maxLength:[dataToWrite length]];                
                    if (!silent) NSLog(@"Sent Data: %@ \n Status: %d", dataToWrite, status);
                    [dataToWrite release];
                    dataToWrite = nil;
                }
                
                
            }
            
            
            break;
            
            
		case NSStreamEventErrorOccurred:
			if (!silent) NSLog(@"Can not connect to the host!");
            [[NSNotificationCenter defaultCenter] postNotificationName:SMConnectionFail object:self userInfo:nil];
			break;
            
		case NSStreamEventEndEncountered:
            if (!silent) NSLog(@"Done with %@", theStream);
            [[NSNotificationCenter defaultCenter] postNotificationName:SMConnectionTimeOut object:self userInfo:nil];
			break;
            
		default:
			if (!silent) NSLog(@"Unknown event");
	}
}
/** ========================== **/

#pragma mark Notification Handling -
- (void) handleSendDataNotification:(NSNotification *) notification {
    NSData *data = [[notification userInfo] objectForKey:SMDataKey];
    [self sendData:data];
}
- (void) handleSendStringNotification:(NSNotification *) notification {
    NSString *string = [[notification userInfo] objectForKey:SMDataKey];
    [self sendString:string];
}
#pragma mark -
@end

@implementation SocketManager

#pragma mark Creation and Destruction Methods -
- (id) init {
    if (( self = [super init] )) {
        
        [self setup];
        
        // The SocketManager listens for notifications to send strings and data.
        [self registerNotifications];
        return self;
        
    } else {
        return nil;
    }
}
+ (id) manager {
    return [[[SocketManager alloc] init] autorelease];
}
- (void) setup {
    // default
    
    // Default Values (should be changed in the future)
    serverAddress = @"127.0.0.1";
    port = 23; // telnet
    
    // Determines if we want SocketManager to dump info in NSLogs
    silent = YES; 
    
    connected = NO;
    
    
    // commonly used bytes
    unsigned char myCR[1] = { 0x0D };
    cr = [[NSString alloc] initWithBytes:myCR length:1 encoding:NSASCIIStringEncoding];

}
- (void) dealloc {
    
    // Retires the streams.
    [input removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [output removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    if (serverAddress != nil) { [serverAddress release]; serverAddress = nil; }
    if (input != nil) { [input release]; input = nil; }
    if (output != nil) { [output release]; output = nil; }
    if (dataToWrite != nil) { [dataToWrite release]; dataToWrite = nil; }
    
    
    [super dealloc];
}
#pragma mark -

#pragma mark Socket Setup Methods -
- (void) setServer:(NSString *) domain {
    serverAddress = [domain retain];
}
- (void) setPort:(int) p {
    port = p;
}
#pragma mark -

#pragma mark Socket Interaction Methods -
- (void) connectToServer {
    
    // Creates the input and output streams (Thanks Ray Wenderlich!)
    
    if (input != nil) { [input release]; input = nil; }
    if (output != nil) { [output release]; output = nil; }
    
    connected = NO;
    silent = YES;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (CFStringRef)serverAddress, port, &readStream, &writeStream);
    input = (NSInputStream *)readStream;
    output = (NSOutputStream *)writeStream;
    
    [input setProperty:NSStreamSocketSecurityLevelNone forKey:NSStreamSocketSecurityLevelKey];
    
    [input setDelegate:self];
    [output setDelegate:self];
    
    [input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [input open];
    [output open];
    
}
- (void) sendString:(NSString *) string {
    
    // appends a carriage return to the data so that you don't have to when sending a string.
    
	NSMutableData *data = [[NSMutableData alloc] initWithData:[string dataUsingEncoding:NSASCIIStringEncoding]];
    NSData *crData = [cr dataUsingEncoding:NSASCIIStringEncoding];
    
    [data appendBytes:[crData bytes] length:[crData length]];
    dataToWrite = nil;
    dataToWrite = [data retain];

    if ([output hasSpaceAvailable]) {
        [output write:[dataToWrite bytes] maxLength:[dataToWrite length]];
        if (!silent) NSLog(@"String sent: %@", string);
    } else {
        if (!silent) NSLog(@"Waiting for OutputStream space...");
    }
    [data release];
}
- (void) sendData:(NSData *) data {
    
    // appends a carriage return to the data
    NSMutableData *d2 = [NSMutableData dataWithData:data];
    NSData *crData = [cr dataUsingEncoding:NSASCIIStringEncoding];
    
    [d2 appendBytes:[crData bytes] length:[crData length]];

    
    dataToWrite = [d2 retain];
    
    if ([output hasSpaceAvailable]) {
        [output write:[dataToWrite bytes] maxLength:[dataToWrite length]];
        if (!silent) NSLog(@"Data Sent: %@ with size %i", d2, [d2 length]);          
    } else {
        if (!silent) NSLog(@"Waiting for OutputStream space...");
    }
    
}
#pragma mark -

@end
