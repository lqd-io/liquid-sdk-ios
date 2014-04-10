//
//  LQValue.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/22/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQVariable.h"

@interface LQValue : NSObject<NSCoding>

-(id)initFromDictionary:(NSDictionary *)dict;
-(NSDictionary *)jsonDictionary;
+(NSDictionary *)dictionaryFromArrayOfValues:(NSArray *)values;

@property(nonatomic, strong, readonly) NSString *identifier;
@property(nonatomic, strong, readonly) id value;
@property(nonatomic, strong, readonly) LQVariable *variable;
@property(nonatomic, strong, readonly) NSNumber *isDefault;

@end
