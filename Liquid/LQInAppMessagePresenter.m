//
//  LQInAppMessage.m
//  PopupTest
//
//  Created by Miguel M. Almeida on 22/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQInAppMessagePresenter.h"
#import "LQModalMessageView.h"
#import "LQModalView.h"
#import "lQDefaults.h"
#import "Liquid.h"

@interface LQInAppMessagePresenter ()

@property (nonatomic, strong) LQModalView *modalView;
@property (nonatomic, strong) LQInAppMessage *inAppMessage;

@end

@implementation LQInAppMessagePresenter

@synthesize modalView = _modalView;
@synthesize inAppMessage = _inAppMessage;

//+ (void)presentInAppMessage:(LQInAppMessage *)inAppMessage {
//    if([inAppMessage isInvalid]) {
//        LQLog(kLQLogLevelError, @"Could not present In-App Message because it is invalid");
//        return;
//    }
//    if(inAppMessage.layout == kLQInAppMessageLayoutModal) {
//        LQInAppMessageModal *message = (LQInAppMessageModal *)inAppMessage;
//        [[[LQInAppMessagePresenter alloc] initWithModalInAppMessage:message] present];
//    } else if(inAppMessage.layout == kLQInAppMessageLayoutSlideUp) {
//        [[[LQInAppMessagePresenter alloc] initWithSlideUpInAppMessage:inAppMessage] present];
//    } else if(inAppMessage.layout == kLQInAppMessageLayoutFullScreen) {
//        [[[LQInAppMessagePresenter alloc] initWithFullScreenInAppMessage:inAppMessage] present];
//    } else {
//        [NSException raise:NSInvalidArgumentException format:@"Invalid In-App Message type %@", NSStringFromSelector(_cmd)];
//    }
//}

#pragma mark - Present In-App Message

- (void)present {
    if([_inAppMessage isInvalid]) {
        LQLog(kLQLogLevelError, @"Could not present In-App Message because it is invalid");
        return;
    }
    if([_inAppMessage isKindOfClass:[LQInAppMessageModal class]]) {
        [self.modalView presentModal];
    }
}

#pragma mark - Modal In-App Message

- (instancetype)initWithModal:(LQInAppMessageModal *)inAppMessage {
    self = [super init];
    if(self) {
        _inAppMessage = inAppMessage;
        // Build message view
        if([[NSBundle mainBundle] pathForResource:@"LQModalMessage" ofType:@"nib"]) {
            LQModalMessageView *messageView = [[[NSBundle mainBundle] loadNibNamed:@"LQModalMessage" owner:self options:nil] lastObject];
            messageView.delegate = self;
            [messageView updateLayoutWithInAppMessage:inAppMessage];
            // Put the message view inside modal view and present it
            self.modalView = [LQModalView modalWithContentView:messageView];
        } else {
            LQLog(kLQLogLevelError, @"Could not found LQModalMessage to show modal in-app message.");
        }
    }
    return self;
}

- (void)modalMessageDismiss {
    [self.modalView dismissModal];
}

- (void)modalMessageCTA1 {
    NSLog(@"CTA 1");
    //LQInAppMessageModal *inAppMessage = (LQInAppMessageModal *)_inAppMessage;
    //[[Liquid sharedInstance] track:[inAppMessage.callsToAction objectAtIndex:0]];
    [self.modalView dismissModal];
}

- (void)modalMessageCTA2 {
    NSLog(@"CTA 2");
    [self.modalView dismissModal];
}

#pragma mark - Slide Up In-App Message

- (instancetype)initWithSlideUpInAppMessage:(LQInAppMessage *)inAppMessage {
    self = [super init];
    if(self) {
        // TO DO
    }
    return self;
}

#pragma mark - Full Screen In-App Message

- (instancetype)initWithFullScreenInAppMessage:(LQInAppMessage *)inAppMessage {
    self = [super init];
    if(self) {
        // TO DO
    }
    return self;
}

+ (BOOL)fileExistsInProject:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileInResourcesFolder = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName];
    return [fileManager fileExistsAtPath:fileInResourcesFolder];
}

@end
