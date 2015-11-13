//
//  LQNetworking.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 24/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQRequest.h"

@interface LQNetworking : NSObject

@property(nonatomic, assign) NSUInteger queueSizeLimit;
@property(nonatomic, assign) NSUInteger flushInterval;

- (instancetype)initWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue;
- (instancetype)initFromDiskWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue;
- (void)startFlushTimer;
- (void)stopFlushTimer;
- (void)flush;
- (void)resetHttpQueue;
- (void)addDictionaryToHttpQueue:(NSDictionary *)dictionary endPoint:(NSString *)endPoint httpMethod:(NSString *)httpMethod;
- (void)addToHttpQueue:(NSData *)jsonData endPoint:(NSString *)endPoint httpMethod:(NSString *)httpMethod;
+ (NSString *)liquidUserAgent;

- (BOOL)archiveHttpQueue;
+ (NSMutableArray*)unarchiveHttpQueueForToken:(NSString*)apiToken;
+ (void)deleteHttpQueueFileForToken:(NSString *)token;

- (void)sendData:(nonnull NSData *)data toEndpoint:(nonnull NSString *)endpoint usingMethod:(nonnull NSString *)method completionHandler:(void(^ _Nonnull)(LQQueueStatus queueStatus, NSData * _Nullable responseData))completionHandler;
- (void)getDataFromEndpoint:(nonnull NSString *)endpoint completionHandler:(void(^ _Nonnull)(LQQueueStatus queueStatus, NSData * _Nullable responseData)) completionHandler;
- (LQQueueStatus)sendSynchronousData:(nonnull NSData *)data toEndpoint:(nonnull NSString *)endpoint usingMethod:(nonnull NSString *)method;
- (nullable NSData *)getSynchronousDataFromEndpoint:(nonnull NSString *)endpoint;

@end
