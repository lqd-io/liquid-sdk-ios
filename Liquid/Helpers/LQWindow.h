//
//  LQWindow.h
//  Liquid
//
//  Created by Miguel M. Almeida on 03/11/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIWindow.h>

@interface LQWindow : UIWindow

+ (UIWindow *)mainWindow;
+ (UIWindow *)fullscreenWindow;
+ (UIWindow *)bottomWindow;
+ (UIWindow *)topWindow;
    
@end
