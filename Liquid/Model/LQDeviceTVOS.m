//
//  LQDeviceTVOS.m
//  Liquid
//
//  Created by Miguel M. Almeida on 16/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQDeviceTVOS.h"
#import "LQDefaults.h"

#if LQ_TVOS
#import <UIKit/UIDevice.h>
#import <UIKit/UIScreen.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "NSString+LQString.h"

#ifdef LIQUID_USE_IFA
#import <AdSupport/ASIdentifierManager.h>
#endif

@implementation LQDeviceTVOS

#pragma mark - JSON

- (NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super jsonDictionary]];
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

#pragma mark - Device Info

+ (NSString*)screenSize {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    NSInteger width = screenSize.width * scale;
    NSInteger height = screenSize.height * scale;
    return [NSString stringWithFormat:@"%ldx%ld", (unsigned long)width, (unsigned long)height];
}

+ (NSString *)platform {
    return @"tvOS";
}

+ (NSString*)systemVersion {
    return [[UIDevice currentDevice] systemVersion];
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
    return [[UIDevice currentDevice].identifierForVendor UUIDString];
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

#pragma mark - Reachability

- (BOOL)reachesInternet {
    return true;
}

@end
#endif
