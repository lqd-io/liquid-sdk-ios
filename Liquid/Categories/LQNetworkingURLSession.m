//
//  LQNetworking+NSURLSession.m
//  Liquid
//
//  Created by Miguel M. Almeida on 16/10/15.
//  Copyright © 2015 Liquid. All rights reserved.
//

#import "LQNetworkingURLSession.h"
#import "LQNetworkingProtected.h"

@implementation LQNetworkingURLSession

- (void)requestData:(NSData *)data toEndpoint:(NSString *)endpoint usingMethod:(NSString *)method completionHandler:(void(^)(LQQueueStatus queueStatus, NSData * responseData))completionHandler {
    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [self.urlRequestFactory buildRequestWithMethod:method forEndpoint:endpoint];
    if (data) {
        [request setHTTPBody:data];
    }
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
        LQQueueStatus status = [[self class] queueStatusFromData:responseData response:response error:error];
        completionHandler(status, responseData);
    }];
    [task resume];
}

@end
