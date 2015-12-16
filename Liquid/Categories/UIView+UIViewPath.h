//
//  UIView+LQViewPath.h
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (UIViewPath)

- (BOOL)matchesLiquidPath:(NSString *)path andTrackableIdentifier:(NSString *)identifier;
- (NSString *)liquidPath;
- (NSString *)trackableIdentifier;

@end
