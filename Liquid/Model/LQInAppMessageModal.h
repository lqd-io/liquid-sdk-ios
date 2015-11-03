//
//  LQInAppMessageModal.h
//  Liquid
//
//  Created by Miguel M. Almeida on 23/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQInAppMessage.h"

#define kLQInAppMessageTypeIdentifierModal @"modal"

@interface LQInAppMessageModal : LQInAppMessage {
    NSString *_title;
    UIColor *_titleColor;
    NSArray *_callsToAction;
}

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) NSArray *callsToAction;

- (instancetype)initFromDictionary:(NSDictionary *)dict;

@end
