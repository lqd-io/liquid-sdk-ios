//
//  LQDataPoint.m
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/20/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQDataPoint.h"
#import "LQDefaults.h"
#import "NSDateFormatter+LQDateFormatter.h"

@implementation LQDataPoint

-(id)initWithDate:(NSDate *)date user:(LQUser *)user device:(LQDevice *)device session:(LQSession *)session event:(LQEvent *)event values:(NSArray *)values{
    self = [super init];
    if(self) {
        _user = user;
        _device = device;
        _session = session;
        _event = event;
        _values = values;
        _timestamp = event.date;
    }
    return self;
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _user = [aDecoder decodeObjectForKey:@"user"];
        _device = [aDecoder decodeObjectForKey:@"device"];
        _session = [aDecoder decodeObjectForKey:@"session"];
        _event = [aDecoder decodeObjectForKey:@"event"];
        _targets = [aDecoder decodeObjectForKey:@"targets"];
        _values = [aDecoder decodeObjectForKey:@"values"];
        _timestamp = [aDecoder decodeObjectForKey:@"timestamp"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_user forKey:@"user"];
    [aCoder encodeObject:_device forKey:@"device"];
    [aCoder encodeObject:_session forKey:@"session"];
    [aCoder encodeObject:_event forKey:@"event"];
    [aCoder encodeObject:_targets forKey:@"targets"];
    [aCoder encodeObject:_values forKey:@"values"];
    [aCoder encodeObject:_timestamp forKey:@"timestamp"];
}

- (id)copyWithZone:(NSZone *)zone {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    NSDictionary *userDict = [_user jsonDictionary];
    NSDictionary *deviceDict = [_device jsonDictionary];
    NSDictionary *sessionDict = [_session jsonDictionary];
    NSDictionary *eventDict = [_event jsonDictionary];
    if (userDict)
        [dictionary setObject:userDict forKey:@"user"];
    if (deviceDict)
        [dictionary setObject:deviceDict forKey:@"device"];
    if (sessionDict)
        [dictionary setObject:sessionDict forKey:@"session"];
    if (eventDict)
        [dictionary setObject:eventDict forKey:@"event"];

    NSMutableArray *valuesArray = [[NSMutableArray alloc] init];
    for (LQValue *value in _values)
        // Values without id are fallback values
        // So, we don't need (and don't want) to send track them on target's results:
        if (value.identifier)
            [valuesArray addObject:[value jsonDictionary]];
    [dictionary setObject:valuesArray forKey:@"values"];

    [dictionary setObject:[NSDateFormatter iso8601StringFromDate:_timestamp] forKey:@"timestamp"];
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end
