#import "Kiwi.h"
#import "LiquidPrivates.h"
#import "OHHTTPStubs.h"
#import "NSString+LQString.h"
#import "LQDevice.h"
#import <OCMock/OCMock.h>

SPEC_BEGIN(LiquidIntegrationSpec)

describe(@"Liquid", ^{
    let(apiToken, ^id{
        return @"12345678901234567890abcdef";
    });

    let(deviceId, ^id{
        return [LQDevice uid];
    });

    let(userId, ^id{
        return @"111";
    });
    
    beforeAll(^{
        [Liquid stub:@selector(archiveQueue:forToken:) andReturn:nil];
        [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
        [LQDevice stub:@selector(appName) andReturn:@"LiquidTest"];
        [LQDevice stub:@selector(appBundle) andReturn:kLQBundle];
        [LQDevice stub:@selector(appVersion) andReturn:@"9.9"];
        [LQDevice stub:@selector(releaseVersion) andReturn:@"9.8"];
    });

    context(@"given a Liquid Package with 2 variables", ^{
        beforeAll(^{
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return [request.URL.path isEqualToString:[NSString stringWithFormat:@"/collect/users/%@/devices/%@/liquid_package", userId, deviceId]];
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                NSString *fixture = OHPathForFileInBundle(@"liquid_package1.json", nil);
                return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
            }];
        });

        context(@"given a Liquid singleton with an auto identified user", ^{
            beforeAll(^{
                [Liquid softReset];
                [Liquid sharedInstanceWithToken:apiToken];
                [[Liquid sharedInstance] identifyUserWithIdentifier:userId];

                // Simulate an app going in background and foreground again:
                [NSThread sleepForTimeInterval:0.5f];
                [[Liquid sharedInstance] loadLiquidPackageSynced];
            });

            context(@"given the very first launch of the app", ^{
                it(@"should use fallback values", ^{
                    [[[[Liquid sharedInstance] stringForKey:@"welcomeText" fallback:@"Fallback text"] should] equal:@"Fallback text"];
                });
            });
            
            context(@"given the second launch of the app (with 2 variables loaded in memory)", ^{
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
    });

});

SPEC_END
