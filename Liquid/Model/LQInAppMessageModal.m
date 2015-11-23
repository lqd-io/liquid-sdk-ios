//
//  LQInAppMessageModal.m
//  Liquid
//
//  Created by Miguel M. Almeida on 23/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQInAppMessageModal.h"
#import "LQDefaults.h"

#if LQ_INAPP_MESSAGES_SUPPORT
#import "LQCallToAction.h"
#import "UIColor+LQColor.h"

@implementation LQInAppMessageModal

@synthesize title = _title;
@synthesize titleColor = _titleColor;
@synthesize callsToAction = _callsToAction;

#pragma mark - Initializers

- (instancetype)initFromDictionary:(NSDictionary *)dict {
    self = [super initFromDictionary:dict];
    if (self) {
        _title = [dict objectForKey:@"title"];
        _titleColor = [UIColor colorFromHexadecimalString:[dict objectForKey:@"title_color"]];
        NSMutableArray *ctas = [[NSMutableArray alloc] init];
        for (NSDictionary *cta in [dict objectForKey:@"ctas"]) {
            [ctas addObject:[[LQCallToAction alloc] initFromDictionary:cta]];
        }
        _callsToAction = ctas;
    }
    return self;
}

#pragma mark - Validations

- (BOOL)isValid {
    if (!_title) return NO;
    for (LQCallToAction *cta in self.callsToAction) {
        if ([cta isInvalid]) return NO;
    }
    return [super isValid];
}

@end
#endif
