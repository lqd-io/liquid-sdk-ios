//
//  LQModalMessageView.m
//  PopupTest
//
//  Created by Miguel M. Almeida on 18/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQModalView.h"
#import <QuartzCore/QuartzCore.h>
#import "LQModalMessageViewController.h"

static NSInteger const kAnimationOptionCurveIOS7 = (7 << 16); // note: this curve ignores durations

@interface LQModalView ()

@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) CGFloat dimmedMaskAlpha;
@property (nonatomic, assign) CGFloat fadingSpeed;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIViewController *contentViewController;

@end

@implementation LQModalView {
    UIView *_backgroundView;
    UIView *_containerView;
    UIViewController *_contentViewController;
    BOOL _isAnimating;
    BOOL _isShowing;
}

@synthesize contentViewController = _contentViewController;
@synthesize backgroundView = _backgroundView;
@synthesize containerView = _containerView;
@synthesize isAnimating = _isAnimating;
@synthesize isShowing = _isShowing;
@synthesize fadingSpeed = _fadingSpeed;

+ (LQModalView *)modalWithContentView:(UIViewController *)contentViewController {
    LQModalView *modal = [[LQModalView alloc] init];
    modal.contentViewController = contentViewController;
    return modal;
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self]; // stop listening to notifications
}

#pragma mark - Initializers/deallocers

- (id)init {
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0.0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizesSubviews = YES;
        self.dimmedMaskAlpha = 0.50;
        self.fadingSpeed = 0.30;
        
        _isAnimating = NO;
        _isShowing = NO;
        
        [self addSubview:self.backgroundView];
        [self addSubview:self.containerView];
    }
    return self;
}

#pragma mark - Lazy Initialization

- (UIView *)backgroundView {
    if(!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [UIColor clearColor];
        _backgroundView.userInteractionEnabled = NO;
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _backgroundView.frame = self.bounds;
    }
    return _backgroundView;
}

- (UIView *)containerView {
    if(!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.autoresizesSubviews = YES;
        _containerView.userInteractionEnabled = YES;
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.layer.cornerRadius = 5;
        _containerView.layer.masksToBounds = YES;
    }
    return _containerView;
}

#pragma mark - Helpers

- (BOOL)modalCanBePresented {
    return !_isAnimating && !_isShowing;
}

- (BOOL)modalCanBeDismissed {
    return _isShowing && !_isAnimating;
}

#pragma mark - Present Modal

- (void)presentInWindow:(UIWindow *)window {
    dispatch_async( dispatch_get_main_queue(), ^{
        [self presentInThreadInWindow:window];
    });
}

- (void)presentInThreadInWindow:(UIWindow *)window {
    if ([self modalCanBePresented]) {
        _isAnimating = YES;
        _isShowing = NO;
        
        [self addToWindow:window];
        
        // Make sure we're not hidden
        self.hidden = NO;
        self.alpha = 1.0;
        
        [self animateBackground];
        
        // Add contentView to container
        if (self.contentViewController.view.superview != self.containerView) {
            [self.containerView addSubview:self.contentViewController.view];
            [self.contentViewController.view layoutIfNeeded];
        }
        
        [self defineContainerViewConstraints];
        [self defineContentViewConstraints];
        
        // Animate
        [self animateContainerFromTopInFrame:self.window.frame];
    }
}

- (void)addToWindow:(UIWindow *)window {
    UIView *topmostView = window.subviews[0];
    [topmostView addSubview:self];
}

#pragma mark - Dismiss Modal

- (void)dismissModal {
    if ([self modalCanBeDismissed]) {
        _isAnimating = YES;
        _isShowing = NO;
        
        dispatch_async( dispatch_get_main_queue(), ^{
            [self dismissModalInThread];
        });
    }
}

- (void)dismissModalInThread {
    // Make fade happen faster than motion. Use linear for fades.
    void (^backgroundAnimationBlock)(void) = ^(void) {
        _backgroundView.alpha = 0.0;
    };
    [UIView animateWithDuration:0.15
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:backgroundAnimationBlock
                     completion:NULL];
    
    // Setup completion block
    void (^completionBlock)(BOOL) = ^(BOOL finished) {
        [self removeFromSuperview];
        _isAnimating = NO;
        _isShowing = NO;
        if (self.hideAnimationCompletedBlock) {
            self.hideAnimationCompletedBlock();
        }
    };
    [UIView animateWithDuration:0.20 delay:0 options:kAnimationOptionCurveIOS7 animations:^{
        CGRect finalFrame = _containerView.frame;
        finalFrame.origin.y = CGRectGetHeight(self.bounds);
        _containerView.frame = finalFrame;
    } completion:completionBlock];
}


#pragma mark - Animations

- (void)animateBackground {
    self.backgroundView.alpha = 0.0;
    self.backgroundView.backgroundColor = [UIColor colorWithRed:(0.0/255.0f) green:(0.0/255.0f) blue:(0.0/255.0f) alpha:self.dimmedMaskAlpha];
    void (^backgroundAnimationBlock)(void) = ^(void) {
        self.backgroundView.alpha = 1.0;
    };
    [UIView animateWithDuration:(self.fadingSpeed * 2) // make fade happen faster than motion.
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:backgroundAnimationBlock
                     completion:NULL];
}

- (void)animateContainerFromTopInFrame:(CGRect)containerFrame {
    // Determine final position and necessary autoresizingMask for container.
    CGRect finalContainerFrame = containerFrame;
    UIViewAutoresizing containerAutoresizingMask = UIViewAutoresizingNone;
    
    // Position at center
    finalContainerFrame.origin.x = floorf((CGRectGetWidth(self.bounds) - CGRectGetWidth(containerFrame)) / 2.0);
    finalContainerFrame.origin.y = floorf((CGRectGetHeight(self.bounds) - CGRectGetHeight(containerFrame)) / 2.0);
    containerAutoresizingMask = containerAutoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _containerView.autoresizingMask = containerAutoresizingMask;
    
    // Animate from top
    _containerView.alpha = 1.0;
    _containerView.transform = CGAffineTransformIdentity;
    CGRect startFrame = finalContainerFrame;
    startFrame.origin.y = -CGRectGetHeight(finalContainerFrame);
    _containerView.frame = startFrame;
    
    // Animate!
    [UIView animateWithDuration:self.fadingSpeed delay:0 options:kAnimationOptionCurveIOS7 animations:^{
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
    NSLayoutConstraint *constraint;
    constraint = [NSLayoutConstraint constraintWithItem:_containerView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationLessThanOrEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                               constant:350];
    constraint.priority = 1000;
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:_containerView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:0.75
                                               constant:0];
    constraint.priority = 750;
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:_containerView
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationLessThanOrEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                               constant:200];
    constraint.priority = 1000;
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:_containerView
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeHeight
                                             multiplier:1
                                               constant:-30];
    constraint.priority = 750;
    [self addConstraint:constraint];
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
    [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentViewController.view
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:_containerView
                                                               attribute:NSLayoutAttributeWidth
                                                              multiplier:1
                                                                constant:0]];
    [_containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentViewController.view
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:_containerView
                                                               attribute:NSLayoutAttributeHeight
                                                              multiplier:1
                                                                constant:0]];
}

@end
