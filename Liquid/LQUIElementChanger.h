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
#import "LQEventTracker.h"

@interface LQUIElementChanger : NSObject

@property (nonatomic, assign) BOOL eventTrackingDisabled;

- (instancetype)initWithNetworking:(LQNetworking *)networking appToken:(NSString *)appToken eventTracker:(LQEventTracker *)eventTracker;
- (void)interceptUIElementsWithBlock:(void(^)(UIView *view))interceptBlock;
- (BOOL)applyChangesTo:(UIView *)view;
- (void)requestUiElements;
- (void)addUIElement:(LQUIElement *)element;
- (void)removeUIElement:(LQUIElement *)element;
- (LQUIElement *)uiElementFor:(UIView *)view;
- (BOOL)viewIsTrackingEvent:(UIView *)view;
- (void)archiveUIElements;
- (void)unarchiveUIElements;

@end
