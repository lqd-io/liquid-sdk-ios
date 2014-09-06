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
#import "NSDateFormatter+LQDateFormatter.h"
#import "OHHTTPStubs.h"
#import <OCMock/OCMock.h>

SPEC_BEGIN(LiquidSpec)

describe(@"Liquid", ^{
    let(deviceId, ^id{
        return [LQDevice uid];
    });

    beforeAll(^{
        [Liquid stub:@selector(archiveQueue:forToken:) andReturn:nil];
        [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
        [LQDevice stub:@selector(appName) andReturn:@"LiquidTest"];
        [LQDevice stub:@selector(appBundle) andReturn:kLQBundle];
        [LQDevice stub:@selector(appVersion) andReturn:@"9.9"];
        [LQDevice stub:@selector(releaseVersion) andReturn:@"9.8"];

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.path hasPrefix:@"/collect/users/"] && [request.URL.path hasSuffix:[NSString stringWithFormat:@"/devices/%@/liquid_package", deviceId]];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            NSString *fixture = OHPathForFileInBundle(@"liquid_package_targets.json", nil);
            return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
        }];

        [Liquid softReset];
    });

    describe(@"aliasUser:withIdentifier:", ^{
        context(@"given a Liquid instance", ^{
            __block Liquid *liquid;

            beforeEach(^{
                liquid = [[Liquid alloc] initWithToken:@"abcdef"];
                [liquid stub:@selector(saveCurrentUserToDisk) andReturn:nil];
                [liquid stub:@selector(loadLastUserFromDisk) andReturn:nil];
            });

            it(@"should not create an identified user with if the ID is an auto generated ID", ^{
                dispatch_queue_t queue1 = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_CONCURRENT);
                __block NSNumber *failed = @NO;
                for(NSInteger i = 0; i < 100; i++) {
                    dispatch_async(queue1, ^{
                        [liquid resetUser];
                        [liquid identifyUserWithIdentifier:@"123" attributes:@{ @"age": @23 } alias:NO];
                        [liquid aliasUser];
                        if (liquid.previousUser.isIdentified || [liquid.previousUser.identifier isEqualToString:@"123"]) {
                            @synchronized(failed) {
                                failed = @YES;
                            }
                        }
                    });
                }
                [[failed should] equal:@NO];
            });
        });
    });

    describe(@"liquidUserAgent", ^{
        it(@"should return a valid User-Agent", ^{
            [Liquid stub:@selector(liquidVersion) andReturn:@"0.8.0-beta"];
            [LQDevice stub:@selector(systemVersion) andReturn:@"7.1"];
            [LQDevice stub:@selector(systemLanguage) andReturn:@"en"];
            [LQDevice stub:@selector(locale) andReturn:@"pt_PT"];
            [LQDevice stub:@selector(deviceModel) andReturn:@"iPhone5,2"];
            Liquid *liquid = [[Liquid alloc] initWithToken:@"1234567890"];
            [[[liquid liquidUserAgent] should] equal:@"Liquid/0.8.0-beta (iOS; iOS 7.1; pt_PT; iPhone5,2)"];
        });
    });

    describe(@"applicationWillEnterForeground:", ^{
        context(@"given a Liquid instance", ^{
            __block Liquid *liquid;

            beforeAll(^{
                liquid = [[Liquid alloc] initWithToken:@"12345678901234567890abcdef"];
                [liquid identifyUser];
                [liquid setSessionTimeout:1.5f];
                [liquid stub:@selector(flush) andReturn:nil];
                [liquid stub:@selector(flush)];
                [liquid stub:@selector(beginBackgroundUpdateTask)];
                [liquid stub:@selector(track:attributes:allowLqdEvents:)];
                [NSThread sleepForTimeInterval:1.0f];
            });

            context(@"given an app that is in background for less than the timeout time", ^{
                __block NSString *previousUserId;
                __block NSString *previousSessionId;

                beforeEach(^{
                    previousUserId = [liquid userIdentifier];
                    previousSessionId = [liquid sessionIdentifier];

                    [NSThread sleepForTimeInterval:0.2f];
                    [liquid applicationDidEnterBackground:nil];
                    [NSThread sleepForTimeInterval:0.25f];
                    [liquid applicationWillEnterForeground:nil];
                    [NSThread sleepForTimeInterval:0.2f];
                });

                it(@"should keep the previous Session ID", ^{
                    [[[liquid sessionIdentifier] should] equal:(NSString *)previousSessionId];
                });
            });

            context(@"given an app that is in background for more than the timeout time", ^{
                __block NSString *previousUserId;
                __block NSString *previousSessionId;

                beforeEach(^{
                    previousUserId = [liquid userIdentifier];
                    previousSessionId = [liquid sessionIdentifier];

                    [NSThread sleepForTimeInterval:0.1f];
                    [liquid applicationDidEnterBackground:nil];
                    [NSThread sleepForTimeInterval:3.0f];
                    [liquid applicationWillEnterForeground:nil];
                    [NSThread sleepForTimeInterval:0.1f];
                });

                it(@"should create a new Session ID", ^{
                    [[[liquid sessionIdentifier] shouldNot] equal:(NSString *)previousSessionId];
                });
            });
        });
    });

    describe(@"track:", ^{
        it(@"should identify User (anonymous) with the automatically generated identifier", ^{
            Liquid *liquidInstance = [[Liquid alloc] initWithToken:@"abcdef123456"];
            [liquidInstance stub:@selector(flush) andReturn:nil];
            [liquidInstance stub:@selector(flush)];
            [liquidInstance track:@"openApplication"];
            [[liquidInstance.userIdentifier shouldNot] equal:@"abcdef123456"];
        });
    });

    describe(@"identifyUserWithIdentifier:", ^{
        it(@"should identify User with the correct identifier", ^{
            Liquid *liquidInstance = [[Liquid alloc] initWithToken:@"abcdef123456"];
            [liquidInstance stub:@selector(flush) andReturn:nil];
            [liquidInstance stub:@selector(flush)];
            [liquidInstance identifyUserWithIdentifier:@"john"];
            [[liquidInstance.userIdentifier should] equal:@"john"];
        });

        it(@"should keep the correct identifier after 1 second", ^{
            Liquid *liquidInstance = [[Liquid alloc] initWithToken:@"abcdef123456"];
            [liquidInstance stub:@selector(flush) andReturn:nil];
            [liquidInstance stub:@selector(flush)];
            [liquidInstance identifyUserWithIdentifier:@"john"];
            [NSThread sleepForTimeInterval:1.0f];
            [[liquidInstance.userIdentifier should] equal:@"john"];
        });
    });

    describe(@"identifyUserSynced:alias:", ^{
        context(@"given a Liquid singleton", ^{
            __block __strong Liquid *liquidInstance;
            __block NSString *userId;
            __block NSString *sessionId;

            beforeEach(^{
                [Liquid softReset];
                liquidInstance = [[Liquid alloc] initWithToken:@"12345678901234567890abcdef"];
                [liquidInstance stub:@selector(flush)];
                [liquidInstance identifyUserWithIdentifier:@"123"];
            });

            context(@"given reiniting Liquid instance", ^{
                beforeEach(^{
                    [NSThread sleepForTimeInterval:0.5f]; // Wait to save last user cache to disk
                    liquidInstance = [[Liquid alloc] initWithToken:@"12345678901234567890abcdef"];
                    [liquidInstance stub:@selector(flush)];
                    userId = [[liquidInstance userIdentifier] copy];
                    sessionId = [[liquidInstance sessionIdentifier] copy];
                });

                context(@"given identifying again with the same unique_id", ^{
                    beforeEach(^{
                        [liquidInstance identifyUserWithIdentifier:@"123"];
                    });

                    it(@"should keep the same user identifier", ^{
                        [[[liquidInstance userIdentifier] should] equal:userId];
                    });

                    it(@"should keep the same session identifier", ^{
                        [[[liquidInstance sessionIdentifier] should] equal:sessionId];
                    });
                });

                context(@"given identifying again with a different unique_id", ^{
                    beforeEach(^{
                        [liquidInstance identifyUserWithIdentifier:@"124"];
                    });

                    it(@"should use the new user identifier", ^{
                        [[[liquidInstance userIdentifier] should] equal:@"124"];
                    });

                    it(@"should create a new session identifier", ^{
                        [[[liquidInstance sessionIdentifier] shouldNot] equal:sessionId];
                    });
                });
            });

            context(@"given an anonymous user", ^{
                beforeEach(^{
                    [liquidInstance resetUser];
                });

                it(@"should alias user by default", ^{
                    [[[liquidInstance should] receive] aliasUser];
                    [liquidInstance identifyUserWithIdentifier:@"123"];
                });

                it(@"should alias user when alias:YES", ^{
                    [[[liquidInstance should] receive] aliasUser];
                    [liquidInstance identifyUserWithIdentifier:@"123" alias:YES];
                });

                it(@"should not alias when alias:NO", ^{
                    [[[liquidInstance shouldNot] receive] aliasUser];
                    [liquidInstance identifyUserWithIdentifier:@"123" alias:NO];
                });
            });

            context(@"given an identified user", ^{
                beforeEach(^{
                    [liquidInstance identifyUserWithIdentifier:@"123"];
                });

                it(@"should not alias the same user", ^{
                    [[[liquidInstance shouldNot] receive] aliasUser];
                    [liquidInstance identifyUserWithIdentifier:@"123"];
                });
            });
        });

        context(@"given a Liquid instance", ^{
            let(liquid, ^id{ return [[Liquid alloc] initWithToken:@"abcdef"]; });

            it(@"should not create an identified user with if the ID is an auto generated ID", ^{
                dispatch_queue_t queue1 = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_CONCURRENT);
                BOOL failed;
                for(NSInteger i = 0; i < 200; i++) {
                    LQUser *user = [[LQUser alloc] initWithIdentifier:@"123" attributes:@{ @"age": @32 }];
                    dispatch_async(queue1, ^{
                        [liquid identifyUserSynced:user alias:NO];
                    });
                }
                [[theValue(failed) should] beNo];
            });
        });
    });
});

SPEC_END
