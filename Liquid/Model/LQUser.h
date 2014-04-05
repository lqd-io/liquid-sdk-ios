//
//  LQUser.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LQUser : NSObject

-(id)initWithIdentifier:(NSString*)identifier withAttributes:(NSDictionary*)attributes withLocation:(CLLocation*)location;

-(void)setAttribute:(id<NSCoding>)attribute forKey:(NSString*)key;
-(id)attributeForKey:(NSString*)key;
-(void)setLocation:(CLLocation*)location;

-(NSDictionary*)jsonDictionary;

@property(nonatomic, strong, readonly) NSString* identifier;
@property(nonatomic, strong, readonly) NSDictionary* attributes;

@end
