//
//  LQModalMessageView.m
//  PopupTest
//
//  Created by Miguel M. Almeida on 19/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQModalMessageView.h"

@interface LQModalMessageView () {
    ModalMessageDismissBlock _modalDismissBlock;
    ModalMessageCTABlock _modalCTABlock;
    BOOL _layoutIsDefined;
}

@end

@implementation LQModalMessageView

@synthesize inAppMessage = _inAppMessage;
@synthesize callsToActionButtons = _callsToActionButtons;
@synthesize modalDismissBlock = _modalDismissBlock;
@synthesize modalCTABlock = _modalCTABlock;

#pragma mark - Lazy initialization

- (NSMutableArray *)callsToActionButtons {
    if (!_callsToActionButtons) {
        _callsToActionButtons = [[NSMutableArray alloc] init];
    }
    return _callsToActionButtons;
}

#pragma mark - Define layout

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
    
    // Define layout
    self.titleLabel.text = self.inAppMessage.title;
    self.messageView.text = self.inAppMessage.message;
    self.backgroundColor = self.inAppMessage.backgroundColor;
    self.titleLabel.textColor = self.inAppMessage.titleColor;
    self.messageView.textColor = self.inAppMessage.messageColor;
    [self.dismissButton setTitleColor:self.inAppMessage.titleColor forState:UIControlStateNormal];

    // Define CTAs layout
    NSInteger index = 0;
    for (LQCallToAction *callToAction in self.inAppMessage.callsToAction) {
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
    [self.callsToActionButtons addObject:button]; // Respect the same order as CTAs in _inAppMessage
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

    // Define width and height
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:(1.0/1)
                                                      constant:-30]]; // 2
}

#pragma mark - Button actions

- (IBAction)dismissButtonPressd:(UIButton *)sender {
    if (self.modalDismissBlock) {
        self.modalDismissBlock();
    }
}

- (IBAction)ctaButtonPressed:(UIButton *)sender {
    if (self.modalCTABlock) {
        LQCallToAction *cta = [self.inAppMessage.callsToAction objectAtIndex:sender.tag];
        self.modalCTABlock(cta);
    }
}

@end
