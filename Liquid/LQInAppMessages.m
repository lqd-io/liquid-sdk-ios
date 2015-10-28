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

@interface LQInAppMessages ()

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

    NSString *endPoint = [NSString stringWithFormat:@"users/%@/inapp_messages", self.currentUser.identifier, nil];
    NSData *dataFromServer = [_networking getDataFromEndpoint:endPoint];
    if (dataFromServer != nil) {
        NSArray *inAppMessages = [NSData fromJSON:dataFromServer];
        for (NSDictionary *inAppMessageDict in inAppMessages) {
            if ([inAppMessageDict[@"layout"] isEqualToString:@"modal"]) {
                [self.messagesQueue addObject:[[LQInAppMessageModal alloc] initFromDictionary:inAppMessageDict]];
            }
        }
    }
}

- (void)presentOldestMessageInQueue {
    id message = [self.messagesQueue objectAtIndex:0];
    if (!message) {
        LQLog(kLQLogLevelInfoVerbose, @"No In-App Messages in queue to show");
        return;
    }
    if ([message isKindOfClass:[LQInAppMessageModal class]]) {
        [self presentModalInAppMessage:message];
        [self.messagesQueue removeObjectAtIndex:0];
    }
}

#pragma mark - Present the different layouts of In-App Messages

- (void)presentModalInAppMessage:(LQInAppMessageModal *)message {
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
    };
    messageView.modalDismissBlock = ^{
        [modalView dismissModal];
    };

    // Present view
    [modalView presentModal];
}

@end
