//
//  UIButton+LQChangeable.h
//  Liquid
//
//  Created by Miguel M. Almeida on 15/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (LQChangeable)

- (NSString *)liquidIdentifier;
- (BOOL)isChangeable;

@end
