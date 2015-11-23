//
//  LQRootViewController.m
//  Liquid
//
//  Created by Miguel M. Almeida on 02/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQRootViewController.h"
#import "LQDefaults.h"

#if LQ_INAPP_MESSAGES_SUPPORT
@interface LQRootViewController ()

@end

@implementation LQRootViewController

@synthesize interfaceOrientationMask = _interfaceOrientationMask;

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)interfaceOrientationMask {
#else
- (UIInterfaceOrientationMask)interfaceOrientationMask {
#endif
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
#endif
