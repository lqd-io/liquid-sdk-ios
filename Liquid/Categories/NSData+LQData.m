//
//  NSData+LQData.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import "NSData+LQData.h"

@implementation NSData (LQData)

+ (NSData *)randomDataOfLength:(size_t)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
    return data;
}

- (NSString *)hexadecimalString {
    NSMutableString *hexToken;
    const unsigned char *iterator = (const unsigned char *) [self bytes];
    if (iterator) {
        hexToken = [[NSMutableString alloc] init];
        for (NSInteger i = 0; i < self.length; i++) {
            [hexToken appendString:[NSString stringWithFormat:@"%02lx", (unsigned long) iterator[i]]];
        }
        return hexToken;
    }
    return nil;
}

@end
