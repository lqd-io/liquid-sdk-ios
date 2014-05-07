//
//  LQLiquidPackage.h
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/23/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQLiquidPackage : NSObject<NSCoding>

-(id)initFromDictionary:(NSDictionary *)dict;
-(id)initWithTargets:(NSArray *)targets withValues:(NSArray *)values;
-(id)valueForKey:(NSString *)variableName fallback:(id)fallbackValue;

+(LQLiquidPackage *)loadFromDisk;
-(BOOL)saveToDisk;

@property(nonatomic, strong, readonly) NSArray* values;
@property(nonatomic, strong, readonly) NSArray* targets;

@property(nonatomic, strong, readonly) NSDictionary *dictOfVariablesAndValues;

@end
