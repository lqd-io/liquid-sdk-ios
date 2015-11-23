//
//  LQCaret.h
//  Liquid
//
//  Created by Miguel M. Almeida on 10/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDefaults.h"
#if LQ_INAPP_MESSAGES_SUPPORT
#import <UIKit/UIKit.h>

@interface LQCaret : UIView

@property (nonatomic, strong) UIColor *strokeColor;

- (instancetype)initWithFrame:(CGRect)frame strokeColor:(UIColor *)strokeColor;

@end
#endif
