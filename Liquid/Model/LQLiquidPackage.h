//
//  LQLiquidPackage.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/23/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQValue.h"
#import "LQTarget.h"

@interface LQLiquidPackage : NSObject<NSCoding>

-(id)initFromDictionary:(NSDictionary *)dict;
-(id)initWithTargets:(NSArray *)targets withValues:(NSArray *)values;
-(LQValue *)valueForKey:(NSString *)variableName error:(NSError **)error;
-(BOOL)variable:(NSString *)variableName matchesLiquidType:(NSString *)typeString;
-(NSInteger)invalidateTargetThatIncludesVariable:(NSString *)variableName;

+(LQLiquidPackage *)loadFromDisk;
+(BOOL)destroyCachedLiquidPackage;
-(BOOL)saveToDisk;

@property(nonatomic, strong, readonly) NSArray *values;
@property(nonatomic, strong, readonly) NSArray *targets;
@property(nonatomic, strong, readonly) NSString *liquidVersion;

@property(nonatomic, strong, readonly) NSDictionary *dictOfVariablesAndValues;

@end
