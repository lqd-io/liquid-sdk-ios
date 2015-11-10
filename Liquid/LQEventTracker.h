//
//  LQEventTracker.h
//  Liquid
//
//  Created by Miguel M. Almeida on 29/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQNetworking.h"
#import "LQUser.h"
#import "LQDevice.h"
#import "LQSession.h"
#import "LQEvent.h"

@interface LQEventTracker : NSObject

@property (nonatomic, strong) LQUser *currentUser;
@property (nonatomic, strong) LQSession *currentSession;

- (instancetype)initWithNetworking:(LQNetworking *)networking dispatchQueue:(dispatch_queue_t)queue;
- (void)track:(NSString *)eventName attributes:(NSDictionary *)attributes loadedValues:(NSArray *)loadedValues withDate:(NSDate *)eventDate;

@end
