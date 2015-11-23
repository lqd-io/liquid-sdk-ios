//
//  LQInAppMessageSlideUp.m
//  Liquid
//
//  Created by Miguel M. Almeida on 29/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQInAppMessageSlideUp.h"
#import "LQDefaults.h"

#if LQ_INAPP_MESSAGES_SUPPORT
@implementation LQInAppMessageSlideUp

#pragma mark - Initializers

- (instancetype)initFromDictionary:(NSDictionary *)dict {
    self = [super initFromDictionary:dict];
    if (self) {
        if ([[dict objectForKey:@"ctas"] count] >= 1) {
            _callToAction = [[LQCallToAction alloc] initFromDictionary:[[dict objectForKey:@"ctas"] objectAtIndex:0]];
        }
    }
    return self;
}

#pragma mark - Validations

- (BOOL)isValid {
    if (!_callToAction) return NO;
    return [super isValid];
}

@end
#endif