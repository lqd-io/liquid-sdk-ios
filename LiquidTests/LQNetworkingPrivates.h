//
//  LQNetworking.h
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 24/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LQNetworking : NSObject

@property(nonatomic, assign) NSUInteger queueSizeLimit;
@property(nonatomic, assign) NSUInteger flushInterval;
@property(nonatomic, strong) NSMutableArray *httpQueue;

- (instancetype)initWithToken:(NSString *)apiToken;
- (instancetype)initFromDiskWithToken:(NSString *)apiToken;
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

- (NSInteger)sendDatza:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method;
- (NSData *)getDataFromEndpoint:(NSString *)endpoint;

@end
