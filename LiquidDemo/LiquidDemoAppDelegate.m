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
    return YES;
}

#pragma mark - Deep Linking

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[Liquid sharedInstance] handleOpenURL:url]) {
        return YES;
    }
    return NO;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Push Notification Received" object:userInfo];
    [[Liquid sharedInstance] handleRemoteNotification:userInfo forApplication:application];
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
