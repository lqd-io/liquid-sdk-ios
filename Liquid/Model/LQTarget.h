//
//  LQTarget.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/22/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQTarget : NSObject <NSCoding, NSCopying>

-(instancetype)initFromDictionary:(NSDictionary *)dict;
-(NSDictionary *)jsonDictionary;

@property(nonatomic, strong, readonly) NSString *identifier;

@end
