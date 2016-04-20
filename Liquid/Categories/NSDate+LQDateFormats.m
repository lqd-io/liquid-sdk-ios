//
//  NSDate+LQDateFormats.m
//  Liquid
//
//  Created by Miguel M. Almeida on 18/04/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "NSDate+LQDateFormats.h"
#import "NSDateFormatter+LQDateFormatter.h"

#define kLQRFC1123DateFormat @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"

@implementation NSDate (LQDateFormats)

- (NSString *)rfc1123String {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    formatter.dateFormat = kLQRFC1123DateFormat;
    formatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:LQGregorianCalendar];
    return [formatter stringFromDate:self];
}

@end
