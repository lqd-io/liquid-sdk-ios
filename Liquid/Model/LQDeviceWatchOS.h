//
//  LQDeviceWatchOS.h
//  Liquid
//
//  Created by Miguel M. Almeida on 18/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDevice.h"

@interface LQDeviceWatchOS : LQDevice

- (BOOL)reachesInternet;
+ (NSString *)screenSize;
+ (NSString *)systemVersion;

@end
