//
//  NSDateFormatter+ISO8601.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateFormatter (ISO8601)

+ (NSDateFormatter *)ISO8601DateFormatter;
+ (NSDate *)dateFromISO8601String:(NSString *)ISO8601String;

@end
