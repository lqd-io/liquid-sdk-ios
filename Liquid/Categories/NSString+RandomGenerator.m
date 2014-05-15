//
//  NSString+RandomUserID.m
//  Liquid
//
//  Created by Rui Peres on 15/05/2014.
//  Copyright (c) 2014 Liquid. All rights reserved.
//

#import "NSString+RandomGenerator.h"
#import "NSData+Random.h"

@implementation NSString (RandomGenerator)

+ (NSString *)generateRandomUniqueId {
    NSData *data = [NSData randomDataOfLength:16];
    NSString *dataStrWithoutBrackets = [[NSString stringWithFormat:@"%@", data]
                                        stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    NSString *dataStr = [dataStrWithoutBrackets stringByReplacingOccurrencesOfString:@" "
                                                                          withString:@""];
    return dataStr;
}

+ (NSString *)generateRandomSessionIdentifier {
    NSData *data = [NSData randomDataOfLength:16];
    NSString *dataStrWithoutBrackets = [[NSString stringWithFormat:@"%@", data] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    NSString *dataStr = [dataStrWithoutBrackets stringByReplacingOccurrencesOfString:@" " withString:@""];
    return [[NSString alloc] initWithFormat:@"%@%ld", dataStr, (long)[[NSDate date] timeIntervalSince1970]];
}


@end
