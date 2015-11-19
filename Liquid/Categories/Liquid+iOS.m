//
//  Liquid+iOS.m
//  Liquid
//
//  Created by Miguel M. Almeida on 15/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "Liquid+iOS.h"
#import <UIKit/UIApplication.h>
#import "LQDefaults.h"

@interface Liquid ()

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundUpdateTask;

@end

@implementation Liquid (iOS)

- (void)bindNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
}

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
