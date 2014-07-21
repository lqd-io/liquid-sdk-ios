#import "Kiwi.h"
#import "LiquidPrivates.h"
#import "OHHTTPStubs.h"
#import "NSString+LQString.h"
#import "LQDevice.h"
#import <OCMock/OCMock.h>

SPEC_BEGIN(LiquidValuesInvalidationSpec)

describe(@"Liquid", ^{
    let(apiToken, ^id{
        return @"12345678901234567890abcdef";
    });
    
    let(deviceId, ^id{
        return [LQDevice uid];
    });
    
    let(userId, ^id{
        return @"333";
    });
    
    beforeAll(^{
        [Liquid stub:@selector(archiveQueue:forToken:) andReturn:nil];
        [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
        [LQDevice stub:@selector(appName) andReturn:@"LiquidTest"];
        [LQDevice stub:@selector(appBundle) andReturn:kLQBundle];
        [LQDevice stub:@selector(appVersion) andReturn:@"9.9"];
        [LQDevice stub:@selector(releaseVersion) andReturn:@"9.8"];
    });

    context(@"given a Liquid Package with 6 variables", ^{
        context(@"given correct data types for all 6 variables", ^{
            beforeAll(^{
                [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                    return [request.URL.path isEqualToString:[NSString stringWithFormat:@"/collect/users/%@/devices/%@/liquid_package", userId, deviceId]];
                } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                    NSString *fixture = OHPathForFileInBundle(@"liquid_package_correct_data_types.json", nil);
                    return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
                }];

                [Liquid softReset];
                [Liquid sharedInstanceWithToken:apiToken];
                [[Liquid sharedInstance] identifyUserWithIdentifier:userId];
                [[Liquid sharedInstance] stub:@selector(flush) andReturn:nil];
                [[Liquid sharedInstance] setFlushOnBackground:NO];

                // Simulate an app going in background and foreground again:
                [NSThread sleepForTimeInterval:0.1f];
                [[Liquid sharedInstance] applicationDidEnterBackground:nil];
                [[Liquid sharedInstance] applicationWillEnterForeground:nil];
                [NSThread sleepForTimeInterval:0.1f];
            });

            it(@"should have loaded 6 values/variables", ^{
                [[theValue([[Liquid sharedInstance] loadedLiquidPackage].values.count) should] equal:theValue(6)];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'title' variable", ^{
                NSString *fallbackValue = @"Fallback value";
                NSString *serverValue = @"Default value of this variable";
                NSString *title = [[Liquid sharedInstance] stringForKey:@"title" fallback:fallbackValue];
                [[title should] equal:serverValue];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'showDate' variable", ^{
                NSDate *fallbackValue = [NSDate dateWithTimeIntervalSince1970:0];
                NSDate *date = [[Liquid sharedInstance] dateForKey:@"showDate" fallback:fallbackValue];
                [[date shouldNot] equal:fallbackValue];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'backgroundColor' variable", ^{
                UIColor *fallbackValue = [UIColor blueColor];
                UIColor *serverValue = [UIColor redColor];
                UIColor *color = [[Liquid sharedInstance] colorForKey:@"backgroundColor" fallback:fallbackValue];
                [[color should] equal:serverValue];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'showAds' variable", ^{
                BOOL fallbackValue = NO;
                BOOL serverValue = YES;
                BOOL showAds = [[Liquid sharedInstance] boolForKey:@"showAds" fallback:fallbackValue];
                [[theValue(showAds) should] equal:theValue(serverValue)];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'discount' variable", ^{
                CGFloat fallbackValue = 0.10;
                CGFloat serverValue = 0.25;
                CGFloat discount = [[Liquid sharedInstance] floatForKey:@"discount" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(serverValue)];
            });

            it(@"should NOT invalidate (thus use Liquid Package value) 'freeCoins' variable", ^{
                NSInteger fallbackValue = 1;
                NSInteger serverValue = 7;
                NSInteger discount = [[Liquid sharedInstance] intForKey:@"freeCoins" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(serverValue)];
            });
        });

        context(@"given INCORRECT data types for all 6 variables", ^{
            beforeAll(^{
                [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                    return [request.URL.path isEqualToString:[NSString stringWithFormat:@"/collect/users/%@/devices/%@/liquid_package", userId, deviceId]];
                } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                    NSString *fixture = OHPathForFileInBundle(@"liquid_package_incorrect_data_types.json", nil);
                    return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
                }];

                [Liquid softReset];
                [Liquid sharedInstanceWithToken:apiToken];
                [[Liquid sharedInstance] identifyUserWithIdentifier:userId];
                [[Liquid sharedInstance] stub:@selector(flush) andReturn:nil];
                [[Liquid sharedInstance] setFlushOnBackground:NO];

                // Simulate an app going in background and foreground again:
                [NSThread sleepForTimeInterval:0.1f];
                [[Liquid sharedInstance] applicationDidEnterBackground:nil];
                [[Liquid sharedInstance] applicationWillEnterForeground:nil];
                [NSThread sleepForTimeInterval:0.1f];
            });

            it(@"should invalidate (thus fallback) a variable that is not in Liquid server", ^{
                NSString *fallbackString = @"Fallback value";
                NSString *title = [[Liquid sharedInstance] stringForKey:@"unknownVariable" fallback:fallbackString];
                [[title should] equal:fallbackString];
            });

            it(@"should invalidate (thus fallback) 'title' variable", ^{
                NSString *fallbackString = @"Fallback value";
                NSString *title = [[Liquid sharedInstance] stringForKey:@"title" fallback:fallbackString];
                [[title should] equal:fallbackString];
            });

            it(@"should invalidate (thus fallback) 'showDate' variable", ^{
                NSDate *fallbackValue = [NSDate dateWithTimeIntervalSince1970:0];
                NSDate *date = [[Liquid sharedInstance] dateForKey:@"showDate" fallback:fallbackValue];
                [[date should] equal:fallbackValue];
            });

            it(@"should invalidate (thus fallback) 'backgroundColor' variable", ^{
                UIColor *fallbackValue = [UIColor blueColor];
                UIColor *color = [[Liquid sharedInstance] colorForKey:@"backgroundColor" fallback:fallbackValue];
                [[color should] equal:fallbackValue];
            });

            it(@"should invalidate (thus fallback) 'showAds' variable", ^{
                BOOL fallbackValue = NO;
                BOOL showAds = [[Liquid sharedInstance] boolForKey:@"showAds" fallback:fallbackValue];
                [[theValue(showAds) should] equal:theValue(fallbackValue)];
            });

            it(@"should invalidate (thus fallback) 'discount' variable", ^{
                CGFloat fallbackValue = 0.10;
                CGFloat discount = [[Liquid sharedInstance] floatForKey:@"discount" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(fallbackValue)];
            });

            it(@"should invalidate (thus fallback) 'freeCoins' variable", ^{
                NSInteger fallbackValue = 1;
                NSInteger discount = [[Liquid sharedInstance] intForKey:@"freeCoins" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(fallbackValue)];
            });
        });
    });
    
});

SPEC_END
