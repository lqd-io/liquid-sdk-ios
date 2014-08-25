//
//  LQDate.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 24/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQDate.h"

@implementation LQDate

static NSNumber *uniqueNowIncrement;

+ (void)resetUniqueNow {
    @synchronized(uniqueNowIncrement) {
        uniqueNowIncrement = [NSNumber numberWithInteger:0];
    }
}

+ (NSNumber *)uniqueNowIncrement {
    if (!uniqueNowIncrement) {
        [LQDate resetUniqueNow];
    }
    return uniqueNowIncrement;
}

+ (NSDate *)uniqueNow {
    NSTimeInterval millisecondsIncrement;
    @synchronized(uniqueNowIncrement) {
        uniqueNowIncrement = [[NSNumber numberWithInteger:[uniqueNowIncrement intValue] + 1] copy];
        millisecondsIncrement = ([uniqueNowIncrement intValue] % 1000) * 0.001;
    }
    return [[NSDate new] dateByAddingTimeInterval:millisecondsIncrement];
}

@end
