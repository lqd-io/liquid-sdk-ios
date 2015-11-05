//
//  LQInAppMessages.m
//  Liquid
//
//  Created by Miguel M. Almeida on 27/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQInAppMessages.h"
#import "LQDefaults.h"
#import "NSData+LQData.h"
#import "LQModalView.h"
#import "LQModalMessageViewController.h"
#import "LQInAppMessageModal.h"
#import "LQRequest.h"
#import "LQDate.h"
#import "LQWindow.h"

@interface LQInAppMessages () {
    BOOL _presentingMessage;
}

@property (nonatomic, strong) LQNetworking *networking;
@property (nonatomic, strong) LQEventTracker *eventTracker;
@property (nonatomic, strong) NSMutableArray *messagesQueue;
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
    }
    return self;
}

- (NSMutableArray *)messagesQueue {
    if (!_messagesQueue) {
        _messagesQueue = [[NSMutableArray alloc] init];
    }
    return _messagesQueue;
}

#pragma mark - Request and Present Messages

- (void)requestAndPresentInAppMessages {
    if (_presentingMessage) {
        LQLog(kLQLogLevelInfo, @"<Liquid/InAppMessages> Will not request more In-App Messages while showing one.");
        return;
    }
    dispatch_async(self.queue, ^{
        [self requestMessagesWithCompletionHandler:^(NSData *dataFromServer) {
            NSArray *inAppMessages = [NSData fromJSON:dataFromServer];
            for (NSDictionary *inAppMessageDict in inAppMessages) {
                id message;
                if ([inAppMessageDict[@"layout"] isEqualToString:@"modal"]) {
                    message = [[LQInAppMessageModal alloc] initFromDictionary:inAppMessageDict];
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
    NSData *dataFromServer = [_networking getDataFromEndpoint:endPoint];
    if (dataFromServer != nil) {
        completionBlock(dataFromServer);
    }
}

- (void)presentNextMessageInQueue {
    if (_presentingMessage) {
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

#pragma mark - Reports

- (void)reportPresentedMessageWithAttributes:(NSDictionary *)attributes {
    __block NSData *json = [NSData toJSON:attributes];
    dispatch_async(self.queue, ^{
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Sending In-App Message report to server: %@",
              [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]);
        NSString *endpoint = [NSString stringWithFormat:@"users/%@/formulas/%@/report",
                              self.currentUser.identifier, attributes[@"formula_id"]];
        NSInteger res = [_networking sendData:json toEndpoint:endpoint usingMethod:@"POST"];
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
    if ([message isKindOfClass:[LQInAppMessageModal class]]) {
        _presentingMessage = YES;
        [self presentModalInAppMessage:message];
    }
}

- (void)presentModalInAppMessage:(LQInAppMessageModal *)message {
    if(![[NSBundle mainBundle] pathForResource:@"LQModalMessage" ofType:@"nib"]) {
        LQLog(kLQLogLevelError, @"Could not find LQModalMessage XIB to show Modal In-App Message.");
        return;
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
        [modalView dismissModal];
        [cta followURL];
    };
    messageViewController.dismissBlock = ^{
        [self.eventTracker track:message.dismissEventName
                      attributes:message.dismissEventAttributes
                    loadedValues:nil
                        withDate:[LQDate uniqueNow]];
        [self reportPresentedMessageWithAttributes:message.dismissEventAttributes];
        [modalView dismissModal];
    };
    modalView.hideAnimationCompletedBlock = ^{
        self.window = nil;
        _presentingMessage = NO;
        [self presentNextMessageInQueue];
    };

    // Create window and present message
    UIWindow *window = [LQWindow fullscreenWindow];
    [window makeKeyAndVisible];
    self.window = window;
    [modalView presentInWindow:self.window];
}

#pragma mark - Keyboard

+ (void)dismissKeyboard {
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

@end
