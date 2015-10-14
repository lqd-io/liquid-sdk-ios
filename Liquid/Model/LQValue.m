//
//  LQValue.m
//  LiquidApp
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 3/22/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LQValue.h"
#import "LQVariable.h"

@implementation LQValue

- (id)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        _identifier = [dict objectForKey:@"id"];
        _value = [dict objectForKey:@"value"];
        _isDefault = [dict objectForKey:@"default"];
        _variable = [[LQVariable alloc] initFromDictionary:[dict objectForKey:@"variable"]];
        _targetId = [dict objectForKey:@"target_id"];
        _isFallback = [NSNumber numberWithBool:NO];
    }
    return self;
}

- (id)initWithFallbackValue:(id)value {
    self = [super init];
    if(self) {
        _identifier = nil;
        _value = nil;
        _variable = nil;
        _isDefault = nil;
        _targetId = nil;
        _isFallback = [NSNumber numberWithBool:YES];
    }
    return self;
}

- (id)initWithValue:(id)value {
    self = [super init];
    if(self) {
        _value = value;
        _variable = nil;
        _isDefault = nil;
        _targetId = nil;
        _isFallback = [NSNumber numberWithBool:NO];
    }
    return self;
}

- (id)initWithValue:(id)value variable:(LQVariable *)variable {
    self = [super init];
    if(self) {
        _value = value;
        _variable = variable;
        _isDefault = nil;
        _targetId = nil;
        _isFallback = [NSNumber numberWithBool:NO];
    }
    return self;
}

#pragma mark - Data Type

- (BOOL)variableMatchesLiquidType:(NSString *)typeString {
    if ([self.variable matchesLiquidType:typeString]) {
        return YES;
    }
    return NO;
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        _identifier = [aDecoder decodeObjectForKey:@"id"];
        _value = [aDecoder decodeObjectForKey:@"value"];
        _variable = [aDecoder decodeObjectForKey:@"variable"];
        _targetId = [aDecoder decodeObjectForKey:@"target_id"];
        _isDefault = [aDecoder decodeObjectForKey:@"default"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_identifier forKey:@"id"];
    [aCoder encodeObject:_value forKey:@"value"];
    [aCoder encodeObject:_variable forKey:@"variable"];
    [aCoder encodeObject:_targetId forKey:@"target_id"];
    [aCoder encodeObject:_isDefault forKey:@"default"];
}

- (id)copyWithZone:(NSZone *)zone {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark - JSON

-(NSDictionary *)jsonDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    [dictionary setObject:_identifier forKey:@"id"];
    [dictionary setObject:_targetId forKey:@"target_id"];
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

+(NSDictionary *)dictionaryFromArrayOfValues:(NSArray *)values {
    NSMutableDictionary *dictOfValues = [NSMutableDictionary new];
    for(LQValue *value in values) {
        if (value.value) { // If nominal value is present, use it
            if (value.variable.name)
                [dictOfValues setObject:value forKey:value.variable.name];
        }
    }
    return [NSDictionary dictionaryWithDictionary:dictOfValues];
}

@end
