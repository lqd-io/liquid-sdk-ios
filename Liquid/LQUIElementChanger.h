//
//  LQUIElementChanger.h
//  Liquid
//
//  Created by Miguel M. Almeida on 10/12/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQNetworking.h"
#import "LQUser.h"

@interface LQUIElementChanger : NSObject

- (instancetype)initWithNetworking:(LQNetworking *)networking dispatchQueue:(dispatch_queue_t)queue;
- (void)interceptNewElements;
- (void)requestUiElements;

@end
