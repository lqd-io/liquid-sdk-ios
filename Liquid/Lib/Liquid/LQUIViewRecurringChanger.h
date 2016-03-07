//
//  LQUIViewRecurringChanger.h
//  Liquid
//
//  Created by Miguel M. Almeida on 05/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LQUIViewRecurringChangerDelegate <NSObject>

@optional

- (BOOL)didFindView:(UIView *)view;

@end

@interface LQUIViewRecurringChanger : NSObject

@property (nonatomic, weak) NSObject<LQUIViewRecurringChangerDelegate> *delegate;

- (void)enableTimer;
- (void)disableTimer;

@end
