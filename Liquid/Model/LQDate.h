//
//  LQDate.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 24/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQDate : NSDate

+ (NSDate *)uniqueNow;
+ (void)resetUniqueNow;

@end
