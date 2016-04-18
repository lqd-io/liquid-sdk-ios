//
//  LQInAppMessages.h
//  Liquid
//
//  Created by Miguel M. Almeida on 27/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQUser.h"
#import "LQNetworking.h"
#import "LQEventTracker.h"

@interface LQInAppMessages : NSObject

@property (nonatomic, strong) LQUser *currentUser;

- (instancetype)initWithNetworking:(LQNetworking *)networking dispatchQueue:(dispatch_queue_t)queue eventTracker:(LQEventTracker *)eventTracker;
- (void)requestInAppMessages;
- (void)requestMessagesWithCompletionHandler:(void(^)(NSData *data))completionBlock;
- (void)presentInAppMessage:(id)message;
- (void)addToQueueInAppMessageFromJson:(NSDictionary *)inAppMessageDict;
- (void)presentNextMessageInQueue;

@end
