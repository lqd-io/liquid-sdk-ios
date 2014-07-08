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

        context(@"given a Liquid singleton with an auto identified user", ^{
            beforeAll(^{
                [Liquid softReset];
                [Liquid sharedInstanceWithToken:@"12345678901234567890abcdef"];
                [[Liquid sharedInstance] stub:@selector(flush) andReturn:nil];
                [[Liquid sharedInstance] setFlushOnBackground:NO];
            });

            context(@"given the very first launch of the app", ^{
                it(@"should use fallback values", ^{
                    [[[[Liquid sharedInstance] stringForKey:@"welcomeText" fallback:@"Fallback text"] should] equal:@"Fallback text"];
                });
            });
            
            context(@"given the second launch of the app (with 2 variables loaded in memory)", ^{
                beforeAll(^{
                    // Simulate an app going in background and foreground again:
                    [NSThread sleepForTimeInterval:0.1f];
                    [[Liquid sharedInstance] applicationWillResignActive:nil];
                    [[Liquid sharedInstance] applicationDidBecomeActive:nil];
                    [NSThread sleepForTimeInterval:0.1f];
                });

                it(@"should use a variable from the Liquid Package if it matches name and type", ^{
                    NSString *fallbackValue = @"A fallback value";
                    NSString *serverValue = @"Be very welcome";
                    NSString *title = [[Liquid sharedInstance] stringForKey:@"welcomeMessage" fallback:fallbackValue];
                    [[title should] equal:serverValue];
                });
                
                it(@"should use the fallback value if the variable from the Liquid Package if data type doesn't match", ^{
                    NSString *fallbackValue = @"Welcome to Liquid";
                    NSString *title = [[Liquid sharedInstance] stringForKey:@"discount" fallback:fallbackValue];
                    [[title should] equal:fallbackValue];
                });
                
                it(@"should use the fallback value if the variable from the Liquid Package if variable does not exist", ^{
                    NSString *fallbackValue = @"A fallback value";
                    NSString *title = [[Liquid sharedInstance] stringForKey:@"anUnkownVariable" fallback:fallbackValue];
                    [[title should] equal:fallbackValue];
                });
            });
        });

        context(@"given a Liquid singleton with an identified user", ^{
            __block __strong Liquid *liquidInstance;

            beforeAll(^{
                liquidInstance = [[Liquid alloc] initWithToken:@"abcdef123456"];
                [liquidInstance stub:@selector(flush) andReturn:nil];
                [liquidInstance setFlushOnBackground:NO];

                // Simulate an app going in background and foreground again:
                [NSThread sleepForTimeInterval:0.1f];
                [liquidInstance applicationWillResignActive:nil];
                [liquidInstance applicationDidBecomeActive:nil];
                [NSThread sleepForTimeInterval:0.1f];
            });

            it(@"should be possible to perform multiple operations simultaneously, without race conditions", ^{
                dispatch_queue_t queue = dispatch_queue_create([@"chaos" UTF8String], DISPATCH_QUEUE_CONCURRENT);
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue, ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [liquidInstance applicationWillResignActive:nil];
                        });
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [liquidInstance applicationDidBecomeActive:nil];
                        });
                    });
                }
                for(NSInteger i = 0; i < 20; i++) {
                    dispatch_async(queue, ^{
                        [NSThread sleepForTimeInterval:0.1f];
                    });
                }
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue, ^{
                        [liquidInstance requestValues];
                    });
                }
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue, ^{
                        [liquidInstance loadValues];
                    });
                }
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue, ^{
                        [liquidInstance stringForKey:@"welcomeText" fallback:@"A fallback value"];
                    });
                }
                for(NSInteger i = 0; i < 200; i++) {
                    dispatch_async(queue, ^{
                        [liquidInstance stringForKey:@"unknownVariable" fallback:@"A fallback value"];
                    });
                }
                [NSThread sleepForTimeInterval:6.0f];
            });
        });
    });
});

SPEC_END
