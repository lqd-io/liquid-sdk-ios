//
//  AppDelegate.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 12/06/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LiquidDemoAppDelegate.h"
#import "Liquid.h"

@implementation LiquidDemoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //[Liquid sharedInstanceWithToken:@"gmqrZGBtG3xyi64_tEdbua98FVrmBcQw" development:YES]; // staging key
    [Liquid sharedInstanceWithToken:@"_uNm3RuTnoGcBj5zugzUcNYdJF5QzIkL" development:YES]; // localhost key
    // if the application goes into background for more than 30 seconds, a new session is considered:. default is 30
    [[Liquid sharedInstance] setSessionTimeout:5];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [[Liquid sharedInstance] setCurrentLocation:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}

@end
