//
//  LQEntity.h
//  Liquid
//
//  Created by Miguel M. Almeida on 25/05/14.
//  Copyright (c) 2014 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQEntity : NSObject

+ (void)assertAttributeType:(id)attribute;
+ (void)assertAttributeKey:(NSString *)key;
+ (void)assertAttributesKeysAndTypes:(NSDictionary *)attributes;

@end
