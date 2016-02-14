//
//  LQKeyChain.h
//  Liquid
//
//  Created by Miguel M. Almeida on 13/05/15.
//  Copyright (c) 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQKeychain : NSObject

+ (BOOL)setValue:(NSString *)value forKey:(NSString *)key allowUpdate:(BOOL)allowUpdate;
+ (NSString *)valueForKey:(NSString *)key;

@end
