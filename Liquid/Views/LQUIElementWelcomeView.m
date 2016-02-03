//
//  LQUIElementWelcomeView.m
//  Liquid
//
//  Created by Miguel M. Almeida on 03/02/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQUIElementWelcomeView.h"

@implementation LQUIElementWelcomeView

@synthesize dismissButton = _dismissButton;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor blueColor];
        [self addSubview:self.dismissButton];
    }
    return self;
}

- (UIButton *)dismissButton {
    if (!_dismissButton) {
        _dismissButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _dismissButton.frame = CGRectMake(100, 100, 100, 50);
        [_dismissButton setTitle:@"Dismiss" forState:UIControlStateNormal];
    }
    return _dismissButton;
}

@end
