//
//  LQLiquidPackage.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/23/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQEntity.h"
#import "LQValue.h"
#import "LQTarget.h"

@interface LQLiquidPackage : LQEntity<NSCoding>

-(id)initFromDictionary:(NSDictionary *)dict;
-(id)initWithValues:(NSArray *)values;
-(LQValue *)valueForKey:(NSString *)variableName error:(NSError **)error;
-(NSInteger)invalidateTargetThatIncludesVariable:(NSString *)variableName;

+(LQLiquidPackage *)loadFromDisk;
+(BOOL)destroyCachedLiquidPackage;
-(BOOL)saveToDisk;

@property(nonatomic, strong, readonly) NSArray *values;
@property(nonatomic, strong, readonly) NSString *liquidVersion;

@property(nonatomic, strong, readonly) NSDictionary *dictOfVariablesAndValues;

@end
