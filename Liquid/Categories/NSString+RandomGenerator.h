//
//  NSString+RandomUserID.h
//  Liquid
//
//  Created by Rui Peres on 15/05/2014.
//  Copyright (c) 2014 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RandomGenerator)

+ (NSString *)generateRandomUniqueId;
+ (NSString *)generateRandomSessionIdentifier;

@end
