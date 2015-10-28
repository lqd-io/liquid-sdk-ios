//
//  LQCallToAction.h
//  Liquid
//
//  Created by Miguel M. Almeida on 23/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIColor.h>

@interface LQCallToAction : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) UIColor *titleColor;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) NSString *eventName;
@property (nonatomic, strong) NSDictionary *eventAttributes;

- (instancetype)initFromDictionary:(NSDictionary *)dict;
- (BOOL)isValid;
- (BOOL)isInvalid;

@end
