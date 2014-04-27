//
//  LQDataPoint.m
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/20/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQDataPoint.h"

@implementation LQDataPoint

-(id)initWithDate:(NSDate *)date withUser:(LQUser *)user withDevice:(LQDevice *)device withSession:(LQSession *)session withEvent:(LQEvent *)event withTargets:(NSArray *)targets withValues:(NSArray *)values{
    self = [super init];
    if(self) {
        _user = user;
        _device = device;
        _session = session;
        _event = event;
        _values = values;
        _targets = targets;
        _timestamp = event.date;
    }
    return self;
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
    
    NSMutableArray *targetsArray = [[NSMutableArray alloc] init];
    for (LQTarget *target in _targets)
        [targetsArray addObject:[target jsonDictionary]];
    [dictionary setObject:targetsArray forKey:@"targets"];

    NSMutableArray *valuesArray = [[NSMutableArray alloc] init];
    for (LQValue *value in _values)
        // Values without id are shipped values (on LiquidVariables.plist).
        // So, we don't need (and don't want) to send track them on target's results:
        if (value.identifier)
            [valuesArray addObject:[value jsonDictionary]];
    [dictionary setObject:valuesArray forKey:@"values"];

    NSDateFormatter *dateFormatter = [[self class] isoDateFormatter];
    [dictionary setObject:[dateFormatter stringFromDate:_timestamp] forKey:@"timestamp"];
    return dictionary;
}

+(NSDateFormatter *)isoDateFormatter {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZ"];
    [formatter setCalendar:gregorianCalendar];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    return formatter;
}

@end
