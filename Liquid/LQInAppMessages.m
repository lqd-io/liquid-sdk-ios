//
//  LQInAppMessages.m
//  Liquid
//
//  Created by Miguel M. Almeida on 27/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQInAppMessages.h"
#import "LQDefaults.h"

#if LQ_INAPP_MESSAGES_SUPPORT
#import "NSData+LQData.h"
#import "LQModalView.h"
#import "LQModalMessageViewController.h"
#import "LQInAppMessageModal.h"
#import "LQSlideUpView.h"
#import "LQSlideUpMessageViewController.h"
#import "LQInAppMessageSlideUp.h"
#import "LQRequest.h"
#import "LQDate.h"
#import "LQWindow.h"

@interface LQInAppMessages ()

@property (nonatomic, strong) LQNetworking *networking;
@property (nonatomic, strong) LQEventTracker *eventTracker;
@property (nonatomic, strong) NSMutableArray *messagesQueue;
@property (nonatomic, strong) id presentingMessage;
#if OS_OBJECT_USE_OBJC
@property (atomic, strong) dispatch_queue_t queue;
#else
@property (atomic, assign) dispatch_queue_t queue;
#endif
@property (strong, nonatomic) UIWindow *window;

@end

@implementation LQInAppMessages

@synthesize networking = _networking;
@synthesize eventTracker = _eventTracker;
@synthesize messagesQueue = _messagesQueue;
@synthesize currentUser = _currentUser;

#pragma mark - Initializers

- (instancetype)initWithNetworking:(LQNetworking *)networking dispatchQueue:(dispatch_queue_t)queue eventTracker:(LQEventTracker *)eventTracker {
    self = [super init];
    if (self) {
        self.networking = networking;
        self.queue = queue;
        self.eventTracker = eventTracker;
        self.presentingMessage = nil;
        [self setupRotationNotification];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray *)messagesQueue {
    if (!_messagesQueue) {
        _messagesQueue = [[NSMutableArray alloc] init];
    }
    return _messagesQueue;
}

#pragma mark - Request and Present Messages

- (void)requestAndPresentInAppMessages {
    if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
        LQLog(kLQLogLevelInfo, @"<Liquid/InAppMessages> In-App Messages are only supported in iOS >= 6.0.");
        return;
    }
    if (self.presentingMessage) {
        LQLog(kLQLogLevelInfo, @"<Liquid/InAppMessages> Will not request more In-App Messages while showing one.");
        return;
    }
    dispatch_async(self.queue, ^{
        [self requestMessagesWithCompletionHandler:^(NSData *dataFromServer) {
            if (!dataFromServer) {
                return;
            }
            NSArray *inAppMessages = [NSData fromJSON:dataFromServer];
            for (NSDictionary *inAppMessageDict in inAppMessages) {
                id message;
                if ([inAppMessageDict[@"layout"] isEqualToString:@"modal"]) {
                    message = [[LQInAppMessageModal alloc] initFromDictionary:inAppMessageDict];
                } else if ([inAppMessageDict[@"layout"] isEqualToString:@"slide_up"]) {
                    message = [[LQInAppMessageSlideUp alloc] initFromDictionary:inAppMessageDict];
                }
                if (message) {
                    @synchronized(self.messagesQueue) {
                        [self.messagesQueue addObject:message];
                    }
                }
            }
        }];
        [self presentNextMessageInQueue];
    });
}

- (void)requestMessagesWithCompletionHandler:(void(^)(NSData *data))completionBlock {
    if (!self.currentUser) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid/InAppMessages> A user has not been identified yet.");
        return;
    }
    NSString *endPoint = [NSString stringWithFormat:@"users/%@/inapp_messages", self.currentUser.identifier, nil];
    NSData *dataFromServer = [_networking getSynchronousDataFromEndpoint:endPoint];
    if (dataFromServer != nil) {
        completionBlock(dataFromServer);
    }
}

- (void)presentNextMessageInQueue {
    if (self.presentingMessage) {
        LQLog(kLQLogLevelInfoVerbose, @"Already preesnting a In-App Message.");
        return;
    }
    if ([self.messagesQueue count] == 0) {
        LQLog(kLQLogLevelInfoVerbose, @"No In-App Messages in queue to show");
        return;
    }

    // Pop a Message from queue and present it
    __block id message;
    @synchronized(self.messagesQueue) {
        message = [self.messagesQueue objectAtIndex:0];
        [self.messagesQueue removeObjectAtIndex:0];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentInAppMessage:message];
    });
}

- (void)unpresentCurrentMessage {
    self.window = nil;
    self.presentingMessage = nil;
}

#pragma mark - Reports

- (void)reportPresentedMessageWithAttributes:(NSDictionary *)attributes {
    __block NSData *json = [NSData toJSON:attributes];
    dispatch_async(self.queue, ^{
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Sending In-App Message report to server: %@",
              [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]);
        NSString *endpoint = [NSString stringWithFormat:@"users/%@/formulas/%@/report",
                              self.currentUser.identifier, attributes[@"formula_id"]];
        NSInteger res = [_networking sendSynchronousData:json toEndpoint:endpoint usingMethod:@"POST"];
        if(res != LQQueueStatusOk) {
            LQLog(kLQLogLevelHttpError, @"<Liquid> Could not send report to server %@",
                  [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]);
        }
    });
}

#pragma mark - Present the different layouts of In-App Messages

- (void)presentInAppMessage:(id)message {
    if([message isInvalid]) {
        LQLog(kLQLogLevelError, @"Could not present In-App Message because it is invalid");
        return;
    }
    [[self class] dismissKeyboard];
    BOOL presented = NO;
    if ([message isKindOfClass:[LQInAppMessageModal class]]) {
        self.presentingMessage = message;
        presented = [self presentModalInAppMessage:message];
    } else if ([message isKindOfClass:[LQInAppMessageSlideUp class]]) {
        self.presentingMessage = message;
        presented = [self presentSlideUpInAppMessage:message];
    }
    if (!presented) {
        [self unpresentCurrentMessage];
        [self presentNextMessageInQueue];
    }
}

- (BOOL)presentSlideUpInAppMessage:(LQInAppMessageSlideUp *)message {
    if(![[NSBundle mainBundle] pathForResource:@"LQSlideUpMessage" ofType:@"nib"]) {
        LQLog(kLQLogLevelError, @"Could not find LQSlideUpMessage XIB to show SlideUp In-App Message.");
        return NO;
    }
    
    // Put SlideUpMessageView inside SlideUpView and present it
    LQSlideUpMessageViewController *messageViewController = [[LQSlideUpMessageViewController alloc] initWithNibName:@"LQSlideUpMessage" bundle:[NSBundle mainBundle]];
    messageViewController.inAppMessage = message;
    [messageViewController defineLayoutWithInAppMessage];
    __block LQSlideUpView *slideUpView = [LQSlideUpView slideUpWithContentViewController:messageViewController];

    // Define callbacks for CTAs and Dismiss
    messageViewController.callToActionBlock = ^(LQCallToAction *cta) {
        [self.eventTracker track:cta.eventName
                      attributes:cta.eventAttributes
                    loadedValues:nil
                        withDate:[LQDate uniqueNow]];
        [self reportPresentedMessageWithAttributes:cta.eventAttributes];
        [slideUpView dismiss];
        [cta followURL];
    };
    messageViewController.dismissBlock = ^() {
        [self.eventTracker track:message.dismissEventName
                      attributes:message.dismissEventAttributes
                    loadedValues:nil
                        withDate:[LQDate uniqueNow]];
        [self reportPresentedMessageWithAttributes:message.dismissEventAttributes];
        [slideUpView dismiss];
    };
    slideUpView.hideAnimationCompletedBlock = ^{
        [self unpresentCurrentMessage];
        [self presentNextMessageInQueue];
    };

    // Create window and show message
    UIWindow *window = [LQWindow bottomWindowWithHeight:[messageViewController.height floatValue]];
    [window makeKeyAndVisible];
    self.window = window;
    [slideUpView presentInWindow:self.window];
    return YES;
}

- (BOOL)presentModalInAppMessage:(LQInAppMessageModal *)message {
    if(![[NSBundle mainBundle] pathForResource:@"LQModalMessage" ofType:@"nib"]) {
        LQLog(kLQLogLevelError, @"Could not find LQModalMessage XIB to show Modal In-App Message.");
        return NO;
    }

    // Put ModalMessageView inside ModalView and present it
    LQModalMessageViewController *messageViewController = [[LQModalMessageViewController alloc] initWithNibName:@"LQModalMessage" bundle:[NSBundle mainBundle]];
    messageViewController.inAppMessage = message;
    [messageViewController defineLayoutWithInAppMessage];
    __block LQModalView *modalView = [LQModalView modalWithContentView:messageViewController];

    // Define callbacks for CTAs and Dismiss
    messageViewController.callToActionBlock = ^(LQCallToAction *cta) {
        [self.eventTracker track:cta.eventName
                      attributes:cta.eventAttributes
                    loadedValues:nil
                        withDate:[LQDate uniqueNow]];
        [self reportPresentedMessageWithAttributes:cta.eventAttributes];
        [modalView dismiss];
        [cta followURL];
    };
    messageViewController.dismissBlock = ^{
        [self.eventTracker track:message.dismissEventName
                      attributes:message.dismissEventAttributes
                    loadedValues:nil
                        withDate:[LQDate uniqueNow]];
        [self reportPresentedMessageWithAttributes:message.dismissEventAttributes];
        [modalView dismiss];
    };
    modalView.hideAnimationCompletedBlock = ^{
        [self unpresentCurrentMessage];
        [self presentNextMessageInQueue];
    };

    // Create window and present message
    UIWindow *window = [LQWindow fullscreenWindow];
    [window makeKeyAndVisible];
    self.window = window;
    [modalView presentInWindow:self.window];
    return YES;
}

#pragma mark - Keyboard

+ (void)dismissKeyboard {
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

#pragma mark - Handle device rotation

- (void)setupRotationNotification {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    // Only SlideUp messages need rotation handle
    if (self.presentingMessage && [self.presentingMessage isKindOfClass:[LQInAppMessageSlideUp class]]) {
        self.window = nil;
        [self presentInAppMessage:self.presentingMessage];
    }
}

@end
#endif
