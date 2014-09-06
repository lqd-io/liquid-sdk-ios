//
//  LQDataPoint.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/20/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQUser.h"
#import "LQDevice.h"
#import "LQSession.h"
#import "LQEvent.h"
#import "LQTarget.h"
#import "LQValue.h"

@interface LQDataPoint : NSObject <NSCoding, NSCopying>

-(id)initWithDate:(NSDate *)date user:(LQUser *)user device:(LQDevice *)device session:(LQSession *)session event:(LQEvent *)event values:(NSArray *)values;
-(NSDictionary *)jsonDictionary;

@property(atomic, strong, readonly) LQUser* user;
@property(atomic, strong, readonly) LQDevice* device;
@property(atomic, strong, readonly) LQSession* session;
@property(atomic, strong, readonly) LQEvent* event;
@property(nonatomic, strong, readonly) NSArray* targets;
@property(nonatomic, strong, readonly) NSArray* values;
@property(nonatomic, strong, readonly) NSDate* timestamp;

@end
