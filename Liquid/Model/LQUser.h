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
- (void)resetAttributes;
- (NSDictionary*)jsonDictionary;
- (BOOL)isIdentified;
- (BOOL)isAnonymous;

- (BOOL)archiveUserForToken:(NSString *)apiToken;
+ (LQUser *)unarchiveUserForToken:(NSString *)apiToken;
+ (void)deleteUserFileForToken:(NSString *)apiToken;

@property(atomic, strong, readonly) NSString *identifier;
@property(atomic, strong) NSDictionary *attributes;

@end
