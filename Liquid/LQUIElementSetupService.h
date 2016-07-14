//
//  LQUIElementSetupService.h
//  Liquid
//
//  Created by Miguel M. Almeida on 11/01/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQUIElementChanger.h"
#ifdef LQ_MANUAL_INTEGRATION
#import "SRWebSocket.h"
#else
#import <SocketRocket/SRWebSocket.h>
#endif

@interface LQUIElementSetupService : NSObject <SRWebSocketDelegate>

@property (nonatomic, assign, readonly) BOOL devModeEnabled;

- (void)enterDevelopmentModeWithToken:(NSString *)developmentToken;
- (void)exitDevelopmentMode;
- (instancetype)initWithUIElementChanger:(LQUIElementChanger *)elementChanger;
- (BOOL)enableSetupOnView:(UIView *)view;

@end
