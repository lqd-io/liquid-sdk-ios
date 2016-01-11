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
                                    @"identifier": @"/UIWindow/UIView/UITextView/UITextField/UIButton/x"
                                }];
        LQUIElement *button2 = [[LQUIElement alloc] initFromDictionary:@{
                                    @"identifier": @"/UIWindow/UIView/UIButton/Track \"Play Music\""
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

#pragma mark - Tracking UIButton

- (void)changeUIButton:(UIButton *)button {
    LQUIElement *uiElement = [self uiElementFor:button];
    if (!uiElement || ![uiElement active]) {
        return; // return if button is not on the list of elements to be changed or is not active
    }
    [button addTarget:self action:@selector(touchUpButton:) forControlEvents:UIControlEventTouchUpInside];
    NSLog(@"Binding UIButton with identifier \"%@\" and label \"%@\"", [uiElement identifier], button.titleLabel.text);
}

- (void)touchUpButton:(UIButton *)button {
    NSLog(@"Clicked button %@ with identifier %@", button.titleLabel.text, [button liquidIdentifier]);
}

#pragma mark - Helpers

- (LQUIElement *)uiElementFor:(UIView *)view { // optimize this to NSDictionary
    for (LQUIElement *uiElement in self.changedElements) {
        if ([uiElement matchesUIView:view]) {
            return uiElement;
        }
    }
    return nil; // means not binded
}

@end
