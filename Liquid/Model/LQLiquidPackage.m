//
//  LQLiquidPackage.m
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/23/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQLiquidPackage.h"
#import "LQDefaults.h"

@interface LQLiquidPackage ()

@end

@implementation LQLiquidPackage

-(id)initWithTargets:(NSArray *)targets values:(NSArray *)values {
    self = [super init];
    if (self) {
        _targets = targets;
        _values = values;
        _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];
        _liquidVersion = kLQBundle;
    }
    return self;
}

-(id)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
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
        _liquidVersion = kLQBundle;
    }
    return self;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@", _dictOfVariablesAndValues];
}

#pragma mark - Get dynamic values

-(LQValue *)valueForKey:(NSString *)variableName error:(NSError **)error {
    LQValue *value = [_dictOfVariablesAndValues objectForKey:variableName];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Value not found on Liquid Package", NSLocalizedDescriptionKey, nil];

    // if not found:
    if (value == nil) {
        *error = [NSError errorWithDomain:kLQVersion code:kLQErrorValueNotFound userInfo:userInfo];
        return nil;
    }
    // if found::
    if ([value isKindOfClass:[NSNull class]])
        return nil;
    return value;
}

-(BOOL)variable:(NSString *)variableName matchesLiquidType:(NSString *)typeString {
    LQValue *value = [_dictOfVariablesAndValues objectForKey:variableName];
    if (value == nil) {
        return NO;
    }
    if ([value.variable.dataType isEqualToString:typeString]) {
        return YES;
    }
    return NO;
}

#pragma mark - Invalidation of Targets, Values and Variables

-(NSInteger)invalidateTargetWihId:(NSString *)targetId {
    NSInteger numRemovedValues = 0;

    NSMutableArray *newTargets = [[NSMutableArray alloc] init];
    for (LQTarget *target in _targets) {
        if (![target.identifier isEqualToString:targetId]) {
            [newTargets addObject:newTargets];
        }
    }

    NSMutableArray *newValues = [[NSMutableArray alloc] init];
    for (LQValue *value in _values) {
        if ([targetId isEqualToString:value.targetId]) {
            numRemovedValues++;
        } else {
            [newValues addObject:value];
        }
    }

    _targets = [NSArray arrayWithArray:newTargets];
    _values = [NSArray arrayWithArray:newValues];
    _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];

    LQLog(kLQLogLevelInfo, @"<Liquid> Removed %ld values/variables from Liquid Package related with Target ID #%@", (long)numRemovedValues, targetId);
    return numRemovedValues;
}

-(NSString *)targetIdOfVariable:(NSString *)variableName {
    for (LQValue *value in _values) {
        if ([value.variable.name isEqualToString:variableName]) {
            return value.targetId;
        }
    }
    return nil;
}

-(NSInteger)invalidateTargetThatIncludesVariable:(NSString *)variableName {
    NSString *targetId = [self targetIdOfVariable:variableName];
    if (targetId != nil && ![[NSNull null] isEqual:targetId]) {
        return [self invalidateTargetWihId:[self targetIdOfVariable:variableName]];
    }
    return 0;
}

#pragma mark - NSCoding

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _targets = [aDecoder decodeObjectForKey:@"targets"];
        _values = [aDecoder decodeObjectForKey:@"values"];
        _liquidVersion = [aDecoder decodeObjectForKey:@"liquid_version"];
        _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_targets forKey:@"targets"];
    [aCoder encodeObject:_values forKey:@"values"];
    [aCoder encodeObject:_liquidVersion forKey:@"liquid_version"];
}

#pragma mark - Archive to disk

+(LQLiquidPackage *)loadFromDisk {
    LQLiquidPackage *liquidPackage = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self class] liquidPackageFile]];
    return liquidPackage;
}

+(BOOL)destroyCachedLiquidPackage {
    BOOL status = [[NSFileManager defaultManager] removeItemAtPath:[[self class] liquidPackageFile] error:NULL];
    LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Destroyed cached Liquid Package");
    return status;
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
