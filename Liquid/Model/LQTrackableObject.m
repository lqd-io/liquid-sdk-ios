//
//  LQTrackableObject.m
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQTrackableObject.h"
#import "UIView+UIViewPath.h"

@interface LQTrackableObject ()

@end

@implementation LQTrackableObject

@synthesize path = _path;
@synthesize identifier = _identifier;

- (id)initFromDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        _path = [dict objectForKey:@"path"];
        _identifier = [dict objectForKey:@"identifier"];
    }
    return self;
}

- (BOOL)matchesUIView:(UIView *)view {
    return [view matchesLiquidPath:self.path andTrackableIdentifier:self.identifier];
}

@end
