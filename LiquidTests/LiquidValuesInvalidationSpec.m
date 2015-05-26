#import "Kiwi.h"
#import "LiquidPrivates.h"
#import "OHHTTPStubs.h"
#import "NSString+LQString.h"
#import "LQDevice.h"
#import <OCMock/OCMock.h>
#import "LQNetworkingPrivates.h"

SPEC_BEGIN(LiquidValuesInvalidationSpec)

describe(@"Liquid", ^{
    beforeEach(^{
        [Liquid softReset];
    });

    let(deviceId, ^id{
        return [[LQDevice sharedInstance] uid];
    });
    
    let(userId, ^id{
        return @"333";
    });
    
    beforeAll(^{
        [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
        [LQDevice stub:@selector(appName) andReturn:@"LiquidTest"];
        [LQDevice stub:@selector(appBundle) andReturn:kLQBundle];
        [LQDevice stub:@selector(appVersion) andReturn:@"9.9"];
        [LQDevice stub:@selector(releaseVersion) andReturn:@"9.8"];
    });

    context(@"given a Liquid Package with 6 variables", ^{
        context(@"given correct data types for all 6 variables", ^{
            __block Liquid *liquid;

            beforeAll(^{
                [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                    return [request.URL.path isEqualToString:[NSString stringWithFormat:@"/collect/users/%@/devices/%@/liquid_package", userId, deviceId]];
                } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                    NSString *fixture = OHPathForFileInBundle(@"liquid_package_correct_data_types.json", nil);
                    return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
                }];
            });

            beforeEach(^{
                liquid = [[Liquid alloc] initWithToken:@"liquid_tests"];
                [liquid identifyUserWithIdentifier:userId];
                [liquid stub:@selector(flush)];
                //                [LQNetworking deleteHttpQueueFileForToken:@"liquid_tests"];
                //                [liquid.networking resetQueue];
                
                // Simulate an app going in background and foreground again:
                [NSThread sleepForTimeInterval:0.1f];
                [liquid applicationDidEnterBackground:nil];
                [liquid applicationWillEnterForeground:nil];
                [NSThread sleepForTimeInterval:0.1f];
            });

            it(@"should have loaded 6 values/variables", ^{
                [[theValue([liquid loadedLiquidPackage].values.count) should] equal:theValue(6)];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'title' variable", ^{
                NSString *fallbackValue = @"Fallback value";
                NSString *serverValue = @"Default value of this variable";
                NSString *title = [liquid stringForKey:@"title" fallback:fallbackValue];
                [[title should] equal:serverValue];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'showDate' variable", ^{
                NSDate *fallbackValue = [NSDate dateWithTimeIntervalSince1970:0];
                NSDate *date = [liquid dateForKey:@"showDate" fallback:fallbackValue];
                [[date shouldNot] equal:fallbackValue];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'backgroundColor' variable", ^{
                UIColor *fallbackValue = [UIColor blueColor];
                UIColor *serverValue = [UIColor redColor];
                UIColor *color = [liquid colorForKey:@"backgroundColor" fallback:fallbackValue];
                [[color should] equal:serverValue];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'showAds' variable", ^{
                BOOL fallbackValue = NO;
                BOOL serverValue = YES;
                BOOL showAds = [liquid boolForKey:@"showAds" fallback:fallbackValue];
                [[theValue(showAds) should] equal:theValue(serverValue)];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'discount' variable", ^{
                CGFloat fallbackValue = 0.10;
                CGFloat serverValue = 0.25;
                CGFloat discount = [liquid floatForKey:@"discount" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(serverValue)];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'freeCoins' variable", ^{
                NSInteger fallbackValue = 1;
                NSInteger serverValue = 7;
                NSInteger discount = [liquid intForKey:@"freeCoins" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(serverValue)];
            });
        });

        context(@"given INCORRECT data types for all 6 variables", ^{
            let(liquid, ^id{
                return [[Liquid alloc] initWithToken:@"liquid_tests"];
            });

            beforeAll(^{
                [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                    return [request.URL.path isEqualToString:[NSString stringWithFormat:@"/collect/users/%@/devices/%@/liquid_package", userId, deviceId]];
                } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                    NSString *fixture = OHPathForFileInBundle(@"liquid_package_incorrect_data_types.json", nil);
                    return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
                }];
            });

            beforeEach(^{
                [liquid identifyUserWithIdentifier:userId];
                [liquid stub:@selector(flush)];

                // Simulate an app going in background and foreground again:
                [NSThread sleepForTimeInterval:0.1f];
                [liquid applicationDidEnterBackground:nil];
                [liquid applicationWillEnterForeground:nil];
                [NSThread sleepForTimeInterval:0.1f];
            });

            it(@"should invalidate (thus fallback) a variable that is not in Liquid server", ^{
                NSString *fallbackString = @"Fallback value";
                NSString *title = [liquid stringForKey:@"unknownVariable" fallback:fallbackString];
                [[title should] equal:fallbackString];
            });

            it(@"should invalidate (thus fallback) 'title' variable", ^{
                NSString *fallbackString = @"Fallback value";
                NSString *title = [liquid stringForKey:@"title" fallback:fallbackString];
                [[title should] equal:fallbackString];
            });

            it(@"should invalidate (thus fallback) 'showDate' variable", ^{
                NSDate *fallbackValue = [NSDate dateWithTimeIntervalSince1970:0];
                NSDate *date = [liquid dateForKey:@"showDate" fallback:fallbackValue];
                [[date should] equal:fallbackValue];
            });

            it(@"should invalidate (thus fallback) 'backgroundColor' variable", ^{
                UIColor *fallbackValue = [UIColor blueColor];
                UIColor *color = [liquid colorForKey:@"backgroundColor" fallback:fallbackValue];
                [[color should] equal:fallbackValue];
            });

            it(@"should invalidate (thus fallback) 'showAds' variable", ^{
                BOOL fallbackValue = NO;
                BOOL showAds = [liquid boolForKey:@"showAds" fallback:fallbackValue];
                [[theValue(showAds) should] equal:theValue(fallbackValue)];
            });

            it(@"should invalidate (thus fallback) 'discount' variable", ^{
                CGFloat fallbackValue = 0.10;
                CGFloat discount = [liquid floatForKey:@"discount" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(fallbackValue)];
            });

            it(@"should invalidate (thus fallback) 'freeCoins' variable", ^{
                NSInteger fallbackValue = 1;
                NSInteger discount = [liquid intForKey:@"freeCoins" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(fallbackValue)];
            });
        });
    });
    
});

SPEC_END
