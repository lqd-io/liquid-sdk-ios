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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.interfaceOrientationMask;
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
