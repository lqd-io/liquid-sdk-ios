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
    
    // Configure view elements
    self.titleLabel.text = self.inAppMessage.title;
    self.messageView.text = self.inAppMessage.message;
    self.backgroundColor = self.inAppMessage.backgroundColor;
    self.titleLabel.textColor = self.inAppMessage.titleColor;
    self.messageView.textColor = self.inAppMessage.messageColor;
    [self.dismissButton setTitleColor:self.inAppMessage.titleColor forState:UIControlStateNormal];

    // Add CTAs to view
    NSInteger index = 0;
    for (LQCallToAction *callToAction in self.inAppMessage.callsToAction) {
        [self addCallToActionToView:callToAction index:index++];
    }
    [self defineHorizontalPositionConstraintsForButtons]; // define Horizontal positions + width in view for CTAs
}

- (void)addCallToActionToView:(LQCallToAction *)callToAction index:(NSInteger)index {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"CTA" forState:UIControlStateNormal];
    button.tag = index;

    // Add button to view
    [self.callsToActionButtons addObject:button]; // Respect the same order as CTAs in _inAppMessage
    [self addSubview:button];

    // Define visual aspect
    [button setTitle:callToAction.title forState:UIControlStateNormal];
    [button setTitleColor:callToAction.titleColor forState:UIControlStateNormal];
    button.backgroundColor = callToAction.backgroundColor;
    button.layer.cornerRadius = 4;
    button.clipsToBounds = YES;

    // Define constraints
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self removeConstraints:button.constraints];
    [self defineVerticalPositionConstraintsForButton:button]; // define Vertical position in view for CTA
    if (index > 0) {
        // Set size of all other buttons to the size of first button
        [self defineSizeConstraintsForButton:button equalTo:[self.callsToActionButtons firstObject]];
    }

    // Define action
    [button addTarget:self action:@selector(ctaButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Constraints helpers

- (void)defineSizeConstraintsForButton:(UIButton *)button equalTo:(UIButton *)referenceButton {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:referenceButton
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:referenceButton
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1
                                                      constant:0]];
}

- (void)defineVerticalPositionConstraintsForButton:(UIButton *)button {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.messageView
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1
                                                      constant:10]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:button
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1
                                                      constant:10]];
}

- (void)defineHorizontalPositionConstraintsForButtons {
    // Defines constraints for buttons, creating a dynamic format like e.g: "H:|-(==15)-[button1]-(==15)-[button2]-(==15)-|"
    NSDictionary *viewsDictionary = [[self class] viewsDictionaryForButtons:self.callsToActionButtons];
    NSString *format = [[self class] constraintsFormatForNButtons:[self.callsToActionButtons count]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format
                                                                 options:0
                                                                 metrics:nil
                                                                   views:viewsDictionary]];
}

+ (NSString *)constraintsFormatForNButtons:(NSInteger)count {
    NSMutableString *buttonsFormat = [[NSMutableString alloc] init];
    for (NSInteger i = 0; i < count ; i++) {
        [buttonsFormat appendFormat:@"[button%ld]-(==10)-", (long)i];
    }
    return [NSString stringWithFormat:@"H:|-(==10)-%@|", buttonsFormat];
}

+ (NSDictionary *)viewsDictionaryForButtons:(NSArray *)buttons {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSInteger index = 0;
    for (UIButton *button in buttons) {
        [dict setObject:button forKey:[NSString stringWithFormat:@"button%ld", (long)index++]];
    }
    return dict;
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
