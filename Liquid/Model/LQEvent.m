//
//  LQEvent.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQEvent.h"
#import "LQDefaults.h"
#import "NSDateFormatter+LQDateFormatter.h"

@implementation LQEvent

#pragma mark - Initializer

-(id)initWithName:(NSString *)name attributes:(NSDictionary *)attributes date:(NSDate *)date {
    self = [super init];
    if(self) {
        _name = name;
        if(attributes == nil)
            _attributes = [NSDictionary new];
        else
            _attributes = attributes;
        _date = date;
    }
    return self;
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_name forKey:@"name"];
    [dictionary setObject:[NSDateFormatter iso8601StringFromDate:_date] forKey:@"date"];
    return dictionary;
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _attributes = [aDecoder decodeObjectForKey:@"attributes"];
        _date = [aDecoder decodeObjectForKey:@"date"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_attributes forKey:@"attributes"];
    [aCoder encodeObject:_date forKey:@"date"];
}

- (id)copyWithZone:(NSZone *)zone {
    LQEvent *event = [[[self class] allocWithZone:zone] init];
    event->_name = [_name copyWithZone:zone];
    event->_attributes = [_attributes copyWithZone:zone];
    event->_date = [_date copyWithZone:zone];
    return event;
}

@end
