//
//  LQVariable.m
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/22/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQVariable.h"
#import "LQValue.h"

NSString * const kLQDataTypeString = @"string";
NSString * const kLQDataTypeColor = @"color";
NSString * const kLQDataTypeDateTime = @"datetime";
NSString * const kLQDataTypeBoolean = @"boolean";
NSString * const kLQDataTypeInteger = @"integer";
NSString * const kLQDataTypeFloat = @"float";

@implementation LQVariable

-(id)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        _identifier = [dict objectForKey:@"id"];
        _name = [dict objectForKey:@"name"];
        _defaultValue = [[dict objectForKey:@"default_value"] objectForKey:@"value"];
        _dataType = [dict objectForKey:@"data_type"];
    }
    return self;
}

- (id)initWithName:(NSString *)name dataType:(NSString *)dataType {
    self = [super init];
    if (self) {
        _name = name;
        _dataType = dataType;
    }
    return self;
}

- (BOOL)matchesLiquidType:(NSString *)typeString {
    if ([self.dataType isEqualToString:typeString]) {
        return YES;
    }
    return NO;
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        _identifier = [aDecoder decodeObjectForKey:@"id"];
        _name = [aDecoder decodeObjectForKey:@"name"];
        _defaultValue = [aDecoder decodeObjectForKey:@"default_value"];
        _dataType = [aDecoder decodeObjectForKey:@"data_type"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_identifier forKey:@"id"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_defaultValue forKey:@"default_value"];
    [aCoder encodeObject:_dataType forKey:@"data_type"];
}

- (id)copyWithZone:(NSZone *)zone {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setObject:_identifier forKey:@"id"];
    [dictionary setObject:_name forKey:@"name"];
    [dictionary setObject:_dataType forKey:@"data_type"];
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end
