//
//  LQEventTracker.m
//  Liquid
//
//  Created by Miguel M. Almeida on 29/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQEventTracker.h"
#import "LQDefaults.h"
#import "LQDate.h"
#import "LQDataPoint.h"
#import "NSDateFormatter+LQDateFormatter.h"
#import "NSData+LQData.h"
#import "Liquid.h"

@interface LQEventTracker ()

@property (nonatomic, strong) LQNetworking *networking;
@property (nonatomic, strong) LQDevice *device;
#if OS_OBJECT_USE_OBJC
@property (atomic, strong) dispatch_queue_t queue;
#else
@property (atomic, assign) dispatch_queue_t queue;
#endif

@end

@implementation LQEventTracker

@synthesize networking = _networking;
@synthesize queue = _queue;
@synthesize device = _device;
@synthesize currentUser = _currentUser;

#pragma mark - Initializers

- (instancetype)initWithNetworking:(LQNetworking *)networking dispatchQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        self.networking = networking;
        self.queue = queue;
    }
    return self;
}

- (LQDevice *)device {
    if (!_device) {
        _device = [LQDevice sharedInstance];
    }
    return _device;
}

#pragma mark - Public methods

- (void)track:(NSString *)eventName attributes:(NSDictionary *)attributes
                                  loadedValues:(NSArray *)loadedValues
                                      withDate:(NSDate *)eventDate
                                  errorHandler:(void(^)(NSError *error))errorBlock {
    if (!self.currentUser) {
        errorBlock([NSError errorWithDomain:kLQBundle code:kLQErrorNoUser userInfo:nil]);
    }
    [self track:eventName attributes:attributes loadedValues:loadedValues withDate:eventDate];
}

- (void)track:(NSString *)eventName attributes:(NSDictionary *)attributes
                                  loadedValues:(NSArray *)loadedValues
                                      withDate:(NSDate *)eventDate {
    NSDictionary *validAttributes = [LQEvent assertAttributesTypesAndKeys:attributes];

    if (!self.currentUser) {
        LQLog(kLQLogLevelError, @"<Liquid> %@", @"No user identified yet.");
        return;
    }

    NSDate *now;
    if (eventDate) {
        now = [eventDate copy];
    } else {
        now = [LQDate uniqueNow];
    }

    if ([eventName hasPrefix:@"_"]) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Tracking Liquid event %@ (%@) with attributes: %@",
              eventName, [NSDateFormatter iso8601StringFromDate:now], attributes);
    } else {
        LQLog(kLQLogLevelInfo, @"<Liquid> Tracking event %@ (%@) with attributes: %@",
              eventName, [NSDateFormatter iso8601StringFromDate:now], attributes);
    }
    
    NSString *finalEventName = eventName;
    if (eventName == nil || [eventName length] == 0) {
        LQLog(kLQLogLevelInfo, @"<Liquid> Tracking unnammed event.");
        finalEventName = @"unnamedEvent";
    }
    LQEvent *event = [[LQEvent alloc] initWithName:finalEventName attributes:validAttributes date:now];
    LQUser *user = self.currentUser;
    LQDevice *device = self.device;
    LQDataPoint *dataPoint = [[LQDataPoint alloc] initWithDate:now
                                                          user:user
                                                        device:device
                                                         event:event
                                                        values:loadedValues];
    NSDictionary *jsonDict = [dataPoint jsonDictionary];
    NSData *jsonData = [NSData toJSON:jsonDict];
    dispatch_async(self.queue, ^{
        [_networking addToHttpQueue:jsonData endPoint:@"data_points" httpMethod:@"POST"];
    });
}

@end
