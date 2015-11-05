//
//  NSDateFormatter+LQDateFormatter.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 15/05/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import "NSDateFormatter+LQDateFormatter.h"
#import "LQDefaults.h"
#import <UIKit/UIKit.h>

#define kLQISO8601DateFormat @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
#define kLQISO8601DateFormatWithoutMilliseconds @"yyyy-MM-dd'T'HH:mm:ssZZZZZ"
#define kLQISO8601DateFormatISO5 @"yyyy-MM-dd'T'HH:mm:ss.SSSZ"
#define kLQISO8601DateFormatWithoutMillisecondsISO5 @"yyyy-MM-dd'T'HH:mm:ssZ"

#ifdef __IPHONE_8_0
#define LQGregorianCalendar NSCalendarIdentifierGregorian
#else
#define LQGregorianCalendar NSGregorianCalendar
#endif

@implementation NSDateFormatter (LQDateFormatter)

+ (NSDateFormatter *)iso8601DateFormatterWithFormat:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:format];
    [formatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:LQGregorianCalendar]];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    return formatter;
}

#pragma mark - NSDate to NSString

+ (NSString *)iso8601StringFromDateIOS6:(NSDate *)date {
    NSDateFormatter *formatter = [NSDateFormatter iso8601DateFormatterWithFormat:kLQISO8601DateFormat];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

    NSString *string = [formatter stringFromDate:date];
    return string;
}

+ (NSString *)iso8601StringFromDateIOS5:(NSDate *)date {
    NSDateFormatter *formatter = [NSDateFormatter iso8601DateFormatterWithFormat:kLQISO8601DateFormatISO5];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

    NSString *string = [formatter stringFromDate:date];
    NSMutableString *adaptedString = [NSMutableString stringWithString:string];
    if ([adaptedString rangeOfString:@"+"].location != NSNotFound) {
        [adaptedString insertString:@":" atIndex:(adaptedString.length - 2)];
    }
    return adaptedString;
}

+ (NSString *)iso8601StringFromDate:(NSDate *)date {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        return [NSDateFormatter iso8601StringFromDateIOS6:date];
    } else {
        return [NSDateFormatter iso8601StringFromDateIOS5:date];
    }
}

#pragma mark - NSString to NSDate

+ (NSDate *)dateFromISO8601StringIOS6:(NSString *)string {
    NSDateFormatter *formatter = [NSDateFormatter iso8601DateFormatterWithFormat:kLQISO8601DateFormat];
    NSDate *date = [formatter dateFromString:string];
    if (!date) {
        [formatter setDateFormat:kLQISO8601DateFormatWithoutMilliseconds];
        date = [formatter dateFromString:string];
    }
    if (date) {
        return date;
    }
    return nil;
}

+ (NSDate *)dateFromISO8601StringIOS5:(NSString *)string {
    NSString *adaptedString = string;
    NSDateFormatter *formatter = [NSDateFormatter iso8601DateFormatterWithFormat:kLQISO8601DateFormatISO5];

    if ([adaptedString hasSuffix:@"Z"]) {
        adaptedString = [[string substringToIndex:(string.length-1)] stringByAppendingString:@"-0000"];
    }
    if ([adaptedString rangeOfString:@"+"].location != NSNotFound) {
        NSRange lastThree = NSMakeRange([adaptedString length] - 3, 3);
        adaptedString = [adaptedString stringByReplacingOccurrencesOfString:@":" withString:@"" options:0 range:lastThree];
    }
    NSDate *date = [formatter dateFromString:adaptedString];

    if (!date) {
        [formatter setDateFormat:kLQISO8601DateFormatWithoutMillisecondsISO5];
        date = [formatter dateFromString:adaptedString];
    }
    if (date) {
        return date;
    }
    return nil;
}

+ (NSDate *)dateFromISO8601String:(NSString *)string {
    if (!string) return nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        return [[self class] dateFromISO8601StringIOS6:string];
    } else {
        return [[self class] dateFromISO8601StringIOS5:string];
    }
}

@end
