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

@property (nonatomic, strong) NSSet<LQUIElement *> *changedElements; // TODO: change to nsdictionary
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

- (void)interceptUIElements {
    static dispatch_once_t onceToken; // TODO: probably get rid of this
    dispatch_once(&onceToken, ^{
        [UIControl aspect_hookSelector:@selector(didMoveToWindow) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
            id object = [aspectInfo instance];
            if ([object isChangeable] && [object isKindOfClass:[UIButton class]]) {
                [self changeUIButtonIfActive:(UIButton *)object];
            }
        } error:NULL];
    });
}

#pragma mark - Change UIButton

- (void)changeUIButtonIfActive:(UIButton *)button { // TODO?: receive an UIElement instead of a UIButton?
    LQUIElement *uiElement = [self uiElementFor:button];
    if (!uiElement || ![uiElement active]) {
        return; // return if button is not on the list of elements to be changed or is not active
    }
    if ([uiElement eventName]) {
        [button addTarget:self action:@selector(touchUpButton:) forControlEvents:UIControlEventTouchUpInside];
        LQLog(kLQLogLevelInfo, @"Tracking events in UIButton with identifier \"%@\" and label \"%@\"", [uiElement identifier], button.titleLabel.text);
    }
}

- (void)touchUpButton:(UIButton *)button {
    LQUIElement *uiElement = [self uiElementFor:button];
    if (![uiElement eventName]) { // need to check again because button could not be tracked at the moment of touch event
        return;
    }
    LQLog(kLQLogLevelInfo, @"Touched button %@ with identifier %@ to track event named %@ and attributes %@",
          button.titleLabel.text, button.liquidIdentifier, uiElement.eventName, uiElement.eventAttributes);
}

#pragma mark - Helpers

- (LQUIElement *)uiElementFor:(UIView *)view { // optimize this to NSDictionary
    for (LQUIElement *uiElement in self.changedElements) {
        if ([uiElement matchesUIView:view]) {
            return uiElement;
        }
    }
    return nil; // means "not to be changed"
}

- (BOOL)viewIsChanged:(UIView *)view {
    return !![self uiElementFor:view];
}

#pragma mark - Request UI Elements from server

- (void)requestUiElements {
    [_networking getDataFromEndpoint:@"ui_elements?platform=ios" completionHandler:^(LQQueueStatus queueStatus, NSData *responseData) { // TODO: remove ?platform
        //responseData = [@"[{\"identifier\":\"/UIWindow/UIView/UITextView/UITextField/UIButton/x\",\"event_name\":\"Track X\",\"event_attributes\":{\"x\":1,\"y\":2},\"active\":true},{\"identifier\":\"/UIWindow/UIView/UIButton/Track \\\"Play Music\\\"\",\"event_name\":\"Track Y\",\"event_attributes\":{\"x\":1,\"y\":2},\"active\":true}]" dataUsingEncoding:NSUTF8StringEncoding];
        if (queueStatus == LQQueueStatusOk) {
            NSMutableSet *changedElements = [[NSMutableSet alloc] init];
            for (NSDictionary *uiElementDict in [NSData fromJSON:responseData]) {
                [changedElements addObject:[[LQUIElement alloc] initFromDictionary:uiElementDict]];
            }
            _changedElements = changedElements;
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
                NSMutableSet *newElements = [NSMutableSet setWithSet:self.changedElements];
                [newElements addObject:element];
                self.changedElements = newElements;
                [self logChangedElements];
                dispatch_async(dispatch_get_main_queue(), successHandler);
            } else {
                dispatch_async(dispatch_get_main_queue(), failHandler);
            }
        }];
}

- (void)unregisterUIElement:(LQUIElement *)element withSuccessHandler:(void(^)())successHandler failHandler:(void(^)())failHandler {
    [_networking sendData:nil toEndpoint:@"ui_elements/remove" usingMethod:@"POST"
        completionHandler:^(LQQueueStatus queueStatus, NSData *responseData) {
            if (queueStatus == LQQueueStatusOk) {
                NSMutableSet *newElements = [NSMutableSet setWithSet:self.changedElements];
                [newElements addObject:element];
                self.changedElements = newElements;
                dispatch_async(dispatch_get_main_queue(), successHandler);
            } else {
                dispatch_async(dispatch_get_main_queue(), failHandler);
            }
        }];
}

- (void)logChangedElements {
    if (kLQLogLevel < kLQLogLevelInfoVerbose) return;
    NSSet *elements = [NSSet setWithSet:self.changedElements];
    LQLog(kLQLogLevelInfoVerbose, @"<Liquid/UIElementChanger> Chaged UI Elements:");
    for (LQUIElement *element in elements) {
        LQLog(kLQLogLevelInfoVerbose, @" - %@", [element description]);
    }
}

@end
