//
//  UIView+LQViewPath.m
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "UIView+UIViewPath.h"

@implementation UIView (UIViewPath) // TODO: Change to ...LQViewPath

- (BOOL)matchesLiquidPath:(NSString *)path andTrackableIdentifier:(NSString *)identifier {
    if (![self trackableIdentifier]) {
        return false;
    }
    return [[self liquidPath] isEqualToString:path] && [[self trackableIdentifier] isEqualToString:identifier];
}

- (NSString *)liquidPath { // TODO: change to trackablePath ?
    NSString *path = [NSString stringWithFormat:@"/%@", NSStringFromClass([self class])];
    if ([self.superview respondsToSelector:NSSelectorFromString(@"liquidPath")]) {
        path = [NSString stringWithFormat:@"%@%@", [self.superview liquidPath], path];
    }
    return path;
}

- (NSString *)trackableIdentifier {
    return nil;
}

@end
