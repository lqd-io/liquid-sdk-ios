#import "Kiwi.h"
#import "LiquidPrivates.h"
#import "OHHTTPStubs.h"
#import "NSString+LQString.h"
#import "LQDevice.h"
#import <OCMock/OCMock.h>

SPEC_BEGIN(LiquidTargetsInvalidationSpec)

describe(@"Liquid", ^{
    let(apiToken, ^id{
        return @"12345678901234567890abcdef";
    });
    
    let(deviceId, ^id{
        return [LQDevice uid];
    });
    
    let(jsonDict, nil);
    
    beforeAll(^{
        [Liquid stub:@selector(archiveQueue:forToken:) andReturn:nil];
        [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle bundleForClass:[self class]]];
        [LQDevice stub:@selector(appName) andReturn:@"LiquidTest"];
        [LQDevice stub:@selector(appBundle) andReturn:kLQBundle];
        [LQDevice stub:@selector(appVersion) andReturn:@"9.9"];
        [LQDevice stub:@selector(releaseVersion) andReturn:@"9.8"];
    });
    
    context(@"given a Liquid Package with 6 variables received from Liquid dashboard/server (user covered by one Target)", ^{
        beforeAll(^{
            // Targets and Variables:
            // * freeCoins and discount are defined on target 1 (d8b035d088469702d6c53800)
            // * title is defined on target 2 (9702d388538a062ca6900000)
            // * all the others aren't defined on any target
            //
            // Data Types:
            // * freeCoins has incorrect data type (which should invalidate discount variable too)
            // * all the other variables should NOT be invalidated
            //
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                return [request.URL.path hasPrefix:@"/collect/users/"] && [request.URL.path hasSuffix:[NSString stringWithFormat:@"/devices/%@/liquid_package", deviceId]];
            } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
                NSString *fixture = OHPathForFileInBundle(@"liquid_package_targets.json", nil);
                return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type": @"text/json"}];
            }];

            [Liquid softReset];
            [Liquid sharedInstanceWithToken:apiToken];
            [[Liquid sharedInstance] identifyUser];

            // Simulate an app going in background and foreground again:
            [NSThread sleepForTimeInterval:0.1f];
            [[Liquid sharedInstance] applicationWillResignActive:nil];
            [[Liquid sharedInstance] applicationDidBecomeActive:nil];
            [NSThread sleepForTimeInterval:0.1f];
        });

        it(@"should invalidate (thus fallback) 'freeCoins' variable", ^{
            NSInteger fallbackValue = 1;
            NSInteger discount = [[Liquid sharedInstance] intForKey:@"freeCoins" fallback:fallbackValue];
            [[theValue(discount) should] equal:theValue(fallbackValue)];
        });
        
        context(@"given 'freeCoins' been used (an invalidated)", ^{
            beforeEach(^{
                [[Liquid sharedInstance] intForKey:@"freeCoins" fallback:1];
            });
            
            it(@"should invalidate (thus fallback) 'discount' variable after 'freeCoins' being used", ^{
                CGFloat fallbackValue = 0.10;
                CGFloat discount = [[Liquid sharedInstance] floatForKey:@"discount" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(fallbackValue)];
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
            
            context(@"given an event that is tracked", ^{
                beforeEach(^{
                    [[Liquid sharedInstance] track:@"Click Button"];
                    [NSThread sleepForTimeInterval:0.3f]; // wait for data point to be processed from the queued
                    LQQueue *queuedRequest = [[[Liquid sharedInstance] httpQueue] lastObject];
                    NSData *jsonData = queuedRequest.json;
                    jsonDict = [Liquid fromJSON:jsonData];
                });
                
                it(@"should send events with a Data Point that does NOT include target 'd8b035d088469702d6c53800'", ^{
                    NSArray *values = [jsonDict objectForKey:@"values"];
                    NSInteger numberOfValuesWithTarget = 0;
                    for (NSDictionary *value in values) {
                        if ([[value objectForKey:@"target_id"] isKindOfClass:[NSString class]] && [[value objectForKey:@"target_id"] isEqualToString:@"d8b035d088469702d6c53800"]) {
                            numberOfValuesWithTarget++;
                        }
                    }
                    [[theValue(numberOfValuesWithTarget) should] equal:theValue(0)];
                });
                
                it(@"should send events with a Data Point that includes target '9702d388538a062ca6900000'", ^{
                    NSArray *values = [jsonDict objectForKey:@"values"];
                    NSInteger numberOfValuesWithTarget = 0;
                    for (NSDictionary *value in values) {
                        if ([[value objectForKey:@"target_id"] isKindOfClass:[NSString class]] && [[value objectForKey:@"target_id"] isEqualToString:@"9702d388538a062ca6900000"]) {
                            numberOfValuesWithTarget++;
                        }
                    }
                    [[theValue(numberOfValuesWithTarget) should] equal:theValue(1)];
                });
                
                it(@"should send events with a Data Point that includes only 1 target", ^{
                    NSArray *values = [jsonDict objectForKey:@"values"];
                    NSInteger numberOfValuesWithTarget = 0;
                    for (NSDictionary *value in values) {
                        if ([[value objectForKey:@"target_id"] isKindOfClass:[NSString class]]) {
                            numberOfValuesWithTarget++;
                        }
                    }
                    [[theValue(numberOfValuesWithTarget) should] equal:theValue(1)];
                });
                
                it(@"should send events with a Data Point that includes only 4 of the 6 values/variables", ^{
                    NSArray *values = [jsonDict objectForKey:@"values"];
                    [[expectFutureValue([NSNumber numberWithInt:(int)values.count]) shouldEventuallyBeforeTimingOutAfter(4)] equal:@4];
                });
                
                it(@"should send events with a Data Point that includes 'title' variable", ^{
                    NSArray *values = [jsonDict objectForKey:@"values"];
                    BOOL valueFound = false;
                    for (NSDictionary *value in values) {
                        NSLog(@"VVV: %@", values);
                        if ([[value objectForKey:@"id"] isKindOfClass:[NSString class]] && [[value objectForKey:@"id"] isEqualToString:@"5371978369702d37ca180000"]) {
                            valueFound = YES;
                            break;
                        }
                    }
                    [[theValue(valueFound) should] beYes];
                });
                
                it(@"should send events with a Data Point that does NOT include 'freeCoins' variable", ^{
                    NSArray *values = [jsonDict objectForKey:@"values"];
                    BOOL valueFound = false;
                    for (NSDictionary *value in values) {
                        if ([[value objectForKey:@"id"] isKindOfClass:[NSString class]] && [[value objectForKey:@"id"] isEqualToString:@"538382ca69702d08900c0600"]) {
                            valueFound = YES;
                            break;
                        }
                    }
                    [[theValue(valueFound) should] beNo];
                });
                
                it(@"should send events with a Data Point that does NOT include 'discount' variable", ^{
                    NSArray *values = [jsonDict objectForKey:@"values"];
                    BOOL valueFound = false;
                    for (NSDictionary *value in values) {
                        if ([[value objectForKey:@"id"] isKindOfClass:[NSString class]] && [[value objectForKey:@"id"] isEqualToString:@"538382ca69702d08900a0600"]) {
                            valueFound = YES;
                            break;
                        }
                    }
                    [[theValue(valueFound) should] beNo];
                });
            });
        });
    });
});

SPEC_END
