//
//  LQRootViewController.m
//  Liquid
//
//  Created by Miguel M. Almeida on 02/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQRootViewController.h"

@interface LQRootViewController ()

@end

@implementation LQRootViewController

@synthesize interfaceOrientationMask = _interfaceOrientationMask;

- (UIInterfaceOrientationMask)interfaceOrientationMask {
    if (!_interfaceOrientationMask) {
        _interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
    }
    return _interfaceOrientationMask;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations {
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
#endif
    return self.interfaceOrientationMask;
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
