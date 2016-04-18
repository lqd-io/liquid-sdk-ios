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
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        dateFormatter.dateFormat = kLQRFC1123DateFormat;
        dateFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:LQGregorianCalendar];
    }
    return [dateFormatter stringFromDate:self];
}

@end
