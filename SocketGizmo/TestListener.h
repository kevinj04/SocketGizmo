//
//  TestListener.h
//  SocketGizmo
//
//  Created by Kevin Jenkins on 4/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

extern NSString *const TWGS_telnetDetected;
extern NSString *const TWGS_enterYourName;

#import <Foundation/Foundation.h>
#import "SocketManager.h"

@interface TestListener : NSObject {
    
}

- (id) init;
- (id) object;
- (void) setup;
- (void) dealloc;


@end
