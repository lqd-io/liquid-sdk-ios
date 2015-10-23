//
//  LQInAppMessage.m
//  PopupTest
//
//  Created by Miguel M. Almeida on 22/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQInAppMessage.h"
#import "LQModalView.h"

@interface LQInAppMessage ()

@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) LQModalView *modalView;

@end

@implementation LQInAppMessage

@synthesize options = _options;
@synthesize modalView = _modalView;

+ (void)presentInAppMessageOfType:(LQInAppMessageType)type withTitle:(NSString *)title message:(NSString *)message {
    [self presentInAppMessageOfType:type withTitle:title message:message options:nil];
}

+ (void)presentInAppMessageOfType:(LQInAppMessageType)type withTitle:(NSString *)title message:(NSString *)message options:(NSDictionary *)options {
    LQInAppMessage *inAppMessage = [[[self class] alloc] init];
    if(type == kLQInAppMessageTypeModal) {
        [inAppMessage presentModalWithTitle:[title copy] message:[message copy] options:options];
    } else if(type == kLQInAppMessageTypeSlideUp) {
        [inAppMessage presentSlideUpWithTitle:[title copy] message:[message copy] options:options];
    } else if(type == kLQInAppMessageTypeFullScreen) {
        [inAppMessage presentFullScreenWithTitle:[title copy] message:[message copy] options:options];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Invalid In-App Message type %@", NSStringFromSelector(_cmd)];
    }
}

#pragma mark - Modal In-App Message

- (void)presentModalWithTitle:(NSString *)title message:(NSString *)message options:(NSDictionary *)options {
    self.options = options;
    LQModalMessageView *messageView = [[[NSBundle mainBundle] loadNibNamed:@"LQModalMessage" owner:self options:nil] lastObject];
    messageView.delegate = self;
    messageView.titleLabel.text = title;
    messageView.messageView.text = message;
    messageView.cta1Button.titleLabel.text = options[@"cta1_button_text"] ? options[@"cta1_button_text"] : @"Cancel";
    messageView.cta1Button.titleLabel.text = options[@"cta2_button_text"] ? options[@"cta2_button_text"] : @"OK";

    self.modalView = [LQModalView modalWithContentView:messageView];
    [self.modalView presentModal];
}

- (void)modalMessageDismiss {
    [self.modalView dismissModal];
}

- (void)modalMessageCTA1 {
    NSLog(@"CTA 1");
}

- (void)modalMessageCTA2 {
    NSLog(@"CTA 2");
}

#pragma mark - Slide Up In-App Message

- (void)presentSlideUpWithTitle:(NSString *)title message:(NSString *)message options:(NSDictionary *)options {
    // TODO
}

#pragma mark - Full Screen In-App Message

- (void)presentFullScreenWithTitle:(NSString *)title message:(NSString *)message options:(NSDictionary *)options {
    // TODO
}

@end
