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

@interface LQUser : LQEntity

- (id)initWithIdentifier:(NSString*)identifier attributes:(NSDictionary*)attributes location:(CLLocation*)location;

-(void)setAttribute:(id<NSCoding>)attribute forKey:(NSString*)key;
-(id)attributeForKey:(NSString*)key;
-(void)setLocation:(CLLocation*)location;
-(NSDictionary*)jsonDictionary;
+(NSString *)automaticUserIdentifier;

@property(nonatomic, strong, readonly) NSString* identifier;
@property(nonatomic, strong, readonly) NSDictionary* attributes;
@property(nonatomic, strong, readonly) NSNumber *autoIdentified;

@end
