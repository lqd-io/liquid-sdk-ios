//
//  NSDateFormatter+LQDateFormatter.m.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __IPHONE_8_0
#define LQGregorianCalendar NSCalendarIdentifierGregorian
#else
#define LQGregorianCalendar NSGregorianCalendar
#endif

@interface NSDateFormatter (LQDateFormatter)

+ (NSString *)iso8601StringFromDate:(NSDate *)date;
+ (NSDate *)dateFromISO8601String:(NSString *)ISO8601String;

@end
