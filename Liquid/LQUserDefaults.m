//
//  LQUserDefaults.m
//  Liquid
//
//  Created by Miguel M. Almeida on 17/05/15.
//  Copyright (c) 2015 Liquid. All rights reserved.
//

#import "LQUserDefaults.h"
#import "LQDefaults.h"

@implementation LQUserDefaults

+ (BOOL)setObject:(id)object forKey:(NSString *)key allowUpdate:(BOOL)allowUpdate {
    if (!allowUpdate && [[NSUserDefaults standardUserDefaults] objectForKey:[LQUserDefaults liquidPrefixedKey:key]]) {
        return NO;
    }
    LQLog(kLQLogLevelData, @"Setting NSUserDefaults key '%@' with object '%@'", key, object);
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:[LQUserDefaults liquidPrefixedKey:key]];
    return [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (id)objectForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:[LQUserDefaults liquidPrefixedKey:key]];
}

+ (void)removeObjectForKey:(NSString *)key {
    LQLog(kLQLogLevelData, @"Removing NSUserDefaults key '%@'", key);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[LQUserDefaults liquidPrefixedKey:key]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)liquidPrefixedKey:(NSString *)key {
    return [NSString stringWithFormat:@"%@.%@", kLQBundle, key];
}

@end
