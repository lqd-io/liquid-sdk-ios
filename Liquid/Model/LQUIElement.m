//
//  LQUIElement.m
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQUIElement.h"
#import "UIView+LQChangeable.h"

@interface LQUIElement ()

@end

@implementation LQUIElement

@synthesize identifier = _identifier;
@synthesize active = _active;
@synthesize eventName = _eventName;
@synthesize eventAttributes = _eventAttributes;

- (instancetype)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        if ([[dict objectForKey:@"active"] isEqualToNumber:@YES]) {
            _active = [dict objectForKey:@"active"];
        } else {
            _active = NO;
        }
        _identifier = [dict objectForKey:@"identifier"];
        _eventName = [dict objectForKey:@"event_name"];
        _eventAttributes = [dict objectForKey:@"event_attributes"];
    }
    return self;
}

- (BOOL)matchesUIView:(UIView *)view {
    return [self.identifier isEqualToString:view.liquidIdentifier];
}

@end
