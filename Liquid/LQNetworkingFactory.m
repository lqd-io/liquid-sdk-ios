//
//  LQNetworkingFactory.m
//  Liquid
//
//  Created by Miguel M. Almeida on 17/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <objc/runtime.h>
#import "LQNetworkingFactory.h"
#import "LQDefaults.h"
#if LQ_IOS
#import <UIKit/UIKit.h>
#endif

static Class _lqNetworkingClass = nil;

@implementation LQNetworkingFactory

- (LQNetworking *)createWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue {
    return [[[[self class] lqNetworkingClass] alloc] initWithToken:apiToken dipatchQueue:queue];
}

- (LQNetworking *)createFromDiskWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue {
    return [[[[self class] lqNetworkingClass] alloc] initFromDiskWithToken:apiToken dipatchQueue:queue];
}

+ (Class)classWithName:(NSString *)className {
    Class theClass = NULL;
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL, 0);
    if (numClasses > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i < numClasses; i++) {
            Class class = classes[i];
            if ([NSStringFromClass(class) isEqualToString:className]) {
                theClass = class;
            }
        }
        free(classes);
    }
    return theClass;
}

+ (Class)lqNetworkingClass {
    if (!_lqNetworkingClass) {
#if LQ_WATCHOS
        _lqNetworkingClass = [self classWithName:@"LQNetworkingURLSession"];
#else
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            _lqNetworkingClass = [self classWithName:@"LQNetworkingURLSession"];
        } else {
            _lqNetworkingClass = [self classWithName:@"LQNetworkingURLConnection"];
        }
#endif
    }
    return _lqNetworkingClass;
}

@end
