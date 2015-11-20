//
//  LQDeviceIOS.m
//  Liquid
//
//  Created by Miguel M. Almeida on 18/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDeviceIOS.h"
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "NSString+LQString.h"

#ifdef LIQUID_USE_IFA
#import <AdSupport/ASIdentifierManager.h>
#endif

#define kLQDeviceVendor @"Apple"
#define KLQDeviceReachabilityUrl "www.google.com"
#define kLQDeviceWifi @"WiFi"
#define kLQDeviceCellular @"Cellular"
#define kLQDeviceNoConnectivity @"No Connectivity"

@interface LQDeviceIOS ()

@property (nonatomic, assign) SCNetworkReachabilityRef networkReachability;

@end

@implementation LQDeviceIOS

- (id)init {
    self = [super init];
    if(self) {
        _deviceName = [[self class] deviceName];
        _carrier = [[self class] carrier];

        [self initReachabilityCallback];
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            [self reachabilityChanged:flags];
        } else {
            _internetConnectivity = kLQDeviceNoConnectivity;
        }
    }
    return self;
}

#pragma mark - Deallocation

- (void)dealloc{
    if (self.networkReachability) {
        SCNetworkReachabilitySetCallback(self.networkReachability, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(self.networkReachability, NULL);
        self.networkReachability = nil;
    }
}

#pragma mark - JSON

- (NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super jsonDictionary]];
    [dictionary setObject:_deviceName forKey:@"name"];
    [dictionary setObject:_carrier forKey:@"carrier"];
    [dictionary setObject:_internetConnectivity forKey:@"internet_connectivity"];
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

#pragma mark - Device Info

+ (NSString*)carrier {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    if (carrier.carrierName.length) {
        return carrier.carrierName;
    }
    return @"No Carrier";
}

+ (NSString*)screenSize {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    NSInteger width = screenSize.width * scale;
    NSInteger height = screenSize.height * scale;
    return [NSString stringWithFormat:@"%ldx%ld", (unsigned long)width, (unsigned long)height];
}

+ (NSString *)platform {
    return @"iOS";
}

+ (NSString*)systemVersion {
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString*)deviceName {
    return [[UIDevice currentDevice] name];
}

#pragma mark - Device Unique ID

+ (NSString *)appleIFA {
    NSString *ifa = nil;
#ifndef LIQUID_NO_IFA
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *advertisingIdentifier = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        ifa = [advertisingIdentifier UUIDString];
    }
#endif
    return ifa;
}

+ (NSString *)appleIFV {
    NSString *ifv = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        if (NSClassFromString(@"UIDevice")) {
            ifv = [[UIDevice currentDevice].identifierForVendor UUIDString];
        }
    }
    return ifv;
}

+ (NSString *)generateDeviceUID {
    NSString *newUid;
    if ((newUid = [[self class] appleIFA])) {
        return newUid;
    }
    if ((newUid = [[self class] appleIFV])) {
        return newUid;
    }
    return [NSString generateRandomUUID];
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _deviceName = [aDecoder decodeObjectForKey:@"deviceName"];
        _carrier = [aDecoder decodeObjectForKey:@"carrier"];
        _internetConnectivity = [aDecoder decodeObjectForKey:@"internetConnectivity"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_deviceName forKey:@"deviceName"];
    [aCoder encodeObject:_carrier forKey:@"carrier"];
    [aCoder encodeObject:_internetConnectivity forKey:@"internetConnectivity"];
}

#pragma mark - Reachability

- (void)initReachabilityCallback {
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
            LQDeviceIOS *device = (__bridge LQDeviceIOS *)info;
            [device reachabilityChanged:flags];
        }
    } else {
        //NSLog(@"Reachability: Unexpected info");
    }
}

- (BOOL)reachesInternet {
    if (_internetConnectivity == nil || ![_internetConnectivity isEqualToString:kLQDeviceNoConnectivity]) {
        return true;
    } else {
        return false;
    }
}

@end
