//
//  NSData+Random.m
//  Liquid
//
//  Created by Rui Peres on 15/05/2014.
//  Copyright (c) 2014 Liquid. All rights reserved.
//

#import "NSData+Random.h"

@implementation NSData (Random)

+ (NSData *)randomDataOfLength:(size_t)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
    return data;
}

@end
