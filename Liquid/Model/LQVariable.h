//
//  LQVariable.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/22/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQVariable : NSObject<NSCoding>

-(id)initFromDictionary:(NSDictionary *)dict;
-(NSDictionary *)jsonDictionary;

@property(nonatomic, strong, readonly) NSNumber* identifier;
@property(nonatomic, strong, readonly) NSString* name;
@property(nonatomic, strong, readonly) id defaultValue;

@end
