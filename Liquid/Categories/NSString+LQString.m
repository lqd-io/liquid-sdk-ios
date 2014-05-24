//
//  NSString+RandomUserID.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import "NSString+LQString.h"
#import "NSData+LQData.h"

@implementation NSString (LQString)

+ (NSString *)generateRandomUniqueId {
    NSData *data = [NSData randomDataOfLength:16];
    NSString *dataStrWithoutBrackets = [[NSString stringWithFormat:@"%@", data] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    NSString *dataStr = [dataStrWithoutBrackets stringByReplacingOccurrencesOfString:@" "
                                                                          withString:@""];
    return dataStr;
}

+ (NSString *)generateRandomSessionIdentifier {
    return [[NSString alloc] initWithFormat:@"%@%ld", [self generateRandomUniqueId], (long)[[NSDate date] timeIntervalSince1970]];
}

@end
