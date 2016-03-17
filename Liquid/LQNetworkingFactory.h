//
//  LQNetworkingFactory.h
//  Liquid
//
//  Created by Miguel M. Almeida on 17/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQDefaults.h"

#if LQ_WATCHOS || LQ_TVOS
#import "LQNetworkingURLSession.h"
#else
#import "LQNetworkingURLSession.h"
#import "LQNetworkingURLConnection.h"
#endif

@interface LQNetworkingFactory : NSObject

- (LQNetworking *)createWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue;
- (LQNetworking *)createFromDiskWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue;

@end
