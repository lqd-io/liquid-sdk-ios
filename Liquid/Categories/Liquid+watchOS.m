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

@implementation Liquid (watchOS)

- (void)bindNotifications {
    /*
     TODO:
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                               name:...
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:...
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:...
                             object:nil];
    */
}

@end
#endif
