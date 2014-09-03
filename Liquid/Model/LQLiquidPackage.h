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

- (id)initFromDictionary:(NSDictionary *)dict;
- (id)initWithValues:(NSArray *)values;
- (LQValue *)valueForKey:(NSString *)variableName error:(NSError **)error;
- (NSInteger)invalidateTargetThatIncludesVariable:(NSString *)variableName;

- (BOOL)archiveLiquidPackageForToken:(NSString *)apiToken;
+ (LQLiquidPackage *)unarchiveLiquidPackageForToken:(NSString *)apiToken;
+ (void)deleteLiquidPackageFileForToken:(NSString *)apiToken;

@property(atomic, strong, readonly) NSArray *values;
@property(atomic, strong, readonly) NSString *liquidVersion;
@property(atomic, strong, readonly) NSDictionary *dictOfVariablesAndValues;

@end
