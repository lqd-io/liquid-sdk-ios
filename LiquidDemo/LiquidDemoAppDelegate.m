//
//  AppDelegate.m
//  Liquid
//
//  Created by Liquid Liquid Data Intelligence, S.A. (lqd.io) on 12/06/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import "LiquidDemoAppDelegate.h"
#import "Liquid.h"
#import "BackgroundLocationManager.h"

@interface LiquidDemoAppDelegate ()

@property (strong, nonatomic) BackgroundLocationManager *locationManager;

@end

@implementation LiquidDemoAppDelegate

@synthesize locationManager = _locationManager;

- (BackgroundLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[BackgroundLocationManager alloc] init];
    }
    return _locationManager;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Liquid sharedInstanceWithToken:@"YOUR-DEVELOPMENT-APP-TOKEN" development:YES];

#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Push Notifications only work on real devices, not on iPhone Simulator.");
#else
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert |
                                                                               UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound)];
    }
#endif
    [self.locationManager startUpdatingLocation];

    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    if (UIApplicationStateBackground == application.applicationState) {
        NSLog(@"Launched in background");
    }

    return YES;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [[Liquid sharedInstance] setCurrentLocation:newLocation];
}

#pragma mark - Push Notifications < iOS 8

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[Liquid sharedInstance] setApplePushNotificationToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Notify LiquidDemoViewController about a new Push Notification:
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Push Notification Received" object:userInfo];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"%@", [NSString stringWithFormat: @"Error obtaining push notification token: %@", err]);
}

#pragma mark - Background fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"Updated data in Background");
    completionHandler(UIBackgroundFetchResultNewData);
}

@end
