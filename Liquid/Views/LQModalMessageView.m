//
//  LQModalMessageView.m
//  PopupTest
//
//  Created by Miguel M. Almeida on 19/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQModalMessageView.h"

@implementation LQModalMessageView

- (void)updateLayoutWithInAppMessage:(LQInAppMessageModal *)inAppMessage {
    self.titleLabel.text = inAppMessage.title;
    self.messageView.text = inAppMessage.message;
    self.backgroundColor = inAppMessage.backgroundColor;
    self.titleLabel.textColor = inAppMessage.titleColor;
    self.messageView.textColor = inAppMessage.messageColor;
    [self.dismissButton setTitleColor:inAppMessage.titleColor forState:UIControlStateNormal];
    [self.cta1Button setTitle:[[inAppMessage.callsToAction objectAtIndex:0] title] forState:UIControlStateNormal];
    [self.cta1Button setTitleColor:[[inAppMessage.callsToAction objectAtIndex:0] titleColor] forState:UIControlStateNormal];
    self.cta1Button.backgroundColor = [[inAppMessage.callsToAction objectAtIndex:0] backgroundColor];
}

- (IBAction)dismissButtonPressed:(id)sender {
    if([self.delegate respondsToSelector:@selector(modalMessageDismiss)]) {
        [self.delegate performSelectorOnMainThread:@selector(modalMessageDismiss) withObject:nil waitUntilDone:NO];
    }
}

- (IBAction)ctaButtonPressed:(id)sender {
    if([self.delegate respondsToSelector:@selector(modalMessageCTA1)]) {
        [self.delegate performSelectorOnMainThread:@selector(modalMessageCTA1) withObject:nil waitUntilDone:NO];
    }
}

@end
