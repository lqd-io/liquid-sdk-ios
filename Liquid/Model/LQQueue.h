//
//  LQQueue.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 13/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQQueue : NSObject<NSCoding>

-(id)initWithUrl:(NSString*)url withHttpMethod:(NSString*)httpMethod withJSON:(NSData*)json;
-(void)incrementNumberOfTries;

@property(nonatomic, strong, readonly) NSString* url;
@property(nonatomic, strong, readonly) NSString* httpMethod;
@property(nonatomic, strong, readonly) NSData* json;
@property(nonatomic, strong, readonly) NSNumber* numberOfTries;

extern NSInteger const LQQueueStatusOk;
extern NSInteger const LQQueueStatusUnreachable;
extern NSInteger const LQQueueStatusUnauthorized;
extern NSInteger const LQQueueStatusRejected;

@end
