//
//  LQLiquidPackage.m
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/23/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQLiquidPackage.h"
#import "LQDefaults.h"
#import "LQValue.h"
#import "LQTarget.h"
#import "LQVariable.h"
#import "NSString+LQString.h"

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
    LQValue *value = [[_dictOfVariablesAndValues copy] objectForKey:variableName];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Value not found on Liquid Package", NSLocalizedDescriptionKey, nil];

    // if not found:
    if (value == nil) {
        if (error != NULL) *error = [NSError errorWithDomain:kLQVersion code:kLQErrorValueNotFound userInfo:userInfo];
        return nil;
    }
    // if found:
    if (value.value == [NSNull null])
        return nil;
    return value;
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
        LQLog(kLQLogLevelError, @"<Liquid> Something wrong happened with dynamic variable '%@' (Is it present on Liquid dashboard? Data types mismatch?). For safety reasons, we are using fallback value instead.", variableName);
        return [self invalidateVariable:variableName];
    } else {
        NSInteger numberOfInvalidatedValues = [self invalidateTargetWihId:[self targetIdOfVariable:variableName]];
        LQLog(kLQLogLevelError, @"<Liquid> Something wrong happened with dynamic variable '%@' (Is it present on Liquid dashbaoard? Data types mismatch?). For safety reasons, all variable values (%ld) covered by its target were invalidated, so we are using fallback values instead.", variableName, (long)numberOfInvalidatedValues);
        return numberOfInvalidatedValues;
    }
    return 0;
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _values = [aDecoder decodeObjectForKey:@"values"];
        _liquidVersion = [aDecoder decodeObjectForKey:@"liquid_version"];
        _dictOfVariablesAndValues = [LQValue dictionaryFromArrayOfValues:_values];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_values forKey:@"values"];
    [aCoder encodeObject:_liquidVersion forKey:@"liquid_version"];
}

#pragma mark - Archive to/from disk

+ (LQLiquidPackage *)loadFromDiskForToken:(NSString *)apiToken {
    LQLiquidPackage *liquidPackage = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self class] liquidPackageFileForToken:apiToken]];
    LQLog(kLQLogLevelData, @"<Liquid> Loaded Liquid Package from disk, for token %@", apiToken);
    return liquidPackage;
}

+ (BOOL)destroyCachedLiquidPackageForToken:(NSString *)apiToken {
    BOOL status = [[NSFileManager defaultManager] removeItemAtPath:[[self class] liquidPackageFileForToken:apiToken] error:NULL];
    LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Destroyed cached Liquid Package for token %@", apiToken);
    return status;
}

+ (NSArray *)filesInDirectory:(NSString *)directoryPath {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
    return files;
}

+ (BOOL)destroyCachedLiquidPackageForAllTokens {
    BOOL status = false;
    for (NSString *path in [LQLiquidPackage filesInDirectory:[[self class] liquidPackagesDirectory]]) {
        status &= [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    }
    LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Destroyed cached Liquid Package");
    return status;
}

- (BOOL)saveToDiskForToken:(NSString *)apiToken {
    LQLog(kLQLogLevelData, @"<Liquid> Saving Liquid Package to disk");
    return [NSKeyedArchiver archiveRootObject:self
                                       toFile:[[self class] liquidPackageFileForToken:apiToken]];
}

+ (NSString *)liquidPackagesDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:kLQDirectory];
}

+ (NSString*)liquidPackageFileForToken:(NSString *)apiToken {
    NSString *liquidDirectory = [LQLiquidPackage liquidPackagesDirectory];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:liquidDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:liquidDirectory
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
    NSString *md5apiToken = [NSString md5ofString:apiToken];
    NSString *liquidFile = [liquidDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.last_liquid_package", md5apiToken]];
    LQLog(kLQLogLevelPaths,@"<Liquid> File location %@",liquidFile);
    return liquidFile;
}

@end
