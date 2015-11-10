//
//  LQSlideUpMessageView.m
//  Liquid
//
//  Created by Miguel M. Almeida on 29/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQSlideUpMessageViewController.h"
#import "LQCaret.h"

@interface LQSlideUpMessageViewController () {
    BOOL _layoutIsDefined;
}

@property (nonatomic, assign) CGPoint originalCenter;

@end

static NSNumber *messageMargin;

@implementation LQSlideUpMessageViewController

@synthesize inAppMessage = _inAppMessage;
@synthesize dismissBlock = _dismissBlock;
@synthesize callToActionBlock = _callToActionBlock;
@synthesize height = _height;
@synthesize messageView = _messageView;
@synthesize callToAction = _callToAction;

- (NSNumber *)height {
    return [NSNumber numberWithFloat:(self.messageView.frame.size.height + 20)];
}

- (void)viewDidLoad {
    messageMargin = @20.0;
    _layoutIsDefined = NO;
    self.originalCenter = CGPointMake(self.view.center.x, self.view.center.y);
    [self assignGestureHandlers];
}

#pragma mark - Layout

- (void)defineLayoutWithInAppMessage {
    if (_layoutIsDefined) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Layout has already been defined. You can do it only once"];
        return;
    }
    if (!self.inAppMessage) {
        [NSException raise:NSInvalidArgumentException
                    format:@"No In-App Message was defined."];
        return;
    }

    // Define view elements
    [self.view setNeedsDisplay];
    self.view.backgroundColor = self.inAppMessage.backgroundColor;
    [self defineMessageLayout];
    [self defineCTALayout];

    // Define constraints
    [self.view removeConstraints:self.view.constraints];
    [self defineHorizontalConstraints];
    [self defineVerticalConstraints];

    _layoutIsDefined = YES;
}

- (void)defineMessageLayout {
    [self.messageView setText:self.inAppMessage.message];
    self.messageView.textColor = self.inAppMessage.messageColor;
    [self.messageView sizeToFit];
}

- (void)defineCTALayout {
    [self.callToAction setTitleColor:self.inAppMessage.messageColor forState:UIControlStateNormal];
    [self.callToAction setTitle:@"" forState:UIControlStateNormal];
    LQCaret *caret = [[LQCaret alloc] initWithFrame:CGRectMake(0, 0, 20, 20) strokeColor:self.inAppMessage.messageColor];
    [self.callToAction addSubview:caret];
    [self.callToAction addConstraint:[NSLayoutConstraint constraintWithItem:caret
                                                                  attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.callToAction
                                                                  attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1
                                                                   constant:0]];
    [self.callToAction addConstraint:[NSLayoutConstraint constraintWithItem:caret
                                                                  attribute:NSLayoutAttributeCenterY
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.callToAction
                                                                  attribute:NSLayoutAttributeCenterY
                                                                 multiplier:1
                                                                   constant:1]]; // slightly below the line
}

#pragma mark - Sizes and Constraints

- (void)defineHorizontalConstraints {
    NSString *format = @"H:|-(==margin)-[message]-[cta(==20)]-(==margin)-|";
    NSDictionary *views = @{ @"message": self.messageView, @"cta": self.callToAction };
    NSDictionary *metrics = @{ @"margin": messageMargin };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
}

- (void)defineVerticalConstraints {
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.callToAction
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.messageView
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.messageView
                                                          attribute:NSLayoutAttributeTopMargin
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTopMargin
                                                         multiplier:1
                                                           constant:[messageMargin floatValue]]];
}

#pragma mark - Actions

- (IBAction)ctaButtonPressed {
    if (self.callToActionBlock) {
        self.callToActionBlock(self.inAppMessage.callToAction);
    }
}

#pragma mark - Gestures

- (void)assignGestureHandlers {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.originalCenter = self.view.center;
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.view];
        CGFloat yTranslation = translation.y * [self inertiaFactorRelativeTo:recognizer.view.center.y];
        recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                             recognizer.view.center.y + yTranslation);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.view.center.y > self.originalCenter.y + [self.height floatValue] / 3) {
            [self moveAway];
        } else {
            [self restorePosition];
        }
    }
}

- (CGFloat)inertiaFactorRelativeTo:(CGFloat)position {
    CGFloat max = ([self.height floatValue] * 2.0);
    CGFloat delta = self.originalCenter.y - position;
    if (delta < 0) {
        return 1; // only apply ineria if direction is up
    }
    return (max - delta) / max;
}

- (void)moveAway {
    [UIView animateWithDuration: 0.25 delay: 0 options: UIViewAnimationOptionCurveEaseIn animations:^{
        self.view.center = CGPointMake(self.originalCenter.x, self.originalCenter.y * 2);
    } completion:^(BOOL finished) {
        if (self.dismissBlock) {
            self.dismissBlock();
        }
    }];
}

- (void)restorePosition {
    [UIView animateWithDuration: 0.50 delay: 0 options: UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.center = self.originalCenter;
    } completion:nil];
}

@end
