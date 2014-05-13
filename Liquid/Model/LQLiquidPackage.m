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

-(id)initWithValues:(NSArray *)values {
    self = [super init];
    if (self) {
        _values = values;
        _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];
        _liquidVersion = kLQBundle;
    }
    return self;
}

-(id)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
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

#pragma mark - Invalidation of Values and Variables

-(NSString *)targetIdOfVariable:(NSString *)variableName {
    for (LQValue *value in _values) {
        if ([value.variable.name isEqualToString:variableName]) {
            return value.targetId;
        }
    }
    return nil;
}

-(NSInteger)invalidateTargetWihId:(NSString *)targetId {
    NSInteger numRemovedValues = 0;

    NSMutableArray *newValues = [[NSMutableArray alloc] init];
    for (LQValue *value in _values) {
        if ([targetId isEqualToString:value.targetId]) {
            numRemovedValues++;
        } else {
            [newValues addObject:value];
        }
    }
    _values = [NSArray arrayWithArray:newValues];
    _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];

    LQLog(kLQLogLevelInfo, @"<Liquid> Removed %ld values/variables from Liquid Package related with Target ID #%@", (long)numRemovedValues, targetId);
    return numRemovedValues;
}

-(NSInteger)invalidateVariable:(NSString *)variableName {
    NSMutableArray *newValues = [[NSMutableArray alloc] init];
    for (LQValue *value in _values) {
        if (![variableName isEqualToString:value.variable.name]) {
            [newValues addObject:value];
        }
    }
    _values = [NSArray arrayWithArray:newValues];
    _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];

    LQLog(kLQLogLevelInfo, @"<Liquid> Removed value/variable '%@' from Liquid Package", variableName);
    return 1;
}

-(NSInteger)invalidateTargetThatIncludesVariable:(NSString *)variableName {
    NSString *targetId = [self targetIdOfVariable:variableName];
    if (targetId == nil || [[NSNull null] isEqual:targetId]) {
        LQLog(kLQLogLevelError, @"<Liquid> Something wrong happened with dynamic variable '%@' (data types mismatch?). For safety reasons, we are using fallback value instead.", variableName);
        return [self invalidateVariable:variableName];
    } else {
        NSInteger numberOfInvalidatedValues = [self invalidateTargetWihId:[self targetIdOfVariable:variableName]];
        LQLog(kLQLogLevelError, @"<Liquid> Something wrong happened with dynamic variable '%@' (data types mismatch?). For safety reasons, all variable values (%ld) covered by its target were invalidated, so we are using fallback values instead.", variableName, (long)numberOfInvalidatedValues);
        return numberOfInvalidatedValues;
    }
    return 0;
}

#pragma mark - NSCoding

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _values = [aDecoder decodeObjectForKey:@"values"];
        _liquidVersion = [aDecoder decodeObjectForKey:@"liquid_version"];
        _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
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
