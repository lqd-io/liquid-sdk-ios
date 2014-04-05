//
//  LQTarget.m
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/22/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQTarget.h"

@implementation LQTarget

#pragma mark - Initializer

-(id)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if(self) {
        _identifier = identifier;
    }
    return self;
}

-(id)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        _identifier = [dict objectForKey:@"id"];
    }
    return self;
}

#pragma mark - NSCoding

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        _identifier = [aDecoder decodeObjectForKey:@"id"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_identifier forKey:@"id"];
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setObject:_identifier forKey:@"id"];
    return dictionary;
}

@end
