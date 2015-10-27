//
//  LQCallToAction.m
//  Liquid
//
//  Created by Miguel M. Almeida on 23/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQCallToAction.h"
#import "UIColor+LQColor.h"

@implementation LQCallToAction {
    NSString *_title;
    UIColor *_titleColor;
    UIColor *_backgroundColor;
    NSDictionary *_eventAttributes;
}

- (instancetype)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _title = [dict objectForKey:@"title"];
        _titleColor = [UIColor colorFromHexadecimalString:[dict objectForKey:@"title_color"]];
        _backgroundColor = [UIColor colorFromHexadecimalString:[dict objectForKey:@"bg_color"]];
        _eventName = [dict objectForKey:@"event_name"];
        _eventAttributes = [[self class] fixCTAAttributes:[dict objectForKey:@"cta_attributes"]];
    }
    return self;
}

+ (NSDictionary *)fixCTAAttributes:(NSDictionary *)attributes {
    NSMutableDictionary *fixedCTAAttributes = [[NSMutableDictionary alloc] initWithDictionary:attributes];
    fixedCTAAttributes[@"cta_id"] = attributes[@"id"];
    [fixedCTAAttributes removeObjectForKey:@"id"];
    return fixedCTAAttributes;
}

@end
