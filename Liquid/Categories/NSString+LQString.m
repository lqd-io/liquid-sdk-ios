//
//  NSString+LQString.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import "NSString+LQString.h"
#import "NSData+LQData.h"
#import <CommonCrypto/CommonDigest.h>
#import "LQDefaults.h"
#import <UIKit/UIDevice.h>

@implementation NSString (LQString)

+ (NSString *)generateRandomUUIDAppendingTimestamp:(BOOL)appendTimestamp {
    NSString *uuid;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        uuid = [[NSUUID UUID] UUIDString];
    } else {
        CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef cfuuid = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
        CFRelease(uuidRef);
        uuid = [((__bridge NSString *) cfuuid) copy];
        CFRelease(cfuuid);
    }

    if (appendTimestamp) {
        return [NSString stringWithFormat:@"%@-%ld", uuid, (long) [[NSDate date] timeIntervalSince1970]];
    } else {
        return uuid;
    }
}

+ (NSString *)generateRandomUUID {
    return [self generateRandomUUIDAppendingTimestamp:NO];
}

+ (NSString *)md5ofString:(NSString *)string {
    const char *cstr = [string UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (int) strlen(cstr), result);
    return [NSString stringWithFormat:
        @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
        result[0], result[1], result[2], result[3],
        result[4], result[5], result[6], result[7],
        result[8], result[9], result[10], result[11],
        result[12], result[13], result[14], result[15]
    ];
}


@end
