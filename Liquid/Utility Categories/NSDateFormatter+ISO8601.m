//
//  NSDateFormatter+ISO8601.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "NSDateFormatter+ISO8601.h"
#import "LQDefaults.h"

@implementation NSDateFormatter (ISO8601)

+ (NSDateFormatter *)ISO8601DateFormatter {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kLQISO8601DateFormat];
    [formatter setCalendar:gregorianCalendar];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    return formatter;
}

+ (NSDate *)dateFromISO8601String:(NSString *)iso8601String {
    NSDateFormatter *dateFormatter = [NSDateFormatter ISO8601DateFormatter];
    NSDate *date = [dateFormatter dateFromString:iso8601String];
    if (!date) {
        [dateFormatter setDateFormat:kLQISO8601DateFormatWithoutMilliseconds];
        date = [dateFormatter dateFromString:iso8601String];
    }
    if(date) {
        return date;
    }
    return nil;
}


@end
