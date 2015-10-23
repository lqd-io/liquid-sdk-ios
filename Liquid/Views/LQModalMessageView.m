//
//  LQModalMessageView.m
//  PopupTest
//
//  Created by Miguel M. Almeida on 19/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQModalMessageView.h"

@implementation LQModalMessageView

- (IBAction)dismissButtonPressed:(id)sender {
    if([self.delegate respondsToSelector:@selector(modalMessageDismiss)]) {
        [self.delegate performSelectorOnMainThread:@selector(modalMessageDismiss) withObject:nil waitUntilDone:NO];
    }
}

- (IBAction)cta1ButtonPressed:(id)sender {
    if([self.delegate respondsToSelector:@selector(modalMessageCTA1)]) {
        [self.delegate performSelectorOnMainThread:@selector(modalMessageCTA1) withObject:nil waitUntilDone:NO];
    }
}
- (IBAction)cta2ButtonPressed:(id)sender {
    if([self.delegate respondsToSelector:@selector(modalMessageCTA2)]) {
        [self.delegate performSelectorOnMainThread:@selector(modalMessageCTA2) withObject:nil waitUntilDone:NO];
    }
}

@end
