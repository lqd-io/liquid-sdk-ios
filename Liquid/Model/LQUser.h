//
//  LQUser.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LQEntity.h"

@interface LQUser : LQEntity <NSCoding, NSCopying>

- (id)initWithIdentifier:(NSString*)identifier attributes:(NSDictionary*)attributes;
- (void)setAttribute:(id<NSCoding>)attribute forKey:(NSString*)key;
- (id)attributeForKey:(NSString*)key;
- (NSDictionary*)jsonDictionary;
- (BOOL)isAutoIdentified;

+(LQUser *)loadFromDiskForToken:(NSString *)apiToken;
+(BOOL)destroyLastUserForToken:(NSString *)apiToken;
+(BOOL)destroyLastUserForAllTokens;
-(BOOL)saveToDiskForToken:(NSString *)apiToken;

@property(nonatomic, strong, readonly) NSString* identifier;
@property(nonatomic, strong) NSDictionary* attributes;
@property(nonatomic, strong, readonly) NSNumber *autoIdentified;

@end
