//
//  LQUIViewRecurringChanger.m
//  Liquid
//
//  Created by Miguel M. Almeida on 05/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQUIViewRecurringChanger.h"
#import "UIView+LQChangeable.h"
#import <UIKit/UIKit.h>

@interface LQUIViewRecurringChanger ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableSet *changedViewIdentifiers;

@end

@implementation LQUIViewRecurringChanger

@synthesize delegate = _delegate;
@synthesize timer = _timer;
@synthesize changedViewIdentifiers = _changedViewIdentifiers;

#pragma mark - Initializers

- (NSMutableSet *)changedViewIdentifiers {
    if (!_changedViewIdentifiers) {
        _changedViewIdentifiers = [[NSMutableSet alloc] init];
    }
    return _changedViewIdentifiers;
}

#pragma mark - Timer

- (void)enableTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                      target:self
                                                    selector:@selector(applyChangesToAllRootVCSubviews)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)disableTimer {
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - Apply changes to Views

- (void)applyChangesToAllRootVCSubviews {
    id view = [UIApplication sharedApplication].keyWindow.rootViewController.view;
    [self applyChangesToView:view];
}

- (void)applyChangesToView:(UIView *)view {
    if ([view isChangeable] && ![self.changedViewIdentifiers containsObject:[view liquidIdentifier]]) {
        if ([self.delegate respondsToSelector:@selector(didFindView:)] && [self.delegate didFindView:view]) {
            [self.changedViewIdentifiers addObject:[view liquidIdentifier]];
        }
    }
    for (UIView *subview in view.subviews) {
        [self applyChangesToView:subview];
    }
}

@end
