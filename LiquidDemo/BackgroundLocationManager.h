//
//  LocationManager.h
//  Liquid
//
//  Created by Miguel M. Almeida on 26/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface BackgroundLocationManager : NSObject <CLLocationManagerDelegate>

- (void)startUpdatingLocation;
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;

@end
