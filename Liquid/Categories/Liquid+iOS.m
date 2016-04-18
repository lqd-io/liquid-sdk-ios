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

- (void)clientApplicationDidBecomeActive;
- (void)clientApplicationDidEnterBackground;
- (void)clientApplicationWillEnterForeground;

@end

@implementation Liquid (iOS)

- (void)bindNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
}

#pragma mark - Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self clientApplicationDidBecomeActive];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self clientApplicationWillEnterForeground];
}

- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification {
    [self beginBackgroundUpdateTask];
    [self clientApplicationDidEnterBackground];
    dispatch_async(self.queue, ^{
        [self endBackgroundUpdateTask];
    });
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
