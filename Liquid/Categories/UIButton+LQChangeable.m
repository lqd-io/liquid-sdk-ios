//
//  UIButton+LQChangeable.m
//  Liquid
//
//  Created by Miguel M. Almeida on 15/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "UIButton+LQChangeable.h"
#import "UIView+LQChangeable.h"

@implementation UIButton (LQChangeable)

- (NSString *)liquidIdentifier {
    return [NSString stringWithFormat:@"%@/%@", super.liquidIdentifier, self.titleLabel.text];
}

- (BOOL)isChangeable {
    return YES;
}

@end
