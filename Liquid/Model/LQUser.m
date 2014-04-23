//
//  LQUser.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQUser.h"
#import "LQConstants.h"
#import <AdSupport/ASIdentifierManager.h>

@implementation LQUser

#pragma mark - Initializer

-(id)initWithIdentifier:(NSString *)identifier withAttributes:(NSDictionary *)attributes withLocation:(CLLocation *)location {
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
        [self setLocation:location];
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
    NSMutableDictionary *mutableAttributes = [_attributes mutableCopy];
    [mutableAttributes setObject:attribute forKey:key];
    _attributes = mutableAttributes;
}

-(id)attributeForKey:(NSString *)key {
    return [_attributes objectForKey:key];
}

-(void)setLocation:(CLLocation *)location {
    if(location == nil) {
        NSMutableDictionary *mutableAttributes = [_attributes mutableCopy];
        [mutableAttributes removeObjectForKey:@"_latitude"];
        [mutableAttributes removeObjectForKey:@"_longitude"];
    } else {
        [self setAttribute:[NSNumber numberWithFloat:location.coordinate.latitude] forKey:@"_latitude"];
        [self setAttribute:[NSNumber numberWithFloat:location.coordinate.longitude] forKey:@"_longitude"];
    }
}

+(NSString *)automaticUserIdentifier {
    NSString *automaticUserIdentifier = nil;

    if (NSClassFromString(@"ASIdentifierManager")) {
        automaticUserIdentifier = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    }

    if (automaticUserIdentifier == nil) {
        LQLog(kLQLogLevelError, @"<Liquid> %@ error getting IFA, trying UUID", self);
        NSString *liquidUUIDKey = @"com.liquid.UUID";
        NSString *uuid = [[NSUserDefaults standardUserDefaults]objectForKey:liquidUUIDKey];
        if(uuid == nil) {
            uuid = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults]setObject:uuid forKey:liquidUUIDKey];
            [[NSUserDefaults standardUserDefaults]synchronize];
        }
        automaticUserIdentifier = uuid;
    }
    if (!automaticUserIdentifier) {
        LQLog(kLQLogLevelError, @"<Liquid> %@ could not get automatic user identifier.", self);
    }
    return automaticUserIdentifier;
}

@end
