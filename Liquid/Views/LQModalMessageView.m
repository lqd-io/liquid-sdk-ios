//
//  LQModalMessageView.m
//  PopupTest
//
//  Created by Miguel M. Almeida on 19/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQModalMessageView.h"

@implementation LQModalMessageView

@synthesize inAppMessage = _inAppMessage;
//@synthesize callsToAction = _callsToAction;
@synthesize callsToActionButtons = _callsToActionButtons;

//- (NSMutableArray *)callsToAction {
//    if (!_callsToAction) {
//        _callsToAction = [[NSMutableArray alloc] init];
//    }
//    return _callsToAction;
//}

- (NSMutableArray *)callsToActionButtons {
    if (!_callsToActionButtons) {
        _callsToActionButtons = [[NSMutableArray alloc] init];
    }
    return _callsToActionButtons;
}

- (void)updateLayoutFromInAppMessage {
    if (!self.inAppMessage) {
        [NSException raise:NSInvalidArgumentException format:@"No In-App Message was defined."];
        return;
    }
    self.titleLabel.text = self.inAppMessage.title;
    self.messageView.text = self.inAppMessage.message;
    self.backgroundColor = self.inAppMessage.backgroundColor;
    self.titleLabel.textColor = self.inAppMessage.titleColor;
    self.messageView.textColor = self.inAppMessage.messageColor;
    [self.dismissButton setTitleColor:self.inAppMessage.titleColor forState:UIControlStateNormal];

    NSInteger index = 0;
    for (LQCallToAction *callToAction in self.inAppMessage.callsToAction) {
        //[self.callsToAction addObject:callToAction];
        [self addCallToActionToView:callToAction index:index++];
        return;
    }
}

- (void)addCallToActionToView:(LQCallToAction *)callToAction index:(NSInteger)index {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"CTA" forState:UIControlStateNormal];
    button.tag = index;

    // Define visual aspect
    [button setTitle:callToAction.title forState:UIControlStateNormal];
    [button setTitleColor:callToAction.titleColor forState:UIControlStateNormal];
    button.backgroundColor = callToAction.backgroundColor;

    // Define constraints
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self removeConstraints:button.constraints];
    [self defineConstraintsForButton:button];

    // Define action
    [button addTarget:self action:@selector(ctaButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    // Add button to view
    [self.callsToActionButtons addObject:button];
    [self addSubview:button];
}

- (void)defineConstraintsForButton:(UIButton *)button {
    // Define position in view
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.messageView
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1
                                                      constant:15]]; // 4
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:button
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1
                                                      constant:15]]; // 3
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:15]]; // 1

    // Define width and Height
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:(1.0/1)
                                                      constant:-30]]; // 2
}

#pragma mark - Button actions

- (IBAction)ctaButtonPressed:(UIButton *)sender {
    if([self.delegate respondsToSelector:@selector(modalMessageCTA:)]) {
        LQCallToAction *cta = [self.inAppMessage.callsToAction objectAtIndex:sender.tag];
        [self.delegate performSelectorOnMainThread:@selector(modalMessageCTA:)
                                        withObject:cta
                                     waitUntilDone:NO];
    }
}

@end
