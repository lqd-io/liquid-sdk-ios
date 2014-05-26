//
//  LQUser.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQDevice.h"
#import "LQUser.h"
#import "LQDefaults.h"

@implementation LQUser

#pragma mark - Initializer

-(id)initWithIdentifier:(NSString *)identifier attributes:(NSDictionary *)attributes {
    self = [super init];
    if(self) {
        [LQUser assertAttributesTypesAndKeys:attributes];

        _identifier = identifier;
        _attributes = attributes;
        if (identifier == nil) {
            _identifier = [LQUser automaticUserIdentifier];
            _autoIdentified = @YES;
        } else {
            _identifier = identifier;
            _autoIdentified = @NO;
        }
        if(_attributes == nil)
            _attributes = [NSDictionary new];
    }
    return self;
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_identifier forKey:@"unique_id"];
    [dictionary setObject:_autoIdentified forKey:@"auto_identified"];
    return dictionary;
}

#pragma mark - Attributes

-(void)setAttribute:(id<NSCoding>)attribute forKey:(NSString *)key {
    [LQUser assertAttributeType:attribute andKey:key];

    NSMutableDictionary *mutableAttributes = [_attributes mutableCopy];
    [mutableAttributes setObject:attribute forKey:key];
    _attributes = mutableAttributes;
}

-(id)attributeForKey:(NSString *)key {
    return [_attributes objectForKey:key];
}

+(NSString *)automaticUserIdentifier {
    NSString *automaticUserIdentifier = [LQDevice uid];

    if (!automaticUserIdentifier) {
        LQLog(kLQLogLevelError, @"<Liquid> %@ could not get automatic user identifier.", self);
    }
    return automaticUserIdentifier;
}

@end
