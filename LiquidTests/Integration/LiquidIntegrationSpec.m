#import "Kiwi.h"
#import "LiquidPrivates.h"
#import "OHHTTPStubs.h"
#import "NSString+LQString.h"
#import "LQDevice.h"
#import <OCMock/OCMock.h>
#import "LQDefaults.h"
#import "LQNetworkingPrivates.h"

SPEC_BEGIN(LiquidIntegrationSpec)

describe(@"Liquid", ^{
    beforeEach(^{
        [Liquid softReset];
    });

    let(deviceId, ^id{
        return [[LQDevice sharedInstance] uid];
    });

    context(@"given a Liquid Package with 2 variables", ^{
        beforeAll(^{
            [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
            [LQDevice stub:@selector(appName) andReturn:[@"LiquidTest" copy]];
            [LQDevice stub:@selector(appBundle) andReturn:[kLQBundle copy]];
            [LQDevice stub:@selector(appVersion) andReturn:[@"9.9" copy]];
            [LQDevice stub:@selector(releaseVersion) andReturn:[@"9.8" copy]];
            [LQDevice stub:@selector(uniqueId) andReturn:deviceId];

            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return [request.URL.path hasPrefix:@"/collect/users/"] && [request.URL.path hasSuffix:[NSString stringWithFormat:@"/devices/%@/liquid_package", deviceId]];
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                NSString *fixture = OHPathForFileInBundle(@"liquid_package1.json", nil);
                return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
            }];
        });

        context(@"given a Liquid instance with an anonymous user", ^{
            let(liquid, ^id{ return [[Liquid alloc] initWithToken:@"liquid_tests"]; });

            beforeEach(^{
                [liquid stub:@selector(flush) andReturn:nil];
            });

            context(@"given the very first launch of the app", ^{
                it(@"should use fallback values", ^{
                    [[[liquid stringForKey:@"welcomeText" fallback:@"Fallback text"] should] equal:@"Fallback text"];
                });
            });

            context(@"given the second launch of the app (with 2 variables loaded in memory)", ^{
                beforeAll(^{
                    // Simulate an app going in background and foreground again:
                    [NSThread sleepForTimeInterval:0.1f];
                    [liquid applicationDidEnterBackground:nil];
                    [liquid applicationWillEnterForeground:nil];
                    [NSThread sleepForTimeInterval:0.1f];
                });

                it(@"should use a variable from the Liquid Package if it matches name and type", ^{
                    NSString *fallbackValue = @"A fallback value";
                    NSString *serverValue = @"Be very welcome";
                    NSString *title = [liquid stringForKey:@"welcomeMessage" fallback:fallbackValue];
                    [[title should] equal:serverValue];
                });
                
                it(@"should use the fallback value if the variable from the Liquid Package if data type doesn't match", ^{
                    NSString *fallbackValue = @"Welcome to Liquid";
                    NSString *title = [liquid stringForKey:@"discount" fallback:fallbackValue];
                    [[title should] equal:fallbackValue];
                });
                
                it(@"should use the fallback value if the variable from the Liquid Package if variable does not exist", ^{
                    NSString *fallbackValue = @"A fallback value";
                    NSString *title = [liquid stringForKey:@"anUnkownVariable" fallback:fallbackValue];
                    [[title should] equal:fallbackValue];
                });
            });
        });

        context(@"given a Liquid Package with an identified user", ^{
            __block Liquid *liquid;

            beforeEach(^{
                liquid = [[Liquid alloc] initWithToken:@"liquid_tests"];
                [liquid stub:@selector(flush) andReturn:nil];
                [liquid.networking stub:@selector(flush)];
                [liquid.networking stub:@selector(archiveHttpQueue)];

                // Simulate an app going in background and foreground again:
                [NSThread sleepForTimeInterval:0.1f];
                [liquid applicationDidEnterBackground:nil];
                [liquid applicationWillEnterForeground:nil];
                [NSThread sleepForTimeInterval:0.1f];
            });

            it(@"should be possible to perform multiple operations simultaneously, without race conditions", ^{
                __block NSNumber *totalOfBlocks = @0;
                dispatch_queue_t serialQueue = dispatch_queue_create([@"serial" UTF8String], DISPATCH_QUEUE_SERIAL);
                for(NSInteger i = 0; i < 20; i++) {
                    dispatch_async(serialQueue, ^{
                        [liquid applicationDidEnterBackground:nil];
                        [NSThread sleepForTimeInterval:0.25f];
                        [liquid applicationWillEnterForeground:nil];
                        @synchronized(totalOfBlocks) {
                            totalOfBlocks = [NSNumber numberWithInt:([totalOfBlocks intValue] + 1)];
                        }
                    });
                }
                for(NSInteger i = 0; i < 20; i++) {
                    dispatch_async(serialQueue, ^{
                        [NSThread sleepForTimeInterval:0.1f];
                        @synchronized(totalOfBlocks) {
                            totalOfBlocks = [NSNumber numberWithInt:([totalOfBlocks intValue] + 1)];
                        }
                    });
                }
                for(NSInteger i = 0; i < 20; i++) {
                    dispatch_async(serialQueue, ^{
                        [liquid requestValues];
                        @synchronized(totalOfBlocks) {
                            totalOfBlocks = [NSNumber numberWithInt:([totalOfBlocks intValue] + 1)];
                        }
                    });
                }
                for(NSInteger i = 0; i < 20; i++) {
                    dispatch_async(serialQueue, ^{
                        [liquid loadValues];
                        @synchronized(totalOfBlocks) {
                            totalOfBlocks = [NSNumber numberWithInt:([totalOfBlocks intValue] + 1)];
                        }
                    });
                }
                for(NSInteger i = 0; i < 20; i++) {
                    dispatch_async(serialQueue, ^{
                        [liquid stringForKey:@"welcomeText" fallback:@"A fallback value"];
                        @synchronized(totalOfBlocks) {
                            totalOfBlocks = [NSNumber numberWithInt:([totalOfBlocks intValue] + 1)];
                        }
                    });
                }
                for(NSInteger i = 0; i < 20; i++) {
                    dispatch_async(serialQueue, ^{
                        [liquid stringForKey:@"unknownVariable" fallback:@"A fallback value"];
                        @synchronized(totalOfBlocks) {
                            totalOfBlocks = [NSNumber numberWithInt:([totalOfBlocks intValue] + 1)];
                        }
                    });
                }

                [[expectFutureValue(totalOfBlocks) shouldEventuallyBeforeTimingOutAfter(20.0f)] equal:[NSNumber numberWithInt:120]];
            });
        });
    });
});

SPEC_END
