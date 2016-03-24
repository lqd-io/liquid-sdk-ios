//
//  LQUserDefaults.h
//  Liquid
//
//  Created by Miguel M. Almeida on 17/05/15.
//  Copyright (c) 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQUserDefaults : NSObject

+ (BOOL)setObject:(id)object forKey:(NSString *)key allowUpdate:(BOOL)allowUpdate;
+ (id)objectForKey:(NSString *)key;
+ (void)removeObjectForKey:(NSString *)key;

@end
