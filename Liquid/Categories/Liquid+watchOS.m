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

- (void)clientApplicationForeground;
- (void)clientApplicationBackground;

@end

@implementation Liquid (watchOS)

- (void)bindNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(clientApplicationForeground)
                               name:NSExtensionHostWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(clientApplicationBackground)
                               name:NSExtensionHostDidEnterBackgroundNotification
                             object:nil];
}

#pragma mark - Notifications

- (void)applicationWillEnterForeground {
    [self clientApplicationForeground];
}

- (void)applicationDidEnterBackground {
    [self clientApplicationBackground];
}

@end
#endif
