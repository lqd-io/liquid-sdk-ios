//
//  LQSession.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQSession.h"
#import "LQDefaults.h"

@implementation LQSession

#pragma mark - Initializer

-(id)initWithDate:(NSDate *)date timeout:(NSNumber*)timeout {
    self = [super init];
    if(self) {
        _identifier = [LQSession newSessionIdentifier];
        _start = [NSDate date];
        _timeout = timeout;
        _attributes = [NSDictionary new];
    }
    return self;
}

#pragma mark - Attributes

-(void)setAttribute:(id<NSCoding>)attribute forKey:(NSString *)key {
    NSMutableDictionary *mutableAttributes = [_attributes mutableCopy];
    [mutableAttributes setObject:attribute forKey:key];
    _attributes = mutableAttributes;
}

-(id)attributeForKey:(NSString *)key {
    return [_attributes objectForKey:key];
}

-(void)endSessionOnDate:(NSDate *)endDate {
    _end = endDate;
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary{
    return [self jsonDictionaryWithUser:nil device:nil];
}

-(NSDictionary *)jsonDictionaryWithUser:(LQUser *)user device:(LQDevice *)device {
    NSDateFormatter *dateFormatter = [[self class] isoDateFormatter];
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary addEntriesFromDictionary:_attributes];
    [dictionary setObject:_identifier forKey:@"unique_id"];
    [dictionary setObject:[dateFormatter stringFromDate:_start] forKey:@"started_at"];
    [dictionary setObject:_timeout forKey:@"timeout"];
    if(_end != nil)
        [dictionary setObject:[dateFormatter stringFromDate:_end] forKey:@"ended_at"];
    if(user != nil)
        [dictionary setObject:[user jsonDictionary] forKey:@"user"];
    if(device != nil)
        [dictionary setObject:[device jsonDictionary] forKey:@"device"];
    return dictionary;
}

#pragma mark - Session Identifier Generator

+(NSString*)newSessionIdentifier {
    NSData *data = [LQSession randomDataOfLength:16];
    NSString *dataStrWithoutBrackets = [[NSString stringWithFormat:@"%@", data] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    NSString *dataStr = [dataStrWithoutBrackets stringByReplacingOccurrencesOfString:@" " withString:@""];
    return [[NSString alloc] initWithFormat:@"%@%ld", dataStr, (long)[[NSDate date] timeIntervalSince1970]];
}

+ (NSData *)randomDataOfLength:(size_t)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
    return data;
}

+(NSDateFormatter *)isoDateFormatter {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kLQISO8601DateFormat];
    [formatter setCalendar:gregorianCalendar];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    return formatter;
}

@end
