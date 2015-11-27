//
//  Liquid+watchOS.m
//  Liquid
//
//  Created by Miguel M. Almeida on 15/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "Liquid+watchOS.h"
#import "LQDefaults.h"

#if LQ_WATCHOS

@interface Liquid ()

- (void)clientApplicationDidBecomeActive;
- (void)clientApplicationDidEnterBackground;
- (void)clientApplicationWillEnterForeground;

@end

@implementation Liquid (watchOS)

- (void)bindNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive)
                               name:NSExtensionHostDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground)
                               name:NSExtensionHostWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground)
                               name:NSExtensionHostDidEnterBackgroundNotification
                             object:nil];
}

#pragma mark - Notifications

- (void)applicationDidBecomeActive {
    [self clientApplicationDidBecomeActive];
}

- (void)applicationDidEnterBackground {
    [self clientApplicationDidEnterBackground];
}

- (void)applicationWillEnterForeground {
    [self clientApplicationWillEnterForeground];
}

@end
#endif
