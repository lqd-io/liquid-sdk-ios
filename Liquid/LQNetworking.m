//
//  LQNetworking.m
//  Liquid
//
//  Created by Liquid Data Intelligence, S.A. (lqd.io) on 24/08/14.
//  Copyright (c) 2014 Liquid Data Intelligence, S.A. All rights reserved.
//

#import <Foundation/NSKeyedArchiver.h>
#import "LQNetworking.h"
#import "LQNetworkingProtected.h"
#import "NSString+LQString.h"
#import "NSData+LQData.h"
#import "LQDevice.h"
#import "LQDate.h"
#import "LQHelpers.h"
#import "LQStorage.h"

#define kLQDefaultHttpQueueSizeLimit 500 // number of requests (data points) to keep in queue
#ifdef DEBUG
#define kLQDefaultFlushInterval 5 //seconds
#else
#define kLQDefaultFlushInterval 10 //seconds
#endif
#define kLQMinFlushInterval 5 // seconds
#define kLQHttpUnreachableWait 60 // seconds
#define kLQHttpRejectedWait 3600 // seconds
#define kLQHttpMaxTries 40

@interface LQNetworking ()

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation LQNetworking

@synthesize appToken = _appToken;
@synthesize httpQueue = _httpQueue;

NSUInteger const minFlushInterval = kLQMinFlushInterval;
NSUInteger const timeUnreachableWait = kLQHttpUnreachableWait;
NSUInteger const timeRejectedWait = kLQHttpRejectedWait;
NSUInteger const maxTries = kLQHttpMaxTries;

#pragma mark - Initializers

- (instancetype)initWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue {
    if ([self isKindOfClass:[LQNetworking class]]) {
        _urlRequestFactory = [[LQURLRequestFactory alloc] initWithAppToken:apiToken];
        _httpQueue = [NSMutableArray new];
        _appToken = apiToken;
        _queueSizeLimit = kLQDefaultHttpQueueSizeLimit;
        _flushInterval = kLQDefaultFlushInterval;
        _queue = queue;
    }
    return self;
}

- (instancetype)initFromDiskWithToken:(NSString *)apiToken dipatchQueue:(dispatch_queue_t)queue {
    if ([self isKindOfClass:[LQNetworking class]]) {
        _urlRequestFactory = [[LQURLRequestFactory alloc] initWithAppToken:apiToken];
        _httpQueue = [LQNetworking unarchiveHttpQueueForToken:apiToken];
        _appToken = apiToken;
        _queueSizeLimit = kLQDefaultHttpQueueSizeLimit;
        _flushInterval = kLQDefaultFlushInterval;
        _queue = queue;
    }
    return self;
}

- (void)setQueueSizeLimit:(NSUInteger)limit {
    @synchronized(self) {
        if (_flushInterval < minFlushInterval) {
            _queueSizeLimit = minFlushInterval;
        } else {
            _queueSizeLimit = limit;
        }
    }
}

- (void)setFlushInterval:(NSUInteger)interval {
    [self stopFlushTimer];
    @synchronized(self) {
        if (_flushInterval < kLQMinFlushInterval) _flushInterval = kLQMinFlushInterval;
        _flushInterval = interval;
    }
    [self startFlushTimer];
}

#pragma mark - Flusher

- (void)startFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_flushInterval > 0 && _timer == nil) {
            _timer = [NSTimer scheduledTimerWithTimeInterval:_flushInterval target:self selector:@selector(flush) userInfo:nil repeats:YES];
            LQLog(kLQLogLevelInfoVerbose, @"<Liquid> %@ started flush timer: %@", self, _timer);
        }
    });
}

- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_timer) {
            [_timer invalidate];
            LQLog(kLQLogLevelInfoVerbose,@"<Liquid> %@ stopped flush timer: %@", self, _timer);
        }
        _timer = nil;
    });
}

- (void)flush {
    dispatch_async(_queue, ^{
        [self flushSynced];
    });
}

- (void)flushSynced {
    if (![[LQDevice sharedInstance] reachesInternet]) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> There's no Internet connection. Will try to deliver data points later.");
    } else {
        NSMutableArray *failedQueue = [NSMutableArray new];
        while (self.httpQueue.count > 0) {
            LQRequest *queuedHttp = [self.httpQueue firstObject];
            if ([[NSDate new] compare:[queuedHttp nextTryAfter]] > NSOrderedAscending) {
                LQLog(kLQLogLevelHttpData, @"<Liquid> Flushing: %@", [[NSString alloc] initWithData:queuedHttp.json encoding:NSUTF8StringEncoding]);
                LQQueueStatus res = [self sendSynchronousData:queuedHttp.json
                                                   toEndpoint:queuedHttp.url
                                                  usingMethod:queuedHttp.httpMethod];
                [self.httpQueue removeObject:queuedHttp];
                if(res != LQQueueStatusOk) {
                    if([[queuedHttp numberOfTries] intValue] < kLQHttpMaxTries) {
                        if (res == LQQueueStatusUnauthorized) {
                            [queuedHttp incrementNumberOfTries];
                            [queuedHttp incrementNextTryDateIn:(kLQHttpUnreachableWait + [LQHelpers randomInt:kLQHttpUnreachableWait/2])];
                        }
                        if (res == LQQueueStatusRejected) {
                            [queuedHttp incrementNumberOfTries];
                            [queuedHttp incrementNextTryDateIn:(kLQHttpRejectedWait + [LQHelpers randomInt:kLQHttpRejectedWait/2])];
                        }
                        [failedQueue addObject:queuedHttp];
                    }
                }
            } else {
                [self.httpQueue removeObject:queuedHttp];
                [failedQueue addObject:queuedHttp];
                LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Queued failed request is too recent. Waiting for a while to try again (%d/%d)", [[queuedHttp numberOfTries] intValue], kLQHttpMaxTries);
            }
        }
        [self.httpQueue addObjectsFromArray:failedQueue];
        [self archiveHttpQueue];
    }
}

#pragma mark - Queue of requests to send to server

- (void)resetHttpQueue {
    _httpQueue = [NSMutableArray new];
}

- (void)addDictionaryToHttpQueue:(NSDictionary *)dictionary endPoint:(NSString *)endPoint httpMethod:(NSString *)httpMethod {
    NSData *jsonData = [NSData toJSON:dictionary];
    [self addToHttpQueue:jsonData endPoint:endPoint httpMethod:httpMethod];
}

- (void)addToHttpQueue:(NSData *)jsonData endPoint:(NSString *)endPoint httpMethod:(NSString *)httpMethod {
    LQRequest *queuedData = [[LQRequest alloc] initWithUrl:endPoint withHttpMethod:httpMethod withJSON:jsonData];
    LQLog(kLQLogLevelHttpData, @"Adding a HTTP request to the queue, for the endpoint %@ %@ ", httpMethod, endPoint);
    if (self.httpQueue.count >= self.queueSizeLimit) {
        LQLog(kLQLogLevelInfoVerbose, @"<Liquid> Queue exceeded its limit size (%ld). Removing oldest event from queue.", (long) self.queueSizeLimit);
        [self.httpQueue removeObjectAtIndex:0];
    }
    [self.httpQueue addObject:queuedData];
    [self archiveHttpQueue];
}

#pragma mark - Save and Restore to/from Disk

- (BOOL)archiveHttpQueue {
    if (_httpQueue.count > 0) {
        LQLog(kLQLogLevelData, @"<Liquid> Saving queue with %ld items to disk", (unsigned long) _httpQueue.count);
        return [NSKeyedArchiver archiveRootObject:_httpQueue toFile:[LQNetworking liquidHttpQueueFileForToken:self.appToken]];
    } else {
        [LQStorage deleteFileIfExists:[LQNetworking liquidHttpQueueFileForToken:self.appToken] error:nil];
        return FALSE;
    }
}

+ (NSMutableArray*)unarchiveHttpQueueForToken:(NSString *)apiToken {
    NSString *token = apiToken;
    NSString *filePath = [LQNetworking liquidHttpQueueFileForToken:token];
    NSMutableArray *plistArray = nil;
    @try {
        id object = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        plistArray = [object isKindOfClass:[NSArray class]] ? object : nil;
        LQLog(kLQLogLevelData, @"<Liquid> Loading queue with %ld items from disk", (unsigned long) [plistArray count]);
    }
    @catch (NSException *exception) {
        LQLog(kLQLogLevelError, @"<Liquid> %@: Found invalid queue on cache. Destroying it...", [exception name]);
        [LQStorage deleteFileIfExists:filePath error:nil];
    }
    if(plistArray == nil) {
        plistArray = [NSMutableArray new];
    }
    return plistArray;
}

+ (NSString*)liquidHttpQueueFileForToken:(NSString*)apiToken {
    return [LQStorage filePathWithExtension:@"queue" forToken:apiToken];
}

+ (void)deleteHttpQueueFileForToken:(NSString *)token {
    NSString *apiToken = token;
    NSString *filePath = [LQNetworking liquidHttpQueueFileForToken:apiToken];
    LQLog(kLQLogLevelInfo, @"<Liquid> Deleting cached HTTP Queue, for token %@", apiToken);
    NSError *error;
    [LQStorage deleteFileIfExists:filePath error:&error];
    if (error) {
        LQLog(kLQLogLevelError, @"<Liquid> Error deleting cached HTTP Queue, for token %@", apiToken);
    }
}

#pragma mark - Asynchronous send/get methods

- (void)requestData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method completionHandler:(void(^)(LQQueueStatus queueStatus, NSData *responseData))completionHandler {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)sendData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method completionHandler:(void(^)(LQQueueStatus queueStatus, NSData *responseData))completionHandler {
    [self requestData:data toEndpoint:endpoint usingMethod:method completionHandler:completionHandler];
}

- (void)getDataFromEndpoint:(NSString *)endpoint completionHandler:(void(^)(LQQueueStatus queueStatus, NSData *responseData)) completionHandler {
    [self requestData:nil toEndpoint:endpoint usingMethod:@"GET" completionHandler:completionHandler];
}

#pragma mark - Synchronous send/get methods

- (LQQueueStatus)sendSynchronousData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block LQQueueStatus returnQueueStatus;
    [self sendData:data toEndpoint:endpoint usingMethod:method completionHandler:^(LQQueueStatus queueStatus, NSData *responseData) {
        returnQueueStatus = queueStatus;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return returnQueueStatus;
}

- (NSData *)getSynchronousDataFromEndpoint:(NSString *)endpoint {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *returnData = nil;
    [self getDataFromEndpoint:endpoint completionHandler:^(LQQueueStatus queueStatus, NSData *responseData) {
        if (queueStatus == LQQueueStatusOk) {
            returnData = responseData;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return returnData;
}

#pragma mark - Queue status

+ (LQQueueStatus)queueStatusFromData:(NSData *)responseData response:(NSURLResponse *)response error:(NSError *)error {
    if (error) {
        return [[self class] queueStatusFromError:error];
    }
    return [[self class] queueStatusFromResponse:response data:responseData];
}

+ (LQQueueStatus)queueStatusFromError:(NSError *)error {
    if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorCannotConnectToHost || error.code == NSURLErrorNetworkConnectionLost) {
        LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Server is unreachable", (long)error.code);
        return LQQueueStatusUnreachable;
    } else if(error.code == NSURLErrorUserCancelledAuthentication || error.code == NSURLErrorUserAuthenticationRequired) {
        LQLog(kLQLogLevelError, @"<Liquid> Error (%ld) while sending data to server: Unauthorized (check App Token)", (long)error.code);
        return LQQueueStatusUnauthorized;
    }
    LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server: Server error", (long)error.code);
    return LQQueueStatusRejected;
}

+ (LQQueueStatus)queueStatusFromResponse:(NSURLResponse *)response data:(NSData *)responseData {
    if (kLQLogLevel == kLQLogLevelHttpData) {
        LQLog(kLQLogLevelHttpData, @"<Liquid> Response from server: '%@'", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
    }
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if(httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
        LQLog(kLQLogLevelHttpError, @"<Liquid> Error (%ld) while sending data to server.", (long) httpResponse.statusCode);
        return LQQueueStatusRejected;
    }
    return LQQueueStatusOk;
}

@end
