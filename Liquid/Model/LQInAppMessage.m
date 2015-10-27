//
//  LQInAppMessage.m
//  Liquid
//
//  Created by Miguel M. Almeida on 23/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQInAppMessage.h"
#import "LQDefaults.h"
#import "UIColor+LQColor.h"

@implementation LQInAppMessage

@synthesize message = _message;
@synthesize backgroundColor = _backgroundColor;
@synthesize messageColor = _messageColor;
//@synthesize layout = _layout;
@synthesize dismissEventName = _dismissEventName;

#pragma mark - Initilizers

- (instancetype)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _message = [dict objectForKey:@"message"];
        _backgroundColor = [UIColor colorFromHexadecimalString:[dict objectForKey:@"bg_color"]];
        _messageColor = [UIColor colorFromHexadecimalString:[dict objectForKey:@"message_color"]];
        //_layout = [[self class] layoutFromLayoutName:[dict objectForKey:@"layout"]];
        //_layout = [self layout];
        _dismissEventName = [dict objectForKey:@"dismiss_event_name"];
    }
    return self;
}

#pragma mark - Helper methods

- (BOOL)isValid {
    // Force to be valid only in subclasses:
    if([self isMemberOfClass:[LQInAppMessage class]]) return NO;
    if(!_message) return NO;
    return YES;
}

- (BOOL)isInvalid {
    return ![self isValid];
}

//+ (LQInAppMessageLayout)layoutFromLayoutName:(NSString *)layoutName {
//    if([layoutName isEqualToString:kLQInAppMessageTypeIdentifierModal]) {
//        return kLQInAppMessageLayoutModal;
//    } else if([layoutName isEqualToString:@"slide_up"]) {
//        return kLQInAppMessageLayoutSlideUp;
//    } else if([layoutName isEqualToString:@"full_screen"]) {
//        return kLQInAppMessageLayoutFullScreen;
//    }
//    return kLQInAppMessageLayoutUnknown;
//}

@end
