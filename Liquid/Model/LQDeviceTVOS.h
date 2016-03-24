//
//  LQDeviceTVOS.h
//  Liquid
//
//  Created by Miguel M. Almeida on 16/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQDevice.h"

@interface LQDeviceTVOS : LQDevice

+ (NSString *)screenSize;
+ (NSString *)platform;
+ (NSString *)systemVersion;

- (BOOL)reachesInternet;

@end
