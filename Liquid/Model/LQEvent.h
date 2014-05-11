//
//  LQEvent.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQSession.h"

@interface LQEvent : NSObject

-(id)initWithName:(NSString*)name attributes:(NSDictionary*)attributes date:(NSDate *)date;
-(NSDictionary *)jsonDictionary;
-(NSDictionary *)jsonDictionaryWithUser:(LQUser*)user device:(LQDevice*)device session:(LQSession *)session;

@property(nonatomic, strong, readonly) NSString* name;
@property(nonatomic, strong, readonly) NSDictionary* attributes;
@property(nonatomic, strong, readonly) NSDate* date;

@end
