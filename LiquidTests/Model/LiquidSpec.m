//
//  Liquid.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 03/06/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "LiquidPrivates.h"
#import "LQDevice.h"

SPEC_BEGIN(LiquidSpec)

describe(@"Liquid", ^{
    let(apiToken, ^id{
        return @"12345678901234567890abcdef";
    });
    
    let(deviceId, ^id{
        return [LQDevice uid];
    });
    
    let(userId, ^id{
        return @"444";
    });

    let(previousUserId, nil);

    let(previousSessionId, nil);

    beforeAll(^{
        [Liquid softReset];
        [Liquid sharedInstanceWithToken:apiToken];
        [[Liquid sharedInstance] identifyUserWithIdentifier:userId];
        [[Liquid sharedInstance] setSessionTimeout:1];
        [NSThread sleepForTimeInterval:1.0f];
    });

    describe(@"applicationDidBecomeActive:", ^{
        context(@"given an app that is in background for less than the timeout time", ^{
            beforeEach(^{
                previousUserId = [[Liquid sharedInstance] userIdentifier];
                previousSessionId = [[Liquid sharedInstance] sessionIdentifier];

                [NSThread sleepForTimeInterval:0.1f];
                [[Liquid sharedInstance] applicationWillResignActive:nil];
                [NSThread sleepForTimeInterval:0.25f];
                [[Liquid sharedInstance] applicationDidBecomeActive:nil];
                [NSThread sleepForTimeInterval:0.1f];
            });

            it(@"should keep the previous Session ID", ^{
                [[[[Liquid sharedInstance] sessionIdentifier] should] equal:(NSString *)previousSessionId];
            });
        });

        context(@"given an app that is in background for more than the timeout time", ^{
            beforeEach(^{
                previousUserId = [[Liquid sharedInstance] userIdentifier];
                previousSessionId = [[Liquid sharedInstance] sessionIdentifier];

                [NSThread sleepForTimeInterval:0.1f];
                [[Liquid sharedInstance] applicationWillResignActive:nil];
                [NSThread sleepForTimeInterval:2.0f];
                [[Liquid sharedInstance] applicationDidBecomeActive:nil];
                [NSThread sleepForTimeInterval:0.1f];
            });
            
            it(@"should keep the previous Session ID", ^{
                [[[[Liquid sharedInstance] sessionIdentifier] shouldNot] equal:(NSString *)previousSessionId];
            });
        });
    });
});

SPEC_END
