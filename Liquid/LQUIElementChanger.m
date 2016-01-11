//
//  LQUIElementChanger.m
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQDefaults.h"
#import "LQUIElementChanger.h"
#import "LQUIElement.h"
#import <objc/runtime.h>
#import <Aspects/Aspects.h>
#import <UIKit/UIKit.h>
#import "UIView+LQChangeable.h"
#import "NSData+LQData.h"

@interface LQUIElementChanger ()

@property (nonatomic, strong) NSSet<LQUIElement *> *changedElements; // TODO: change to nsdictionary
@property (nonatomic, strong) LQNetworking *networking;
#if OS_OBJECT_USE_OBJC
@property (atomic, strong) dispatch_queue_t queue;
#else
@property (atomic, assign) dispatch_queue_t queue;
#endif

@end

@implementation LQUIElementChanger

@synthesize changedElements = _changedElements;
@synthesize networking = _networking;
@synthesize queue = _queue;

#pragma mark - Initializers

- (instancetype)initWithNetworking:(LQNetworking *)networking dispatchQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        self.networking = networking;
        self.queue = queue;
    }
    return self;
}

- (void)interceptNewElements {
    static dispatch_once_t onceToken; // TODO: probably get rid of this
    dispatch_once(&onceToken, ^{
        [UIControl aspect_hookSelector:@selector(didMoveToWindow) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
            id object = [aspectInfo instance];
            if ([object isChangeable] && [object isKindOfClass:[UIButton class]]) {
                [self changeUIButton:(UIButton *)object];
            }
        } error:NULL];
    });
}

#pragma mark - Change UIButton

- (void)changeUIButton:(UIButton *)button { // TODO?: receive an UIElement instead of a UIButton?
    LQUIElement *uiElement = [self uiElementFor:button];
    if (!uiElement || ![uiElement active]) {
        return; // return if button is not on the list of elements to be changed or is not active
    }
    if ([uiElement eventName]) {
        [button addTarget:self action:@selector(touchUpButton:) forControlEvents:UIControlEventTouchUpInside];
        NSLog(@"Tracking events in UIButton with identifier \"%@\" and label \"%@\"", [uiElement identifier], button.titleLabel.text);
    }
}

- (void)touchUpButton:(UIButton *)button {
    LQUIElement *uiElement = [self uiElementFor:button];
    if (![uiElement eventName]) { // need to check again because button could not be tracked at the moment of touch event
        return;
    }
    NSLog(@"Touched button %@ with identifier %@ to track event named %@ and attributes %@",
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

#pragma mark - Request UI Elements from server

- (void)requestUiElements {
    dispatch_async(self.queue, ^{
        [self requestUIElementsWithCompletionHandler:^(NSData *dataFromServer) {
            if (!dataFromServer) return;
            NSMutableSet *changedElements = [[NSMutableSet alloc] init];
            for (NSDictionary *uiElementDict in [NSData fromJSON:dataFromServer]) {
                [changedElements addObject:[[LQUIElement alloc] initFromDictionary:uiElementDict]];
            }
            _changedElements = changedElements;
        }];
    });
}

- (void)requestUIElementsWithCompletionHandler:(void(^)(NSData *data))completionBlock {
    NSData *dataFromServer = [_networking getSynchronousDataFromEndpoint:@"ui_elements"];
    if (dataFromServer != nil) {
        completionBlock(dataFromServer);
    }
}

@end
