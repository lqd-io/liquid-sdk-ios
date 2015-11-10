//
//  LQInAppMessageSlideUp.h
//  Liquid
//
//  Created by Miguel M. Almeida on 29/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQInAppMessage.h"
#import "LQCallToAction.h"

@interface LQInAppMessageSlideUp : LQInAppMessage

@property (nonatomic, strong, readonly) LQCallToAction *callToAction;

- (instancetype)initFromDictionary:(NSDictionary *)dict;

@end
