//
//  LQWebSocket.m
//  Liquid
//
//  Created by Miguel M. Almeida on 14/02/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import "LQWebSocket.h"
#import "SRWebSocket.h"
#import "WebSocketRailsDispatcher.h"
#import "WebSocketRailsChannel.h"

#define kLQWebSocketServerrUrl @"ws://lvh.me:3000/websocket"

@interface LQWebSocket ()

@property (nonatomic, strong) WebSocketRailsDispatcher *dispatcher;
@property (nonatomic, strong) WebSocketRailsChannel *channel;

@end

@implementation LQWebSocket

#pragma mark - Initializers

- (instancetype)initWithWebSocketURL:(NSString *)url channel:(NSString *)channel {
    self = [super init];
    if (self) {
        _dispatcher = [[WebSocketRailsDispatcher alloc] initWithUrl:[NSURL URLWithString:kLQWebSocketServerrUrl]];
        _channel = [_dispatcher subscribe:channel];
    }
    return self;
}

#pragma mark - Public methods

- (void)bindEvents {
    [self.dispatcher bind:@"connection_opened" callback:^(id data) {
        NSLog(@"Yay! Connected!");
    }];
    [self.channel bind:@"start_development" callback:^(id data) {
        NSLog(@"start_development: %@", data);
    }];
    [self.channel bind:@"add_element" callback:^(id data) {
        NSLog(@"add_element: %@", data);
    }];
}

- (void)triggerEvent:(NSString *)eventName message:(NSString *)message {
    [self.channel trigger:eventName message:message];
}

@end
