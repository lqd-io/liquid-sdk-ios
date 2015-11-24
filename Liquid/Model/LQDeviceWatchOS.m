//
//  LQDeviceWatchOS.m
//  Liquid
//
//  Created by Miguel M. Almeida on 18/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDeviceWatchOS.h"
#import "LQDefaults.h"

#if LQ_WATCHOS
#import "NSString+LQString.h"

@import WatchKit;

static NSString *platform;

@implementation LQDeviceWatchOS

#pragma mark - Device Info

+ (NSString*)screenSize {
    CGFloat scale = [[WKInterfaceDevice currentDevice] screenScale];
    CGSize screenSize = [[WKInterfaceDevice currentDevice] screenBounds].size;
    NSInteger width = screenSize.width * scale;
    NSInteger height = screenSize.height * scale;
    return [NSString stringWithFormat:@"%ldx%ld", (unsigned long)width, (unsigned long)height];
}

+ (NSString *)platform {
    return @"watchOS";
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
#endif
