//
//  LQEvent.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQEvent.h"

@implementation LQEvent

#pragma mark - Initializer

-(id)initWithName:(NSString *)name withAttributes:(NSDictionary *)attributes withDate:(NSDate *)date {
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
    return [self jsonDictionaryWithUser:nil withDevice:nil withSession:nil];
}

-(NSDictionary *)jsonDictionaryWithUser:(LQUser*)user withDevice:(LQDevice*)device withSession:(LQSession *)session {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_name forKey:@"name"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZ"];
    [dictionary setObject:[dateFormatter stringFromDate:_date] forKey:@"date"];
    
    if(user != nil)
        [dictionary setObject:[user jsonDictionary] forKey:@"user"];
    if(device != nil)
        [dictionary setObject:[device jsonDictionary] forKey:@"device"];
    if(session != nil)
        [dictionary setObject:[session jsonDictionary] forKey:@"session"];
    return dictionary;
}

@end
