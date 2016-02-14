//
//  LQStorage.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 01/09/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQStorage.h"
#import "LQDefaults.h"
#import "NSString+LQString.h"

#define kLQDirectory kLQBundle

@implementation LQStorage

#pragma mark - File Handling

+ (BOOL)deleteAllLiquidFiles {
    BOOL status = false;
    for (NSString *path in [LQStorage filesInDirectory:[LQStorage liquidDirectory]]) {
        status &= [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    }
    LQLog(kLQLogLevelInfo, @"<Liquid> Destroyed all Liquid cache files");
    return status;
}

+ (BOOL)fileExists:(NSString *)fileName {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:fileName];
}

+ (BOOL)deleteFileIfExists:(NSString *)fileName error:(NSError **)err {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([LQStorage fileExists:fileName]) {
        return [fm removeItemAtPath:fileName error:err];
    }
    return NO;
}

+ (NSString *)liquidDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:kLQDirectory];
}

+ (NSArray *)filesInDirectory:(NSString *)directoryPath {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
    return files;
}

#pragma mark - File paths

+ (NSString*)filePathWithExtension:(NSString *)extesion forToken:(NSString *)apiToken {
    NSString *liquidDirectory = [LQStorage liquidDirectory];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:liquidDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:liquidDirectory withIntermediateDirectories:NO attributes:nil error:&error];
    }
    NSString *md5apiToken = [NSString md5ofString:apiToken];
    NSString *liquidFile = [liquidDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", md5apiToken, extesion]];
    LQLog(kLQLogLevelPaths,@"<Liquid> File location %@",liquidFile);
    return liquidFile;
}

+ (NSString*)filePathForAllTokensWithExtension:(NSString *)extesion {
    return [[self class] filePathWithExtension:extesion forToken:@"all_tokens"];
}

@end
