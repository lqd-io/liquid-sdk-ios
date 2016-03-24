//
//  LQHelpers.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 24/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQHelpers.h"
#import "UIColor+LQColor.h"
#import "NSDateFormatter+LQDateFormatter.h"

@implementation LQHelpers

+ (NSUInteger)randomInt:(NSUInteger)max {
    return (int) arc4random_uniform ((int) max);
}

+ (NSDictionary *)normalizeDataTypes:(NSDictionary *)dictionary {
    NSMutableDictionary *newDictionary = [NSMutableDictionary new];
    for (id key in dictionary) {
        id element = [dictionary objectForKey:key];
        if ([element isKindOfClass:[NSDate class]]) {
            [newDictionary setObject:[NSDateFormatter iso8601StringFromDate:element] forKey:key];
        } else if ([element isKindOfClass:[UIColor class]]) {
            [newDictionary setObject:[UIColor hexadecimalStringFromUIColor:element] forKey:key];
        } else if ([element isKindOfClass:[NSDictionary class]]) {
            [newDictionary setObject:[LQHelpers normalizeDataTypes:element] forKey:key];
        } else {
            [newDictionary setObject:element forKey:key];
        }
    }
    return [NSDictionary dictionaryWithDictionary:newDictionary];
}

@end
