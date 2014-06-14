//
//  AppDelegate.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 12/06/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "AppDelegate.h"
#import "Liquid.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Liquid sharedInstanceWithToken:@"YOUR-DEVELOPMENT-APP-TOKEN" development:YES];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    //NSLog(@"New Location: %@", [newLocation description]);
    //NSLog(@"Stored Location: %@", [[_locationManager location] description]);
    [[Liquid sharedInstance] setCurrentLocation:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}

@end
