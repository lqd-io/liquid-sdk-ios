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
    if (![LQSession assertAttributeType:attribute andKey:key]) return;
    NSMutableDictionary *mutableAttributes = [_attributes mutableCopy];
    [mutableAttributes setObject:attribute forKey:key];
    _attributes = [NSDictionary dictionaryWithDictionary:mutableAttributes];
}

-(id)attributeForKey:(NSString *)key {
    return [_attributes objectForKey:key];
}

+ (NSDictionary *)reservedAttributes {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @YES, @"_id",
            @YES, @"id",
            @YES, @"unique_id",
            @YES, @"started_at",
            @YES, @"ended_at",
            @YES, @"length",
            @YES, @"created_at",
            @YES, @"updated_at", nil];
}

#pragma mark - Helpers

- (void)endSessionOnDate:(NSDate *)endDate {
    _end = endDate;
}

- (BOOL)inProgress {
    return (_end ? NO : YES);
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_identifier forKey:@"unique_id"];
    [dictionary setObject:[NSDateFormatter iso8601StringFromDate:_start] forKey:@"started_at"];
    [dictionary setObject:_timeout forKey:@"timeout"];
    if(_end != nil) {
        [dictionary setObject:[NSDateFormatter iso8601StringFromDate:_end] forKey:@"ended_at"];
    }
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

+ (NSString *)generateRandomSessionIdentifier {
    return [NSString generateRandomUUIDAppendingTimestamp:YES];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _identifier = [aDecoder decodeObjectForKey:@"identifier"];
        _start = [aDecoder decodeObjectForKey:@"start"];
        _end = [aDecoder decodeObjectForKey:@"end"];
        _timeout = [aDecoder decodeObjectForKey:@"timeout"];
        _attributes = [aDecoder decodeObjectForKey:@"attributes"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_start forKey:@"start"];
    [aCoder encodeObject:_end forKey:@"end"];
    [aCoder encodeObject:_timeout forKey:@"timeout"];
    [aCoder encodeObject:_attributes forKey:@"attributes"];
}

@end
