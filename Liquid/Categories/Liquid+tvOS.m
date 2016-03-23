//
//  Liquid+tvOS.m
//  Liquid
//
//  Created by Miguel M. Almeida on 16/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "Liquid+tvOS.h"
#import "LQDefaults.h"

#if LQ_TVOS
#import <UIKit/UIApplication.h>

@interface Liquid ()

#if OS_OBJECT_USE_OBJC
@property (atomic, strong) dispatch_queue_t queue;
#else
@property (atomic, assign) dispatch_queue_t queue;
#endif

- (void)clientApplicationDidBecomeActive;
- (void)clientApplicationDidEnterBackground;
- (void)clientApplicationWillEnterForeground;

@end

@implementation Liquid (tvOS)

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
    [self clientApplicationDidEnterBackground];
}

@end
#endif
