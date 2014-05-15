//
//  LQSession.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQSession.h"
#import "LQDefaults.h"
#import "NSDateFormatter+ISO8601.h"
#import "NSData+Random.h"
#import "NSString+RandomGenerator.h"

@implementation LQSession

#pragma mark - Initializer

-(id)initWithDate:(NSDate *)date timeout:(NSNumber*)timeout {
    self = [super init];
    if(self) {
        _identifier = [NSString generateRandomSessionIdentifier];
        _start = [NSDate date];
        _timeout = timeout;
        _attributes = [NSDictionary new];
    }
    return self;
}

#pragma mark - Attributes

-(void)setAttribute:(id<NSCoding>)attribute forKey:(NSString *)key {
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

-(NSDictionary *)jsonDictionary{
    return [self jsonDictionaryWithUser:nil device:nil];
}

-(NSDictionary *)jsonDictionaryWithUser:(LQUser *)user device:(LQDevice *)device {
    NSDateFormatter *dateFormatter = [NSDateFormatter ISO8601DateFormatter];
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_identifier forKey:@"unique_id"];
    [dictionary setObject:[dateFormatter stringFromDate:_start] forKey:@"started_at"];
    [dictionary setObject:_timeout forKey:@"timeout"];
    if(_end != nil)
        [dictionary setObject:[dateFormatter stringFromDate:_end] forKey:@"ended_at"];
    if(user != nil)
        [dictionary setObject:[user jsonDictionary] forKey:@"user"];
    if(device != nil)
        [dictionary setObject:[device jsonDictionary] forKey:@"device"];
    return dictionary;
}

@end
