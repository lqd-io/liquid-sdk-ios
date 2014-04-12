//
//  LQDevice.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQDevice.h"
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#include <sys/sysctl.h>

#import <AdSupport/ASIdentifierManager.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define kLQDeviceVendor @"Apple"
#define KLQDeviceReachabilityUrl "www.google.com"
#define kLQDeviceWifi @"WiFi"
#define kLQDeviceCellular @"Cellular"
#define kLQDeviceNoConnectivity @"No Connectivity"

@interface LQDevice ()

@property (nonatomic, assign) SCNetworkReachabilityRef networkReachability;

@end

@implementation LQDevice

#pragma mark - Initializer

-(id)initWithLiquidVersion:(NSString *)liquidVersion {
    self = [super init];
    if(self) {
        _vendor = kLQDeviceVendor;
        _deviceModel = [LQDevice deviceModel];
        _systemVersion = [LQDevice systemVersion];
        _deviceName = [LQDevice deviceName];
        _carrier = [LQDevice carrier];
        _screenSize = [LQDevice screenSize];
        _uid = [LQDevice uid];
        _appBundle = [LQDevice appBundle];
        _appName = [LQDevice appName];
        _appVersion = [LQDevice appVersion];
        _releaseVersion = [LQDevice releaseVersion];
        _liquidVersion = liquidVersion;
        [self initReachabilityCallback];
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            [self reachabilityChanged:flags];
        } else {
            _internetConnectivity = kLQDeviceNoConnectivity;
        }
        if(_attributes == nil)
            _attributes = [NSDictionary new];
        
    }
    return self;
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

#pragma mark - Deallocation

-(void)dealloc{
    if (self.networkReachability) {
        SCNetworkReachabilitySetCallback(self.networkReachability, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(self.networkReachability, NULL);
        self.networkReachability = nil;
    }
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    return [self jsonDictionaryWithUser:nil];
}

-(NSDictionary *)jsonDictionaryWithUser:(LQUser *)user {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_vendor forKey:@"_vendor"];
    [dictionary setObject:_deviceModel forKey:@"_deviceModel"];
    [dictionary setObject:_systemVersion forKey:@"_systemVersion"];
    [dictionary setObject:_deviceName forKey:@"_deviceName"];
    [dictionary setObject:_screenSize forKey:@"_screenSize"];
    [dictionary setObject:_carrier forKey:@"_carrier"];
    [dictionary setObject:_internetConnectivity forKey:@"_internetConnectivity"];
    [dictionary setObject:_uid forKey:@"_uid"];
    [dictionary setObject:_appBundle forKey:@"_appBundle"];
    [dictionary setObject:_appName forKey:@"_appName"];
    [dictionary setObject:_appVersion forKey:@"_appVersion"];
    [dictionary setObject:_releaseVersion forKey:@"_releaseVersion"];
    [dictionary setObject:_liquidVersion forKey:@"_liquidVersion"];
    [dictionary setObject:self.uid forKey:@"unique_id"];
    [dictionary setObject:@"iOS" forKey:@"platform"];
    
    if(user != nil)
        [dictionary setObject:[user jsonDictionary] forKey:@"user"];
    return dictionary;
}


#pragma mark - Device Info

+(NSString*)carrier {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    if (carrier.carrierName.length) {
        return  carrier.carrierName;
    }
    return @"No Carrier";
}

+(NSString*)screenSize {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    NSInteger width = screenSize.width  *scale;
    NSInteger height = screenSize.height  *scale;
    return [NSString stringWithFormat:@"%ldx%ld", (unsigned long)width, (unsigned long)height];
}

+(NSString*)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithUTF8String:machine];
    free(machine);
    return deviceModel;
}

+(NSString*)systemVersion {
    return [[UIDevice currentDevice]systemVersion];
}

+(NSString*)deviceName {
    return [[UIDevice currentDevice]name];
}

+(NSString*)uid {
    NSString *uid;
    if (NSClassFromString(@"ASIdentifierManager")) {
        uid = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    }
    if (uid == nil) {
        NSString *liquidUUIDKey = @"com.liquid.UUID";
        NSString *uuid = [[NSUserDefaults standardUserDefaults]objectForKey:liquidUUIDKey];
        if(uuid == nil) {
            uuid = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults]setObject:uuid forKey:liquidUUIDKey];
            [[NSUserDefaults standardUserDefaults]synchronize];
        }
        uid = uuid;
    }
    return uid;
}

#pragma mark - Application Info

+(NSString*)appName{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
}

+(NSString*)appBundle{
    return [[NSBundle mainBundle] bundleIdentifier];
}

+(NSString*)appVersion{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+(NSString*)releaseVersion{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

#pragma mark - Reachability

-(void)initReachabilityCallback {
    BOOL reachabilityInitated = NO;
    self.networkReachability = SCNetworkReachabilityCreateWithName(NULL, KLQDeviceReachabilityUrl);
    if (self.networkReachability != NULL) {
        SCNetworkReachabilityContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
        if (SCNetworkReachabilitySetCallback(self.networkReachability, LQDeviceNetworkReachabilityCallback, &context)) {
            dispatch_queue_t queue  = dispatch_queue_create("LQReachabilityQueue", DISPATCH_QUEUE_SERIAL);
            if (SCNetworkReachabilitySetDispatchQueue(self.networkReachability, queue)) {
                reachabilityInitated = YES;
            } else {
                // cleanup callback if setting dispatch queue failed
                SCNetworkReachabilitySetCallback(self.networkReachability, NULL, NULL);
            }
        }
    }
    if (!reachabilityInitated) {
        //NSLog(@"%@ failed to set up reachability callback: %s", self, SCErrorString(SCError()));
    }
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags {
    if(flags & kSCNetworkReachabilityFlagsReachable) {
        if(flags & kSCNetworkReachabilityFlagsIsWWAN) {
            _internetConnectivity = kLQDeviceCellular;
        } else {
            _internetConnectivity = kLQDeviceWifi;
        }
    } else {
        _internetConnectivity = kLQDeviceNoConnectivity;
    }
}

static void LQDeviceNetworkReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    if (info != NULL && [(__bridge NSObject*)info isKindOfClass:[LQDevice class]]) {
        @autoreleasepool {
            LQDevice *device = (__bridge LQDevice *)info;
            [device reachabilityChanged:flags];
        }
    } else {
        //NSLog(@"Reachability: Unexpected info");
    }
}

@end
