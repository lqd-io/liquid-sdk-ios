//
//  LQHelpers.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 24/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQHelpers : NSObject

+ (NSUInteger)randomInt:(NSUInteger)max;
+ (NSDictionary *)normalizeDataTypes:(NSDictionary *)dictionary;

@end
