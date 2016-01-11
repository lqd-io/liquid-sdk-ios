//
//  UIView+LQChangeable.h
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (LQChangeable)

- (NSString *)liquidIdentifier;
- (BOOL)isChangeable;

@end
