//
//  LQWindow.m
//  Liquid
//
//  Created by Miguel M. Almeida on 03/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQWindow.h"
#import "LQRootViewController.h"

@implementation LQWindow

+ (UIWindow *)mainWindow {
    return [[UIApplication sharedApplication] keyWindow];
}

+ (UIWindow *)fullscreenWindow {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.backgroundColor = [UIColor clearColor];
    window.windowLevel = UIWindowLevelAlert;
    window.hidden = NO;
    window.rootViewController = [[self class] autoRotateRootViewController];
    return window;
}

+ (UIWindow *)bottomWindow {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, (bounds.size.height - 50), bounds.size.width, bounds.size.height)];
    window.backgroundColor = [UIColor redColor];
    window.windowLevel = UIWindowLevelAlert;
    window.hidden = NO;
    window.rootViewController = [[self class] autoRotateRootViewController];
    return window;
}

+ (UIWindow *)topWindow {
    UIWindow *window = [[self class] bottomWindow];
    window.frame = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
    return window;
}

+ (LQRootViewController *)autoRotateRootViewController {
    LQRootViewController *viewController = [[LQRootViewController alloc] init];

    // Set orientatio to be the same os the current root view controller
    UIViewController *currentRootViewController = [[[UIApplication sharedApplication] windows] firstObject].rootViewController;
    if (currentRootViewController && ![currentRootViewController isKindOfClass:[LQRootViewController class]]) {
        viewController.interfaceOrientationMask = currentRootViewController.supportedInterfaceOrientations;
    }
    return viewController;
}

@end
