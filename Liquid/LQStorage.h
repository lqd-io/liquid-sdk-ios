//
//  LQStorage.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 01/09/14.
//  Copyright (c) Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQStorage : NSObject

+ (void)setObject:(id)object forKey:(NSString *)key;
+ (id)objectForKey:(NSString *)key;

+ (BOOL)deleteAllLiquidFiles;
+ (BOOL)deleteFileIfExists:(NSString *)fileName error:(NSError **)err;
+ (NSString *)liquidDirectory;
+ (NSString*)filePathWithExtension:(NSString *)extesion forToken:(NSString *)apiToken;
+ (NSArray *)filesInDirectory:(NSString *)directoryPath;

@end
