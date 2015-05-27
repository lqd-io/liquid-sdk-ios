//
//  LQKeychainItem.m
//  Liquid
//
//  Created by Miguel M. Almeida on 13/05/15.
//  Copyright (c) 2015 Liquid. All rights reserved.
//

#import "LQKeychainItem.h"
#import "LQDefaults.h"

@import Security;

@interface LQKeychainItem ()

@property(nonatomic, strong, readonly) NSDictionary *keychainItem;

@end

@implementation LQKeychainItem

@synthesize key = _key;
@synthesize value = _value;
@synthesize keychainItem = _keychainItem;
@synthesize nameSpace = _nameSpace;

#pragma mark - Initializers

- (id)initWithKey:(NSString *)key namespace:(NSString *)nameSpace {
    self = [self init];
    if (self) {
        _nameSpace = nameSpace;
        _keychainItem = [LQKeychainItem keychainItemForKey:key service:_nameSpace];
        _key = key;
        [self reload];
    }
    return self;
}

- (id)initWithKey:(NSString *)key andValue:(NSString *)value namespace:(NSString *)nameSpace {
    self = [self init];
    if (self) {
        _nameSpace = nameSpace;
        _keychainItem = [LQKeychainItem keychainItemForKey:key service:_nameSpace];
        _key = key;
        _value = value;
    }
    return self;
}

#pragma mark - Instance methods

- (OSStatus)save {
    if (!_value) {
        return errSecParam;
    }
    if ([self exists]) {
        return [LQKeychainItem updateValue:_value inKeychainItem:_keychainItem];
    } else {
        return [LQKeychainItem setValue:_value inKeychainItem:_keychainItem];
    }
}

- (OSStatus)reload {
    OSStatus status = noErr;
    _value = [LQKeychainItem valueFromKeychainItem:_keychainItem statusCode:status];
    return status;
}

- (BOOL)exists {
    return [LQKeychainItem keychainContainsItem:_keychainItem];
}

#pragma mark - Class methods

+ (OSStatus)setValue:(NSString *)value inKeychainItem:(NSDictionary *)keychainItem {
    NSMutableDictionary *mutableKeychain = [NSMutableDictionary dictionaryWithDictionary:keychainItem];
    mutableKeychain[(__bridge id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
    return SecItemAdd((__bridge CFDictionaryRef)mutableKeychain, NULL);
}

+ (OSStatus)updateValue:(NSString *)value inKeychainItem:(NSDictionary *)keychainItem {
    NSMutableDictionary *mutableKeychain = [NSMutableDictionary dictionaryWithDictionary:keychainItem];
    NSMutableDictionary *attributesToUpdate = [[NSMutableDictionary alloc] init];
    attributesToUpdate[(__bridge id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
    return SecItemUpdate((__bridge CFDictionaryRef)mutableKeychain, (__bridge CFDictionaryRef)attributesToUpdate);
}

+ (BOOL)keychainContainsItem:(NSDictionary *)keychainItem {
    return (SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL) == noErr);
}

+ (NSDictionary *)keychainItemForKey:(NSString *)key service:(NSString *)service {
    NSMutableDictionary *keychainItem = [[NSMutableDictionary alloc] init];
    keychainItem[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    keychainItem[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAlways;
    keychainItem[(__bridge id)kSecAttrAccount] = key;
    keychainItem[(__bridge id)kSecAttrService] = service;
    return keychainItem;
}

+ (NSString *)valueFromKeychainItem:(NSDictionary *)keychainItem statusCode:(OSStatus)status {
    NSMutableDictionary *mutableKeychainItem = [NSMutableDictionary dictionaryWithDictionary:keychainItem];
    mutableKeychainItem[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    mutableKeychainItem[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;
    CFDictionaryRef result = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)mutableKeychainItem, (CFTypeRef *)&result);
    if (status == noErr) {
        NSDictionary *resultDict = (__bridge_transfer NSDictionary *)result;
        NSData *data = resultDict[(__bridge id)kSecValueData];
        if (data) {
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        } else {
            status = errSecItemNotFound;
        }
    }
    return nil;
}

@end
