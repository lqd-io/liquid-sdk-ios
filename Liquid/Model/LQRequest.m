//
//  LQQueue.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 13/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQRequest.h"

@implementation LQRequest

#define kLQQueueUrl @"Url"
#define kLQQueueHttpMethod @"HttpMethod"
#define kLQQueueJSON @"JSON"
#define kLQQueueNumberOfTries @"NumberOfTries"

NSInteger const LQQueueStatusOk = 0;
NSInteger const LQQueueStatusUnreachable = 1;
NSInteger const LQQueueStatusUnauthorized = 2;
NSInteger const LQQueueStatusRejected = 3;

@synthesize nextTryAfter = _nextTryAfter;

#pragma mark - Initializers

-(id)initWithUrl:(NSString *)url withHttpMethod:(NSString *)httpMethod withJSON:(NSData *)json {
    self = [super init];
    if(self) {
        _url = url;
        _httpMethod = httpMethod;
        _json = json;
        _numberOfTries = [NSNumber numberWithInt:0];
    }
    return self;
}

-(NSDate *)nextTryAfter {
    if (!_nextTryAfter) {
        _nextTryAfter = [NSDate dateWithTimeIntervalSince1970:0];
    }
    return _nextTryAfter;
}

#pragma mark - NSCoding

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        _url = [aDecoder decodeObjectForKey:kLQQueueUrl];
        _httpMethod = [aDecoder decodeObjectForKey:kLQQueueHttpMethod];
        _json = [aDecoder decodeObjectForKey:kLQQueueJSON];
        _numberOfTries = [aDecoder decodeObjectForKey:kLQQueueNumberOfTries];
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_url forKey:kLQQueueUrl];
    [aCoder encodeObject:_httpMethod forKey:kLQQueueHttpMethod];
    [aCoder encodeObject:_json forKey:kLQQueueJSON];
    [aCoder encodeObject:_numberOfTries forKey:kLQQueueNumberOfTries];
}

#pragma mark - Network Retries

-(void)incrementNumberOfTriesBy:(NSUInteger)increment {
    int numberOfTries = _numberOfTries.intValue + (int) increment;
    _numberOfTries = [NSNumber numberWithInt:numberOfTries];
}

-(void)incrementNumberOfTries {
    [self incrementNumberOfTriesBy:1];
}

-(void)incrementNextTryDateIn:(NSTimeInterval)seconds {
    _nextTryAfter = [[NSDate date] dateByAddingTimeInterval:seconds];
}

@end
