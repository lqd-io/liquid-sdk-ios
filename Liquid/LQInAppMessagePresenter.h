//
//  LQInAppMessage.h
//  PopupTest
//
//  Created by Miguel M. Almeida on 22/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQModalMessageView.h"
#import "LQInAppMessageModal.h"

//typedef NS_ENUM(NSInteger, LQInAppMessageType) {
//    kLQInAppMessageTypeModal = 0,
//    kLQInAppMessageTypeSlideUp = 1,
//    kLQInAppMessageTypeFullScreen = 2
//};

@interface LQInAppMessagePresenter : NSObject <LQModalMessageViewDelegate>

//+ (void)presentInAppMessage:(LQInAppMessage *)inAppMessage;
- (instancetype)initWithModal:(LQInAppMessageModal *)inAppMessage;
- (void)present;

@end
