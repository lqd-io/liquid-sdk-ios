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
#import "LQUIElement.h"
#import "LQWindow.h"
#import "LQUIElementWelcomeViewControler.h"

@interface LQUIElementSetupService()

@property (nonatomic, strong) LQUIElementChanger *elementChanger;
@property (nonatomic, assign) BOOL devModeEnabled;
@property (nonatomic, strong) NSTimer *pollTimer;
@property (nonatomic, strong) NSTimer *longPressTimer;
@property (nonatomic, assign) BOOL touchingDown;

@end

@implementation LQUIElementSetupService

@synthesize elementChanger = _elementChanger;
@synthesize devModeEnabled = _devModeEnabled;
@synthesize pollTimer = _pollTimer;
@synthesize longPressTimer = _longPressTimer;
@synthesize touchingDown = _touchingDown;


- (instancetype)initWithUIElementChanger:(LQUIElementChanger *)elementChanger {
    self = [super init];
    if (self) {
        _elementChanger = elementChanger;
        _devModeEnabled = NO;
        _touchingDown = NO;
    }
    return self;
}

#pragma mark - Enable/disable Development Mode

- (void)enterDevelopmentMode {
    if (self.devModeEnabled) return;
    self.devModeEnabled = YES;
    self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                      target:self
                                                    selector:@selector(timerCode)
                                                    userInfo:nil
                                                     repeats:YES];
    [self presentWelcomeScreen];
}

- (void)exitDevelopmentMode {
    if (!self.devModeEnabled) return;
    self.devModeEnabled = NO;
    [self.pollTimer invalidate];
    self.pollTimer = nil;
}

- (void)timerCode {
    [self.elementChanger requestUiElements];
}

#pragma mark - Change UIButton

- (BOOL)applySetupMenuTargetsTo:(UIView *)view {
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [button addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(buttonTouchesEnded:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
        [button addTarget:self action:@selector(buttonTouchesEnded:withEvent:) forControlEvents:UIControlEventTouchUpInside];
        return true;
    }
    return false;
}

#pragma mark - UI Elements events

- (void)buttonTouchDown:(UIButton *)button { // TODO: UIAlertController is only supported in iOS 8
    if (!self.devModeEnabled) {
        return;
    }
    self.touchingDown = YES;
    self.longPressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                         selector:@selector(longPressCode:)
                                                    userInfo:button
                                                     repeats:YES];
}

- (void)longPressCode:(NSTimer *)timer {
    if (self.touchingDown) {
        UIButton *button = timer.userInfo;
        self.touchingDown = NO;
        [self presentTrackingAlertForView:button];
        LQLog(kLQLogLevelInfo, @"<Liquid/UIElementSetupService>Configuring button with title %@", button.titleLabel.text);
    }
}

- (void)buttonTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.devModeEnabled) {
        return;
    }
    self.touchingDown = NO;
    [self.longPressTimer invalidate];
    self.longPressTimer = nil;
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
        [alert addAction:[UIAlertAction actionWithTitle:@"Stop Tracking" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
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
    [self presentViewControllerInTopMost:alert];
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
        [self registerUIElement:[[LQUIElement alloc] initFromUIView:view evetName:alert.textFields.firstObject.text]];
    }]];
    [self presentViewControllerInTopMost:alert];
}

- (void)showNetworkFailAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network error"
                                                                   message:@"An error occured while configuring your UI element on Liquid. Please try again."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewControllerInTopMost:alert];
}

#pragma mark - Button actions

- (void)registerUIElement:(LQUIElement *)element {
    [self.elementChanger registerUIElement:element withSuccessHandler:^{
        LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Registered a new UI Element: %@", element);
    } failHandler:^{
        [self showNetworkFailAlert];
    }];
}

- (void)unregisterUIElement:(LQUIElement *)element {
    [self.elementChanger unregisterUIElement:element withSuccessHandler:^{
        LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Unregistered UI Element %@", element.identifier);
    } failHandler:^{
        [self showNetworkFailAlert];
    }];
}

#pragma mark - Welcome Screen

- (void)presentWelcomeScreen {
    LQUIElementWelcomeViewControler *welcomeViewController = [[LQUIElementWelcomeViewControler alloc] init];
    [self presentViewControllerInTopMost:welcomeViewController];
}

#pragma mark - Helper methods

- (void)presentViewControllerInTopMost:(UIViewController *)viewController {
    UIWindow *window = [LQWindow fullscreenWindow];
    [window makeKeyAndVisible];
    [window.rootViewController presentViewController:viewController animated:YES completion:nil];
}

@end
