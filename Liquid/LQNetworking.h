//
//  LQNetworking.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 24/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQRequest.h"
#import "LQURLRequestFactory.h"

@interface LQNetworking : NSObject

@property(nonatomic, assign) NSUInteger queueSizeLimit;
@property(nonatomic, assign) NSUInteger flushInterval;
@property (nonatomic, strong, readonly) LQURLRequestFactory *urlRequestFactory;

- (instancetype)initWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue;
- (instancetype)initFromDiskWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue;
- (void)startFlushTimer;
- (void)stopFlushTimer;
- (void)flush;
- (void)resetHttpQueue;
- (void)addDictionaryToHttpQueue:(NSDictionary *)dictionary endPoint:(NSString *)endPoint httpMethod:(NSString *)httpMethod;
- (void)addToHttpQueue:(NSData *)jsonData endPoint:(NSString *)endPoint httpMethod:(NSString *)httpMethod;

- (BOOL)archiveHttpQueue;
+ (NSMutableArray*)unarchiveHttpQueueForToken:(NSString*)apiToken;
+ (void)deleteHttpQueueFileForToken:(NSString *)token;

- (void)sendData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method completionHandler:(void(^)(LQQueueStatus queueStatus, NSData *responseData))completionHandler;
- (void)getDataFromEndpoint:(NSString *)endpoint completionHandler:(void(^)(LQQueueStatus queueStatus, NSData *responseData)) completionHandler;
- (LQQueueStatus)sendSynchronousData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method;
- (NSData *)getSynchronousDataFromEndpoint:(NSString *)endpoint;

+ (LQQueueStatus)queueStatusFromData:(NSData *)responseData response:(NSURLResponse *)response error:(NSError *)error;

@end
