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
#import "LQNetworkingPrivates.h"

SPEC_BEGIN(LiquidSpec)

describe(@"Liquid", ^{
    beforeEach(^{
        [Liquid softReset];
    });

    let(deviceId, ^id{
        return [[LQDevice sharedInstance] uid];
    });

    beforeAll(^{
        [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
        [LQDevice stub:@selector(appName) andReturn:@"LiquidTest"];
        [LQDevice stub:@selector(appBundle) andReturn:kLQBundle];
        [LQDevice stub:@selector(appVersion) andReturn:@"9.9"];
        [LQDevice stub:@selector(releaseVersion) andReturn:@"9.8"];
        [LQDevice stub:@selector(uniqueId) andReturn:deviceId];

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return [request.URL.path hasPrefix:@"/collect/users/"] && [request.URL.path hasSuffix:[NSString stringWithFormat:@"/devices/%@/liquid_package", deviceId]];
        } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
            NSString *fixture = OHPathForFileInBundle(@"liquid_package_targets.json", nil);
            return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
        }];

        [Liquid softReset];
    });

    describe(@"aliasUser", ^{
        context(@"given a Liquid instance", ^{
            __block Liquid *liquid = [[Liquid alloc] initWithToken:@"liquid_tests"];

            context(@"given identifying anonymously", ^{
                beforeEach(^{
                    [liquid resetUser];
                });

                it(@"should not alias user", ^{
                    [[liquid shouldNot] receive:@selector(aliasUser:withIdentifier:)];
                    [liquid aliasUser];
                });
            });
        });
    });

    describe(@"aliasUser:withIdentifier:", ^{
        context(@"given a Liquid instance", ^{
            __block Liquid *liquid;

            beforeEach(^{
                liquid = [[Liquid alloc] initWithToken:@"liquid_tests"];
                [liquid stub:@selector(saveCurrentUserToDisk) andReturn:nil];
                [LQUser stub:@selector(unarchiveUserForToken:) andReturn:nil];
            });

            it(@"should not create an identified user with if the ID is an auto generated ID", ^{
                dispatch_queue_t queue = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_SERIAL);
                __block NSNumber *failed = @NO;
                for(NSInteger i = 0; i < 10; i++) {
                    dispatch_async(queue, ^{
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
                [[expectFutureValue(failed) shouldNotEventuallyBeforeTimingOutAfter(10)] equal:@YES];
            });
        });
    });

    describe(@"applicationWillEnterForeground:", ^{
        context(@"given a Liquid instance", ^{
            __block Liquid *liquid;

            beforeAll(^{
                liquid = [[Liquid alloc] initWithToken:@"liquid_tests"];
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
            Liquid *liquidInstance = [[Liquid alloc] initWithToken:@"liquid_tests"];
            [liquidInstance stub:@selector(flush) andReturn:nil];
            [liquidInstance stub:@selector(flush)];
            [liquidInstance track:@"openApplication"];
            [[liquidInstance.userIdentifier shouldNot] equal:@"abcdef123456"];
        });
    });

    describe(@"identifyUserWithIdentifier:", ^{
        it(@"should identify User with the correct identifier", ^{
            Liquid *liquidInstance = [[Liquid alloc] initWithToken:@"liquid_tests"];
            [liquidInstance stub:@selector(flush) andReturn:nil];
            [liquidInstance stub:@selector(flush)];
            [liquidInstance identifyUserWithIdentifier:@"john"];
            [[liquidInstance.userIdentifier should] equal:@"john"];
        });

        it(@"should keep the correct identifier after 1 second", ^{
            Liquid *liquidInstance = [[Liquid alloc] initWithToken:@"liquid_tests"];
            [liquidInstance stub:@selector(flush) andReturn:nil];
            [liquidInstance stub:@selector(flush)];
            [liquidInstance identifyUserWithIdentifier:@"john"];
            [NSThread sleepForTimeInterval:1.0f];
            [[liquidInstance.userIdentifier should] equal:@"john"];
        });
    });

    describe(@"identifyUserWithIdentifier:", ^{
        context(@"given a Liquid instance with an identified user", ^{
            __block Liquid *liquidInstance;

            beforeEach(^{
                liquidInstance = [[Liquid alloc] initWithToken:@"liquid_tests"];
                [liquidInstance identifyUserWithIdentifier:@"123" attributes:nil];
            });

            it(@"should set the correct user identifier", ^{
                [[liquidInstance.currentUser.identifier should] equal:@"123"];
            });

            it(@"should not call identifyUser:", ^{
                [[liquidInstance shouldNot] receive:@selector(identifyUser:alias:)];
                [liquidInstance identifyUserWithIdentifier:nil attributes:nil];
            });

            context(@"given identifying the user with a nil identifier", ^{
                beforeEach(^{
                    [liquidInstance identifyUserWithIdentifier:nil attributes:nil];
                });

                it(@"should not change the identifier (an error in logs is given)", ^{
                    [[liquidInstance.currentUser.identifier should] equal:@"123"];
                });

                it(@"should not call identifyUser: if called multiple times", ^{
                    [[liquidInstance shouldNot] receive:@selector(identifyUser:alias:)];
                    [liquidInstance identifyUserWithIdentifier:nil attributes:nil];
                });
            });
        });
    });

    describe(@"resetUser:", ^{
        context(@"given a Liquid instance with an identified user", ^{
            __block Liquid *liquidInstance;

            let(identifiedUserUniqueId, ^id{
                return @"123";
            });

            beforeEach(^{
                liquidInstance = [[Liquid alloc] initWithToken:@"liquid_tests"];
                [liquidInstance identifyUserWithIdentifier:identifiedUserUniqueId attributes:nil];
            });

            it(@"should call identifyUser:", ^{
                [[liquidInstance should] receive:@selector(identifyUser:alias:)];
                [liquidInstance resetUser];
            });

            it(@"should change the user identifier to a new one", ^{
                [liquidInstance resetUser];
                [[[liquidInstance userIdentifier] shouldNot] equal:identifiedUserUniqueId];
            });

            it(@"should change the user identifier to an anonymous one", ^{
                [liquidInstance resetUser];
                [[theValue([[liquidInstance currentUser] isAnonymous]) should] beYes];
            });

            it(@"should not create another anonymous user uniqueId if called multiple times", ^{
                [liquidInstance resetUser];
                NSString *anonymousUserIdentifier = [[liquidInstance userIdentifier] copy];
                [liquidInstance resetUser];
                [[[liquidInstance userIdentifier] should] equal:anonymousUserIdentifier];
            });

            it(@"should not call aliasUser method", ^{
                [[liquidInstance shouldNot] receive:@selector(aliasUser)];
                [liquidInstance resetUser];
            });
        });
    });

    describe(@"identifyUser:alias:", ^{
        context(@"given a Liquid singleton", ^{
            __block __strong Liquid *liquidInstance;
            __block NSString *userId;
            __block NSString *sessionId;

            beforeEach(^{
                [Liquid softReset];
                liquidInstance = [[Liquid alloc] initWithToken:@"liquid_tests"];
                [liquidInstance stub:@selector(flush)];
                [liquidInstance identifyUserWithIdentifier:@"123"];
            });

            context(@"given reiniting Liquid instance", ^{
                beforeEach(^{
                    [NSThread sleepForTimeInterval:0.5f]; // Wait to save last user cache to disk
                    liquidInstance = [[Liquid alloc] initWithToken:@"liquid_tests"];
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

                    it(@"should not create a new session identifier", ^{
                        [[[liquidInstance sessionIdentifier] should] equal:sessionId];
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
            let(liquid, ^id{ return [[Liquid alloc] initWithToken:@"liquid_tests"]; });

            it(@"should not create anonymous users if all users have an user identifier", ^{
                dispatch_queue_t queue = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_SERIAL);
                __block NSNumber *failed = @NO;
                for(NSInteger i = 0; i < 10; i++) {
                    dispatch_async(queue, ^{
                        Liquid *liquidInstance = liquid;
                        LQUser *user = [[LQUser alloc] initWithIdentifier:@"123" attributes:@{ @"age": @32 }];
                        [liquidInstance identifyUser:user alias:NO];
                        if ([liquidInstance.currentUser isAnonymous]) {
                            @synchronized(failed) {
                                failed = @YES;
                            }
                        }
                    });
                }
                [[expectFutureValue(failed) shouldNotEventuallyBeforeTimingOutAfter(10)] equal:@YES];
            });
        });
    });

    describe(@"softReset:", ^{
        context(@"given a Liquid instance", ^{
            __block Liquid *liquid = [[Liquid alloc] initWithToken:@"liquid_tests"];

            it(@"should change the User Unqiue ID to a new one", ^{
                [liquid identifyUserWithIdentifier:@"previous-unique-id"];
                [Liquid softReset];
                [[[liquid userIdentifier] shouldNot] equal:@"previous-unique-id"];
            });

            it(@"should change the User Unqiue ID to a new one", ^{
                NSString *previousSessionId = [liquid sessionIdentifier];
                [Liquid softReset];
                [[[liquid userIdentifier] shouldNot] equal:previousSessionId];
            });
        });
    });

    describe(@"setUserAttributes:", ^{
        context(@"given a Liquid instance", ^{
            __block Liquid *liquid = [[Liquid alloc] initWithToken:@"liquid_tests"];

            it(@"should keep the same User Unique ID", ^{
                [liquid identifyUserWithIdentifier:@"previous-unique-id"];
                [liquid setUserAttributes:@{ @"new-attribute": @123 }];
                [[[liquid userIdentifier] should] equal:@"previous-unique-id"];
            });

            context(@"given a user with an attribute", ^{
                beforeEach(^{
                    liquid.currentUser.attributes = @{ @"age": @10 };
                });

                it(@"should add the new user attribute", ^{
                    [liquid setUserAttributes:@{ @"country": @"france" }];
                    [[[liquid.currentUser.attributes objectForKey:@"country"] should] equal:@"france"];
                });

                it(@"should keep the other attributes", ^{
                    [liquid setUserAttributes:@{ @"country": @"france" }];
                    [[[liquid.currentUser.attributes objectForKey:@"age"] should] equal:@10];
                });

                it(@"should override an existing attribute", ^{
                    [liquid setUserAttributes:@{ @"age": @30 }];
                    [[[liquid.currentUser.attributes objectForKey:@"age"] should] equal:@30];
                });
            });
        });
    });
});

SPEC_END
