//
//  NSDateFormatter+LQDateFormatter.m.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateFormatter (LQDateFormatter)

+ (NSString *)iso8601StringFromDate:(NSDate *)date;
+ (NSDate *)dateFromISO8601String:(NSString *)ISO8601String;

@end
