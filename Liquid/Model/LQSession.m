//
//  LQSession.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQSession.h"
#import "LQDefaults.h"
#import "NSDateFormatter+LQDateFormatter.h"
#import "NSData+LQData.h"
#import "NSString+LQString.h"

@implementation LQSession

#pragma mark - Initializer

-(id)initWithDate:(NSDate *)date timeout:(NSNumber*)timeout {
    self = [super init];
    if(self) {
        _identifier = [LQSession generateRandomSessionIdentifier];
        _start = [NSDate date];
        _timeout = timeout;
        _attributes = [NSDictionary new];
    }
    return self;
}

#pragma mark - Attributes

-(void)setAttribute:(id<NSCoding>)attribute forKey:(NSString *)key {
    [LQSession assertAttributeType:attribute];
    [LQSession assertAttributeKey:key];

    NSMutableDictionary *mutableAttributes = [_attributes mutableCopy];
    [mutableAttributes setObject:attribute forKey:key];
    _attributes = mutableAttributes;
}

-(id)attributeForKey:(NSString *)key {
    return [_attributes objectForKey:key];
}

-(void)endSessionOnDate:(NSDate *)endDate {
    _end = endDate;
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSDateFormatter *dateFormatter = [NSDateFormatter ISO8601DateFormatter];
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_identifier forKey:@"unique_id"];
    [dictionary setObject:[dateFormatter stringFromDate:_start] forKey:@"started_at"];
    [dictionary setObject:_timeout forKey:@"timeout"];
    if(_end != nil) {
        [dictionary setObject:[dateFormatter stringFromDate:_end] forKey:@"ended_at"];
    }
    return dictionary;
}

+ (NSString *)generateRandomSessionIdentifier {
    return [NSString generateRandomUniqueIdAppendingTimestamp:YES];
}

@end
