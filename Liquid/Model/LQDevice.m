//
//  LQDevice.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQDefaults.h"
#import "LQDevice.h"
#import "LQKeychain.h"
#import "LQStorage.h"
#import "LQUserDefaults.h"
#include <sys/sysctl.h>
#define kLQDeviceVendor @"Apple"

static LQDevice *sharedInstance = nil;

@implementation LQDevice

@synthesize uid = _uid;

#pragma mark - Singleton

+ (LQDevice *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)resetSharedInstance {
    sharedInstance = [[self alloc] init];
}

#pragma mark - Initializer

- (id)init {
    self = [super init];
    if(self) {
        _vendor = kLQDeviceVendor;
        _deviceModel = [[self class] deviceModel];
        _platform = [[self class] platform];
        _systemVersion = [[self class] systemVersion];
        _systemLanguage = [[self class] systemLanguage];
        _locale = [[self class] locale];
        _screenSize = [[self class] screenSize];
        _uid = [self uid];
        _appBundle = [[self class] appBundle];
        _appName = [[self class] appName];
        _appVersion = [[self class] appVersion];
        _releaseVersion = [[self class] releaseVersion];
        _liquidVersion = [[self class] liquidVersion];

        _uid = [[self class] uniqueId];
        [self storeUniqueId];

        NSString *apnsTokenCacheKey = [NSString stringWithFormat:@"%@.%@", kLQBundle, @"APNSToken"];
        _apnsToken = [[NSUserDefaults standardUserDefaults] objectForKey:apnsTokenCacheKey];
        if(_attributes == nil) {
            _attributes = [NSDictionary new];
        }
    }
    return self;
}

#pragma mark - Attributes

- (void)setAttribute:(id<NSCoding>)attribute forKey:(NSString *)key {
    if (![LQDevice assertAttributeType:attribute andKey:key]) return;

    NSMutableDictionary *mutableAttributes = [_attributes mutableCopy];
    [mutableAttributes setObject:attribute forKey:key];
    _attributes = [NSDictionary dictionaryWithDictionary:mutableAttributes];
}

- (id)attributeForKey:(NSString *)key {
    return [_attributes objectForKey:key];
}

- (void)setLocation:(CLLocation *)location {
    NSMutableDictionary *mutableAttributes = [_attributes mutableCopy];
    if(location == nil) {
        [mutableAttributes removeObjectForKey:@"latitude"];
        [mutableAttributes removeObjectForKey:@"longitude"];
    } else {
        [mutableAttributes setObject:[NSNumber numberWithFloat:location.coordinate.latitude] forKey:@"latitude"];
        [mutableAttributes setObject:[NSNumber numberWithFloat:location.coordinate.longitude] forKey:@"longitude"];
    }
    _attributes = [NSDictionary dictionaryWithDictionary:mutableAttributes];
}

+ (NSDictionary *)reservedAttributes {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @YES, @"_id",
            @YES, @"id",
            @YES, @"unique_id",
            @YES, @"platform",
            @YES, @"ip_address",
            @YES, @"created_at",
            @YES, @"updated_at", nil];
}

#pragma mark - JSON

- (NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_vendor forKey:@"vendor"];
    [dictionary setObject:_deviceModel forKey:@"model"];
    [dictionary setObject:_systemVersion forKey:@"system_version"];
    [dictionary setObject:_systemLanguage forKey:@"system_language"];
    [dictionary setObject:_locale forKey:@"locale"];
    [dictionary setObject:_screenSize forKey:@"screen_size"];
    if (_appBundle) {
        [dictionary setObject:_appBundle forKey:@"app_bundle"];
    }
    if (_appName) {
        [dictionary setObject:_appName forKey:@"app_name"];
    }
    if (_appVersion) {
        [dictionary setObject:_appVersion forKey:@"app_version"];
    }
    if (_releaseVersion) {
        [dictionary setObject:_releaseVersion forKey:@"release_version"];
    }
    if (_apnsToken) {
        [dictionary setObject:_apnsToken forKey:@"push_token"];
    }
    [dictionary setObject:_liquidVersion forKey:@"liquid_version"];
    [dictionary setObject:self.uid forKey:@"unique_id"];
    [dictionary setObject:self.platform forKey:@"platform"];

    return [NSDictionary dictionaryWithDictionary:dictionary];
}


#pragma mark - Device Info

+ (NSString*)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithUTF8String:machine];
    free(machine);
    return deviceModel;
}

+ (NSString*)screenSize {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)platform {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString*)systemVersion {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString*)liquidVersion {
    return kLQVersion;
}

+ (NSString*)systemLanguage {
    return [[NSLocale preferredLanguages] firstObject];
}

+ (NSString*)locale {
    return [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
}

#pragma mark - Device Unique ID

/*! Stores the UniqueId in Keychain (1), so it can be persisted between different installations.
 *  A backup of this UniqueId is also created on disk (2) to avoid generating
 *  a new ID if keychain access is lost by a new provisioning profile, and also in  NSUserDefaults (3)
 *  if Liquid cache files are reset with [softReset] or [hardReset] methods.
 */
- (void)storeUniqueId {
    [LQKeychain setValue:_uid forKey:@"device.unique_id" allowUpdate:NO]; // 1.
    [LQDevice archiveUniqueId:_uid allowUpdate:NO]; // 2.
    [LQUserDefaults setObject:_uid forKey:@"UUID" allowUpdate:NO]; // 3.
}

/*! Retrieves the device UniqueId, by its order of veracity:
 *  1. Keychain
 *  2. File
 *  3. Standard NSUserDefaults (retro compatibility)
 *  4. Generate a new ID
 */
+ (NSString*)uniqueId {
    NSString *uniqueId;
    if ((uniqueId = [[self class] uniqueIdFromKeychain])) { // 1.
        LQLog(kLQLogLevelData, @"Retrieved Device UniqueId from Keychain: %@", uniqueId);
        return uniqueId;
    }
    if ((uniqueId = [[self class] uniqueIdFromArchive])) { // 2.
        LQLog(kLQLogLevelData, @"Retrieved Device UniqueId from file: %@", uniqueId);
        return uniqueId;
    }
    if ((uniqueId = [[self class] uniqueIdFromNSUserDefaults])) { // 3.
        LQLog(kLQLogLevelData, @"Retrieved Device UniqueId from NSUserDefaults: %@", uniqueId);
        return uniqueId;
    }
    uniqueId = [[self class] generateDeviceUID]; // 4.
    LQLog(kLQLogLevelData, @"No Device UniqueId found in cache (Keychain, file or NSUserDefaults). Generating a new one: %@", uniqueId);
    return uniqueId;
}

+ (NSString *)uniqueIdFromKeychain {
    return [LQKeychain valueForKey:@"device.unique_id"];
}

+ (NSString *)uniqueIdFromNSUserDefaults {
    NSString *liquidUUIDKey = [NSString stringWithFormat:@"%@.%@", kLQBundle, @"UUID"];
    return [[NSUserDefaults standardUserDefaults]objectForKey:liquidUUIDKey];
}

+ (NSString *)uniqueIdFromArchive {
    return [[self class] unarchiveUniqueId];
}

+ (NSString *)generateDeviceUID {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark - Application Info

+ (NSString*)appName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
}

+ (NSString*)appBundle {
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSString*)appVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (NSString*)releaseVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

#pragma mark - Reachability

- (BOOL)reachesInternet {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _vendor = [aDecoder decodeObjectForKey:@"vendor"];
        _deviceModel = [aDecoder decodeObjectForKey:@"deviceModel"];
        _systemVersion = [aDecoder decodeObjectForKey:@"systemVersion"];
        _systemLanguage = [aDecoder decodeObjectForKey:@"systemLanguage"];
        _locale = [aDecoder decodeObjectForKey:@"locale"];
        _screenSize = [aDecoder decodeObjectForKey:@"screenSize"];
        _uid = [aDecoder decodeObjectForKey:@"uid"];
        _appBundle = [aDecoder decodeObjectForKey:@"appBundle"];
        _appName = [aDecoder decodeObjectForKey:@"appName"];
        _appVersion = [aDecoder decodeObjectForKey:@"appVersion"];
        _releaseVersion = [aDecoder decodeObjectForKey:@"releaseVersion"];
        _liquidVersion = [aDecoder decodeObjectForKey:@"liquidVersion"];
        _apnsToken = [aDecoder decodeObjectForKey:@"apnsToken"];
        _attributes = [aDecoder decodeObjectForKey:@"attributes"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_vendor forKey:@"vendor"];
    [aCoder encodeObject:_deviceModel forKey:@"deviceModel"];
    [aCoder encodeObject:_systemVersion forKey:@"systemVersion"];
    [aCoder encodeObject:_systemLanguage forKey:@"systemLanguage"];
    [aCoder encodeObject:_locale forKey:@"locale"];
    [aCoder encodeObject:_screenSize forKey:@"screenSize"];
    [aCoder encodeObject:_uid forKey:@"uid"];
    [aCoder encodeObject:_appBundle forKey:@"appBundle"];
    [aCoder encodeObject:_appName forKey:@"appName"];
    [aCoder encodeObject:_appVersion forKey:@"appVersion"];
    [aCoder encodeObject:_releaseVersion forKey:@"releaseVersion"];
    [aCoder encodeObject:_liquidVersion forKey:@"liquidVersion"];
    [aCoder encodeObject:_apnsToken forKey:@"apnsToken"];
    [aCoder encodeObject:_attributes forKey:@"attributes"];
}

#pragma mark - Archive to/from disk

+ (BOOL)archiveUniqueId:(NSString *)uniqueId allowUpdate:(BOOL)allowUpdate {
    if (!allowUpdate && [LQStorage fileExists:[self uniqueIdFile]]) {
        return NO;
    }
    LQLog(kLQLogLevelData, @"<Liquid> Saving Device UniqueId to disk");
    return [NSKeyedArchiver archiveRootObject:uniqueId toFile:[[self class] uniqueIdFile]];
}

+ (NSString *)unarchiveUniqueId {
    NSString *filePath = [[self class] uniqueIdFile];
    NSString *uniqueId = nil;
    @try {
        id object = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        uniqueId = [object isKindOfClass:[NSString class]] ? object : nil;
        LQLog(kLQLogLevelData, @"<Liquid> Loaded Device UID from disk");
    }
    @catch (NSException *exception) {
        LQLog(kLQLogLevelError, @"<Liquid> %@: Found invalid Device UID on cache. Destroying it...", [exception name]);
        [LQStorage deleteFileIfExists:filePath error:nil];
    }
    return uniqueId;
}

+ (NSString *)uniqueIdFile {
    return [LQStorage filePathForAllTokensWithExtension:@"device.unique_id"];
}

+ (void)deleteUniqueIdFile {
    NSString *filePath = [[self class] uniqueIdFile];
    LQLog(kLQLogLevelInfo, @"<Liquid> Deleting cached Device UID");
    NSError *error;
    [LQStorage deleteFileIfExists:filePath error:&error];
    if (error) {
        LQLog(kLQLogLevelError, @"<Liquid> Error deleting cached Device UID");
    }
}

@end
