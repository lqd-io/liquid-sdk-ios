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

@property (atomic, strong) NSString *developerToken;

- (instancetype)initWithNetworking:(LQNetworking *)networking;
- (void)interceptUIElementsWithBlock:(void(^)(id view))interceptBlock; // TODO: FIX ID to UIView
- (BOOL)applyChangesTo:(id)view; // TODO: FIX ID to UIView
- (void)requestUiElements;
- (void)registerUIElement:(LQUIElement *)element withSuccessHandler:(void(^)())successHandler failHandler:(void(^)())failHandler;
- (void)unregisterUIElement:(LQUIElement *)element withSuccessHandler:(void(^)())successHandler failHandler:(void(^)())failHandler;
- (LQUIElement *)uiElementFor:(id)view; // TODO: FIX ID to UIView
- (BOOL)viewIsTrackingEvent:(id)view; // TODO: FIX ID to UIView

@end
