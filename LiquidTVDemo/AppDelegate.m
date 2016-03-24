//
//  AppDelegate.m
//  LiquidTVDemo
//
//  Created by Miguel M. Almeida on 24/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "AppDelegate.h"
#import "Liquid.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Liquid sharedInstanceWithToken:@"YOUR-DEVELOPMENT-APP-TOKEN" development:YES];
    return YES;
}

@end
