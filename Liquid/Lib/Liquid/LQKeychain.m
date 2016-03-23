//
//  LQKeyChain.m
//  Liquid
//
//  Created by Miguel M. Almeida on 13/05/15.
//  Copyright (c) 2015 Liquid. All rights reserved.
//

#import "LQKeychain.h"
#import "LQKeychainItem.h"
#import "LQDefaults.h"

@implementation LQKeychain

+ (BOOL)setValue:(NSString *)value forKey:(NSString *)key allowUpdate:(BOOL)allowUpdate {
    LQKeychainItem *item = [[LQKeychainItem alloc] initWithKey:key andValue:value namespace:[LQKeychain liquidNameSpace]];
    if (allowUpdate || ![item exists]) {
        LQLog(kLQLogLevelData, @"<Liquid> Saved value '%@' in Keychain for key '%@'.", value, key);
        return [item save] == noErr;
    }
    return NO;
}

+ (NSString *)valueForKey:(NSString *)key {
    LQKeychainItem *item = [[LQKeychainItem alloc] initWithKey:key namespace:[LQKeychain liquidNameSpace]];
    LQLog(kLQLogLevelData, @"<Liquid> Retrieved value '%@' from Keychain for key '%@'.", item.value, item.key);
    return item.value;
}

+ (NSString *)liquidNameSpace {
    return [NSString stringWithFormat:@"%@.keychain", kLQBundle];
}

@end
