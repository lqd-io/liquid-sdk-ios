//
//  LQSlideUplMessageView.m
//  PopupTest
//
//  Created by Miguel M. Almeida on 18/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQSlideUpView.h"
#import <QuartzCore/QuartzCore.h>
#import "LQSlideUpMessageViewController.h"

static NSInteger const kAnimationOptionCurveIOS7 = (7 << 16); // note: this curve ignores durations
static NSInteger const kiPhone6Width = 667;
static NSInteger const kCornerRadius = 4;

@interface LQSlideUpView ()

@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) CGFloat fadingSpeed;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIViewController *contentViewController;

@end

@implementation LQSlideUpView {
    UIView *_containerView;
    LQSlideUpMessageViewController *_contentViewController;
    BOOL _isAnimating;
    BOOL _isShowing;
}

@synthesize contentViewController = _contentViewController;
@synthesize containerView = _containerView;
@synthesize isAnimating = _isAnimating;
@synthesize isShowing = _isShowing;

+ (instancetype)slideUpWithContentViewController:(UIViewController *)contentViewController {
    LQSlideUpView *slideUp = [[[self class] alloc] init];
    slideUp.contentViewController = contentViewController;
    [slideUp defineLayoutAndSize];
    return slideUp;
}

#pragma mark - Initializers/deallocers

- (id)init {
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.alpha = 0.0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizesSubviews = YES;
        self.fadingSpeed = 0.50;

        _isAnimating = NO;
        _isShowing = NO;

        [self addSubview:self.containerView];
    }
    return self;
}

#pragma mark - Lazy Initialization

- (UIView *)containerView {
    if(!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.autoresizesSubviews = YES;
        _containerView.userInteractionEnabled = YES;
        _containerView.backgroundColor = [UIColor clearColor];
    }
    return _containerView;
}

#pragma mark - Helpers

- (BOOL)canBePresented {
    return !_isAnimating && !_isShowing;
}

- (BOOL)canBeDismissed {
    return _isShowing && !_isAnimating;
}

#pragma mark - Present SlideUp

- (void)defineLayoutAndSize {
    // Add contentView to container
    if (self.contentViewController.view.superview != self.containerView) {
        [self.containerView addSubview:self.contentViewController.view];
        [self.contentViewController.view layoutIfNeeded];
        self.contentViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
        self.contentViewController.view.layer.shadowOpacity = 0.25;
        self.contentViewController.view.layer.shadowOffset = CGSizeMake(0.0, -2.0);
        self.contentViewController.view.layer.cornerRadius = kCornerRadius;
    }
    [self defineContainerViewConstraints];
    [self defineContentViewConstraints];
}

- (void)presentInWindow:(UIWindow *)window {
    dispatch_async( dispatch_get_main_queue(), ^{
        [self presentInThreadInWindow:window];
    });
}

- (void)presentInThreadInWindow:(UIWindow *)window {
    if ([self canBePresented]) {
        _isAnimating = YES;
        _isShowing = NO;

        // Make sure we're not hidden
        self.hidden = NO;
        self.alpha = 1.0;

        // Animate
        [self addToWindow:window];
        [self animateContainerFromTopInFrame:self.window.frame];
    }
}

- (void)addToWindow:(UIWindow *)window {
    UIView *topmostView = window.subviews[0];
    [topmostView addSubview:self];
}

#pragma mark - Dismiss SlideUp

- (void)dismiss {
    if ([self canBeDismissed]) {
        _isAnimating = YES;
        _isShowing = NO;
        dispatch_async( dispatch_get_main_queue(), ^{
            if (self.hideAnimationCompletedBlock) {
                self.hideAnimationCompletedBlock();
            }
        });
    }
}

#pragma mark - Animations

- (void)animateContainerFromTopInFrame:(CGRect)containerFrame {
    // Determine final position and necessary autoresizingMask for container.
    CGRect finalContainerFrame = containerFrame;
    UIViewAutoresizing containerAutoresizingMask = UIViewAutoresizingNone;
    
    // Position at center
    finalContainerFrame.origin.x = floorf((CGRectGetWidth(self.bounds) - CGRectGetWidth(containerFrame)) / 2.0);
    finalContainerFrame.origin.y = floorf((CGRectGetHeight(self.bounds) - CGRectGetHeight(containerFrame)) / 2.0);
    containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _containerView.autoresizingMask = containerAutoresizingMask;
    
    // Animate from bottom
    _containerView.alpha = 1.0;
    _containerView.transform = CGAffineTransformIdentity;
    CGRect startFrame = finalContainerFrame;
    startFrame.origin.y = CGRectGetHeight(finalContainerFrame) + 1000;
    _containerView.frame = startFrame;
    
    // Animate!
    [UIView animateWithDuration:0.0 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
        _containerView.frame = finalContainerFrame;
    } completion:^(BOOL finished) {
        _isAnimating = NO;
        _isShowing = YES;
        if (self.showAnimationCompletedBlock) {
            self.showAnimationCompletedBlock();
        }
    }];
}

#pragma mark - Constraints

- (void)defineContainerViewConstraints {
    [_containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self removeConstraints:_containerView.constraints];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_containerView
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1
                                                      constant:0]];
}

- (void)defineContentViewConstraints {
    [self.contentViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self removeConstraints:self.contentViewController.view.constraints];
    
    // Align Container View frame with Content View frame
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentViewController.view
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];
    [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentViewController.view
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:_containerView
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0]];

    NSLayoutConstraint *constraint;
    constraint = [NSLayoutConstraint constraintWithItem:self.contentViewController.view
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:_containerView
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1
                                               constant:(kCornerRadius * 2)];
    constraint.priority = 999;
    [_containerView addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self.contentViewController.view
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationLessThanOrEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                               constant:(kiPhone6Width + kCornerRadius * 2)]; // full width at iPhone 6
    constraint.priority = 1000;
    [_containerView addConstraint:constraint];

    [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentViewController.view
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:_containerView
                                                               attribute:NSLayoutAttributeHeight
                                                              multiplier:1
                                                                constant:0]];
}

@end
