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

@interface LQUIElementChanger ()

@property (nonatomic, strong) NSSet<LQUIElement *> *changedElements; // TODO: change to nsdictionary

@end

@implementation LQUIElementChanger

@synthesize changedElements = _changedElements;

- (NSSet<LQUIElement *> *)changedElements { // TMP
    if (!_changedElements) {
        LQUIElement *button1 = [[LQUIElement alloc] initFromDictionary:@{
                                    @"identifier": @"/UIWindow/UIView/UITextView/UITextField/UIButton/x",
                                    @"event_name": @"Track X",
                                    @"event_attributes": @{ @"x": @1, @"y": @2 },
                                    @"active": @YES
                                }];
        LQUIElement *button2 = [[LQUIElement alloc] initFromDictionary:@{
                                    @"identifier": @"/UIWindow/UIView/UIButton/Track \"Play Music\"",
                                    @"event_name": @"Track Y",
                                    @"event_attributes": @{ @"x": @1, @"y": @2 },
                                    @"active": @YES
                                }];
        _changedElements = [NSSet setWithObjects:button1, button2, nil];
    }
    return _changedElements;
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

@end
