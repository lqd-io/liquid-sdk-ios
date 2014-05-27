//
//  NSString+RandomUserID.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import "NSString+LQString.h"
#import "NSData+LQData.h"
#import "LQDefaults.h"
#import <UIKit/UIDevice.h>

@implementation NSString (LQString)

+ (NSString *)generateRandomUUIDAppendingTimestamp:(BOOL)appendTimestamp {
    NSString *uuid;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        uuid = [[NSUUID UUID] UUIDString];
    } else {
        CFUUIDRef cfuuid = CFUUIDCreate(kCFAllocatorDefault);
        uuid = (NSString *) CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, cfuuid));
    }

    if (appendTimestamp) {
        return [[NSString alloc] initWithFormat:@"%@-%ld", uuid, (long) [[NSDate date] timeIntervalSince1970]];
    } else {
        return uuid;
    }
}

+ (NSString *)generateRandomUUID {
    return [self generateRandomUUIDAppendingTimestamp:NO];
}

@end
