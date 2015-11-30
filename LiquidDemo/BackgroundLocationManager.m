//
//  LocationManager.m
//  Liquid
//
//  Created by Miguel M. Almeida on 26/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "BackgroundLocationManager.h"
#import "Liquid.h"

@interface BackgroundLocationManager ()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSDate *lastTimestamp;

@end

@implementation BackgroundLocationManager

- (instancetype)init {
    self = [super self];
    if (self) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
    }
    return self;
}

- (void)startUpdatingLocation {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusDenied) {
        NSLog(@"ERROR: Location Services are disabled. Enable them in System Settings.");
        return;
    }
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *mostRecentLocation = locations.lastObject;
    NSLog(@"New location is: %@ %@", @(mostRecentLocation.coordinate.latitude), @(mostRecentLocation.coordinate.longitude));

    NSDate *now = [NSDate date];
    NSTimeInterval interval = self.lastTimestamp ? [now timeIntervalSinceDate:self.lastTimestamp] : 0;

    if (!self.lastTimestamp || interval >= 5 * 10) {
        self.lastTimestamp = now;
        NSLog(@"Updating Liquid location");
        [[Liquid sharedInstance] setCurrentLocation:mostRecentLocation];
    }
}

@end
