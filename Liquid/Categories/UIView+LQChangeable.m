//
//  UIView+LQChangeable.m
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "UIView+LQChangeable.h"

@implementation UIView (LQChangeable)

- (NSString *)liquidIdentifier {
    NSString *identifier = [NSString stringWithFormat:@"/%@", NSStringFromClass([self class])];
    if ([self.superview respondsToSelector:NSSelectorFromString(@"liquidIdentifier")]) {
        identifier = [NSString stringWithFormat:@"%@%@", [self.superview liquidIdentifier], identifier];
    }
    return identifier;
}

- (BOOL)isChangeable {
    return NO;
}

@end
