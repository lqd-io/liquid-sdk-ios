//
//  LQNetworking.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 24/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQDefaults.h"
#import "LQRequest.h"

@interface LQNetworking () {
    @protected NSString *_apptoken;
    @protected NSMutableArray *_httpQueue;
    @protected NSString *_liquidUserAgent;
    @protected dispatch_queue_t _queue;
}

@property(atomic, strong) NSMutableArray *httpQueue;
@property(nonatomic, strong) NSString *appToken;

@property(nonatomic, strong, readonly) NSString *liquidUserAgent;
#if OS_OBJECT_USE_OBJC
@property(atomic, strong) dispatch_queue_t queue;
#else
@property(atomic, assign) dispatch_queue_t queue;
#endif

extern NSString * const serverUrl;
extern NSUInteger const minFlushInterval;
extern NSUInteger const timeUnreachableWait;
extern NSUInteger const timeRejectedWait;
extern NSUInteger const maxTries;

@end
