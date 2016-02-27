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

#define kLQWebSocketServerrUrl @"wss://cable.onliquid.com/"

@interface LQUIElementSetupService()

@property (nonatomic, strong) LQUIElementChanger *elementChanger;
@property (nonatomic, strong) NSTimer *longPressTimer;
@property (nonatomic, assign) UIButton *touchingDownButton;
@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *developerToken;

@end

@implementation LQUIElementSetupService

@synthesize elementChanger = _elementChanger;
@synthesize devModeEnabled = _devModeEnabled;
@synthesize longPressTimer = _longPressTimer;
@synthesize touchingDownButton = _touchingDownButton;
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

#pragma mark - Enable/disable Development Mode

- (void)enterDevelopmentModeWithToken:(NSString *)developmentToken {
    if (self.devModeEnabled) {
        return;
    }
    self.elementChanger.eventTrackingDisabled = YES;
    self.developerToken = developmentToken;
    LQLog(kLQLogLevelDevMode, @"<Liquid/EventTracking> Trying to enter development mode...");
    [self.webSocket open];
}

- (void)exitDevelopmentMode {
    if (!self.devModeEnabled) {
        return;
    }
    self.elementChanger.eventTrackingDisabled = NO;
    [self.webSocket close];
    if (!self.devModeEnabled) return;
    _devModeEnabled = NO;
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
                                                         selector:@selector(longPressedButton:)
                                                    userInfo:button
                                                     repeats:YES];
}

- (void)longPressedButton:(NSTimer *)timer {
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
                                                                   message:@"An error occured while connecting to Liquid servers. Please try again."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewControllerInTopMost:alert];
}

#pragma mark - Button actions

- (void)registerUIElement:(LQUIElement *)element {
    [self.elementChanger addUIElement:element];
    [self sendMessage:[element jsonDictionary] forAction:@"add_element"];
    LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Registered a new UI Element: %@", element);
}

- (void)unregisterUIElement:(LQUIElement *)element {
    [self.elementChanger removeUIElement:element];
    [self sendMessage:[element jsonDictionary] forAction:@"remove_element"];
    LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Unregistered UI Element %@", element.identifier);
}

- (void)changeUIElement:(LQUIElement *)element {
    [self.elementChanger removeUIElement:element];
    [self.elementChanger addUIElement:element];
    [self sendMessage:[element jsonDictionary] forAction:@"change_element"];
    LQLog(kLQLogLevelInfo, @"<Liquid/LQUIElementChanger> Changed UI Element %@", element.identifier);
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
        NSLog(@"JSON error: %@", [jsonError description]);
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
    NSLog(@"WebSocket open. Subscribing to channel..."); // TODO message
    [self sendCommand:@"subscribe"];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"did fail with error: %@", error); // TODO message
    [self showNetworkFailAlert];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"Did close with code: %ld. Reason is %@", code, reason); // TODO message
}

@end

