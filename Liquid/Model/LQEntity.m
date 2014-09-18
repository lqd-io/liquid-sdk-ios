//
//  LQEntity.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 25/05/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <UIKit/UIApplication.h>
#import "LQEntity.h"
#import "LQDefaults.h"

@implementation LQEntity

#pragma mark - Private methods

+ (BOOL)assertAttributeType:(id)attribute {
    BOOL assert = [attribute isKindOfClass:[NSString class]] ||
                  [attribute isKindOfClass:[NSNumber class]] ||
                  [attribute isKindOfClass:[UIColor class]] ||
                  [attribute isKindOfClass:[NSNull class]] ||
                  [attribute isKindOfClass:[NSDate class]];
    NSAssert(assert, @"%@'s %@ attribute type must be NSString, NSNumber, NSDate, UIColor or NSNull. Got: %@ %@",
             self, [self class], [attribute class], attribute);
    if (!assert) {
        LQLog(kLQLogLevelError, @"<Liquid> Ignoring %@ attribute because its type is not valid (%@). Accepted types are NSString, NSNumber, NSDate, UIColor and NSNull.", [self class], [attribute class]);
    }
    return assert;
}

+ (BOOL)assertAttributeKey:(NSString *)key {
    NSCharacterSet __unused *notAllowedCharacters = [NSCharacterSet characterSetWithCharactersInString:@".$\0"];
    BOOL assert = [key rangeOfCharacterFromSet:notAllowedCharacters].location == NSNotFound;
    NSAssert(assert, @"%@ attribute keys cannot include dollar ($), dot (.) or null (\\0) characters. Got %@", [self class], key);
    if (!assert) {
        LQLog(kLQLogLevelError, @"<Liquid> Ignoring attribute key %@ because includes an invalid character ($, . or \\0).", [self class]);
    }
    return assert;
}

+ (NSDictionary *)reservedAttributes {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (void)assertReservedAttributeKey:(NSString *)key {
    NSAssert([[[self class] reservedAttributes] objectForKey:key] == nil,
             @"You cannot use reserved attributes on %@ entity. You've used '%@', which is forbidden.", [self class], key);
}

#pragma mark - Public methods

+ (BOOL)assertAttributeType:(id)attribute andKey:(NSString *)key {
    [[self class] assertReservedAttributeKey:key];
    return [[self class] assertAttributeKey:key] && [[self class] assertAttributeType:attribute];
}

+ (NSDictionary *)assertAttributesTypesAndKeys:(NSDictionary *)attributes {
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:attributes];
    for (id k in attributes) {
        BOOL assertKeyClass = [k isKindOfClass: [NSString class]];
        NSAssert(assertKeyClass, @"%@ attribute keys must be an NSString. Got: %@ %@", self, [k class], k);
        BOOL assertAttributeAndKey = [[self class] assertAttributeType:[attributes objectForKey:k] andKey:k];
        [[self class] assertReservedAttributeKey:k];
        if (!assertKeyClass || !assertAttributeAndKey) {
            if (!assertKeyClass) LQLog(kLQLogLevelError, @"<Liquid> %@ attribute keys must be an NSString. Got: %@", self, [k class]);
            [newDict removeObjectForKey:k];
        }
    }
    return [NSDictionary dictionaryWithDictionary:newDict];
}

- (id)copyWithZone:(NSZone *)zone {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end
