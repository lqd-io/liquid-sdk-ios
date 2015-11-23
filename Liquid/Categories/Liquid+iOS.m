//
//  Liquid+iOS.m
//  Liquid
//
//  Created by Miguel M. Almeida on 15/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "Liquid+iOS.h"
#import "LQDefaults.h"
#import "LQInAppMessages.h"

#if LQ_IOS
#import <UIKit/UIApplication.h>

@interface Liquid ()

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundUpdateTask;
@property (nonatomic, strong) LQInAppMessages *inAppMessages;
#if OS_OBJECT_USE_OBJC
@property (atomic, strong) dispatch_queue_t queue;
#else
@property (atomic, assign) dispatch_queue_t queue;
#endif

- (void)clientApplicationForeground;
- (void)clientApplicationBackground;
- (void)clientApplicationTerminate;

@end

@implementation Liquid (iOS)

- (void)bindNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(clientApplicationForeground)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(clientApplicationBackground)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
}

#pragma mark - Notifications

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self clientApplicationForeground];
    [self.inAppMessages requestAndPresentInAppMessages];
}

- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification {
    [self beginBackgroundUpdateTask];
    [self clientApplicationBackground];
    dispatch_async(self.queue, ^{
        [self endBackgroundUpdateTask];
    });
}

- (void)applicationWillTerminate:(NSNotificationCenter *)notification {
    [self clientApplicationTerminate];
}

#pragma mark - Background Tasks

- (void)initializeBackgroundTaskIdentifier {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.backgroundUpdateTask = UIBackgroundTaskInvalid;
    }
}

- (void)beginBackgroundUpdateTask {
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) return;
    NSString *backgroundTaskName = [NSString stringWithFormat:@"%@.BackgroundTask", kLQBundle];
    self.backgroundUpdateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:backgroundTaskName expirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
}

- (void)endBackgroundUpdateTask {
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) return;
    if (self.backgroundUpdateTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundUpdateTask];
        self.backgroundUpdateTask = UIBackgroundTaskInvalid;
    }
}

@end
#endif
