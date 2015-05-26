#import "Kiwi.h"
#import "LiquidPrivates.h"
#import "OHHTTPStubs.h"
#import "NSString+LQString.h"
#import "NSData+LQData.h"
#import "LQDevice.h"
#import <OCMock/OCMock.h>
#import "LQNetworkingPrivates.h"

SPEC_BEGIN(LiquidTargetsInvalidationSpec)

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
    });
    
    context(@"given a Liquid Package with 6 variables received from Liquid dashboard/server (user covered by one Target)", ^{
        __block __strong Liquid *liquidInstance;

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
        });

        beforeEach(^{
            liquidInstance = [[Liquid alloc] initWithToken:@"liquid_tests"];
            [liquidInstance stub:@selector(flush)];
        });

        it(@"should invalidate (thus fallback) 'freeCoins' variable", ^{
            NSInteger fallbackValue = 1;
            NSInteger discount = [liquidInstance intForKey:@"freeCoins" fallback:fallbackValue];
            [[theValue(discount) should] equal:theValue(fallbackValue)];
        });
        
        context(@"given 'freeCoins' been used (and invalidated)", ^{
            beforeEach(^{
                [liquidInstance intForKey:@"freeCoins" fallback:1];
            });
            
            it(@"should invalidate (thus fallback) 'discount' variable after 'freeCoins' being used", ^{
                CGFloat fallbackValue = 0.10;
                CGFloat discount = [liquidInstance floatForKey:@"discount" fallback:fallbackValue];
                [[theValue(discount) should] equal:theValue(fallbackValue)];
            });
            
            it(@"should NOT invalidate (thus use Liquid Package value) 'title' variable", ^{
                NSString *fallbackValue = @"Fallback value";
                NSString *serverValue = @"Default value of this variable";
                NSString *title = [liquidInstance stringForKey:@"title" fallback:fallbackValue];
                [[title should] equal:serverValue];
            });
            
            it(@"should NOT invalidate (thus use Liquid Package value) 'showDate' variable", ^{
                NSDate *fallbackValue = [NSDate dateWithTimeIntervalSince1970:0];
                NSDate *date = [liquidInstance dateForKey:@"showDate" fallback:fallbackValue];
                [[date shouldNot] equal:fallbackValue];
            });
            
            it(@"should NOT invalidate (thus use Liquid Package value) 'backgroundColor' variable", ^{
                UIColor *fallbackValue = [UIColor blueColor];
                UIColor *serverValue = [UIColor redColor];
                UIColor *color = [liquidInstance colorForKey:@"backgroundColor" fallback:fallbackValue];
                [[color should] equal:serverValue];
            });
            
            it(@"should NOT invalidate (thus use Liquid Package value) 'showAds' variable", ^{
                BOOL fallbackValue = NO;
                BOOL serverValue = YES;
                BOOL showAds = [liquidInstance boolForKey:@"showAds" fallback:fallbackValue];
                [[theValue(showAds) should] equal:theValue(serverValue)];
            });
            
            context(@"given an event that is tracked", ^{
                __block NSDictionary *jsonDictionary;

                beforeEach(^{
                    [LQNetworking deleteHttpQueueFileForToken:@"liquid_tests2"];
                    [liquidInstance.networking resetHttpQueue];
                    [liquidInstance track:@"Click Button"];
                    [NSThread sleepForTimeInterval:0.10f]; // wait for data point to be processed from the queue
                    LQRequest *queuedRequest = [liquidInstance.networking.httpQueue lastObject];
                    NSData *jsonData = queuedRequest.json;
                    jsonDictionary = [NSData fromJSON:jsonData];
                });

                it(@"should send events with a Data Point that does NOT include target 'd8b035d088469702d6c53800'", ^{
                    NSArray *values = [jsonDictionary objectForKey:@"values"];
                    NSInteger numberOfValuesWithTarget = 0;
                    for (NSDictionary *value in values) {
                        if ([[value objectForKey:@"target_id"] isKindOfClass:[NSString class]] && [[value objectForKey:@"target_id"] isEqualToString:@"d8b035d088469702d6c53800"]) {
                            numberOfValuesWithTarget++;
                        }
                    }
                    [[theValue(numberOfValuesWithTarget) should] equal:theValue(0)];
                });
                
                it(@"should send events with a Data Point that includes target '9702d388538a062ca6900000'", ^{
                    NSArray *values = [jsonDictionary objectForKey:@"values"];
                    NSInteger numberOfValuesWithTarget = 0;
                    for (NSDictionary *value in values) {
                        if ([[value objectForKey:@"target_id"] isKindOfClass:[NSString class]] && [[value objectForKey:@"target_id"] isEqualToString:@"9702d388538a062ca6900000"]) {
                            numberOfValuesWithTarget++;
                        }
                    }
                    [[expectFutureValue(theValue(numberOfValuesWithTarget)) shouldEventually] equal:theValue(1)];
                });
                
                it(@"should send events with a Data Point that includes only 1 target", ^{
                    NSArray *values = [jsonDictionary objectForKey:@"values"];
                    NSInteger numberOfValuesWithTarget = 0;
                    for (NSDictionary *value in values) {
                        if ([[value objectForKey:@"target_id"] isKindOfClass:[NSString class]]) {
                            numberOfValuesWithTarget++;
                        }
                    }
                    [[expectFutureValue(theValue(numberOfValuesWithTarget)) shouldEventually] equal:theValue(1)];
                });
                
                it(@"should send events with a Data Point that includes only 4 of the 6 values/variables", ^{
                    NSArray *values = [jsonDictionary objectForKey:@"values"];
                    [NSThread sleepForTimeInterval:0.5f];
                    [[expectFutureValue([NSNumber numberWithInt:(int)values.count]) should] equal:@4];
                });
                
                it(@"should send events with a Data Point that includes 'title' variable", ^{
                    NSArray *values = [jsonDictionary objectForKey:@"values"];
                    BOOL valueFound = false;
                    for (NSDictionary *value in values) {
                        if ([[value objectForKey:@"id"] isKindOfClass:[NSString class]] && [[value objectForKey:@"id"] isEqualToString:@"5371978369702d37ca180000"]) {
                            valueFound = YES;
                            break;
                        }
                    }
                    [[theValue(valueFound) should] beYes];
                });
                
                it(@"should send events with a Data Point that does NOT include 'freeCoins' variable", ^{
                    NSArray *values = [jsonDictionary objectForKey:@"values"];
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
                    NSArray *values = [jsonDictionary objectForKey:@"values"];
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
