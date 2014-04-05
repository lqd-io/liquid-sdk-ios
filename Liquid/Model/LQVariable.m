//
//  LQVariable.m
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/22/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQVariable.h"

@implementation LQVariable

-(id)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        _identifier = [dict objectForKey:@"id"];
        _name = [dict objectForKey:@"name"];
        _defaultValue = [[dict objectForKey:@"default_value"] objectForKey:@"value"];
    }
    return self;
}

#pragma mark - NSCoding
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        _identifier = [aDecoder decodeObjectForKey:@"id"];
        _name = [aDecoder decodeObjectForKey:@"name"];
        _defaultValue = [aDecoder decodeObjectForKey:@"default_value"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_identifier forKey:@"id"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_defaultValue forKey:@"default_value"];
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setObject:_identifier forKey:@"id"];
    [dictionary setObject:_name forKey:@"name"];
    return dictionary;
}

@end
