//
//  LQEntity.m
//  Liquid
//
//  Created by Miguel M. Almeida on 25/05/14.
//  Copyright (c) 2014 Liquid. All rights reserved.
//

#import <UIKit/UIApplication.h>
#import "LQEntity.h"

@implementation LQEntity

+ (void)assertAttributeType:(id)attribute {
    NSAssert([attribute isKindOfClass:[NSString class]] ||
             [attribute isKindOfClass:[NSNumber class]] ||
             [attribute isKindOfClass:[UIColor class]] ||
             [attribute isKindOfClass:[NSNull class]] ||
             [attribute isKindOfClass:[NSDate class]],
             @"%@'s %@ attribute type must be NSString, NSNumber, NSDate, UIColor or NSNull. Got: %@ %@", self, [self class], [attribute class], attribute);
}

+ (void)assertAttributeKey:(NSString *)key {
    NSCharacterSet *notAllowedCharacters = [NSCharacterSet characterSetWithCharactersInString:@".$\0"];
    NSAssert([key rangeOfCharacterFromSet:notAllowedCharacters].location == NSNotFound,
             @"%@ attribute keys cannot include dollar ($), dot (.) or null (\\0) characters. Got %@", [self class], key);
}

+ (void)assertAttributesKeysAndTypes:(NSDictionary *)attributes {
    for (id k in attributes) {
        NSAssert([k isKindOfClass: [NSString class]], @"%@ attribute keys must be an NSString. Got: %@ %@", self, [k class], k);
        [[self class] assertAttributeKey:k];
        [[self class] assertAttributeType:[attributes objectForKey:k]];
    }
}

@end
