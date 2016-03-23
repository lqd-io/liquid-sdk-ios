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

- (instancetype)initWithIdentifier:(NSString *)identifier eventName:(NSString *)eventName {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _eventName = eventName;
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
    [aCoder encodeObject:self.identifier forKey:@"identifier"];
    [aCoder encodeObject:self.eventName forKey:@"event_name"];
}

- (id)copyWithZone:(NSZone *)zone {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end
