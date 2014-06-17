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
    if (![LQUser assertAttributeType:attribute andKey:key]) return;

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

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _identifier = [aDecoder decodeObjectForKey:@"identifier"];
        _attributes = [aDecoder decodeObjectForKey:@"attributes"];
        _autoIdentified = [aDecoder decodeObjectForKey:@"autoIdentified"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_identifier forKey:@"identifier"];
    [aCoder encodeObject:_attributes forKey:@"attributes"];
    [aCoder encodeObject:_autoIdentified forKey:@"autoIdentified"];
}

- (id)copyWithZone:(NSZone *)zone {
    LQUser *user = [[[self class] allocWithZone:zone] init];
    user->_identifier = [_identifier copyWithZone:zone];
    user->_attributes = [_attributes copyWithZone:zone];
    user->_autoIdentified = [_autoIdentified copyWithZone:zone];
    return user;
}

@end
