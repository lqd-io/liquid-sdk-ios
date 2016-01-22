//
//  LQUIElementChanger.m
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDefaults.h"
#import "LQUIElementChanger.h"
#import <objc/runtime.h>
#import <Aspects/Aspects.h>
#import <UIKit/UIKit.h>
#import "UIView+LQChangeable.h"
#import "NSData+LQData.h"

@interface LQUIElementChanger ()

@property (nonatomic, strong) NSDictionary<NSString *, LQUIElement *> *changedElements;
@property (nonatomic, strong) LQNetworking *networking;

@end

@implementation LQUIElementChanger

@synthesize changedElements = _changedElements;
@synthesize networking = _networking;

#pragma mark - Initializers

- (instancetype)initWithNetworking:(LQNetworking *)networking {
    self = [super init];
    if (self) {
        self.networking = networking;
    }
    return self;
}

- (void)interceptUIElementsWithBlock:(void(^)(UIView *view))interceptBlock {
    static dispatch_once_t onceToken; // TODO: probably get rid of this
    dispatch_once(&onceToken, ^{
        [UIControl aspect_hookSelector:@selector(didMoveToWindow) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
            id view = [aspectInfo instance];
            if ([view isKindOfClass:[UIView class]]) {
                interceptBlock(view);
            }
        } error:NULL];
    });
}

#pragma mark - Change Elements

- (BOOL)applyChangesTo:(UIView *)view {
    LQUIElement *uiElement = [self uiElementFor:view];
    if (!uiElement || ![view isChangeable] || ![uiElement active]) {
        return false;
    }
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [button addTarget:self action:@selector(touchUpButton:) forControlEvents:UIControlEventTouchUpInside];
        LQLog(kLQLogLevelInfo, @"<Liquid/UIElementChanger>Tracking events in UIButton with identifier \"%@\" and label \"%@\"", [uiElement identifier], button.titleLabel.text);
        return true;
    }
    return false;
}

#pragma mark - UI Elements events

- (void)touchUpButton:(UIButton *)button {
    LQUIElement *uiElement = [self uiElementFor:button];
    if (![uiElement eventName]) { // need to check again because button could not be tracked at the moment of touch event
        return;
    }
    LQLog(kLQLogLevelInfo, @"<Liquid/UIElementChanger>Touched button %@ with identifier %@ to track event named %@ and attributes %@",
          button.titleLabel.text, button.liquidIdentifier, uiElement.eventName, uiElement.eventAttributes);
}

#pragma mark - Helpers

- (BOOL)viewIsTrackingEvent:(UIView *)view {
    LQUIElement *element = [self uiElementFor:view];
    return element && element.eventName;
}

- (LQUIElement *)uiElementFor:(UIView *)view {
    for (NSString *identifier in self.changedElements) { // TODO: get rid of this for
        LQUIElement *uiElement = self.changedElements[identifier];
        if ([uiElement matchesUIView:view] && uiElement.active) {
            return uiElement;
        }
    }
    return nil;
}

#pragma mark - Request UI Elements from server

- (void)requestUiElements {
    [_networking getDataFromEndpoint:@"ui_elements?platform=ios" completionHandler:^(LQQueueStatus queueStatus, NSData *responseData) { // TODO: remove ?platform
        //responseData = [@"[{\"identifier\":\"/UIWindow/UIView/UITextView/UITextField/UIButton/x\",\"event_name\":\"Track X\",\"event_attributes\":{\"x\":1,\"y\":2},\"active\":true},{\"identifier\":\"/UIWindow/UIView/UIButton/Track \\\"Play Music\\\"\",\"event_name\":\"Track Y\",\"event_attributes\":{\"x\":1,\"y\":2},\"active\":true}]" dataUsingEncoding:NSUTF8StringEncoding];
        if (queueStatus == LQQueueStatusOk) {
            NSMutableDictionary *newElements = [[NSMutableDictionary alloc] init];
            for (NSDictionary *uiElementDict in [NSData fromJSON:responseData]) {
                LQUIElement *uiElement = [[LQUIElement alloc] initFromDictionary:uiElementDict];
                [newElements setObject:uiElement forKey:uiElement.identifier];
            }
            _changedElements = newElements;
            [self logChangedElements];
        } else {
            LQLog(kLQLogLevelHttpError, @"<Liquid/UIElementChanger>: Error requesting UI Elements: %@", responseData);
        }
    }];
}

#pragma mark - Register and unregister UI Elements on server

- (void)registerUIElement:(LQUIElement *)element withSuccessHandler:(void(^)())successHandler failHandler:(void(^)())failHandler {
    [_networking sendData:[NSData toJSON:[element jsonDictionary]] toEndpoint:@"ui_elements/add" usingMethod:@"POST"
        completionHandler:^(LQQueueStatus queueStatus, NSData *responseData) {
            if (queueStatus == LQQueueStatusOk) {
                NSMutableDictionary *newElements = [NSMutableDictionary dictionaryWithDictionary:self.changedElements];
                [newElements setObject:element forKey:element.identifier];
                self.changedElements = newElements;
                [self logChangedElements];
                dispatch_async(dispatch_get_main_queue(), successHandler);
            } else {
                dispatch_async(dispatch_get_main_queue(), failHandler);
            }
        }];
}

- (void)unregisterUIElement:(LQUIElement *)element withSuccessHandler:(void(^)())successHandler failHandler:(void(^)())failHandler {
    [_networking sendData:[NSData toJSON:[element jsonDictionary]] toEndpoint:@"ui_elements/remove" usingMethod:@"POST"
        completionHandler:^(LQQueueStatus queueStatus, NSData *responseData) {
            if (queueStatus == LQQueueStatusOk) {
                NSMutableDictionary *newElements = [NSMutableDictionary dictionaryWithDictionary:self.changedElements];
                [newElements removeObjectForKey:element.identifier];
                self.changedElements = newElements;
                [self logChangedElements];
                dispatch_async(dispatch_get_main_queue(), successHandler);
            } else {
                dispatch_async(dispatch_get_main_queue(), failHandler);
            }
        }];
}

- (void)logChangedElements {
    if (kLQLogLevel < kLQLogLevelInfoVerbose) return;
    LQLog(kLQLogLevelInfoVerbose, @"<Liquid/UIElementChanger> Chaged UI Elements:");
    for (NSString *identifier in self.changedElements) {
        LQLog(kLQLogLevelInfoVerbose, @" - %@", identifier);
    }
}

@end
