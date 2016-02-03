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
@synthesize eventName = _eventName;

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
        _identifier = [NSString stringWithString:[view liquidIdentifier]];
    }
    return self;
}

- (instancetype)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _identifier = [dict objectForKey:@"identifier"];
        _eventName = [dict objectForKey:@"event_name"];
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
        _identifier = [aDecoder decodeObjectForKey:@"identifier"];
        _eventName = [aDecoder decodeObjectForKey:@"event_name"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_identifier forKey:@"attributes"];
    [aCoder encodeObject:_eventName forKey:@"event_name"];
}

@end
