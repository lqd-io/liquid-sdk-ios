//
//  LQWeakValue.h
//  Liquid
//
//  Created by Miguel M. Almeida on 07/03/16.
//  Copyright © 2016 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LQWeakValue : NSObject

@property (nonatomic, weak, readonly) id nominalValue;

+ (instancetype)weakValueWithValue:(id)value;
- (instancetype)initWithValue:(id)value;

@end
