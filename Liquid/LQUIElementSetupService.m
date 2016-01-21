//
//  LQUIElementSetupService.m
//  Liquid
//
//  Created by Miguel M. Almeida on 11/01/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQUIElementSetupService.h"
#import <objc/runtime.h>
#import <Aspects/Aspects.h>
#import <UIKit/UIKit.h>
#import "LQDefaults.h"
#import "UIViewController+LQTopmost.h"
#import "LQUIElement.h"

@interface LQUIElementSetupService() {
    BOOL touchingDown;
}

@property (nonatomic, strong) LQUIElementChanger *elementChanger;

@end

@implementation LQUIElementSetupService

@synthesize elementChanger = _elementChanger;

- (instancetype)initWithUIElementChanger:(LQUIElementChanger *)elementChanger {
    self = [super init];
    if (self) {
        _elementChanger = elementChanger;
    }
    return self;
}

#pragma mark - Change UIButton

- (void)interceptUIElements {
    static dispatch_once_t onceToken; // TODO: probably get rid of this
    dispatch_once(&onceToken, ^{
        [UIControl aspect_hookSelector:@selector(didMoveToWindow) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
            id object = [aspectInfo instance];
            if ([object isKindOfClass:[UIButton class]]) {
                [object addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
                [object addTarget:self action:@selector(buttonTouchesEnded:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
            }
        } error:NULL];
    });
}

- (void)buttonTouchDown:(UIButton *)button { // TODO: UIAlertController is only supported in iOS 8
    touchingDown = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (touchingDown) {
            touchingDown = NO;
            [self presentTrackingAlertForView:button];
            LQLog(kLQLogLevelInfo, @"Configuring button with title %@", button.titleLabel.text);
        }
    });
}

- (void)buttonTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    touchingDown = NO;
}

#pragma mark - Alerts

- (void)presentTrackingAlertForView:(UIView *)view {
    UIAlertController *alert;
    NSString *klass = [[view class] description];
    if ([self.elementChanger viewIsTrackingEvent:view]) {
        LQUIElement *element = [self.elementChanger uiElementFor:view];
        alert = [UIAlertController alertControllerWithTitle:@"Liquid"
                                                    message:[NSString stringWithFormat:@"This %@ is being tracked, with event named '%@'", klass, element.eventName]
                                             preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Stop Tracking"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * action) {
                                                    [self unregisterUIElement:element];
                                                }]];
    } else {
        alert = [UIAlertController alertControllerWithTitle:@"Liquid"
                                                    message:[NSString stringWithFormat:@"This %@ isn't being tracked.", klass]
                                             preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Start Tracking" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self presentTrackingEventNameForView:view];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [[UIViewController topViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)presentTrackingEventNameForView:(UIView *)view {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Liquid"
                                                                   message:@"Write down the name of the event"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"e.g: Button Pressed", @"Event Name");
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Start Tracking" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        LQUIElement *element = [[LQUIElement alloc] initFromUIView:view evetName:alert.textFields.firstObject.text];
        [self registerUIElement:element];
    }]];
    [[UIViewController topViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)showNetworkFailAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network error"
                                                                   message:@"An error occured while configuring your UI element on Liquid. Please try again."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
    [[UIViewController topViewController] presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Button actions

- (void)registerUIElement:(LQUIElement *)element {
    [self.elementChanger registerUIElement:element withSuccessHandler:^{
        LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Registered a new UIElement");
    } failHandler:^{
        [self showNetworkFailAlert];
    }];
}

- (void)unregisterUIElement:(LQUIElement *)element {
    [self.elementChanger unregisterUIElement:element withSuccessHandler:^{
        LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Unregistered UIElement %@", element.identifier);
    } failHandler:^{
        [self showNetworkFailAlert];
    }];
}

@end
