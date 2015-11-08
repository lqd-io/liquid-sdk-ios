//
//  LQSlideUpMessageView.m
//  Liquid
//
//  Created by Miguel M. Almeida on 29/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQSlideUpMessageViewController.h"

@interface LQSlideUpMessageViewController () {
    BOOL _layoutIsDefined;
}

@property (nonatomic, assign) CGPoint originalCenter;

@end

@implementation LQSlideUpMessageViewController

@synthesize inAppMessage = _inAppMessage;
@synthesize dismissBlock = _dismissBlock;
@synthesize callToActionBlock = _callToAcionBlock;

- (void)viewDidLoad {
    _layoutIsDefined = NO;
    self.originalCenter = CGPointMake(self.view.center.x, self.view.center.y);
    [self assignGestureHandlers];
}

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
    _layoutIsDefined = YES;
    
    // Configure view elements
    self.messageView.text = self.inAppMessage.message;
    self.view.backgroundColor = self.inAppMessage.backgroundColor;
    self.messageView.textColor = self.inAppMessage.messageColor;
    [self.callToAction setTitleColor:self.inAppMessage.messageColor forState:UIControlStateNormal];
}

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
        if (self.view.center.y > self.originalCenter.y + 50 / 2) {
            [self moveAway];
        } else {
            [self restorePosition];
        }
    }
}

- (CGFloat)inertiaFactorRelativeTo:(CGFloat)position {
    CGFloat max = 100;
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