//
//  LQKeychainItem.h
//  Liquid
//
//  Created by Miguel M. Almeida on 13/05/15.
//  Copyright (c) 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQKeychainItem : NSObject

@property(nonatomic, strong, readonly) NSString *key;
@property(nonatomic, strong, readonly) NSString *value;
@property(nonatomic, strong, readonly) NSString *nameSpace;

- (id)initWithKey:(NSString *)key namespace:(NSString *)nameSpace;
- (id)initWithKey:(NSString *)key andValue:(NSString *)value namespace:(NSString *)nameSpace;
- (OSStatus)save;
- (OSStatus)reload;
- (BOOL)exists;

@end
