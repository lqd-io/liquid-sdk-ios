//
//  LQUIElementWelcomeView.m
//  Liquid
//
//  Created by Miguel M. Almeida on 03/02/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQUIElementWelcomeView.h"

@implementation LQUIElementWelcomeView

@synthesize backgroundImageView = _backgroundImageView;
@synthesize dismissButton = _dismissButton;
@synthesize checkImageView = _checkImageView;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor colorWithRed:241.0f green:248.0f blue:254.0f alpha:1.0f];
        [self addSubview:self.backgroundImageView];
        [self addSubview:self.dismissButton];
        [self addSubview:self.checkImageView];
    }
    return self;
}

- (UIImageView *)checkImageView {
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _checkImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _checkImageView;
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.frame = self.bounds;
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _backgroundImageView;
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
