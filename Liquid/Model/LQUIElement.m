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

#pragma mark - Initializers

- (instancetype)initFromUIView:(id)view evetName:(NSString *)eventName {
    id me = [self initFromUIView:view];
    _eventName = eventName;
    return me;
}

- (instancetype)initFromUIView:(UIView *)view {
    self = [super init];
    if (self) {
        if (![view isChangeable]) {
            [NSException raise:NSInternalInconsistencyException format:@"Liquid: View %@ is not changeable", [view liquidIdentifier]];
        }
        _active = YES;
        _identifier = [NSString stringWithString:[view liquidIdentifier]];
    }
    return self;
}

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
        //_eventAttributes = [dict objectForKey:@"event_attributes"]; // TODO: TO REMOVE FROM HERE AND EVERYWHERE ELSE
    }
    return self;
}

#pragma mark - Instance methods

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", self.identifier];
}

- (BOOL)matchesUIView:(UIView *)view {
    return [self.identifier isEqualToString:view.liquidIdentifier];
}

- (NSDictionary *)jsonDictionary {
    return [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"ios", @"platform",
            _identifier, @"identifier",
            _eventName, @"event_name", nil];
}

#pragma mark - NSCoding & NSCopying

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _active = [[aDecoder decodeObjectForKey:@"active"] boolValue];
        _identifier = [aDecoder decodeObjectForKey:@"identifier"];
        _eventName = [aDecoder decodeObjectForKey:@"event_name"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[NSNumber numberWithBool:_active] forKey:@"active"];
    [aCoder encodeObject:_identifier forKey:@"attributes"];
    [aCoder encodeObject:_eventName forKey:@"event_name"];
}

@end
