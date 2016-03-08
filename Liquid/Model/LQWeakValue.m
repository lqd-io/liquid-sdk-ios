//
//  LQWeakValue.m
//  Liquid
//
//  Created by Miguel M. Almeida on 07/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQWeakValue.h"

@implementation LQWeakValue

@synthesize nominalValue = _nominalValue;

+ (instancetype)weakValueWithValue:(id)value {
    return [[[self class] alloc] initWithValue:value];
}

- (instancetype)initWithValue:(id)value {
    self = [super self];
    if (self) {
        _nominalValue = value;
    }
    return self;
}

@end
