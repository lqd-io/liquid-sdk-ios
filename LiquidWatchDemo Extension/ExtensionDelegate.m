//
//  ExtensionDelegate.m
//  LiquidWatchDemo Extension
//
//  Created by Miguel M. Almeida on 14/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "ExtensionDelegate.h"
#import "Liquid.h"

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    [Liquid sharedInstanceWithToken:@"YOUR-DEVELOPMENT-APP-TOKEN" development:YES];
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

@end
