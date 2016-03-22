//
//  LQUIElementSetupService.m
//  Liquid
//
//  Created by Miguel M. Almeida on 11/01/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQUIElementSetupService.h"
#import <objc/runtime.h>
#import "LQAspects.h"
#import <UIKit/UIKit.h>
#import "LQDefaults.h"
#import "LQUIElement.h"
#import "LQWindow.h"
#import "LQUIElementWelcomeViewControler.h"
#import "NSData+LQData.h"
#import "UIView+LQChangeable.h"
#import "UIButton+LQChangeable.h"
#import "LQUIViewRecurringChanger.h"
#import "LQWireframeLayer.h"

#define kLQWebSocketServerrUrl @"wss://cable.onliquid.com/"

@interface LQUIElementSetupService()

@property (nonatomic, strong) LQUIElementChanger *elementChanger;
@property (nonatomic, strong) NSTimer *longPressTimer;
@property (nonatomic, assign) UIButton *touchingDownButton;
@property (nonatomic, assign) NSString *touchingDownButtonIdentifier;
@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *developerToken;
@property (nonatomic, strong) LQUIViewRecurringChanger *recurringChanger;

@end

@implementation LQUIElementSetupService

@synthesize elementChanger = _elementChanger;
@synthesize recurringChanger = _recurringChanger;
@synthesize devModeEnabled = _devModeEnabled;
@synthesize longPressTimer = _longPressTimer;
@synthesize touchingDownButton = _touchingDownButton;
@synthesize touchingDownButtonIdentifier = _touchingDownButtonIdentifier;
@synthesize webSocket = _webSocket;
@synthesize developerToken = _developerToken;

#pragma mark - Initializers

- (instancetype)initWithUIElementChanger:(LQUIElementChanger *)elementChanger {
    self = [super init];
    if (self) {
        _elementChanger = elementChanger;
        _devModeEnabled = NO;
    }
    return self;
}

- (SRWebSocket *)webSocket {
    if (!_webSocket) {
        _webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:kLQWebSocketServerrUrl]];
        _webSocket.delegate = self;
    }
    return _webSocket;
}

- (LQUIViewRecurringChanger *)recurringChanger {
    if (!_recurringChanger) {
        _recurringChanger = [[LQUIViewRecurringChanger alloc] init];
        _recurringChanger.delegate = self;
    }
    return _recurringChanger;
}

#pragma mark - Enable/disable Development Mode

- (void)enterDevelopmentModeWithToken:(NSString *)developmentToken {
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        LQLog(kLQLogLevelNone, @"<Liquid> ERROR: Event Tracking Mode is only supported in iOS 8+");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Liquid Event Tracking Mode"
                                                                       message:@"Error: You need iOS 8+ to use Event Tracking Mode."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewControllerInTopMost:alert];
        return;
    }
    if (self.devModeEnabled) {
        return;
    }
    self.elementChanger.eventTrackingDisabled = YES;
    self.developerToken = developmentToken;
    LQLog(kLQLogLevelDevMode, @"<Liquid/EventTracking> Trying to enter development mode...");
    [self.webSocket open];
    [self.recurringChanger enableTimer];
    
    // Enable dev mode for already created views:
    [self.elementChanger.registeredViews getExistingWeakValuesWithCompletionHandler:^(NSArray *weakValues) {
        for (LQWeakValue *weakValue in weakValues) {
            __block UIView *view = [weakValue nominalValue];
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (view) {
                    [self enableSetupOnView:view];
                }
            });
        }
    }];
}

- (void)exitDevelopmentMode {
    if (!self.devModeEnabled) {
        return;
    }
    LQLog(kLQLogLevelDevMode, @"<Liquid/EventTracking> Exiting development mode...");
    self.elementChanger.eventTrackingDisabled = NO;
    [self.webSocket close];
    [self.elementChanger requestUiElements];
    [self.recurringChanger disableTimer];
    [self showEndDevelopmentModeAlert];
    _devModeEnabled = NO;

    // Disable dev mode for already created views:
    [self.elementChanger.registeredViews getExistingWeakValuesWithCompletionHandler:^(NSArray *weakValues) {
        for (LQWeakValue *weakValue in weakValues) {
            __block UIView *view = [weakValue nominalValue];
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (view) {
                    [self unsetWireFrameOnView:view];
                }
            });
        }
    }];
}

- (BOOL)enableSetupOnView:(UIView *)view {
    if (![view isChangeable] || [[view liquidIdentifier] containsString:@"/LQ"]) {
        return NO;
    }
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [self setWireframeOnView:button enabled:([self.elementChanger.changedElements objectForKey:[view liquidIdentifier]])];
        [button addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(buttonTouchesEnded:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
        [button addTarget:self action:@selector(buttonTouchesEnded:withEvent:) forControlEvents:UIControlEventTouchUpInside];
        return YES;
    }
    return NO;
}

#pragma mark - Wirelframe actions

- (void)setWireframeOnView:(UIView *)view enabled:(BOOL)enabled {
    UIColor *color = (enabled ? [UIColor redColor] : [UIColor blueColor]);
    LQWireframeLayer *wireframe;
    for (CALayer *sublayer in view.layer.sublayers) {
        if ([sublayer isKindOfClass:[LQWireframeLayer class]]) {
            wireframe = (LQWireframeLayer *)sublayer;
        }
    }
    if (wireframe) {
        wireframe.borderColor = color.CGColor;
    } else {
        [view.layer addSublayer:[[LQWireframeLayer alloc] initWithFrame:view.bounds color:color]];
    }

    // Also set wireframe on view layer, if needed:
    if (view.layer.borderWidth > 0.0f) {
        view.layer.borderColor = color.CGColor;
        view.layer.borderWidth = 1.0f;
        view.layer.cornerRadius = 2.0f;
        view.layer.zPosition = 999999999;
    }
}

- (void)unsetWireFrameOnView:(UIView *)view {
    for (CALayer *sublayer in view.layer.sublayers) {
        if ([sublayer isKindOfClass:[LQWireframeLayer class]]) {
            [sublayer removeFromSuperlayer];
        }
    }
}

- (void)refreshAllWireframes {
    [self.elementChanger.registeredViews getExistingWeakValuesWithCompletionHandler:^(NSArray *weakValues) {
        for (LQWeakValue *weakValue in weakValues) {
            __block UIView *view = [weakValue nominalValue];
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (view) {
                    BOOL enabled = [self.elementChanger.changedElements objectForKey:[view liquidIdentifier]] != nil;
                    [self setWireframeOnView:view enabled:enabled];
                }
            });
        }
    }];
}

#pragma mark - UI Elements events

- (void)buttonTouchDown:(UIButton *)button {
    if (!self.devModeEnabled) {
        return;
    }
    self.touchingDownButton = button;
    self.touchingDownButtonIdentifier = [button liquidIdentifier];
    self.longPressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(longPressedButton:)
                                                         userInfo:@{ @"button": button, @"identifier": [button liquidIdentifier] }
                                                          repeats:NO];
}

- (void)longPressedButton:(NSTimer *)timer {
    UIButton *button = self.touchingDownButton;
    if (button && button == timer.userInfo[@"button"]) {
        self.touchingDownButton = nil;
        [self presentTrackingAlertForViewWithUIView:button andIdentifier:timer.userInfo[@"identifier"]];
        LQLog(kLQLogLevelInfo, @"<Liquid/UIElementSetupService> Configuring button with identifier %@", [button liquidIdentifier]);
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

#pragma mark - Present Views

- (void)presentWelcomeScreen {
    LQUIElementWelcomeViewControler *welcomeViewController = [[LQUIElementWelcomeViewControler alloc] init];
    [self presentViewControllerInTopMost:welcomeViewController];
}

- (void)presentViewControllerInTopMost:(UIViewController *)viewController {
    UIWindow *window = [LQWindow fullscreenWindow];
    [window makeKeyAndVisible];
    [window.rootViewController presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - Alerts

- (void)presentTrackingAlertForViewWithUIView:(UIView *)view andIdentifier:(NSString *)identifier {
    UIAlertController *alert;
    LQUIElement *element = [self.elementChanger.changedElements objectForKey:identifier];
    NSString *klass = [[view class] description];
    if (element && element.eventName) {
        LQUIElement *element = [self.elementChanger uiElementFor:view];
        alert = [UIAlertController alertControllerWithTitle:@"Liquid Event Tracking Mode"
                                                    message:[NSString stringWithFormat:@"This %@ is being tracked by Liquid as the event '%@'", klass, element.eventName]
                                             preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Remove Event"
                                                  style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [self setWireframeOnView:view enabled:NO];
            [self refreshAllWireframes];
            [self unregisterUIElement:element];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Rename Event" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self presentChangeTrackingEventNameForView:view identifier:identifier currentElement:element];
        }]];
    } else {
        alert = [UIAlertController alertControllerWithTitle:@"Liquid Event Tracking Mode"
                                                    message:[NSString stringWithFormat:@"This %@ isn't being tracked.", klass]
                                             preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"Add Event" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self presentSetTrackingEventNameForView:view identifier:identifier];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewControllerInTopMost:alert];
}

- (void)presentSetTrackingEventNameForView:(UIView *)view identifier:(NSString *)identifier {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Set the Event Name"
                                                                   message:[[NSString alloc] initWithFormat:@"Identifier for element is:\n%@", [view liquidIdentifier]]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"e.g: Button Pressed", @"");
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self setWireframeOnView:view enabled:YES];
        [self refreshAllWireframes];
        [self registerUIElement:[[LQUIElement alloc] initWithIdentifier:identifier
                                                              eventName:alert.textFields.firstObject.text]];
    }]];
    [self presentViewControllerInTopMost:alert];
}

- (void)presentChangeTrackingEventNameForView:(UIView *)view identifier:(NSString *)identifier currentElement:(LQUIElement *)element {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Rename the Event Name"
                                                                   message:[[NSString alloc] initWithFormat:@"Identifier for element is:\n%@", [view liquidIdentifier]]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [NSString stringWithFormat:@"%@", element.eventName];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self changeUIElement:[[LQUIElement alloc] initWithIdentifier:identifier
                                                            eventName:alert.textFields.firstObject.text]];
    }]];
    [self presentViewControllerInTopMost:alert];
}

- (void)showNetworkFailAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network error"
                                                                   message:@"An error occured while connecting to Liquid servers. Please try again."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewControllerInTopMost:alert];
}

- (void)showEndDevelopmentModeAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Exiting Event Tracking Mode"
                                                                   message:@"To exit Event Tracking Mode your app needs to be closed."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Close App" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }]];
    [self presentViewControllerInTopMost:alert];
}

#pragma mark - Button actions

- (void)registerUIElement:(LQUIElement *)element {
    [self.elementChanger addUIElement:element];
    [self sendMessage:[element jsonDictionary] forAction:@"add_element"];
    LQLog(kLQLogLevelDevMode, @"<Liquid/LQUIElementChanger> Registered a new UI Element: %@", element);
}

- (void)unregisterUIElement:(LQUIElement *)element {
    [self.elementChanger removeUIElement:element];
    [self sendMessage:[element jsonDictionary] forAction:@"remove_element"];
    LQLog(kLQLogLevelDevMode, @"<Liquid/LQUIElementChanger> Unregistered UI Element %@", element.identifier);
}

- (void)changeUIElement:(LQUIElement *)element {
    [self.elementChanger removeUIElement:element];
    [self.elementChanger addUIElement:element];
    [self sendMessage:[element jsonDictionary] forAction:@"change_element"];
    LQLog(kLQLogLevelDevMode, @"<Liquid/LQUIElementChanger> Changed UI Element %@", element.identifier);
}

#pragma mark - WebSocket methods

- (void)sendMessage:(NSDictionary *)messageDict forAction:(NSString *)action {
    [self sendCommand:@"message" withMessage:messageDict forAction:action];
}

- (void)sendCommand:(NSString *)command withMessage:(NSDictionary *)message forAction:(NSString *)action {
    NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] initWithDictionary:message];
    dataDict[@"action"] = action;
    NSDictionary *payload = @{
                              @"command": command,
                              @"identifier": [self websocketIdentifier],
                              @"data": [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dataDict options:0 error:nil] encoding:NSUTF8StringEncoding]
                            };
    [self.webSocket send:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:payload options:0 error:nil] encoding:NSUTF8StringEncoding]];
}

- (void)sendCommand:(NSString *)command {
    NSDictionary *payload = @{
                              @"command": command,
                              @"identifier": [self websocketIdentifier]
                              };
    [self.webSocket send:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:payload options:0 error:nil] encoding:NSUTF8StringEncoding]];
}

- (NSString *)websocketIdentifier {
    return [NSString stringWithFormat:@"{\"channel\": \"MessageChannel\", \"token\": \"%@\"}", self.developerToken];
}

#pragma mark - SRWebSocketDelegate methods

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)rawMessage {
    NSError *jsonError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[(NSString *)rawMessage dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&jsonError];
    if (jsonError) {
        LQLog(kLQLogLevelInfo, @"<Liquid/UIElementSetupService> Error while parsing JSON.");
        return;
    }
    if ([json[@"identifier"] isEqualToString:@"_ping"]) {
        return;
    }

    if ([json[@"type"] isEqualToString:@"confirm_subscription"]) {
        _devModeEnabled = YES;
        [self presentWelcomeScreen];
        [self sendMessage:@{} forAction:@"start_development"];
        LQLog(kLQLogLevelDevMode, @"<Liquid/EventTracking> Started development mode");
    } else if (json[@"message"]) {
        [self handleReceivedMessage:json[@"message"]];
    }
}

- (void)handleReceivedMessage:(NSDictionary *)message {
    if ([message[@"action"] isEqualToString:@"end_development"]) {
        [self exitDevelopmentMode];
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    LQLog(kLQLogLevelInfo, @"<Liquid/UIElementSetupService> WebSocket open. Subscribing to channel...");
    [self sendCommand:@"subscribe"];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    LQLog(kLQLogLevelInfo, @"<Liquid/UIElementSetupService> WebSocket failed with error: %@", error);
    [self showNetworkFailAlert];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    LQLog(kLQLogLevelInfo, @"<Liquid/UIElementSetupService> WebSocket close with code: %ld. Reason is %@.", code, reason);
}

#pragma mark - LQUIElementFramerDelegate methods

- (BOOL)didFindView:(UIView *)view {
    return [self enableSetupOnView:view];
}

@end

