//
//  LQUIElementChanger.h
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQNetworking.h"
#import "LQUser.h"
#import "LQUIElement.h"

@interface LQUIElementChanger : NSObject

- (instancetype)initWithNetworking:(LQNetworking *)networking;
- (void)interceptUIElements;
- (void)requestUiElements;
- (void)registerUIElement:(LQUIElement *)element withSuccessHandler:(void(^)())successHandler failHandler:(void(^)())failHandler;
- (void)unregisterUIElement:(LQUIElement *)element withSuccessHandler:(void(^)())successHandler failHandler:(void(^)())failHandler;
- (BOOL)viewIsChanged:(id)view; // FIX ID to UIView

@end
