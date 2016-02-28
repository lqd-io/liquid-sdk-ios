//
//  LQUIElementWelcomeView.m
//  Liquid
//
//  Created by Miguel M. Almeida on 03/02/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQUIElementWelcomeView.h"

@implementation LQUIElementWelcomeView

@synthesize sketchImageView = _sketchImageView;
@synthesize dismissButton = _dismissButton;
@synthesize checkImageView = _checkImageView;
@synthesize titleLabel = _titleLabel;
@synthesize messageText = _messageText;

#pragma mark - Initializers

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor colorWithRed:241.0f/255 green:248.0f/255 blue:254.0f/255 alpha:1.0f];
        [self addSubview:self.sketchImageView];
        [self addSubview:self.dismissButton];
        [self addSubview:self.checkImageView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.messageText];
        [self resetConstraints];
        [self applyCenterXConstraints];
        [self applyCenterYConstraints];
    }
    return self;
}

- (UIImageView *)checkImageView {
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] init];
        _checkImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _checkImageView;
}

- (UIImageView *)sketchImageView {
    if (!_sketchImageView) {
        _sketchImageView = [[UIImageView alloc] init];
        _sketchImageView.frame = self.bounds;
        _sketchImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_sketchImageView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:_sketchImageView
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1
                                                          constant:0]];
    }
    return _sketchImageView;
}

- (UIButton *)dismissButton {
    if (!_dismissButton) {
        _dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _dismissButton.backgroundColor = [UIColor colorWithRed:58.0f/255 green:152.0f/255 blue:252.0f/255 alpha:1.0f];
        [_dismissButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_dismissButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [_dismissButton setTitle:@"LET'S GO!" forState:UIControlStateNormal];
        _dismissButton.layer.cornerRadius = 4;
        _dismissButton.clipsToBounds = YES;
    }
    return _dismissButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor colorWithRed:128.0f/255 green:128.0f/255 blue:128.0f/255 alpha:1.0f];
        _titleLabel.text = @"Start tracking events now!";
        _titleLabel.font = [UIFont systemFontOfSize:16];
    }
    return _titleLabel;
}

- (UILabel *)messageText {
    if (!_messageText) {
        _messageText = [[UILabel alloc] init];
        _messageText.textColor = [UIColor colorWithRed:128.0f/255 green:128.0f/255 blue:128.0f/255 alpha:1.0f];
        _messageText.text = @"Tap and hold the element you want\nto track and give it an event name.";
        _messageText.textAlignment = NSTextAlignmentCenter;
        _messageText.numberOfLines = 2;
        _messageText.lineBreakMode = NSLineBreakByWordWrapping;
        _messageText.font = [UIFont systemFontOfSize:16];
    }
    return _messageText;
}

#pragma mark - Constraints

- (void)resetConstraints {
    self.checkImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.sketchImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageText.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)applyCenterYConstraints {
    NSDictionary *viewsDictionary = @{
                                      @"check": self.checkImageView,
                                      @"title": self.titleLabel,
                                      @"image": self.sketchImageView,
                                      @"message": self.messageText,
                                      @"dismiss": self.dismissButton
                                     };
    NSString *format = @"V:|-(>=15)-[check(==36)]-(==15)-[title]-(==20)-[image(==240)]-(==20)-[message]-(==20)-[dismiss(==30)]-(>=15)-|";
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format
                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                 metrics:nil
                                                                   views:viewsDictionary]];
}

- (void)applyCenterXConstraints {
    [self applyCenterXConstraintTo:self.checkImageView];
    [self applyCenterXConstraintTo:self.sketchImageView];
    [self applyCenterXConstraintTo:self.titleLabel];
    [self applyCenterXConstraintTo:self.messageText];
    NSString *format = @"H:|-(==15)-[message]-(==15)-|";
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format
                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                 metrics:nil
                                                                   views:@{ @"message": self.messageText }]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==20)-[button]-(==20)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{ @"button": self.dismissButton }]];
}

- (void)applyCenterXConstraintTo:(UIView *)view {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];
}


@end
