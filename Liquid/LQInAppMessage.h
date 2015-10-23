//
//  LQInAppMessage.h
//  PopupTest
//
//  Created by Miguel M. Almeida on 22/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQModalMessageView.h"

typedef NS_ENUM(NSInteger, LQInAppMessageType) {
    kLQInAppMessageTypeModal = 0,
    kLQInAppMessageTypeSlideUp = 1,
    kLQInAppMessageTypeFullScreen = 2
};

@interface LQInAppMessage : NSObject <LQModalMessageViewDelegate>

+ (void)presentInAppMessageOfType:(LQInAppMessageType)type withTitle:(NSString *)title message:(NSString *)message;
+ (void)presentInAppMessageOfType:(LQInAppMessageType)type withTitle:(NSString *)title message:(NSString *)message options:(NSDictionary *)options;

@end
