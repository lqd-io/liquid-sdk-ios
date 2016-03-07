//
//  UIButton+LQChangeable.m
//  Liquid
//
//  Created by Miguel M. Almeida on 15/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "UIButton+LQChangeable.h"
#import "UIView+LQChangeable.h"
#import "NSData+LQData.h"

@implementation UIButton (LQChangeable)

#pragma mark - Public methods

- (NSString *)liquidIdentifier {
    return [NSString stringWithFormat:@"%@%@", [self path], [self bestIdentifier]];
}

- (BOOL)isChangeable {
    return YES;
}

- (NSString *)bestIdentifier {
    NSString *identifier;
    if ((identifier = [self imagePathidentifier])) {
        return [NSString stringWithFormat:@"?image=%@", identifier];
    }
    if ((identifier = [self textIdentifier])) {
        return [NSString stringWithFormat:@"?title=%@", identifier];
    }
    return @"";
}

#pragma mark - Path generation

- (NSString *)path {
    NSString *path = [NSString stringWithFormat:@"%@", [self class]];
    if ([self isKindOfClass:[UIControl class]]) {
        UIResponder *responder = [self nextResponder];
        do {
//            if ([responder isKindOfClass:[UIWindow class]]) {
//                // Stop at /UIWindow, which means removing all the path before it.
//                // Example:
//                //   remove /LiquidDemoAppDelegate/UIApplication/UIWindow/
//                //   and keep just /LiquidDemoViewController/UIView/UIButton?title=Track "Buy Product"
//                return [NSString stringWithFormat:@"/%@", path];
//            }
            if ([responder isKindOfClass:[UIViewController class]]) {
                path = [NSString stringWithFormat:@"%@/%@", [responder class], path];
            }
            responder = [responder nextResponder];
        } while (responder);
    }
    return [NSString stringWithFormat:@"/%@", path];
}

#pragma mark - Identifiers generatiosn

- (NSString *)imagePathidentifier {
    UIImage *image = [self imageForState:UIControlStateNormal];
    if (!image) {
        return nil;
    }
    return [UIImagePNGRepresentation(image) md5digest];
}

- (NSString *)textIdentifier {
    NSString *text;
    if ((text = [self titleForState:UIControlStateNormal])) return text;
    return self.titleLabel.text;
}

@end
