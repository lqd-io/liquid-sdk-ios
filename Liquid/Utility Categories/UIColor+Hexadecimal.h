//
//  UIColor+Hexadecimal.h
//  Liquid
//
//  Created by Rui Peres on 15/05/2014.
//  Copyright (c) 2014 Liquid. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hexadecimal)

+ (UIColor *)colorFromHexadecimalString:(NSString *)hexadecimalString;
+ (NSString *)hexadecimalStringFromUIColor:(UIColor *)color;

@end
