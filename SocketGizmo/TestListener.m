//
//  TestListener.m
//  SocketGizmo
//
//  Created by Kevin Jenkins on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

NSString *const TWGS_telnetDetected = @"Telnet connection detected.";
NSString *const TWGS_enterYourName = @"Please enter your name (ENTER for none):";


#import "TestListener.h"

@interface TestListener (hidden)
- (void) registerNotifications;
- (void) handleStringDataRecievedNotification:(NSNotification *) notification;
- (void) handleCommandRecievedNotification:(NSNotification *) notification;
- (NSString *) stringFromNotification:(NSNotification *) notification;
- (NSData *) dataFromNotification:(NSNotification *) notificaiton;

- (void) interpretTWGSString:(NSString *) str;
- (void) interpretTWGSData:(NSData *) data;

- (void) handleTWGSTelnetDetected:(NSNotification *) notification;
- (void) handleTWGSEnterYourName:(NSNotification *) notification;
@end

@implementation TestListener (hidden)
- (void) registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCommandRecievedNotification:) name:SMRecCmd object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStringDataRecievedNotification:) name:SMRecData object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTWGSTelnetDetected:) name:TWGS_telnetDetected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTWGSEnterYourName:) name:TWGS_enterYourName object:nil];
}
- (void) handleStringDataRecievedNotification:(NSNotification *) notification {
    NSString *data = [self stringFromNotification:notification];
    //NSLog(@"ASCII: %@", [data stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]);
    //NSLog(@"Recieved Data: %@", data);
    [self interpretTWGSString:data];
}
- (void) handleCommandRecievedNotification:(NSNotification *) notification {
    NSData *data = [self dataFromNotification:notification];
    NSLog(@"Recieved Command: %@", data);
    [self interpretTWGSData:data];
}
- (NSString *) stringFromNotification:(NSNotification *) notification {
    return [[notification userInfo] objectForKey:SMDataKey];
}
- (NSData *) dataFromNotification:(NSNotification *) notificaiton {
    return [[notificaiton userInfo] objectForKey:SMDataKey];
}


- (void) interpretTWGSString:(NSString *) str {
    
    //unsigned char telnetAck[4] = {0x00, 0xff, 0xfd, 0xf6 };
    
    NSArray *lines = [str componentsSeparatedByString:@"\n"];
    
    for (NSString *line in lines) {
        
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSLog(@"Line: %@", line);                
        
        if ([line isEqualToString:TWGS_telnetDetected]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:TWGS_telnetDetected object:self userInfo:nil];
        }
        
        if ([line isEqualToString:TWGS_enterYourName]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:TWGS_enterYourName object:self userInfo:nil];
        }
        
    }
    
    
}
- (void) interpretTWGSData:(NSData *) data {

    // We don't really care about commands that are not length 4.
    if ([data length] < 1) return;
    
    unsigned char buffer[[data length]];
    
    [data getBytes:buffer length:[data length]];

    // right now we only care about one command NULL IAC DOTEL YATHERE
    if (buffer[0] == 0x00) {
            
        // TWGS is asking us if we are rLogin or telnet, respond with telnet 0xff (not 0x00 for rLogin)
        
        NSLog(@"NULL recieved, send 255");
        
        unsigned char bs[1] = { 0xFF };
        NSData *d2 = [NSData dataWithBytes:bs length:1];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SMSendData object:self userInfo:[NSDictionary dictionaryWithObject:d2 forKey:SMDataKey]];

        
    } else if (buffer[0] == 0xFF && buffer[1] == 0xFD && buffer[2] == 0xF6) { 
        
        // TWGS IS IAC DOTEL YATHERE ing
        
    }
}
- (void) handleTWGSTelnetDetected:(NSNotification *) notification {
    NSLog(@"Telnet Detected!");
}
- (void) handleTWGSEnterYourName:(NSNotification *) notification {
    NSLog(@"Recieved ENTER YOUR NAME, Entering Kevin");
    [[NSNotificationCenter defaultCenter] postNotificationName:SMSendString object:self userInfo:[NSDictionary dictionaryWithObject:@"Kevin" forKey:SMDataKey]];
}
@end

@implementation TestListener

- (id) init {
    
    if (( self = [super init] )) {
        
        [self setup];
        [self registerNotifications];
        return self;
    } else {
        return nil;
    }
    
}
- (id) object {
    return [[[TestListener alloc] init] autorelease];
}
- (void) setup {
    
}
- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

@end
