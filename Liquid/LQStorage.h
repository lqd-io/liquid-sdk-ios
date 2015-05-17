//
//  LQStorage.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 01/09/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQStorage : NSObject

+ (BOOL)deleteAllLiquidFiles;
+ (BOOL)deleteFileIfExists:(NSString *)fileName error:(NSError **)err;
+ (NSString *)liquidDirectory;
+ (BOOL)fileExists:(NSString *)fileName;
+ (NSArray *)filesInDirectory:(NSString *)directoryPath;;
+ (NSString *)filePathWithExtension:(NSString *)extesion forToken:(NSString *)apiToken;
+ (NSString *)filePathForAllTokensWithExtension:(NSString *)extesion;

@end
