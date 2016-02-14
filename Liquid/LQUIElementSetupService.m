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
#import "NSData+LQData.h"
#import "SRWebSocket.h"
#import "WebSocketRailsDispatcher.h"
#import "WebSocketRailsChannel.h"

#define kLQWebSocketServerrUrl @"ws://lqd.io/websocket"

@interface LQUIElementSetupService()

@property (nonatomic, strong) LQUIElementChanger *elementChanger;
@property (nonatomic, assign) BOOL devModeEnabled;
@property (nonatomic, strong) NSTimer *longPressTimer;
@property (nonatomic, assign) UIButton *touchingDownButton;
@property (nonatomic, strong) WebSocketRailsDispatcher *webSocketDispatcher;
@property (nonatomic, strong) WebSocketRailsChannel *webSocketChannel;

@end

@implementation LQUIElementSetupService

@synthesize elementChanger = _elementChanger;
@synthesize devModeEnabled = _devModeEnabled;
@synthesize longPressTimer = _longPressTimer;
@synthesize touchingDownButton = _touchingDownButton;


- (instancetype)initWithUIElementChanger:(LQUIElementChanger *)elementChanger {
    self = [super init];
    if (self) {
        _elementChanger = elementChanger;
        _devModeEnabled = NO;
    }
    return self;
}

#pragma mark - Enable/disable Development Mode

- (void)enterDevelopmentModeWithToken:(NSString *)developmentToken {
    if (self.devModeEnabled) {
        return;
    }
    [self connectWebSocketToChannel:developmentToken];
    [self.webSocketDispatcher bind:@"connection_opened" callback:^(id data) {
        self.devModeEnabled = YES;
        [self presentWelcomeScreen];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.webSocketChannel trigger:@"start_development" message:@""];
        });
    }];
    [self.webSocketDispatcher connect];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.devModeEnabled) {
            [self showNetworkFailAlert];
        }
    });
}

- (void)exitDevelopmentMode {
    [self.webSocketDispatcher disconnect];
    self.webSocketChannel = nil;
    if (!self.devModeEnabled) return;
    self.devModeEnabled = NO;
}

#pragma mark - Web Socket

- (void)connectWebSocketToChannel:(NSString *)channelName {
    if (self.webSocketDispatcher) {
        [self.webSocketDispatcher disconnect];
    }
    self.webSocketDispatcher = [[WebSocketRailsDispatcher alloc] initWithUrl:[NSURL URLWithString:kLQWebSocketServerrUrl]];
    self.webSocketChannel = [self.webSocketDispatcher subscribe:channelName];
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
    self.touchingDownButton = button;
    self.longPressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                         selector:@selector(longPressCode:)
                                                    userInfo:button
                                                     repeats:YES];
}

- (void)longPressCode:(NSTimer *)timer {
    UIButton *button = self.touchingDownButton;
    if (button && button == timer.userInfo) {
        self.touchingDownButton = nil;
        [self presentTrackingAlertForView:button];
        LQLog(kLQLogLevelInfo, @"<Liquid/UIElementSetupService>Configuring button with title %@", button.titleLabel.text);
    }
}

- (void)buttonTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.devModeEnabled) {
        return;
    }
    self.touchingDownButton = nil;
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
        [alert addAction:[UIAlertAction actionWithTitle:@"Stop Tracking"
                                                  style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [self unregisterUIElement:element];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Change Element" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self presentChangeTrackingEventNameForView:view currentElement:element];
        }]];
    } else {
        alert = [UIAlertController alertControllerWithTitle:@"Liquid"
                                                    message:[NSString stringWithFormat:@"This %@ isn't being tracked.", klass]
                                             preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Start Tracking" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self presentSetTrackingEventNameForView:view];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewControllerInTopMost:alert];
}

- (void)presentSetTrackingEventNameForView:(UIView *)view {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Liquid"
                                                                   message:@"Write down the name of the event"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"e.g: Button Pressed", @"");
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Start Tracking" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self registerUIElement:[[LQUIElement alloc] initFromUIView:view evetName:alert.textFields.firstObject.text]];
    }]];
    [self presentViewControllerInTopMost:alert];
}

- (void)presentChangeTrackingEventNameForView:(UIView *)view currentElement:(LQUIElement *)element {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Liquid"
                                                                   message:@"Write down the name of the new event"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        NSString *currentEventName = [NSString stringWithFormat:@"Current: %@", element.eventName];
        textField.placeholder = NSLocalizedString(currentEventName, @"");
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Change Event Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self changeUIElement:[[LQUIElement alloc] initFromUIView:view evetName:alert.textFields.firstObject.text]];
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
    [self.elementChanger addUIElement:element];
    NSString *message = [[NSString alloc] initWithData:[NSData toJSON:[element jsonDictionary]] encoding:NSUTF8StringEncoding];
    [self.webSocketChannel trigger:@"add_element" message:message];
    LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Registered a new UI Element: %@", element);
}

- (void)unregisterUIElement:(LQUIElement *)element {
    [self.elementChanger removeUIElement:element];
    NSString *message = [[NSString alloc] initWithData:[NSData toJSON:[element jsonDictionary]] encoding:NSUTF8StringEncoding];
    [self.webSocketChannel trigger:@"remove_element" message:message];
    LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Unregistered UI Element %@", element.identifier);
}

- (void)changeUIElement:(LQUIElement *)element {
    [self.elementChanger removeUIElement:element];
    [self.elementChanger addUIElement:element];
    NSString *message = [[NSString alloc] initWithData:[NSData toJSON:[element jsonDictionary]] encoding:NSUTF8StringEncoding];
    [self.webSocketChannel trigger:@"change_element" message:message];
    LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Changed UI Element %@", element.identifier);
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
