//
//  LQValue.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/22/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LQVariable;

@interface LQValue : NSObject <NSCoding, NSCopying>

-(id)initFromDictionary:(NSDictionary *)dict;
-(id)initWithValue:(id)value;
-(id)initWithValue:(id)value variable:(LQVariable *)variable;
-(id)initWithFallbackValue:(id)value;
-(BOOL)variableMatchesLiquidType:(NSString *)typeString;
-(NSDictionary *)jsonDictionary;
+(NSDictionary *)dictionaryFromArrayOfValues:(NSArray *)values;

@property(nonatomic, strong, readonly) NSString *identifier;
@property(nonatomic, strong, readonly) id value;
@property(nonatomic, strong, readonly) LQVariable *variable;
@property(nonatomic, strong, readonly) NSString *targetId;
@property(nonatomic, strong, readonly) NSNumber *isDefault;
@property(nonatomic, strong, readonly) NSNumber *isFallback;

@end
