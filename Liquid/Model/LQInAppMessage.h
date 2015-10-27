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
    //LQInAppMessageLayout _layout;
    NSString *_message;
    UIColor *_backgroundColor;
    UIColor *_messageColor;
    NSString *_dismissEventName;
}

//@property (nonatomic, assign, readonly) LQInAppMessageLayout layout;
@property (nonatomic, strong, readonly) NSString *message;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *messageColor;
@property (nonatomic, strong) NSString *dismissEventName;

- (instancetype)initFromDictionary:(NSDictionary *)dict;
- (BOOL)isValid;
- (BOOL)isInvalid;

@end
