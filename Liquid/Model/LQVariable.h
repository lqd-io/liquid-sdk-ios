//
//  LQVariable.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/22/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LQValue;

@interface LQVariable : NSObject <NSCoding, NSCopying>

extern NSString * const kLQDataTypeString;
extern NSString * const kLQDataTypeColor;
extern NSString * const kLQDataTypeDateTime;
extern NSString * const kLQDataTypeBoolean;
extern NSString * const kLQDataTypeInteger;
extern NSString * const kLQDataTypeFloat;

- (id)initFromDictionary:(NSDictionary *)dict;
- (id)initWithName:(NSString *)name dataType:(NSString *)dataType;
- (NSDictionary *)jsonDictionary;
- (BOOL)matchesLiquidType:(NSString *)typeString;

@property(nonatomic, strong, readonly) NSString *identifier;
@property(nonatomic, strong, readonly) NSString *name;
@property(nonatomic, strong, readonly) NSString *dataType;
@property(nonatomic, strong, readonly) LQValue *defaultValue;

@end
