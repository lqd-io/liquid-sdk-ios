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
#import "LQModalMessageView.h"

@interface LQInAppMessages () {
    BOOL _presentingMessage;
}

@property (nonatomic, strong) LQNetworking *networking;
@property (nonatomic, strong) NSMutableArray *messagesQueue;

@end

@implementation LQInAppMessages

@synthesize networking = _networking;
@synthesize messagesQueue = _messagesQueue;
@synthesize currentUser = _currentUser;

- (instancetype)initWithNetworking:(LQNetworking *)networking {
    self = [super init];
    if (self) {
        self.networking = networking;
    }
    return self;
}

- (NSMutableArray *)messagesQueue {
    if (!_messagesQueue) {
        _messagesQueue = [[NSMutableArray alloc] init];
    }
    return _messagesQueue;
}

- (void)requestAndShowInAppMessages {
    [self requestMessages];
    [self presentOldestMessageInQueue];
}

- (void)requestMessages {
    if (!self.currentUser) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid/InAppMessages> A user has not been identified yet.");
        return;
    }

    //NSString *endPoint = [NSString stringWithFormat:@"users/%@/devices/%@/inapp_messages", self.currentUser.identifier, self.device.uid, nil];
    //NSData *dataFromServer = [_networking getDataFromEndpoint:endPoint];

    NSString *str = @"[{\"bg_color\":\"#123456\",\"layout\":\"modal\",\"message\":\"bla bla bla\",\"message_color\":\"#727272\",\"title\":\"lole\",\"title_color\":\"#ffffff\",\"type\":\"actions/inapp_message\",\"dismiss_event_name\":\"_iam_dismiss\",\"event_attributes\":{\"formula_id\":\"562902ce5269636507000000\",\"id\":\"562902ce5269636507000002\"},\"ctas\":[{\"bg_color\":\"#9f9f9f\",\"title\":\"cancel\",\"title_color\":\"#182454\",\"event_name\":\"_iam_cta_click\",\"cta_attributes\":{\"formula_id\":\"562902ce5269636507000000\",\"id\":\"562902ce5269636507000003\"}},{\"bg_color\":\"#1f3f4f\",\"title\":\"ok\",\"title_color\":\"#987463\",\"event_name\":\"_iam_cta_click\",\"cta_attributes\":{\"formula_id\":\"562902ce5269636507000000\",\"id\":\"562902ce5269636507000003\"}}]}]";
    NSData *dataFromServer = [str dataUsingEncoding:NSUTF8StringEncoding];

    if (dataFromServer != nil) {
        NSArray *inAppMessages = [NSData fromJSON:dataFromServer];
        for (NSDictionary *inAppMessageDict in inAppMessages) {
            if ([inAppMessageDict[@"layout"] isEqualToString:@"modal"]) {
                @synchronized(self.messagesQueue) {
                    [self.messagesQueue addObject:[[LQInAppMessageModal alloc] initFromDictionary:inAppMessageDict]];
                }
            }
        }
    }
}

- (void)presentOldestMessageInQueue {
    if (_presentingMessage) {
        LQLog(kLQLogLevelInfoVerbose, @"Already preesnting a In-App Message.");
        return;
    }
    if ([self.messagesQueue count] == 0) {
        LQLog(kLQLogLevelInfoVerbose, @"No In-App Messages in queue to show");
        return;
    }

    // Pop a Message from queue and present it
    id message;
    @synchronized(self.messagesQueue) {
        message = [self.messagesQueue objectAtIndex:0];
        [self.messagesQueue removeObjectAtIndex:0];
    }
    if ([message isKindOfClass:[LQInAppMessageModal class]]) {
        [self presentModalInAppMessage:message];
    }
}

#pragma mark - Present the different layouts of In-App Messages

- (void)presentModalInAppMessage:(LQInAppMessageModal *)message {
    _presentingMessage = YES;
    if([message isInvalid]) {
        LQLog(kLQLogLevelError, @"Could not present In-App Message because it is invalid");
        return;
    }
    if(![[NSBundle mainBundle] pathForResource:@"LQModalMessage" ofType:@"nib"]) {
        LQLog(kLQLogLevelError, @"Could not found LQModalMessage to show modal in-app message.");
        return;
    }

    // Put ModalMessageView inside ModalView and present it
    LQModalMessageView *messageView = [[[NSBundle mainBundle] loadNibNamed:@"LQModalMessage" owner:self options:nil] lastObject];
    messageView.inAppMessage = message;
    [messageView defineLayoutWithInAppMessage];
    __block LQModalView *modalView = [LQModalView modalWithContentView:messageView];

    // Define callbacks for CTAs and Dismiss
    messageView.modalCTABlock = ^(LQCallToAction *cta) {
        //[[Liquid sharedInstance] track:[cta eventName] attributes:[cta eventAttributes]];
        [modalView dismissModal];
        _presentingMessage = NO;
        [self presentOldestMessageInQueue];
    };
    messageView.modalDismissBlock = ^{
        [modalView dismissModal];
        _presentingMessage = NO;
        [self presentOldestMessageInQueue];
    };

    // Present view
    [modalView presentModal];
}

@end
