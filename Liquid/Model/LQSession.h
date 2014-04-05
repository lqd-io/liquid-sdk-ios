//
//  LQSession.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQUser.h"
#import "LQDevice.h"

@interface LQSession : NSObject

-(id)initWithTimeout:(NSNumber*)timeout;

-(void)setAttribute:(id<NSCoding>)attribute forKey:(NSString *)key;
-(id)attributeForKey:(NSString *)key;
-(void)endSessionOnDate:(NSDate *)endDate;

-(NSDictionary*)jsonDictionary;
-(NSDictionary*)jsonDictionaryWithUser:(LQUser*)user withDevice:(LQDevice*)device;

@property(nonatomic, strong, readonly) NSString* identifier;
@property(nonatomic, strong, readonly) NSDate* start;
@property(nonatomic, strong) NSDate* end;
@property(nonatomic, strong, readonly) NSNumber* timeout;
@property(nonatomic, strong, readonly) NSDictionary* attributes;

@end
