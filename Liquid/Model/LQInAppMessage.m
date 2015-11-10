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
@synthesize dismissEventName = _dismissEventName;
@synthesize dismissEventAttributes = _dismissEventAttributes;

#pragma mark - Initilizers

- (instancetype)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _message = [dict objectForKey:@"message"];
        _backgroundColor = [UIColor colorFromHexadecimalString:[dict objectForKey:@"bg_color"]];
        _messageColor = [UIColor colorFromHexadecimalString:[dict objectForKey:@"message_color"]];
        _dismissEventName = [dict objectForKey:@"dismiss_event_name"];
        _dismissEventAttributes = [[self class] fixCTAAttributes:[dict objectForKey:@"event_attributes"]];
    }
    return self;
}

#pragma mark - Helper methods

- (BOOL)isValid {
    if([self isMemberOfClass:[LQInAppMessage class]]) return NO; // force to be valid only in subclasses
    if(!_message) return NO;
    return YES;
}

- (BOOL)isInvalid {
    return ![self isValid];
}

+ (NSDictionary *)fixCTAAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *fixedCTAAttributes = [[NSMutableDictionary alloc] initWithDictionary:attributes];
    fixedCTAAttributes[@"event_id"] = attributes[@"id"];
    [fixedCTAAttributes removeObjectForKey:@"id"];
    return fixedCTAAttributes;
}

@end
