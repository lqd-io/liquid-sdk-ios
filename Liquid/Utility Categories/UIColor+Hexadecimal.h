//
//  UIColor+Hexadecimal.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 09/01/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hexadecimal)

+ (UIColor *)colorFromHexadecimalString:(NSString *)hexadecimalString;
+ (NSString *)hexadecimalStringFromUIColor:(UIColor *)color;

@end
