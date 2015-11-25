//
//  LQDeviceIOS.h
//  Liquid
//
//  Created by Miguel M. Almeida on 18/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDevicePrivates.h"
#import <UIKit/UIKit.h>

@interface LQDeviceIOS : LQDevice

@property (nonatomic, strong, readonly) NSString *internetConnectivity;
@property (nonatomic, strong, readonly) NSString *carrier;
@property (nonatomic, strong, readonly) NSString *deviceName;

- (BOOL)reachesInternet;
+ (NSString *)screenSize;
+ (NSString *)carrier;
+ (NSString *)platform;
+ (NSString *)systemVersion;

@end
