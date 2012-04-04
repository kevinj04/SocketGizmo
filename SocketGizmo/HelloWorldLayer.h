//
//  HelloWorldLayer.h
//  SocketGizmo
//
//  Created by Kevin Jenkins on 3/23/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "SocketManager.h"
#import "TestListener.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
    SocketManager *manager;
    TestListener *listener;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
