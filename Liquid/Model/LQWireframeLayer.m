//
//  LQWireframeLayer.m
//  Liquid
//
//  Created by Miguel M. Almeida on 08/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQWireframeLayer.h"

@implementation LQWireframeLayer

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color {
    self = [super init];
    if (self) {
        self.frame = frame;
        self.borderColor = color.CGColor;
        self.borderWidth = 1.0f;
        self.cornerRadius = 2.0f;
        self.zPosition = 999999999;
    }
    return self;
}

@end
