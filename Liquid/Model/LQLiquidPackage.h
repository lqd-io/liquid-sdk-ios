//
//  LQLiquidPackage.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/23/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQEntity.h"

@class LQValue;
@class LQTarget;

@interface LQLiquidPackage : LQEntity <NSCoding, NSCopying>

-(id)initFromDictionary:(NSDictionary *)dict;
-(id)initWithValues:(NSArray *)values;
-(LQValue *)valueForKey:(NSString *)variableName error:(NSError **)error;
-(NSInteger)invalidateTargetThatIncludesVariable:(NSString *)variableName;

+(LQLiquidPackage *)loadFromDiskForToken:(NSString *)apiToken;
+(BOOL)destroyCachedLiquidPackageForToken:(NSString *)apiToken;
+(BOOL)destroyCachedLiquidPackageForAllTokens;
-(BOOL)saveToDiskForToken:(NSString *)apiToken;

@property(nonatomic, strong, readonly) NSArray *values;
@property(nonatomic, strong, readonly) NSString *liquidVersion;
@property(nonatomic, strong, readonly) NSDictionary *dictOfVariablesAndValues;

@end
