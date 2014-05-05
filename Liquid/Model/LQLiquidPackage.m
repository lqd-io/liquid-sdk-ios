//
//  LQLiquidPackage.m
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/23/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQLiquidPackage.h"
#import "LQValue.h"
#import "LQTarget.h"
#import "LQConstants.h"

@interface LQLiquidPackage ()

@end

@implementation LQLiquidPackage

-(id)initWithTargets:(NSArray *)targets withValues:(NSArray *)values {
    self = [super init];
    if(self) {
        _targets = targets;
        _values = values;
        _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];
    }
    return self;
}

-(id)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        NSMutableArray *targets = [[NSMutableArray alloc] initWithObjects:nil];
        for (NSDictionary *target in [dict objectForKey:@"targets"]) {
            [targets addObject:[[LQTarget alloc] initFromDictionary:target]];
        }
        _targets = targets;

        NSMutableArray *values = [[NSMutableArray alloc] initWithObjects:nil];
        for (NSDictionary *value in [dict objectForKey:@"values"]) {
            [values addObject:[[LQValue alloc] initFromDictionary:value]];
        }
        _values = values;
        _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];
    }
    return self;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@", _dictOfVariablesAndValues];
}

#pragma mark - Get dynamic values

-(id)valueForKey:(NSString *)variableName withDefault:(id)defaultValue {
    id value = [_dictOfVariablesAndValues objectForKey:variableName];
    if(value == nil)
        return defaultValue;
    if([value isKindOfClass:[NSNull class]])
        return nil;
    return value;
}

#pragma mark - NSCoding

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        _targets = [aDecoder decodeObjectForKey:@"targets"];
        _values = [aDecoder decodeObjectForKey:@"values"];
        _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_targets forKey:@"targets"];
    [aCoder encodeObject:_values forKey:@"values"];
}

#pragma mark - Archive to disk

+(LQLiquidPackage *)loadFromDisk {
    LQLiquidPackage *liquidPackage = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self class] liquidPackageFile]];
    return liquidPackage;
}

-(BOOL)saveToDisk {
    LQLog(kLQLogLevelData, @"<Liquid> Saving Liquid Package to disk");
    return [NSKeyedArchiver archiveRootObject:self
                                       toFile:[[self class] liquidPackageFile]];
}

+(NSString*)liquidPackageFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *liquidDirectory = [documentsDirectory stringByAppendingPathComponent:kLQDirectory];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:liquidDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:liquidDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
    
    NSString *liquidFile = [liquidDirectory stringByAppendingPathComponent:@"last.liquid_package"];
    LQLog(kLQLogLevelPaths,@"<Liquid> File location %@",liquidFile);
    return liquidFile;
}

@end
