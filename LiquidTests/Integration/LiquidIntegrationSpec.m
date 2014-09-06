#import "Kiwi.h"
#import "LiquidPrivates.h"
#import "OHHTTPStubs.h"
#import "NSString+LQString.h"
#import "LQDevice.h"
#import <OCMock/OCMock.h>
#import "LQDefaults.h"

SPEC_BEGIN(LiquidIntegrationSpec)

describe(@"Liquid", ^{
    let(deviceId, ^id{
        return [LQDevice uid];
    });

    context(@"given a Liquid Package with 2 variables", ^{
        beforeAll(^{
            [Liquid stub:@selector(archiveQueue:forToken:) andReturn:nil];
            [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
            [LQDevice stub:@selector(appName) andReturn:[@"LiquidTest" copy]];
            [LQDevice stub:@selector(appBundle) andReturn:[kLQBundle copy]];
            [LQDevice stub:@selector(appVersion) andReturn:[@"9.9" copy]];
            [LQDevice stub:@selector(releaseVersion) andReturn:[@"9.8" copy]];

            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return [request.URL.path hasPrefix:@"/collect/users/"] && [request.URL.path hasSuffix:[NSString stringWithFormat:@"/devices/%@/liquid_package", deviceId]];
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                NSString *fixture = OHPathForFileInBundle(@"liquid_package1.json", nil);
                return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
            }];
        });

        context(@"given a Liquid instance with an anonymous user", ^{
            let(liquid, ^id{ return [[Liquid alloc] initWithToken:@"12345678901234567890abcdef"]; });

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
            let(liquid, ^id{ return [[Liquid alloc] initWithToken:@"12345678901234567890abcdef"]; });

            beforeEach(^{
                [liquid stub:@selector(flush) andReturn:nil];
            });

            beforeAll(^{
                liquid = [[Liquid alloc] initWithToken:@"abcdef123456"];

                // Simulate an app going in background and foreground again:
                [NSThread sleepForTimeInterval:0.1f];
                [liquid applicationDidEnterBackground:nil];
                [liquid applicationWillEnterForeground:nil];
                [NSThread sleepForTimeInterval:0.1f];
            });

            it(@"should be possible to perform multiple operations simultaneously, without race conditions", ^{
                dispatch_queue_t queue1 = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_CONCURRENT);
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue1, ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [liquid applicationDidEnterBackground:nil];
                        });
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [liquid applicationWillEnterForeground:nil];
                        });
                    });
                }

                dispatch_queue_t queue2 = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_CONCURRENT);
                for(NSInteger i = 0; i < 20; i++) {
                    dispatch_async(queue2, ^{
                        [NSThread sleepForTimeInterval:0.1f];
                    });
                }

                dispatch_queue_t queue3 = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_CONCURRENT);
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue3, ^{
                        [liquid requestValues];
                    });
                }

                dispatch_queue_t queue4 = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_CONCURRENT);
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue4, ^{
                        [liquid loadValues];
                    });
                }

                dispatch_queue_t queue5 = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_CONCURRENT);
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue5, ^{
                        [liquid stringForKey:@"welcomeText" fallback:@"A fallback value"];
                    });
                }

                dispatch_queue_t queue6 = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_CONCURRENT);
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue6, ^{
                        [liquid stringForKey:@"unknownVariable" fallback:@"A fallback value"];
                    });
                }

                [NSThread sleepForTimeInterval:6.0f];
            });
        });
    });
});

SPEC_END
