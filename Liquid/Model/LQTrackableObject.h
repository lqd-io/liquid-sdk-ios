//
//  LQTrackableObject.h
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LQTrackableObject : NSObject

@property (nonatomic, strong, readonly) NSString *path;
@property (nonatomic, strong, readonly) NSString *identifier;

- (id)initFromDictionary:(NSDictionary *)dict;
- (BOOL)matchesUIView:(UIView *)view;

@end
