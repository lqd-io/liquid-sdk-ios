//
//  LQInAppMessage.h
//  Liquid
//
//  Created by Miguel M. Almeida on 23/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIColor.h>

typedef NS_ENUM(NSInteger, LQInAppMessageLayout) {
    kLQInAppMessageLayoutUnknown = -1,
    kLQInAppMessageLayoutModal = 0,
    kLQInAppMessageLayoutSlideUp = 1,
    kLQInAppMessageLayoutFullScreen = 2
};

@interface LQInAppMessage : NSObject {
    NSString *_message;
    UIColor *_backgroundColor;
    UIColor *_messageColor;
    NSString *_dismissEventName;
}

@property (nonatomic, strong, readonly) NSString *message;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *messageColor;
@property (nonatomic, strong) NSString *dismissEventName;

- (instancetype)initFromDictionary:(NSDictionary *)dict;
- (BOOL)isValid;
- (BOOL)isInvalid;

@end
