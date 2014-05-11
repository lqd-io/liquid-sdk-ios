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

@interface LQDataPoint : NSObject

-(id)initWithDate:(NSDate *)date user:(LQUser *)user device:(LQDevice *)device session:(LQSession *)session event:(LQEvent *)event targets:(NSArray *)targets values:(NSArray *)values;
-(NSDictionary *)jsonDictionary;

@property(nonatomic, strong, readonly) LQUser* user;
@property(nonatomic, strong, readonly) LQDevice* device;
@property(nonatomic, strong, readonly) LQSession* session;
@property(nonatomic, strong, readonly) LQEvent* event;
@property(nonatomic, strong, readonly) NSArray* targets;
@property(nonatomic, strong, readonly) NSArray* values;
@property(nonatomic, strong, readonly) NSDate* timestamp;

@end
