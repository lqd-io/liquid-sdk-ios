//
//  NSString+LQString.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LQString)

+ (NSString *)generateRandomUUIDAppendingTimestamp:(BOOL)appendTimestamp;
+ (NSString *)generateRandomUUID;
+ (NSString *)md5ofString:(NSString *)string;

@end
