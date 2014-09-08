//
//  Liquid.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 03/06/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Kiwi/Kiwi.h>

#import "LQDataPoint.h"
#import "LQDefaults.h"
#import "LQUser.h"
#import "LQDevice.h"
#import "LQSession.h"
#import "LQEvent.h"

SPEC_BEGIN(LQDataPointSpec)

describe(@"LQDataPoint", ^{
    context(@"given a DataPoint with a user, a device, a session and an event", ^{
        __block LQDataPoint *dataPoint;

        beforeEach(^{
            LQUser *user = [[LQUser alloc] initWithIdentifier:@"audreytautou@gmail.com" attributes:@{
                @"name": @"Audrey Tautou",
                @"age": [NSNumber numberWithInt:37]
            }];
            LQDevice *device = [[LQDevice alloc] init];
            LQSession *session = [[LQSession alloc] initWithDate:[NSDate date] timeout:[NSNumber numberWithInt:30]];
            LQEvent *event = [[LQEvent alloc] initWithName:@"Click Button" attributes:nil date:[NSDate date]];
            dataPoint = [[LQDataPoint alloc] initWithDate:event.date
                                                     user:user
                                                   device:device
                                                  session:session
                                                    event:event
                                                   values:nil];
        });

        it(@"should create a Data Point with the corrrect User unique identifier", ^{
            [[dataPoint.user.identifier should] equal:@"audreytautou@gmail.com"];
        });

        it(@"should create a Data Point with a device", ^{
            [[dataPoint.device shouldNot] equal:@"audreytautou@gmail.com"];
        });

        it(@"should create a Data Point with a Session", ^{
            [[dataPoint.session shouldNot] equal:@"audreytautou@gmail.com"];
        });

        it(@"should create a Data Point with the correct Event name", ^{
            [[dataPoint.event.name should] equal:@"Click Button"];
        });
    });

});

SPEC_END
