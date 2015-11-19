//
//  LQDeviceWatchOS.m
//  Liquid
//
//  Created by Miguel M. Almeida on 18/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDeviceWatchOS.h"
#import "NSString+LQString.h"

@import WatchKit;

@implementation LQDeviceWatchOS

#pragma mark - Device Info

+ (NSString*)screenSize {
    return @"n/a";
}

+ (NSString*)systemVersion {
    return @"n/a";
}

#pragma mark - Device Unique ID

+ (NSString *)generateDeviceUID {
    return [NSString generateRandomUUID];
}

#pragma mark - Reachability

- (BOOL)reachesInternet {
    return true;
}

@end
